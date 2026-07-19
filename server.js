const express = require('express');
const cors = require('cors');
const axios = require('axios');
const rateLimit = require('express-rate-limit');
const { GoogleGenerativeAI } = require('@google/generative-ai');
require('dotenv').config();

// ─── Startup Environment Validation ─────────────────────────────────────────
const GEMINI_KEY = process.env.GEMINI_API_KEY;

console.log('═══════════════════════════════════════════');
console.log('🚀 Rahhal AI Backend — Environment Check');
console.log('═══════════════════════════════════════════');

if (!GEMINI_KEY || GEMINI_KEY === 'your_gemini_api_key_here') {
  console.error('❌ GEMINI_API_KEY: NOT SET');
  console.error('⚠️  WARNING: No Gemini AI API key found!');
  console.error('   All trip generation will fail with "missing-api-key" error.');
  console.error('   Add GEMINI_API_KEY to your .env file.');
} else {
  console.log('✅ GEMINI_API_KEY: Set (Google Gemini AI active)');
}

if (process.env.GOOGLE_PLACES_API_KEY &&
    process.env.GOOGLE_PLACES_API_KEY !== 'your_google_places_api_key_here') {
  console.log('✅ GOOGLE_PLACES_API_KEY: Set (place verification active)');
} else {
  console.log('⚠️  GOOGLE_PLACES_API_KEY: Not set (coordinates unverified)');
}

console.log('═══════════════════════════════════════════');

// Conditional Firebase Admin import (only used if FIREBASE_SERVICE_ACCOUNT is set)
let admin = null;
if (process.env.FIREBASE_SERVICE_ACCOUNT) {
  try {
    admin = require('firebase-admin');
    console.log('[AUTH] Firebase Admin SDK loaded');
  } catch (e) {
    console.warn('[AUTH] firebase-admin not installed. Run: npm install firebase-admin');
  }
}

// ─── In-Memory Caches ────────────────────────────────────────────────────────
// Google Places verification cache: key = "name_en|city", value = { lat, lng, address, placeId, rating }
// TTL: 24 hours — reduces Places API costs significantly
const placesCache = new Map();
const PLACES_CACHE_TTL_MS = 24 * 60 * 60 * 1000; // 24 hours

const app = express();
const PORT = process.env.PORT || 3000;

const corsOptions = {
  origin: (origin, callback) => {
    if (!origin) return callback(null, true); // Mobile apps have no origin
    const allowed = [
      /^http:\/\/localhost:\d+$/,       // Any localhost port
      /^http:\/\/127\.0\.0\.1:\d+$/,   // Loopback
      /^https:\/\/.*\.web\.app$/,       // Firebase Hosting
      /^https:\/\/.*\.firebaseapp\.com$/,
    ];
    const ok = allowed.some(r => r instanceof RegExp ? r.test(origin) : r === origin);
    callback(ok ? null : new Error('CORS blocked'), ok);
  },
  credentials: true,
};
app.use(cors(corsOptions));
app.options('*', cors(corsOptions)); // Handle preflight
app.use(express.json());

// Rate Limiter: Protect API from DDoS & quota drain (Max 100 requests per 15 min per IP)
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests from this IP, please try again later.' },
});

// Rate limiter for heavy trip generation endpoint (Max 10 requests per minute)
const tripLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many trip generation requests, please try again in a minute.' },
});

// Dedicated rate limiter for interactive AI Chat (Max 30 requests per minute)
const chatLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many chat messages, please wait a few seconds.' },
});

// ─── Firebase ID Token Verification Middleware ──────────────────────────────
// Validates Firebase Auth Bearer Token sent by Flutter app via _FirebaseTokenInterceptor
async function authenticateFirebaseToken(req, res, next) {
  const authHeader = req.headers.authorization;

  // Only enforce token verification if FIREBASE_SERVICE_ACCOUNT is configured
  if (process.env.FIREBASE_SERVICE_ACCOUNT && admin) {
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Missing Authorization header' });
    }
    const token = authHeader.split('Bearer ')[1].trim();
    try {
      if (!admin.apps.length) {
        const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
        admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
      }
      const decodedToken = await admin.auth().verifyIdToken(token);
      req.user = decodedToken;
      return next();
    } catch (err) {
      console.error('[AUTH] Token verification failed:', err.message);
      return res.status(403).json({ error: 'Invalid Firebase ID token' });
    }
  }
  next(); // Allow if no service account configured
}

app.use('/api/', limiter);
app.use('/api/generate-trip', tripLimiter, authenticateFirebaseToken);
app.use('/api/chat', chatLimiter, authenticateFirebaseToken);

// Health Check Endpoints for cloud hosting services (Render / Railway)
app.get('/', (req, res) => {
  res.status(200).send('🚀 Rahhal AI Proxy Server is running!');
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', service: 'Rahhal AI Proxy', timestamp: new Date() });
});

// Detailed status endpoint — Flutter uses this to check AI readiness before generating
app.get('/api/status', (req, res) => {
  const hasGeminiKey = !!(process.env.GEMINI_API_KEY &&
    process.env.GEMINI_API_KEY !== 'your_gemini_api_key_here');
  const hasPlacesKey = !!(process.env.GOOGLE_PLACES_API_KEY &&
    process.env.GOOGLE_PLACES_API_KEY !== 'your_google_places_api_key_here');

  res.json({
    status: 'ok',
    ai_engine: hasGeminiKey ? 'gemini' : 'none',
    ai_ready: hasGeminiKey,
    places_verification: hasPlacesKey,
    timestamp: new Date().toISOString(),
  });
});

// Helper function to call Google Gemini API using official SDK & REST API fallback
// Supports both legacy AIzaSy... and new AQ.... key formats
async function callGemini(systemPrompt, messages, maxTokens = 4000, apiKey) {
  const modelsToTry = ['gemini-flash-latest', 'gemini-flash-lite-latest'];
  let lastError = null;

  // ─── Attempt 1: Official Google Generative AI SDK ─────────────────────────
  for (const modelName of modelsToTry) {
    try {
      console.log(`[GEMINI SDK] Trying model: ${modelName} | Key prefix: ${apiKey.substring(0, 6)}...`);
      const genAI = new GoogleGenerativeAI(apiKey);
      const model = genAI.getGenerativeModel({
        model: modelName,
        generationConfig: {
          temperature: 0.7,
          maxOutputTokens: maxTokens,
        },
        ...(systemPrompt ? { systemInstruction: systemPrompt } : {}),
      });

      const history = messages.slice(0, -1).map(m => ({
        role: m.role === 'assistant' || m.role === 'model' ? 'model' : 'user',
        parts: [{ text: m.content }],
      }));

      const lastMessage = messages[messages.length - 1];
      const chat = model.startChat({ history });
      const result = await chat.sendMessage(lastMessage.content);
      const text = result.response.text();

      console.log(`[GEMINI SDK] ✅ Success with ${modelName}! Response length: ${text.length}`);
      return text;
    } catch (error) {
      lastError = error;
      console.warn(`[GEMINI SDK] ${modelName} error: ${error.message}`);
    }
  }

  // ─── Attempt 2: Direct REST API Fallback (Supports AQ. and AIzaSy keys 100%) ──
  try {
    console.log('[GEMINI REST] Trying direct HTTP REST API fallback (v1beta)...');
    const userMessage = messages[messages.length - 1]?.content || '';
    const fullPrompt = systemPrompt ? `${systemPrompt}\n\n${userMessage}` : userMessage;

    const restUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=${apiKey}`;
    const response = await axios.post(
      restUrl,
      {
        contents: [
          {
            role: 'user',
            parts: [{ text: fullPrompt }],
          },
        ],
        generationConfig: {
          temperature: 0.7,
          maxOutputTokens: maxTokens,
        },
      },
      {
        headers: { 'Content-Type': 'application/json' },
        timeout: 60000,
      }
    );

    const text = response.data?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (text && text.length > 0) {
      console.log(`[GEMINI REST] ✅ REST API Success! Response length: ${text.length}`);
      return text;
    }
  } catch (restErr) {
    console.error(`[GEMINI REST ERROR] ${restErr.response?.data?.error?.message || restErr.message}`);
    lastError = restErr;
  }

  const errMsg = lastError?.response?.data?.error?.message || lastError?.message || '';
  const status = lastError?.response?.status || lastError?.status || 0;

  if (errMsg.includes('API_KEY_INVALID') || errMsg.includes('API key not valid') || status === 401 || status === 403) {
    throw new Error('invalid-api-key');
  }
  if (errMsg.includes('RESOURCE_EXHAUSTED') || status === 429) {
    throw new Error('rate-limit');
  }
  throw new Error(`gemini-error: ${errMsg}`);
}

// Unified AI Engine Call: Uses Google Gemini as the sole AI engine
async function callAI(systemPrompt, messages, maxTokens = 4000) {
  // 1. Try primary Gemini key
  const geminiKey = process.env.GEMINI_API_KEY;
  if (geminiKey && geminiKey !== 'your_gemini_api_key_here' && geminiKey.length > 10) {
    try {
      console.log('[AI Engine] Using Google Gemini...');
      return await callGemini(systemPrompt, messages, maxTokens, geminiKey);
    } catch (e) {
      console.warn('[AI Engine] GEMINI_API_KEY failed:', e.message);
      // Fall through to GOOGLE_PLACES_API_KEY fallback below instead of failing immediately
    }
  }

  // 2. Fallback to GOOGLE_PLACES_API_KEY if it starts with AIzaSy
  const placesKey = process.env.GOOGLE_PLACES_API_KEY;
  if (placesKey && placesKey.startsWith('AIzaSy') && placesKey !== geminiKey) {
    try {
      console.log('[AI Engine] Trying GOOGLE_PLACES_API_KEY fallback for Gemini...');
      return await callGemini(systemPrompt, messages, maxTokens, placesKey);
    } catch (e) {
      console.warn('[AI Engine] Fallback GOOGLE_PLACES_API_KEY failed:', e.message);
    }
  }

  throw new Error('invalid-api-key');
}

// ─── Google Places API: verify a place and return real coordinates ────────────
//
// Strategy (uses Places API (New) — the legacy Places API text search /
// details endpoints return REQUEST_DENIED for projects that only enabled
// the new API):
//   1. Check in-memory cache (24hr TTL) to avoid redundant API calls.
//   2. Call places:searchText with "name_en + city", requesting rating/phone/
//      website fields directly via the field mask (single call, no separate
//      Details request needed).
//   3. Return verified data; caller merges it into the AI response.
//   4. If no GOOGLE_PLACES_API_KEY is set, skip gracefully (log a warning).
async function verifyPlaceWithGoogle(nameEn, cityEn, userLat, userLng) {
  const placesKey = process.env.GOOGLE_PLACES_API_KEY;
  if (!placesKey || placesKey === 'your_google_places_api_key_here') {
    return null; // Places API not configured — skip gracefully
  }

  const cacheKey = `${nameEn.toLowerCase().trim()}|${cityEn.toLowerCase().trim()}${userLat && userLng ? `|${userLat.toFixed(2)},${userLng.toFixed(2)}` : ''}`;
  const now = Date.now();

  // Return cached result if still fresh
  if (placesCache.has(cacheKey)) {
    const cached = placesCache.get(cacheKey);
    if (now - cached.timestamp < PLACES_CACHE_TTL_MS) {
      return cached.data; // may be null if previously not found
    }
    placesCache.delete(cacheKey);
  }

  try {
    const body = {
      textQuery: `${nameEn} ${cityEn}`,
      languageCode: 'en',
    };

    if (userLat && userLng) {
      body.locationBias = {
        circle: {
          center: { latitude: parseFloat(userLat), longitude: parseFloat(userLng) },
          radius: 50000, // 50km radius bias
        },
      };
    }

    const searchRes = await axios.post(
      'https://places.googleapis.com/v1/places:searchText',
      body,
      {
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': placesKey,
          'X-Goog-FieldMask':
            'places.id,places.displayName,places.location,places.formattedAddress,places.rating,places.nationalPhoneNumber,places.websiteUri',
        },
        timeout: 6000,
      }
    );

    const results = searchRes.data.places;
    if (!results || results.length === 0) {
      placesCache.set(cacheKey, { data: null, timestamp: now });
      console.warn(`[PLACES] Not found: "${nameEn}" in ${cityEn}`);
      return null;
    }

    const top = results[0];
    const verified = {
      lat: top.location.latitude,
      lng: top.location.longitude,
      address: top.formattedAddress || '',
      placeId: top.id,
      rating: top.rating || null,
      phoneNumber: top.nationalPhoneNumber || null,
      website: top.websiteUri || null,
    };
    placesCache.set(cacheKey, { data: verified, timestamp: now });
    console.log(`[PLACES] Verified: "${nameEn}" → lat=${verified.lat}, lng=${verified.lng}, placeId=${verified.placeId}`);
    return verified;

  } catch (err) {
    const apiError = err.response?.data?.error;
    console.error(`[PLACES] Text Search error for "${nameEn}":`, apiError?.message || err.message);
    placesCache.set(cacheKey, { data: null, timestamp: now });
    return null;
  }
}

// ─── Verify ALL stops & restaurants in a parsed Claude trip response ──────────
//
// Runs Google Places verification in parallel (with concurrency cap of 5)
// to avoid hammering the API quota.
async function verifyAllPlacesInTrip(tripData, destinationEn, userLat, userLng) {
  const placesKey = process.env.GOOGLE_PLACES_API_KEY;
  if (!placesKey || placesKey === 'your_google_places_api_key_here') {
    console.warn('[PLACES] GOOGLE_PLACES_API_KEY not set — skipping place verification.');
    return tripData; // Return as-is
  }

  // Collect all items to verify: { ref to stop/restaurant, nameEn }
  const tasks = [];

  if (Array.isArray(tripData.days)) {
    for (const day of tripData.days) {
      if (Array.isArray(day.stops)) {
        for (const stop of day.stops) {
          if (stop.name_en) {
            tasks.push({ item: stop, nameEn: stop.name_en });
          }
        }
      }
      if (day.recommended_restaurant && day.recommended_restaurant.name_en) {
        tasks.push({ item: day.recommended_restaurant, nameEn: day.recommended_restaurant.name_en });
      }
    }
  }
  if (Array.isArray(tripData.all_restaurants)) {
    for (const r of tripData.all_restaurants) {
      if (r.name_en) {
        tasks.push({ item: r, nameEn: r.name_en });
      }
    }
  }

  // Process in batches of 5 concurrent requests
  const CONCURRENCY = 5;
  for (let i = 0; i < tasks.length; i += CONCURRENCY) {
    const batch = tasks.slice(i, i + CONCURRENCY);
    await Promise.all(
      batch.map(async ({ item, nameEn }) => {
        const verified = await verifyPlaceWithGoogle(nameEn, destinationEn, userLat, userLng);
        if (verified) {
          // Overwrite Claude's hallucinated coordinates with real Google data
          item.latitude  = verified.lat;
          item.longitude = verified.lng;
          if (verified.address) {
            item.google_address = verified.address; // keep original Arabic address too
          }
          if (verified.placeId) {
            item.place_id = verified.placeId;
          }
          if (verified.rating !== null && verified.rating !== undefined) {
            item.rating = verified.rating; // overwrite Claude's guessed rating
          }
          if (verified.website) {
            item.booking_url = item.booking_url || verified.website;
          }
          item.coords_verified = true;
        } else {
          // Place not found in Google — flag it but keep Claude's data
          item.coords_verified = false;
          console.warn(`[PLACES] Using unverified coords for: ${nameEn}`);
        }
      })
    );
  }

  const verifiedCount = tasks.filter((_, idx) => {
    // Re-check by looping tasks after all resolved
    return true; // just for counting
  }).length;
  console.log(`[PLACES] Verification done: ${tasks.length} places processed for "${destinationEn}"`);

  return tripData;
}

// ─── POST /api/generate-trip ────────────────────────────────────────────────
app.post('/api/generate-trip', async (req, res) => {
  const {
    destination,
    durationDays,
    budgetTier,
    travelStyles,
    travelersCount,
    startDate,
    userLat,        // ← GPS latitude from user device
    userLng,        // ← GPS longitude from user device
    countryCode,    // ← ISO country code e.g. "IQ", "SA"
  } = req.body;

  if (!destination || !durationDays || !budgetTier) {
    return res.status(400).json({ error: 'Missing required parameters' });
  }

  // ── Build GPS context string for the AI ─────────────────────────────────
  // When GPS is available, this dramatically improves location accuracy
  const hasGPS = userLat && userLng &&
    Math.abs(parseFloat(userLat)) > 0.001 &&
    Math.abs(parseFloat(userLng)) > 0.001;

  const gpsContext = hasGPS
    ? `
CRITICAL LOCATION DATA — The user's EXACT GPS position is:
  Latitude:  ${parseFloat(userLat).toFixed(6)}
  Longitude: ${parseFloat(userLng).toFixed(6)}
  Country Code: ${countryCode || 'unknown'}

This means:
1. The destination is confirmed to be at these exact coordinates.
2. ALL stops and restaurants MUST have coordinates within 50km of 
   lat=${parseFloat(userLat).toFixed(4)}, lng=${parseFloat(userLng).toFixed(4)}.
3. Use these GPS coordinates as the CENTER of the trip map.
4. The city center for this location is approximately at these coordinates.
5. Generate places that are REALISTICALLY accessible from this GPS point.
`
    : '';

  const systemPrompt = `You are a professional travel planner expert in creating highly detailed, realistic, and personalized trip itineraries.

ABSOLUTE RULES — NEVER VIOLATE THESE:

RULE 1 — NO REPETITION:
Every attraction, restaurant, park, market, or any place mentioned across ALL days MUST be UNIQUE. If a place appears on Day 1, it CANNOT appear on Day 2, 3, or any other day.
This applies to: stops, recommended_restaurant, and all_restaurants.
COUNT your places before submitting — if any name appears twice, REWRITE that day.

RULE 2 — REAL PLACE NAMES ONLY:
ALL names must be REAL, specific places that actually exist in ${destination}.
FORBIDDEN generic names: "National Museum", "Central Park", "Main Landmark", "Grand Bazaar" (unless that is the ACTUAL name of a place in that city).
REQUIRED: Use official local names with correct Arabic transliterations.

RULE 3 — DAY VARIETY:
Each day MUST have a distinct theme and explore a DIFFERENT part of the city:
- Day 1: Historic/Cultural district
- Day 2: Nature/Parks/Waterfront  
- Day 3: Shopping/Markets/Local neighborhoods
- Day 4: Modern attractions/Viewpoints
- Day 5+: Repeat themes with completely different places

RULE 4 — RESTAURANT VARIETY:
Each day's recommended_restaurant must be a DIFFERENT restaurant.
all_restaurants list must contain UNIQUE restaurants (not repeating recommended_restaurant).

RULE 5 — ACCURATE COORDINATES:
Every latitude/longitude must be the actual GPS coordinates of that specific real place. Google Maps-verifiable coordinates only.
${hasGPS ? `All coordinates MUST be within 50km of lat=${parseFloat(userLat).toFixed(4)}, lng=${parseFloat(userLng).toFixed(4)}.` : ''}

${gpsContext}

Your output MUST be a single, valid, and minified JSON object matching the schema below.
You must NOT include any conversational filler, markdown formatting (do NOT wrap in \`\`\`json ... \`\`\`), or extra text explanation before or after the JSON.
The text values inside the JSON (such as themes, summaries, addresses, descriptions, tips, and names) MUST be in ARABIC (except for English name fields or URLs).

Required JSON Schema:
{
  "destination": "Name of the destination in Arabic",
  "destination_en": "Name of the destination in English (e.g. 'Istanbul', 'Cairo', 'Paris')",
  "country_code": "2-letter ISO country code (e.g., 'TR', 'EG', 'FR', 'AE', 'SA')",
  "ai_summary": "Overall engaging summary of the trip in Arabic",
  "budget_total_usd": 123.45 (double, total cost estimate),
  "hero_image_query": "English keywords for a search query of a representative high-quality image of the destination (e.g. 'istanbul sunset bosporus')",
  "days": [
    {
      "day_number": 1,
      "theme": "Arabic theme title for this day",
      "date_offset": 0 (0 for day 1, 1 for day 2, etc.),
      "summary": "Arabic summary description of the day's itinerary",
      "stops": [
        {
          "order_index": 0 (0, 1, 2, ...),
          "name": "Arabic name of the attraction/place",
          "name_en": "English name of the attraction/place",
          "category": "String value from this list only: ['museum', 'restaurant', 'park', 'shopping', 'landmark', 'beach', 'mosque', 'palace', 'market', 'viewpoint', 'other']",
          "time_of_day": "morning" or "afternoon" or "evening",
          "start_time": "HH:MM format, e.g. '09:00'",
          "duration_minutes": 90 (integer),
          "latitude": 41.0086 (double, correct coordinates for the place),
          "longitude": 28.9798 (double, correct coordinates for the place),
          "address": "Arabic address/area location",
          "cost_usd": 15.00 (double, estimated entry cost in USD, 0 if free),
          "ai_tip": "Arabic helper tip for visitors",
          "booking_required": false (boolean),
          "booking_url": "https://example.com/tickets or null",
          "image_search_query": "3-5 specific English keywords for a beautiful photo of this exact place"
        }
      ],
      "recommended_restaurant": {
        "name": "Arabic name of recommended restaurant",
        "name_en": "English name of recommended restaurant",
        "cuisine_type": "Arabic cuisine category",
        "halal_certified": true (boolean),
        "rating": 4.7 (double),
        "price_per_person_usd": 25.00 (double),
        "address": "Arabic address",
        "latitude": 41.0082 (double),
        "longitude": 28.9784 (double),
        "ai_description": "Arabic paragraph describing why this restaurant is recommended",
        "image_search_query": "3-5 English keywords for food/restaurant photo"
      }
    }
  ],
  "all_restaurants": [
    {
      "name": "Arabic name of a restaurant",
      "name_en": "English name of a restaurant",
      "cuisine_type": "Arabic cuisine",
      "halal_certified": true,
      "rating": 4.5,
      "price_per_person_usd": 20.0,
      "address": "Arabic address",
      "latitude": 41.008,
      "longitude": 28.978,
      "ai_description": "Arabic description",
      "image_search_query": "3-5 English keywords for this restaurant cuisine photo"
    }
  ],
  "budget_breakdown": {
    "accommodation_usd": 400.0,
    "food_usd": 250.0,
    "transport_usd": 120.0,
    "activities_usd": 150.0,
    "shopping_usd": 80.0
  },
  "travel_tips": [
    "Arabic tip 1",
    "Arabic tip 2"
  ],
  "best_time_to_visit": "Arabic description of best travel season",
  "currency": "3-letter currency code (e.g., 'TRY', 'EUR')",
  "timezone": "Timezone offset string (e.g. 'UTC+3', 'GMT+2')"
}`;

  const userPrompt = `Generate a customized travel itinerary for:
- Destination: ${destination}
- Duration: ${durationDays} days
- Budget Tier: ${budgetTier} (economy / mid / luxury)
- Travel Styles: ${travelStyles ? travelStyles.join(', ') : 'any'}
- Travelers Count: ${travelersCount || 1}
${startDate ? `- Start Date: ${startDate}` : ''}
${hasGPS ? `- User GPS Location: lat=${parseFloat(userLat).toFixed(6)}, lng=${parseFloat(userLng).toFixed(6)}` : ''}
${countryCode ? `- Country: ${countryCode}` : ''}`;

  const messages = [{ role: 'user', content: userPrompt }];

  try {
    const estimatedTokens = Math.max(6000, durationDays * 1400);
    const MAX_TOKENS = Math.min(estimatedTokens, 12000);

    async function requestAndParse(extraInstruction) {
      const msgs = extraInstruction
        ? [{ role: 'user', content: userPrompt + '\n\n' + extraInstruction }]
        : messages;
      const rawReply = await callAI(systemPrompt, msgs, MAX_TOKENS);

      let cleanJson = rawReply.trim();
      if (cleanJson.includes('```')) {
        const jsonMatch = cleanJson.match(/```(?:json)?\s*([\s\S]*?)```/);
        if (jsonMatch) cleanJson = jsonMatch[1].trim();
      }

      const jsonStart = cleanJson.indexOf('{');
      const jsonEnd = cleanJson.lastIndexOf('}');
      if (jsonStart === -1 || jsonEnd === -1) {
        throw new Error('malformed-response');
      }
      cleanJson = cleanJson.substring(jsonStart, jsonEnd + 1);

      let parsed;
      try {
        parsed = JSON.parse(cleanJson);
      } catch (parseErr) {
        try {
          const repaired = cleanJson.replace(/,\s*}/g, '}').replace(/,\s*]/g, ']');
          parsed = JSON.parse(repaired);
          console.log('[TRIP] JSON repaired successfully');
        } catch (repairErr) {
          // Both the raw parse and the trailing-comma repair failed —
          // normalize to the same error the caller already knows how to handle.
          throw new Error('malformed-response');
        }
      }

      if (!Array.isArray(parsed.days) || parsed.days.length !== Number(durationDays)) {
        throw new Error('incomplete-itinerary');
      }
      return parsed;
    }

    let parsedData;
    let lastError;
    const maxAttempts = 3; // 1 initial + 2 retries
    for (let attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        const extraInstruction = attempt > 0
          ? `IMPORTANT REMINDER: your previous reply was truncated, incomplete, or had invalid JSON syntax. Return ALL ${durationDays} days as a single complete, valid, non-truncated JSON object with correct JSON syntax (no trailing commas, properly escaped quotes inside strings). Keep descriptions concise if needed to fit within the token limit, but NEVER omit a day.`
          : undefined;
        parsedData = await requestAndParse(extraInstruction);
        lastError = null;
        break;
      } catch (err) {
        lastError = err;
        console.warn(`[TRIP] attempt ${attempt + 1}/${maxAttempts} failed:`, err.message);
      }
    }
    if (lastError) {
      // Whatever the underlying cause, surface it as the friendly, already-handled error.
      throw new Error('malformed-response');
    }

    // Deduplicate
    parsedData = deduplicateTripPlan(parsedData);

    // ── If GPS available: Check distance of AI coordinates ─────
    if (hasGPS && parsedData.days) {
      const centerLat = parseFloat(userLat);
      const centerLng = parseFloat(userLng);
      
      for (const day of parsedData.days) {
        if (day.stops) {
          for (const stop of day.stops) {
            // If stop coordinates are suspiciously far (>200km) from user — flag it
            const distKm = haversineDistance(
              centerLat, centerLng, 
              parseFloat(stop.latitude || 0), 
              parseFloat(stop.longitude || 0)
            );
            if (distKm > 200) {
              console.warn(
                `[GPS] Stop "${stop.name_en}" is ${distKm.toFixed(0)}km from user — coords may be wrong`
              );
              stop.coords_verified = false;
            }
          }
        }
      }
    }

    // Google Places verification (uses English city name)
    const destinationEn = parsedData.destination_en || destination;
    parsedData = await verifyAllPlacesInTrip(parsedData, destinationEn, userLat, userLng);

    return res.status(200).json(parsedData);
  } catch (error) {
    console.error('[API ERROR] generate-trip:', error.message);
    if (error.message === 'missing-api-key') {
      return res.status(401).json({ error: 'GEMINI_API_KEY not configured.' });
    }
    if (error.message === 'invalid-api-key') {
      return res.status(403).json({ error: 'Invalid GEMINI_API_KEY.' });
    }
    if (error.message === 'rate-limit') {
      return res.status(429).json({ error: 'Rate limit exceeded. Try again in a moment.' });
    }
    if (error.message === 'malformed-response' || error.message === 'incomplete-itinerary') {
      return res.status(500).json({
        error: 'AI response was incomplete or malformed even after retry. Try reducing trip duration.'
      });
    }
    return res.status(500).json({ error: 'Failed to generate trip: ' + error.message });
  }
});

// ── Helper: Haversine distance between two GPS points (in km) ────────────────
function haversineDistance(lat1, lng1, lat2, lng2) {
  const R = 6371; // Earth radius in km
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLng = (lng2 - lng1) * Math.PI / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) *
    Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLng / 2) * Math.sin(dLng / 2);
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

// Helper to remove duplicate stops and restaurants across days
function deduplicateTripPlan(plan) {
  if (!plan) return plan;
  const seenPlaces = new Set();
  const seenRestaurants = new Set();

  if (plan.days && Array.isArray(plan.days)) {
    for (const day of plan.days) {
      if (day.stops && Array.isArray(day.stops)) {
        day.stops = day.stops.filter(stop => {
          const key = stop.name_en?.toLowerCase().trim() || stop.name?.toLowerCase().trim();
          if (!key) return true;
          if (seenPlaces.has(key)) {
            console.warn(`[DEDUP] Removed duplicate stop: ${stop.name_en || stop.name}`);
            return false;
          }
          seenPlaces.add(key);
          return true;
        });

        day.stops.forEach((stop, i) => {
          stop.order_index = i;
        });
      }

      if (day.recommended_restaurant) {
        const rKey = day.recommended_restaurant.name_en?.toLowerCase().trim() ||
                     day.recommended_restaurant.name?.toLowerCase().trim();
        if (rKey) {
          if (seenRestaurants.has(rKey)) {
            console.warn(`[DEDUP] Repeated restaurant: ${day.recommended_restaurant.name_en || day.recommended_restaurant.name}`);
          }
          seenRestaurants.add(rKey);
        }
      }
    }
  }

  const seenAllRest = new Set();
  if (plan.all_restaurants && Array.isArray(plan.all_restaurants)) {
    plan.all_restaurants = plan.all_restaurants.filter(r => {
      const key = r.name_en?.toLowerCase().trim() || r.name?.toLowerCase().trim();
      if (!key) return true;
      if (seenAllRest.has(key)) return false;
      seenAllRest.add(key);
      return true;
    });
  }

  const totalStops = (plan.days || []).reduce((sum, d) => sum + (d.stops?.length || 0), 0);
  console.log(`[DEDUP] Final: ${totalStops} unique stops, ${(plan.all_restaurants || []).length} restaurants`);

  return plan;
}

// Helper to translate Arabic city names to English for better stock photo search results
function sanitizePhotoQuery(rawQuery) {
  if (!rawQuery) return 'travel destination';
  let q = rawQuery.trim();

  const arabicToEnglishMap = {
    'القاهرة': 'Cairo',
    'إسطنبول': 'Istanbul',
    'استنبول': 'Istanbul',
    'دبي': 'Dubai',
    'باريس': 'Paris',
    'لندن': 'London',
    'طوكيو': 'Tokyo',
    'روما': 'Rome',
    'مراكش': 'Marrakech',
    'الرياض': 'Riyadh',
    'جدة': 'Jeddah',
    'مكة': 'Mecca',
    'المدينة': 'Madinah',
    'أبوظبي': 'Abu Dhabi',
    'الدوحة': 'Doha',
    'مسقط': 'Muscat',
    'الكويت': 'Kuwait',
    'عمان': 'Amman',
    'بيروت': 'Beirut',
  };

  for (const [ar, en] of Object.entries(arabicToEnglishMap)) {
    q = q.replace(new RegExp(ar, 'g'), en);
  }

  // Strip remaining Arabic letters to keep query purely in English
  q = q.replace(/[\u0600-\u06FF]/g, '').replace(/\s+/g, ' ').trim();

  return q.length > 0 ? q : 'travel destination';
}

// ─── GET /api/photos ────────────────────────────────────────────────────────
app.get('/api/photos', async (req, res) => {
  const { query } = req.query;
  if (!query || !query.trim()) {
    return res.status(400).json({ error: 'Missing query parameter' });
  }

  const cleanQuery = sanitizePhotoQuery(query);

  // ── محاولة 1: Unsplash API (أفضل جودة) ─────────────────────────────────
  const unsplashKey = process.env.UNSPLASH_ACCESS_KEY;
  if (unsplashKey && unsplashKey !== 'your_unsplash_access_key_here' && unsplashKey.length > 10) {
    try {
      const response = await axios.get('https://api.unsplash.com/search/photos', {
        params: {
          query: cleanQuery,
          per_page: 3,
          orientation: 'landscape',
          content_filter: 'high',
        },
        headers: { Authorization: `Client-ID ${unsplashKey}` },
        timeout: 5000,
      });

      if (response.data?.results?.length > 0) {
        // اختر صورة عشوائية من أول 3 نتائج لتنوع أفضل
        const idx = Math.floor(Math.random() * Math.min(3, response.data.results.length));
        const photo = response.data.results[idx];
        const photoUrl = photo.urls.regular; // 1080px عرض
        console.log(`[PHOTOS] Unsplash success for: "${cleanQuery}"`);
        return res.status(200).json({
          url: photoUrl,
          source: 'unsplash',
          photographer: photo.user.name,
        });
      }
    } catch (error) {
      console.error('[PHOTOS] Unsplash error:', error.message);
    }
  }

  // ── محاولة 2: Pexels API (مجاني بدون حد يومي صارم) ──────────────────────
  const pexelsKey = process.env.PEXELS_API_KEY;
  if (pexelsKey && pexelsKey !== 'your_pexels_api_key_here' && pexelsKey.length > 10) {
    try {
      const response = await axios.get('https://api.pexels.com/v1/search', {
        params: {
          query: cleanQuery,
          per_page: 3,
          orientation: 'landscape',
        },
        headers: { Authorization: pexelsKey },
        timeout: 5000,
      });

      if (response.data?.photos?.length > 0) {
        const idx = Math.floor(Math.random() * Math.min(3, response.data.photos.length));
        const photo = response.data.photos[idx];
        const photoUrl = photo.src.large; // ~1280px
        console.log(`[PHOTOS] Pexels success for: "${cleanQuery}"`);
        return res.status(200).json({
          url: photoUrl,
          source: 'pexels',
        });
      }
    } catch (error) {
      console.error('[PHOTOS] Pexels error:', error.message);
    }
  }

  // ── Fallback: Picsum Photos (صور طبيعية جميلة، بدون مفتاح، متسقة) ──────
  // نستخدم hash الـ query لنفس الصورة لنفس المكان دائماً (consistent)
  const hashCode = cleanQuery.split('').reduce((acc, char) => {
    return ((acc << 5) - acc) + char.charCodeAt(0);
  }, 0);
  const seed = Math.abs(hashCode) % 1000;
  const fallbackUrl = `https://picsum.photos/seed/${seed}/800/600`;

  console.log(`[PHOTOS] Using Picsum fallback for: "${cleanQuery}" (seed: ${seed})`);
  return res.status(200).json({ url: fallbackUrl, source: 'fallback' });
});

// ─── POST /api/chat ─────────────────────────────────────────────────────────
app.post('/api/chat', async (req, res) => {
  const { destination, tripSummary, conversationHistory, userMessage } = req.body;

  if (!destination || !userMessage) {
    return res.status(400).json({ error: 'Missing required parameters' });
  }

  const systemPrompt = `You are "رحّال AI", an expert Arabic-speaking AI travel assistant built into the Rahhal travel planning app.

The traveler is visiting: ${destination}.
Their trip summary: ${tripSummary || 'Trip details not provided.'}

YOUR CAPABILITIES — you can answer questions about:
- Specific attractions, museums, parks, markets, restaurants in ${destination}
- Opening hours, ticket prices, booking requirements
- Transportation options (metro, bus, taxi, Uber/Careem)
- Weather, best times to visit, local customs
- Local food recommendations with specific dish names
- Safety tips and cultural etiquette  
- Currency exchange, tipping customs
- Day trip suggestions near ${destination}
- Hotel neighborhoods and accommodation advice
- Shopping recommendations
- ANY other travel-related question about ${destination}

RULES:
1. Always respond in ARABIC
2. Keep responses focused and practical (2-5 sentences max unless a list is needed)
3. Mention REAL place names that exist in ${destination}
4. If you don't know something specific, acknowledge it and provide the best advice you can
5. Be friendly, warm, and encouraging — like a knowledgeable local friend

The traveler can ask you ANYTHING about their trip — answer helpfully and specifically.`;

  // Map client history format to Gemini format
  const mappedMessages = [];
  if (conversationHistory && Array.isArray(conversationHistory)) {
    conversationHistory.forEach((msg) => {
      // role must be either 'user' or 'assistant'
      const role = (msg.role === 'model' || msg.role === 'ai' || msg.role === 'bot') ? 'assistant' : 'user';
      mappedMessages.push({
        role: role,
        content: msg.content
      });
    });
  }

  // Add the final user message
  mappedMessages.push({
    role: 'user',
    content: userMessage
  });

  try {
    const reply = await callAI(systemPrompt, mappedMessages, 1500);
    return res.status(200).json({ reply });
  } catch (error) {
    console.error('[API ERROR] chat failed:', error.message);
    if (error.message === 'missing-api-key') {
      return res.status(401).json({ error: 'GEMINI_API_KEY is not configured in backend .env file.' });
    }
    if (error.message === 'invalid-api-key') {
      return res.status(403).json({ error: 'The provided GEMINI_API_KEY is invalid or unauthorized.' });
    }
    if (error.message === 'rate-limit') {
      return res.status(429).json({ error: 'API rate limit exceeded. Please try again in a few moments.' });
    }
    return res.status(500).json({ error: 'Failed to get chat reply: ' + error.message });
  }
});

// ─── Currency Converter ───────────────────────────────────────────────────────
// Uses Frankfurter.app — completely free, no API key required
const currencyCache = new Map(); // in-memory cache

app.get('/api/currency', async (req, res) => {
  const { base = 'USD', target } = req.query;
  if (!target) return res.status(400).json({ error: 'target currency code is required' });

  const cacheKey = `${base}-${target}`;
  const now = Date.now();

  // Cache for 6 hours
  if (currencyCache.has(cacheKey)) {
    const cached = currencyCache.get(cacheKey);
    if (now - cached.timestamp < 6 * 60 * 60 * 1000) {
      return res.status(200).json({ base, target, rate: cached.rate, cached: true });
    }
  }

  try {
    const response = await axios.get(
      `https://api.frankfurter.app/latest?base=${base}&symbols=${target}`,
      { timeout: 5000 }
    );
    const rate = response.data.rates[target];
    if (!rate) return res.status(404).json({ error: `No rate found for ${target}` });

    currencyCache.set(cacheKey, { rate, timestamp: now });
    return res.status(200).json({ base, target, rate });
  } catch (error) {
    console.error('[CURRENCY ERROR]', error.message);
    return res.status(500).json({ error: 'Failed to fetch exchange rate' });
  }
});

// ─── GET /api/weather ───────────────────────────────────────────────────────
app.get('/api/weather', async (req, res) => {
  const { city, countryCode } = req.query;
  if (!city) return res.status(400).json({ error: 'city param required' });

  const owmKey = process.env.OPENWEATHER_API_KEY;

  const mockWeather = {
    temp: 24,
    feelsLike: 22,
    description: 'مشمس (بيانات محاكاة)',
    icon: '01d',
    humidity: 45,
    windSpeed: 3.2,
    cityName: city,
    isMock: true,
  };

  if (!owmKey || owmKey === 'your_openweather_key_here') {
    return res.status(200).json(mockWeather);
  }

  try {
    const cleanCity = sanitizePhotoQuery(city);
    const query = countryCode ? `${cleanCity},${countryCode}` : cleanCity;
    const response = await axios.get(
      'https://api.openweathermap.org/data/2.5/weather',
      {
        params: {
          q: query,
          appid: owmKey,
          units: 'metric',
          lang: 'ar',
        },
        timeout: 6000,
      }
    );
    const d = response.data;
    return res.status(200).json({
      temp: Math.round(d.main.temp),
      feelsLike: Math.round(d.main.feels_like),
      description: d.weather[0].description,
      icon: d.weather[0].icon,
      humidity: d.main.humidity,
      windSpeed: d.wind.speed,
      cityName: d.name,
      isMock: false,
    });
  } catch (err) {
    console.error('[WEATHER ERROR]', err.message, '- returning fallback weather');
    return res.status(200).json(mockWeather);
  }
});

// ─── GET /api/nearby-places ──────────────────────────────────────────────────
app.get('/api/nearby-places', async (req, res) => {
  const { lat, lng, radius = 2000 } = req.query;

  if (!lat || !lng) {
    return res.status(400).json({ error: 'lat and lng are required' });
  }

  const overpassQuery = `
    [out:json][timeout:15];
    (
      node["tourism"="attraction"](around:${radius},${lat},${lng});
      node["tourism"="museum"](around:${radius},${lat},${lng});
      node["amenity"="restaurant"]["cuisine"](around:${radius},${lat},${lng});
      node["leisure"="park"](around:${radius},${lat},${lng});
      node["tourism"="viewpoint"](around:${radius},${lat},${lng});
    );
    out body 20;
  `;

  try {
    const response = await axios.post(
      'https://overpass-api.de/api/interpreter',
      overpassQuery,
      {
        headers: { 'Content-Type': 'text/plain' },
        timeout: 20000,
      }
    );

    const elements = response.data?.elements || [];
    const places = elements
      .filter(el => el.tags && (el.tags.name || el.tags['name:ar'] || el.tags['name:en']))
      .map(el => ({
        id: el.id,
        name: el.tags['name:ar'] || el.tags.name || el.tags['name:en'] || 'مكان',
        name_en: el.tags['name:en'] || el.tags.name || '',
        lat: el.lat,
        lng: el.lon,
        type: el.tags.tourism || el.tags.amenity || el.tags.leisure || 'other',
      }))
      .slice(0, 15); // max 15 places

    return res.status(200).json({ places });
  } catch (error) {
    console.error('[NEARBY] Overpass API error:', error.message);
    return res.status(500).json({ error: 'Failed to fetch nearby places', places: [] });
  }
});

// ─── Self Keep-Alive Ping (prevents Render free tier sleep) ─────────────────
// Render free tier puts the server to sleep after 15 minutes of inactivity.
// This self-ping sends a lightweight GET /health every 14 minutes to keep it awake.
const SELF_PING_INTERVAL_MS = 14 * 60 * 1000; // 14 minutes

function startSelfPing() {
  // RENDER_EXTERNAL_URL is auto-set by Render with the public URL
  const selfUrl = process.env.RENDER_EXTERNAL_URL || `http://localhost:${PORT}`;
  console.log(`[KEEP-ALIVE] Self-ping enabled → ${selfUrl}/health every 14min`);

  setInterval(async () => {
    try {
      await axios.get(`${selfUrl}/health`, { timeout: 10000 });
      console.log('[KEEP-ALIVE] Self-ping successful ✅');
    } catch (err) {
      console.warn('[KEEP-ALIVE] Self-ping failed:', err.message);
    }
  }, SELF_PING_INTERVAL_MS);
}

app.listen(PORT, () => {
  console.log(`🚀 Rahhal AI Backend Proxy is running on http://localhost:${PORT}`);
  console.log(`Press Ctrl+C to terminate.`);
  startSelfPing();
});
