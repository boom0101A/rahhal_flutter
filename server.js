const express = require('express');
const cors = require('cors');
const axios = require('axios');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Rate Limiter: Protect API from DDoS & quota drain (Max 100 requests per 15 min per IP)
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests from this IP, please try again later.' },
});

app.use('/api/', limiter);

// Health Check Endpoints for cloud hosting services (Render / Railway)
app.get('/', (req, res) => {
  res.status(200).send('🚀 Rahhal AI Proxy Server is running!');
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', service: 'Rahhal AI Proxy', timestamp: new Date() });
});

// Helper function to call Anthropic API
async function callClaude(systemPrompt, messages, maxTokens = 4000) {
  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey || apiKey === 'your_anthropic_api_key_here') {
    throw new Error('missing-api-key');
  }

  try {
    const response = await axios.post(
      'https://api.anthropic.com/v1/messages',
      {
        model: 'claude-3-5-sonnet-20241022',
        max_tokens: maxTokens,
        system: systemPrompt,
        messages: messages,
      },
      {
        headers: {
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
      }
    );

    if (response.data && response.data.content && response.data.content[0]) {
      return response.data.content[0].text;
    }
    throw new Error('Invalid response from Claude API');
  } catch (error) {
    if (error.response) {
      const status = error.response.status;
      if (status === 401 || status === 403) {
        throw new Error('invalid-api-key');
      }
      if (status === 429) {
        throw new Error('rate-limit');
      }
      throw new Error(`api-error-${status}`);
    }
    throw error;
  }
}

// ─── POST /api/generate-trip ────────────────────────────────────────────────
app.post('/api/generate-trip', async (req, res) => {
  const { destination, durationDays, budgetTier, travelStyles, travelersCount, startDate } = req.body;

  if (!destination || !durationDays || !budgetTier) {
    return res.status(400).json({ error: 'Missing required parameters' });
  }

  const systemPrompt = `You are a professional travel planner expert in creating highly detailed, realistic, and personalized trip itineraries.
Your output MUST be a single, valid, and minified JSON object matching the schema below. 
You must NOT include any conversational filler, markdown formatting (do NOT wrap in \`\`\`json ... \`\`\`), or extra text explanation before or after the JSON.
The text values inside the JSON (such as themes, summaries, addresses, descriptions, tips, and names) MUST be in ARABIC (except for English name fields or URLs).

Required JSON Schema:
{
  "destination": "Name of the destination in Arabic",
  "destination_en": "Name of the destination in English (e.g. 'Istanbul', 'Cairo', 'Paris')",
  "country_code": "2-letter ISO country code (e.g., 'TR', 'EG', 'FR')",
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
          "image_search_query": "3-5 English keywords for a beautiful photo of this specific place (e.g., 'Hagia Sophia Istanbul interior', 'Eiffel Tower Paris night', 'Tokyo shibuya crossing')"
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
        "image_search_query": "3-5 English keywords for a beautiful photo of this restaurant or its cuisine type (e.g., 'Turkish kebab restaurant Istanbul', 'sushi restaurant Tokyo interior')"
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
      "image_search_query": "3-5 English keywords for a beautiful food photo (e.g., 'fresh sushi plate Japan', 'Turkish baklava dessert')"
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
}

Ensure the latitude and longitude of all attractions and restaurants are real and correct coordinates for the destination city to display correctly on maps.`;

  const userPrompt = `Generate a customized travel itinerary for:
- Destination: ${destination}
- Duration: ${durationDays} days
- Budget Tier: ${budgetTier} (economy / mid / luxury)
- Travel Styles: ${travelStyles ? travelStyles.join(', ') : 'any'}
- Travelers Count: ${travelersCount || 1}
${startDate ? `- Start Date: ${startDate}` : ''}`;

  const messages = [
    { role: 'user', content: userPrompt }
  ];

  try {
    const rawReply = await callClaude(systemPrompt, messages, 4000);
    
    // Clean up response if Claude accidentally wrapped it in markdown code blocks
    let cleanJson = rawReply.trim();
    if (cleanJson.startsWith('```')) {
      const firstLineBreak = cleanJson.indexOf('\n');
      const lastBackticks = cleanJson.lastIndexOf('```');
      if (firstLineBreak !== -1 && lastBackticks !== -1) {
        cleanJson = cleanJson.substring(firstLineBreak + 1, lastBackticks).trim();
      }
    }
    
    const parsedData = JSON.parse(cleanJson);
    return res.status(200).json(parsedData);
  } catch (error) {
    console.error('[API ERROR] generate-trip failed:', error.message);
    if (error.message === 'missing-api-key') {
      return res.status(401).json({ error: 'Anthropic API key is not configured in backend .env file.' });
    }
    if (error.message === 'invalid-api-key') {
      return res.status(403).json({ error: 'The provided Anthropic API key is invalid or unauthorized.' });
    }
    if (error.message === 'rate-limit') {
      return res.status(429).json({ error: 'API rate limit exceeded. Please try again in a few moments.' });
    }
    return res.status(500).json({ error: 'Failed to generate trip plan: ' + error.message });
  }
});

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

  const systemPrompt = `You are a helpful, expert AI travel assistant built into the "Rahhal" application.
You are helping a traveler visiting: ${destination}.
Here is the summary of their current trip:
${tripSummary || 'No summary details provided.'}

Answer the user's travel questions in a friendly, engaging, and professional manner in ARABIC. 
Keep your responses relatively concise, focused, and tailored to their trip context. 
If they ask for suggestions, make sure your coordinates or location suggestions align with their travel zone.`;

  // Map client history format to Anthropic format
  const mappedMessages = [];
  if (conversationHistory && Array.isArray(conversationHistory)) {
    conversationHistory.forEach((msg) => {
      // Anthropic role must be either 'user' or 'assistant'
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
    const reply = await callClaude(systemPrompt, mappedMessages, 1500);
    return res.status(200).json({ reply });
  } catch (error) {
    console.error('[API ERROR] chat failed:', error.message);
    if (error.message === 'missing-api-key') {
      return res.status(401).json({ error: 'Anthropic API key is not configured in backend .env file.' });
    }
    if (error.message === 'invalid-api-key') {
      return res.status(403).json({ error: 'The provided Anthropic API key is invalid or unauthorized.' });
    }
    if (error.message === 'rate-limit') {
      return res.status(429).json({ error: 'API rate limit exceeded. Please try again in a few moments.' });
    }
    return res.status(500).json({ error: 'Failed to get chat reply: ' + error.message });
  }
});

app.listen(PORT, () => {
  console.log(`🚀 Rahhal AI Backend Proxy is running on http://localhost:${PORT}`);
  console.log(`Press Ctrl+C to terminate.`);
});
