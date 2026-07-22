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

if (process.env.GROQ_API_KEY &&
    process.env.GROQ_API_KEY !== 'your_groq_api_key_here') {
  console.log('✅ GROQ_API_KEY: Set (primary AI engine — Groq)');
} else {
  console.log('⚠️  GROQ_API_KEY: Not set (will use Gemini instead)');
}

if (!GEMINI_KEY || GEMINI_KEY === 'your_gemini_api_key_here') {
  console.error('❌ GEMINI_API_KEY: NOT SET (Gemini fallback unavailable)');
} else {
  console.log('✅ GEMINI_API_KEY: Set (Gemini fallback active)');
}

if (process.env.GOOGLE_PLACES_API_KEY &&
    process.env.GOOGLE_PLACES_API_KEY !== 'your_google_places_api_key_here') {
  console.log('✅ GOOGLE_PLACES_API_KEY: Set (place verification active)');
} else {
  console.log('⚠️  GOOGLE_PLACES_API_KEY: Not set (coordinates unverified)');
}

// authenticateFirebaseToken is a NO-OP without this, so every /api route is
// open to anyone who knows the URL — including the ones that spend Groq,
// Gemini, Places, Unsplash and OpenWeather quota. Say so loudly rather than
// letting the deployment look protected when it isn't.
if (process.env.FIREBASE_SERVICE_ACCOUNT) {
  console.log('✅ FIREBASE_SERVICE_ACCOUNT: Set (API authentication enforced)');
} else {
  console.warn('🔓 FIREBASE_SERVICE_ACCOUNT: NOT SET — API AUTH IS DISABLED.');
  console.warn('   Every /api endpoint is publicly reachable and will burn');
  console.warn('   your third-party quota. Set it before exposing this server.');
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

// Circuit breaker for the Places free tier (100 searches/day). Once the daily
// quota is gone every further call fails anyway, so a whole trip would spend
// seconds hammering a dead endpoint (measured: 2.2s wasted on 14 lookups that
// all 404'd). When we see a quota error we stop calling until this timestamp.
let placesQuotaBlockedUntil = 0;
const PLACES_QUOTA_COOLDOWN_MS = 30 * 60 * 1000; // re-probe every 30 minutes
function isPlacesQuotaBlocked() {
  return Date.now() < placesQuotaBlockedUntil;
}
function tripPlacesBreaker(errMessage) {
  if (/quota|RESOURCE_EXHAUSTED|rate limit/i.test(errMessage || '')) {
    placesQuotaBlockedUntil = Date.now() + PLACES_QUOTA_COOLDOWN_MS;
    console.warn('[PLACES] Daily quota exhausted — skipping Places lookups for 30 minutes.');
    return true;
  }
  return false;
}
// Max distance (km) a Places text-search match may be from the destination
// center before it's rejected as "wrong city/governorate". Generous enough
// to cover a metro area, tight enough to catch a same-named place resolved
// to a different city entirely.
const PLACES_MAX_DISTANCE_KM = 100;

// Arabic → English city dictionary. The trip model (gpt-oss) can't reliably
// read an Arabic city name buried inside the big trip prompt and either asks
// "which city?" or drifts to a famous one — so we resolve the destination to
// English first. This zero-cost lookup covers the common cases (all Iraqi
// governorate capitals + major MENA/world cities) without spending any Google
// Places quota; Places is only used as a fallback for names not listed here.
const AR_CITY_DICTIONARY = {
  // ═══ Iraq — comprehensive: all 19 governorates (capital + governorate name
  // aliases) plus notable districts/cities from the far north to the far south
  // and the far west to the far east. Country is always Iraq/IQ. ═══

  // Baghdad governorate
  'بغداد': { en: 'Baghdad', country: 'Iraq', code: 'IQ' },
  'الكاظمية': { en: 'Kadhimiya, Baghdad', country: 'Iraq', code: 'IQ' },
  'أبو غريب': { en: 'Abu Ghraib', country: 'Iraq', code: 'IQ' },
  'المحمودية': { en: 'Al-Mahmudiyah', country: 'Iraq', code: 'IQ' },
  'المدائن': { en: 'Al-Mada\'in', country: 'Iraq', code: 'IQ' },
  'التاجي': { en: 'Al-Taji', country: 'Iraq', code: 'IQ' },

  // Basra governorate (far south)
  'البصرة': { en: 'Basra', country: 'Iraq', code: 'IQ' },
  'بصرة': { en: 'Basra', country: 'Iraq', code: 'IQ' },
  'الفاو': { en: 'Al-Faw', country: 'Iraq', code: 'IQ' },
  'الزبير': { en: 'Al-Zubair', country: 'Iraq', code: 'IQ' },
  'القرنة': { en: 'Al-Qurna', country: 'Iraq', code: 'IQ' },
  'أبو الخصيب': { en: 'Abu Al-Khaseeb', country: 'Iraq', code: 'IQ' },
  'أم قصر': { en: 'Umm Qasr', country: 'Iraq', code: 'IQ' },
  'شط العرب': { en: 'Shatt Al-Arab, Basra', country: 'Iraq', code: 'IQ' },

  // Nineveh governorate (far north-west)
  'نينوى': { en: 'Mosul (Nineveh)', country: 'Iraq', code: 'IQ' },
  'الموصل': { en: 'Mosul', country: 'Iraq', code: 'IQ' },
  'موصل': { en: 'Mosul', country: 'Iraq', code: 'IQ' },
  'تلعفر': { en: 'Tal Afar', country: 'Iraq', code: 'IQ' },
  'سنجار': { en: 'Sinjar', country: 'Iraq', code: 'IQ' },
  'بعشيقة': { en: 'Bashiqa', country: 'Iraq', code: 'IQ' },
  'الحمدانية': { en: 'Al-Hamdaniya (Qaraqosh)', country: 'Iraq', code: 'IQ' },
  'قرقوش': { en: 'Qaraqosh', country: 'Iraq', code: 'IQ' },
  'الشيخان': { en: 'Al-Shikhan', country: 'Iraq', code: 'IQ' },
  'لالش': { en: 'Lalish, Nineveh', country: 'Iraq', code: 'IQ' },
  'الحضر': { en: 'Hatra', country: 'Iraq', code: 'IQ' },
  'نمرود': { en: 'Nimrud', country: 'Iraq', code: 'IQ' },

  // Erbil governorate (north / Kurdistan)
  'أربيل': { en: 'Erbil', country: 'Iraq', code: 'IQ' },
  'اربيل': { en: 'Erbil', country: 'Iraq', code: 'IQ' },
  'شقلاوة': { en: 'Shaqlawa', country: 'Iraq', code: 'IQ' },
  'سوران': { en: 'Soran', country: 'Iraq', code: 'IQ' },
  'كويسنجق': { en: 'Koya', country: 'Iraq', code: 'IQ' },
  'راوندوز': { en: 'Rawanduz', country: 'Iraq', code: 'IQ' },
  'عنكاوة': { en: 'Ainkawa, Erbil', country: 'Iraq', code: 'IQ' },
  'جومان': { en: 'Choman', country: 'Iraq', code: 'IQ' },
  'صلاح الدين أربيل': { en: 'Salahaddin, Erbil', country: 'Iraq', code: 'IQ' },

  // Kirkuk governorate
  'كركوك': { en: 'Kirkuk', country: 'Iraq', code: 'IQ' },
  'الحويجة': { en: 'Al-Hawija', country: 'Iraq', code: 'IQ' },
  'داقوق': { en: 'Daquq', country: 'Iraq', code: 'IQ' },
  'دبس': { en: 'Dibis', country: 'Iraq', code: 'IQ' },

  // Najaf governorate
  'النجف': { en: 'Najaf', country: 'Iraq', code: 'IQ' },
  'نجف': { en: 'Najaf', country: 'Iraq', code: 'IQ' },
  'الكوفة': { en: 'Kufa', country: 'Iraq', code: 'IQ' },
  'المشخاب': { en: 'Al-Mishkhab', country: 'Iraq', code: 'IQ' },
  'المناذرة': { en: 'Al-Manathira', country: 'Iraq', code: 'IQ' },

  // Karbala governorate
  'كربلاء': { en: 'Karbala', country: 'Iraq', code: 'IQ' },
  'عين التمر': { en: 'Ain Al-Tamur', country: 'Iraq', code: 'IQ' },
  'الهندية': { en: 'Al-Hindiya', country: 'Iraq', code: 'IQ' },
  'طويريج': { en: 'Twairij', country: 'Iraq', code: 'IQ' },

  // Babil governorate
  'بابل': { en: 'Babylon (Hillah)', country: 'Iraq', code: 'IQ' },
  'الحلة': { en: 'Hillah', country: 'Iraq', code: 'IQ' },
  'المسيب': { en: 'Al-Musayyib', country: 'Iraq', code: 'IQ' },
  'المحاويل': { en: 'Al-Mahawil', country: 'Iraq', code: 'IQ' },
  'الهاشمية': { en: 'Al-Hashimiyah', country: 'Iraq', code: 'IQ' },

  // Anbar governorate (far west)
  'الأنبار': { en: 'Ramadi (Anbar)', country: 'Iraq', code: 'IQ' },
  'الرمادي': { en: 'Ramadi', country: 'Iraq', code: 'IQ' },
  'الفلوجة': { en: 'Fallujah', country: 'Iraq', code: 'IQ' },
  'هيت': { en: 'Hit', country: 'Iraq', code: 'IQ' },
  'حديثة': { en: 'Haditha', country: 'Iraq', code: 'IQ' },
  'القائم': { en: 'Al-Qaim', country: 'Iraq', code: 'IQ' },
  'عنة': { en: 'Anah', country: 'Iraq', code: 'IQ' },
  'راوة': { en: 'Rawa', country: 'Iraq', code: 'IQ' },
  'الرطبة': { en: 'Rutba', country: 'Iraq', code: 'IQ' },
  'الحبانية': { en: 'Habbaniyah', country: 'Iraq', code: 'IQ' },

  // Dhi Qar governorate (south)
  'ذي قار': { en: 'Nasiriyah (Dhi Qar)', country: 'Iraq', code: 'IQ' },
  'الناصرية': { en: 'Nasiriyah', country: 'Iraq', code: 'IQ' },
  'الرفاعي': { en: 'Al-Rifai', country: 'Iraq', code: 'IQ' },
  'سوق الشيوخ': { en: 'Suq Al-Shuyukh', country: 'Iraq', code: 'IQ' },
  'الجبايش': { en: 'Al-Chibayish', country: 'Iraq', code: 'IQ' },
  'الشطرة': { en: 'Al-Shatrah', country: 'Iraq', code: 'IQ' },
  'أور': { en: 'Ur', country: 'Iraq', code: 'IQ' },

  // Maysan governorate (south-east)
  'ميسان': { en: 'Amarah (Maysan)', country: 'Iraq', code: 'IQ' },
  'العمارة': { en: 'Amarah', country: 'Iraq', code: 'IQ' },
  'علي الغربي': { en: 'Ali Al-Gharbi', country: 'Iraq', code: 'IQ' },
  'المجر الكبير': { en: 'Al-Majar Al-Kabir', country: 'Iraq', code: 'IQ' },
  'قلعة صالح': { en: 'Qalat Saleh', country: 'Iraq', code: 'IQ' },
  'الكحلاء': { en: 'Al-Kahla', country: 'Iraq', code: 'IQ' },

  // Al-Qadisiyyah governorate
  'القادسية': { en: 'Diwaniyah (Al-Qadisiyyah)', country: 'Iraq', code: 'IQ' },
  'الديوانية': { en: 'Diwaniyah', country: 'Iraq', code: 'IQ' },
  'عفك': { en: 'Afak', country: 'Iraq', code: 'IQ' },
  'الحمزة': { en: 'Al-Hamza', country: 'Iraq', code: 'IQ' },
  'الشامية': { en: 'Al-Shamiya', country: 'Iraq', code: 'IQ' },
  'نفر': { en: 'Nippur', country: 'Iraq', code: 'IQ' },

  // Wasit governorate (east)
  'واسط': { en: 'Kut (Wasit)', country: 'Iraq', code: 'IQ' },
  'الكوت': { en: 'Kut', country: 'Iraq', code: 'IQ' },
  'العزيزية': { en: 'Al-Aziziyah', country: 'Iraq', code: 'IQ' },
  'الصويرة': { en: 'Al-Suwaira', country: 'Iraq', code: 'IQ' },
  'الحي': { en: 'Al-Hai', country: 'Iraq', code: 'IQ' },
  'بدرة': { en: 'Badra', country: 'Iraq', code: 'IQ' },
  'النعمانية': { en: 'Al-Numaniyah', country: 'Iraq', code: 'IQ' },

  // Al-Muthanna governorate
  'المثنى': { en: 'Samawah (Al-Muthanna)', country: 'Iraq', code: 'IQ' },
  'السماوة': { en: 'Samawah', country: 'Iraq', code: 'IQ' },
  'الرميثة': { en: 'Al-Rumaitha', country: 'Iraq', code: 'IQ' },
  'الخضر': { en: 'Al-Khidr', country: 'Iraq', code: 'IQ' },
  'الوركاء': { en: 'Uruk (Warka)', country: 'Iraq', code: 'IQ' },

  // Diyala governorate (east)
  'ديالى': { en: 'Baqubah (Diyala)', country: 'Iraq', code: 'IQ' },
  'بعقوبة': { en: 'Baqubah', country: 'Iraq', code: 'IQ' },
  'خانقين': { en: 'Khanaqin', country: 'Iraq', code: 'IQ' },
  'المقدادية': { en: 'Al-Muqdadiyah', country: 'Iraq', code: 'IQ' },
  'بلدروز': { en: 'Baladruz', country: 'Iraq', code: 'IQ' },
  'جلولاء': { en: 'Jalawla', country: 'Iraq', code: 'IQ' },
  'كفري': { en: 'Kifri', country: 'Iraq', code: 'IQ' },
  'مندلي': { en: 'Mandali', country: 'Iraq', code: 'IQ' },

  // Saladin (Salah al-Din) governorate
  'صلاح الدين': { en: 'Tikrit (Salah al-Din)', country: 'Iraq', code: 'IQ' },
  'تكريت': { en: 'Tikrit', country: 'Iraq', code: 'IQ' },
  'سامراء': { en: 'Samarra', country: 'Iraq', code: 'IQ' },
  'بلد': { en: 'Balad', country: 'Iraq', code: 'IQ' },
  'بيجي': { en: 'Baiji', country: 'Iraq', code: 'IQ' },
  'الدجيل': { en: 'Al-Dujail', country: 'Iraq', code: 'IQ' },
  'طوز خورماتو': { en: 'Tuz Khurmatu', country: 'Iraq', code: 'IQ' },
  'الشرقاط': { en: 'Al-Shirqat', country: 'Iraq', code: 'IQ' },
  'الدور': { en: 'Al-Dour', country: 'Iraq', code: 'IQ' },

  // Dohuk governorate (far north)
  'دهوك': { en: 'Duhok', country: 'Iraq', code: 'IQ' },
  'زاخو': { en: 'Zakho', country: 'Iraq', code: 'IQ' },
  'العمادية': { en: 'Amadiya', country: 'Iraq', code: 'IQ' },
  'سيميل': { en: 'Sumel', country: 'Iraq', code: 'IQ' },
  'عقرة': { en: 'Akre', country: 'Iraq', code: 'IQ' },
  'بردرش': { en: 'Bardarash', country: 'Iraq', code: 'IQ' },

  // Sulaymaniyah governorate (north-east)
  'السليمانية': { en: 'Sulaymaniyah', country: 'Iraq', code: 'IQ' },
  'رانية': { en: 'Ranya', country: 'Iraq', code: 'IQ' },
  'جمجمال': { en: 'Chamchamal', country: 'Iraq', code: 'IQ' },
  'كلار': { en: 'Kalar', country: 'Iraq', code: 'IQ' },
  'دربنديخان': { en: 'Darbandikhan', country: 'Iraq', code: 'IQ' },
  'دوكان': { en: 'Dukan', country: 'Iraq', code: 'IQ' },
  'بنجوين': { en: 'Penjwin', country: 'Iraq', code: 'IQ' },
  'حلبجة': { en: 'Halabja', country: 'Iraq', code: 'IQ' },

  // Kurdistan region (generic)
  'كردستان': { en: 'Erbil (Kurdistan)', country: 'Iraq', code: 'IQ' },
  'إقليم كردستان': { en: 'Erbil (Kurdistan)', country: 'Iraq', code: 'IQ' },

  // Major MENA / world cities
  'القاهرة': { en: 'Cairo', country: 'Egypt', code: 'EG' },
  'الإسكندرية': { en: 'Alexandria', country: 'Egypt', code: 'EG' },
  'إسطنبول': { en: 'Istanbul', country: 'Turkey', code: 'TR' },
  'اسطنبول': { en: 'Istanbul', country: 'Turkey', code: 'TR' },
  'أنقرة': { en: 'Ankara', country: 'Turkey', code: 'TR' },
  'دبي': { en: 'Dubai', country: 'United Arab Emirates', code: 'AE' },
  'أبوظبي': { en: 'Abu Dhabi', country: 'United Arab Emirates', code: 'AE' },
  'الرياض': { en: 'Riyadh', country: 'Saudi Arabia', code: 'SA' },
  'جدة': { en: 'Jeddah', country: 'Saudi Arabia', code: 'SA' },
  'مكة': { en: 'Mecca', country: 'Saudi Arabia', code: 'SA' },
  'المدينة': { en: 'Medina', country: 'Saudi Arabia', code: 'SA' },
  'الدوحة': { en: 'Doha', country: 'Qatar', code: 'QA' },
  'الكويت': { en: 'Kuwait City', country: 'Kuwait', code: 'KW' },
  'المنامة': { en: 'Manama', country: 'Bahrain', code: 'BH' },
  'مسقط': { en: 'Muscat', country: 'Oman', code: 'OM' },
  'عمّان': { en: 'Amman', country: 'Jordan', code: 'JO' },
  'عمان': { en: 'Amman', country: 'Jordan', code: 'JO' },
  'بيروت': { en: 'Beirut', country: 'Lebanon', code: 'LB' },
  'دمشق': { en: 'Damascus', country: 'Syria', code: 'SY' },
  'الدار البيضاء': { en: 'Casablanca', country: 'Morocco', code: 'MA' },
  'مراكش': { en: 'Marrakesh', country: 'Morocco', code: 'MA' },
  'تونس': { en: 'Tunis', country: 'Tunisia', code: 'TN' },
  'طرابلس': { en: 'Tripoli', country: 'Libya', code: 'LY' },
  // ── World cities (Arabic input) ─────────────────────────────────────────
  // Europe
  'باريس': { en: 'Paris', country: 'France', code: 'FR' },
  'لندن': { en: 'London', country: 'United Kingdom', code: 'GB' },
  'روما': { en: 'Rome', country: 'Italy', code: 'IT' },
  'ميلان': { en: 'Milan', country: 'Italy', code: 'IT' },
  'البندقية': { en: 'Venice', country: 'Italy', code: 'IT' },
  'مدريد': { en: 'Madrid', country: 'Spain', code: 'ES' },
  'برشلونة': { en: 'Barcelona', country: 'Spain', code: 'ES' },
  'برلين': { en: 'Berlin', country: 'Germany', code: 'DE' },
  'ميونخ': { en: 'Munich', country: 'Germany', code: 'DE' },
  'أمستردام': { en: 'Amsterdam', country: 'Netherlands', code: 'NL' },
  'فيينا': { en: 'Vienna', country: 'Austria', code: 'AT' },
  'براغ': { en: 'Prague', country: 'Czech Republic', code: 'CZ' },
  'أثينا': { en: 'Athens', country: 'Greece', code: 'GR' },
  'لشبونة': { en: 'Lisbon', country: 'Portugal', code: 'PT' },
  'زيورخ': { en: 'Zurich', country: 'Switzerland', code: 'CH' },
  'جنيف': { en: 'Geneva', country: 'Switzerland', code: 'CH' },
  'بروكسل': { en: 'Brussels', country: 'Belgium', code: 'BE' },
  'موسكو': { en: 'Moscow', country: 'Russia', code: 'RU' },
  'دبلن': { en: 'Dublin', country: 'Ireland', code: 'IE' },
  // Asia
  'طوكيو': { en: 'Tokyo', country: 'Japan', code: 'JP' },
  'أوساكا': { en: 'Osaka', country: 'Japan', code: 'JP' },
  'كيوتو': { en: 'Kyoto', country: 'Japan', code: 'JP' },
  'سيول': { en: 'Seoul', country: 'South Korea', code: 'KR' },
  'بكين': { en: 'Beijing', country: 'China', code: 'CN' },
  'شنغهاي': { en: 'Shanghai', country: 'China', code: 'CN' },
  'هونغ كونغ': { en: 'Hong Kong', country: 'Hong Kong', code: 'HK' },
  'بانكوك': { en: 'Bangkok', country: 'Thailand', code: 'TH' },
  'سنغافورة': { en: 'Singapore', country: 'Singapore', code: 'SG' },
  'كوالالمبور': { en: 'Kuala Lumpur', country: 'Malaysia', code: 'MY' },
  'جاكرتا': { en: 'Jakarta', country: 'Indonesia', code: 'ID' },
  'بالي': { en: 'Bali', country: 'Indonesia', code: 'ID' },
  'مومباي': { en: 'Mumbai', country: 'India', code: 'IN' },
  'نيودلهي': { en: 'New Delhi', country: 'India', code: 'IN' },
  'دلهي': { en: 'Delhi', country: 'India', code: 'IN' },
  'مانيلا': { en: 'Manila', country: 'Philippines', code: 'PH' },
  'باكو': { en: 'Baku', country: 'Azerbaijan', code: 'AZ' },
  'تبليسي': { en: 'Tbilisi', country: 'Georgia', code: 'GE' },
  // Americas
  'نيويورك': { en: 'New York', country: 'United States', code: 'US' },
  'لوس أنجلوس': { en: 'Los Angeles', country: 'United States', code: 'US' },
  'لاس فيغاس': { en: 'Las Vegas', country: 'United States', code: 'US' },
  'سان فرانسيسكو': { en: 'San Francisco', country: 'United States', code: 'US' },
  'ميامي': { en: 'Miami', country: 'United States', code: 'US' },
  'شيكاغو': { en: 'Chicago', country: 'United States', code: 'US' },
  'واشنطن': { en: 'Washington', country: 'United States', code: 'US' },
  'تورنتو': { en: 'Toronto', country: 'Canada', code: 'CA' },
  'مونتريال': { en: 'Montreal', country: 'Canada', code: 'CA' },
  'المكسيك': { en: 'Mexico City', country: 'Mexico', code: 'MX' },
  'ريو دي جانيرو': { en: 'Rio de Janeiro', country: 'Brazil', code: 'BR' },
  'ساو باولو': { en: 'Sao Paulo', country: 'Brazil', code: 'BR' },
  'بوينس آيرس': { en: 'Buenos Aires', country: 'Argentina', code: 'AR' },
  // Oceania & Africa
  'سيدني': { en: 'Sydney', country: 'Australia', code: 'AU' },
  'ملبورن': { en: 'Melbourne', country: 'Australia', code: 'AU' },
  'كيب تاون': { en: 'Cape Town', country: 'South Africa', code: 'ZA' },
  'نيروبي': { en: 'Nairobi', country: 'Kenya', code: 'KE' },
  'زنجبار': { en: 'Zanzibar', country: 'Tanzania', code: 'TZ' },
};

// A destination written in Latin script (e.g. "Barcelona", "Kyoto") doesn't
// need resolving — the LLM reads Latin city names reliably. Only Arabic names
// buried in the trip prompt confuse it, which is what the dictionary/Places
// path is for. Detecting Latin input lets us skip the Google Places call
// entirely for the whole non-Arabic world, saving the daily quota.
function isLatinScriptDestination(s) {
  if (!s) return false;
  if (/[؀-ۿ]/.test(s)) return false; // contains Arabic letters
  return /[A-Za-z]/.test(s); // has Latin letters
}

// Look up a destination in the static dictionary. Matches the whole string
// first, then tries each known Arabic name as a substring (handles inputs
// like "كربلاء، العراق" or "مدينة النجف").
function lookupCityDictionary(rawDestination) {
  if (!rawDestination) return null;
  const q = rawDestination.trim();
  if (AR_CITY_DICTIONARY[q]) return AR_CITY_DICTIONARY[q];
  for (const [ar, info] of Object.entries(AR_CITY_DICTIONARY)) {
    if (q.includes(ar)) return info;
  }
  return null;
}

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

// These four spend real third-party quota (Unsplash/Pexels, OpenWeather, the
// currency feed, Overpass) and were previously reachable by anyone who knew
// the deployment URL — the generic IP limiter alone let a single client drain
// the daily allowance. Every app screen that calls them already sits behind
// the router's auth gate, so a Firebase ID token is always available.
app.use('/api/photos', authenticateFirebaseToken);
app.use('/api/weather', authenticateFirebaseToken);
app.use('/api/currency', authenticateFirebaseToken);
app.use('/api/nearby-places', authenticateFirebaseToken);

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
  const hasGroqKey = !!(process.env.GROQ_API_KEY &&
    process.env.GROQ_API_KEY !== 'your_groq_api_key_here');
  const hasPlacesKey = !!(process.env.GOOGLE_PLACES_API_KEY &&
    process.env.GOOGLE_PLACES_API_KEY !== 'your_google_places_api_key_here');

  res.json({
    status: 'ok',
    ai_engine: hasGroqKey ? 'groq' : (hasGeminiKey ? 'gemini' : 'none'),
    ai_ready: hasGroqKey || hasGeminiKey,
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

// Helper: call Groq (OpenAI-compatible).
// Groq's free tier is far more generous than Gemini's (~1000 requests/day,
// no credit card). We use openai/gpt-oss-120b rather than llama-3.3-70b —
// the Llama model can't reliably read Arabic city names (it mistook
// "كربلاء" for Paris and returned Dubai trips), whereas the gpt-oss models
// understand the Arabic destination and return clean JSON. We use the 20b
// (not 120b) because both share the free tier's 8000 tokens-per-minute cap,
// and 20b returns cleaner, non-truncated output for our prompt size.
const GROQ_MODEL = process.env.GROQ_MODEL || 'openai/gpt-oss-20b';
async function callGroq(systemPrompt, messages, maxTokens = 4000, apiKey) {
  // Groq's free tier caps tokens-per-minute at 8000 for the gpt-oss models,
  // and (prompt + max_tokens) — not actual usage — counts against it. With a
  // ~1700-token system prompt that leaves ~6000 for output, which is also
  // about what a 3-day Arabic itinerary genuinely needs. The practical
  // consequence is roughly one generation per minute on the free tier;
  // anything more falls through to the Gemini fallback.
  const outputBudget = Math.max(1024, Math.min(maxTokens, 6000));

  const chatMessages = [];
  if (systemPrompt) chatMessages.push({ role: 'system', content: systemPrompt });
  for (const m of messages) {
    chatMessages.push({
      role: m.role === 'assistant' || m.role === 'model' ? 'assistant' : 'user',
      content: m.content,
    });
  }

  try {
    console.log(`[GROQ] Calling ${GROQ_MODEL} (output budget ${outputBudget} tokens)...`);
    const response = await axios.post(
      'https://api.groq.com/openai/v1/chat/completions',
      {
        model: GROQ_MODEL,
        messages: chatMessages,
        temperature: 0.7,
        max_tokens: outputBudget,
      },
      {
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${apiKey}`,
        },
        timeout: 60000,
      }
    );

    const text = response.data?.choices?.[0]?.message?.content;
    if (text && text.length > 0) {
      console.log(`[GROQ] ✅ Success! Response length: ${text.length}`);
      return text;
    }
    throw new Error('empty-response');
  } catch (err) {
    const status = err.response?.status || 0;
    const errMsg = err.response?.data?.error?.message || err.response?.data?.message || err.message || '';
    console.warn(`[GROQ] ${GROQ_MODEL} error (${status}): ${errMsg}`);
    if (status === 401 || status === 403) throw new Error('invalid-api-key');
    if (status === 429) throw new Error('rate-limit');
    throw new Error(`groq-error: ${errMsg}`);
  }
}

// Unified AI Engine Call: prefers Groq (generous free tier), falls back
// to Google Gemini so the app keeps working if either provider is down.
async function callAI(systemPrompt, messages, maxTokens = 4000) {
  // 1. Try Groq first if configured (much larger free daily quota).
  const groqKey = process.env.GROQ_API_KEY;
  if (groqKey && groqKey !== 'your_groq_api_key_here' && groqKey.length > 10) {
    try {
      console.log('[AI Engine] Using Groq...');
      return await callGroq(systemPrompt, messages, maxTokens, groqKey);
    } catch (e) {
      console.warn('[AI Engine] GROQ_API_KEY failed:', e.message);
      // Fall through to Gemini below instead of failing immediately.
    }
  }

  // 2. Try primary Gemini key
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
async function verifyPlaceWithGoogle(nameEn, cityEn, centerLat, centerLng) {
  const placesKey = process.env.GOOGLE_PLACES_API_KEY;
  if (!placesKey || placesKey === 'your_google_places_api_key_here') {
    return null; // Places API not configured — skip gracefully
  }
  if (isPlacesQuotaBlocked()) {
    return null; // daily quota already known to be gone — don't waste the round-trip
  }

  const cacheKey = `${nameEn.toLowerCase().trim()}|${cityEn.toLowerCase().trim()}${centerLat && centerLng ? `|${centerLat.toFixed(2)},${centerLng.toFixed(2)}` : ''}`;
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

    if (centerLat && centerLng) {
      body.locationBias = {
        circle: {
          center: { latitude: parseFloat(centerLat), longitude: parseFloat(centerLng) },
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

    // locationBias is a SOFT hint — Google can still return a same-named
    // place in a completely different city/governorate (or country) as the
    // top result, especially for generic names or chains. Reject it rather
    // than silently overwriting the AI's coordinates with a wrong location.
    if (centerLat && centerLng) {
      const distKm = haversineDistance(
        parseFloat(centerLat), parseFloat(centerLng),
        top.location.latitude, top.location.longitude
      );
      if (distKm > PLACES_MAX_DISTANCE_KM) {
        console.warn(
          `[PLACES] Rejected "${nameEn}" — match is ${distKm.toFixed(0)}km from ${cityEn}, likely wrong city/governorate`
        );
        placesCache.set(cacheKey, { data: null, timestamp: now });
        return null;
      }
    }

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
    const message = apiError?.message || err.message;
    // Trip the breaker on quota errors so the remaining places in this trip
    // (and the next few minutes of traffic) skip Places entirely.
    if (!tripPlacesBreaker(message)) {
      console.error(`[PLACES] Text Search error for "${nameEn}":`, message);
    }
    placesCache.set(cacheKey, { data: null, timestamp: now });
    return null;
  }
}

// Centroid of every stop coordinate in a trip. Used as a search/verify center
// when the user gave no GPS — the stops aren't verified yet, but their average
// still pins the right city well enough to reject cross-country mismatches.
function tripStopCentroid(tripData) {
  const coords = [];
  for (const day of tripData.days || []) {
    for (const stop of day.stops || []) {
      const lat = parseFloat(stop.latitude);
      const lng = parseFloat(stop.longitude);
      if (!isNaN(lat) && !isNaN(lng)) coords.push([lat, lng]);
    }
  }
  if (!coords.length) return null;
  return {
    lat: coords.reduce((sum, c) => sum + c[0], 0) / coords.length,
    lng: coords.reduce((sum, c) => sum + c[1], 0) / coords.length,
  };
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

  // Center point used to bias Places text search AND to reject matches that
  // land in the wrong city/governorate. Prefer the user's real GPS; when
  // that's unavailable (destination typed manually, not "use my location"),
  // fall back to the centroid of the AI's own stop coordinates — still a
  // useful sanity anchor even though those coordinates aren't yet verified.
  let centerLat = userLat ? parseFloat(userLat) : null;
  let centerLng = userLng ? parseFloat(userLng) : null;
  if (!centerLat || !centerLng) {
    const centroid = tripStopCentroid(tripData);
    if (centroid) {
      centerLat = centroid.lat;
      centerLng = centroid.lng;
    }
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
  const CONCURRENCY = 8;
  for (let i = 0; i < tasks.length; i += CONCURRENCY) {
    const batch = tasks.slice(i, i + CONCURRENCY);
    await Promise.all(
      batch.map(async ({ item, nameEn }) => {
        const verified = await verifyPlaceWithGoogle(nameEn, destinationEn, centerLat, centerLng);
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

  const verifiedCount = tasks.filter(({ item }) => item.coords_verified).length;
  console.log(
    `[PLACES] Verification done: ${verifiedCount}/${tasks.length} places verified for "${destinationEn}"`
  );

  return tripData;
}

// ─── Real restaurants, sourced from Google Places (not from the LLM) ─────────
//
// Attractions survive LLM generation because they're famous enough to exist in
// Places under the name the model guessed. Restaurants don't — the model
// invents plausible-sounding names, verifyPlaceWithGoogle can't find them, and
// we used to keep the invented name with `coords_verified: false`. That is the
// root cause of "the stops are right but the restaurants are wrong".
//
// So we stop asking the LLM for restaurants at all and pull the real ones
// straight out of Places. Bonus: this is CHEAPER than the old path — two
// searchText calls total instead of one per invented restaurant.

// Places priceLevel enum → rough USD per person, used for the budget tab.
const PRICE_LEVEL_USD = {
  PRICE_LEVEL_FREE: 0,
  PRICE_LEVEL_INEXPENSIVE: 8,
  PRICE_LEVEL_MODERATE: 20,
  PRICE_LEVEL_EXPENSIVE: 45,
  PRICE_LEVEL_VERY_EXPENSIVE: 90,
};

// Countries where restaurants are halal by default unless stated otherwise.
const HALAL_DEFAULT_COUNTRIES = new Set([
  'SA', 'AE', 'QA', 'KW', 'BH', 'OM', 'IQ', 'JO', 'EG', 'MA', 'TN', 'DZ',
  'TR', 'MY', 'ID', 'PK', 'LY', 'SD', 'YE', 'SY', 'LB', 'PS', 'BN', 'MV',
]);

// Place types we accept as "somewhere you eat".
const FOOD_PLACE_TYPES = new Set([
  'restaurant', 'cafe', 'bakery', 'meal_takeaway', 'meal_delivery',
  'coffee_shop', 'breakfast_restaurant', 'brunch_restaurant',
  'fine_dining_restaurant', 'fast_food_restaurant', 'steak_house',
  'seafood_restaurant', 'middle_eastern_restaurant', 'turkish_restaurant',
  'lebanese_restaurant', 'italian_restaurant', 'japanese_restaurant',
  'indian_restaurant', 'chinese_restaurant', 'american_restaurant',
  'pizza_restaurant', 'sandwich_shop', 'dessert_shop', 'ice_cream_shop',
]);

const RESTAURANT_FIELD_MASK = [
  'places.id',
  'places.displayName',
  'places.location',
  'places.formattedAddress',
  'places.rating',
  'places.userRatingCount',
  'places.priceLevel',
  'places.primaryTypeDisplayName',
  'places.types',
  'places.websiteUri',
  'places.regularOpeningHours.weekdayDescriptions',
  'places.editorialSummary',
].join(',');

async function searchRestaurantsInLanguage(cityEn, centerLat, centerLng, languageCode) {
  const placesKey = process.env.GOOGLE_PLACES_API_KEY;
  const body = {
    textQuery: `best restaurants in ${cityEn}`,
    includedType: 'restaurant',
    languageCode,
    maxResultCount: 20,
  };
  if (centerLat && centerLng) {
    body.locationBias = {
      circle: {
        center: { latitude: parseFloat(centerLat), longitude: parseFloat(centerLng) },
        radius: 30000,
      },
    };
  }

  const res = await axios.post(
    'https://places.googleapis.com/v1/places:searchText',
    body,
    {
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': placesKey,
        'X-Goog-FieldMask': RESTAURANT_FIELD_MASK,
      },
      timeout: 10000,
    }
  );
  return res.data?.places || [];
}

// Returns an array of app-shaped restaurant objects, or [] when Places is
// unconfigured / returns nothing usable (caller then keeps the LLM's list).
async function fetchRealRestaurants(cityEn, centerLat, centerLng, countryCode, limit) {
  const placesKey = process.env.GOOGLE_PLACES_API_KEY;
  if (!placesKey || placesKey === 'your_google_places_api_key_here') {
    console.warn('[RESTAURANTS] Places not configured — keeping AI-generated restaurants.');
    return [];
  }

  const cacheKey = `__restaurants__|${cityEn.toLowerCase().trim()}|${limit}`;
  const now = Date.now();
  if (placesCache.has(cacheKey)) {
    const cached = placesCache.get(cacheKey);
    if (now - cached.timestamp < PLACES_CACHE_TTL_MS) return cached.data;
    placesCache.delete(cacheKey);
  }

  let arPlaces = [];
  let enPlaces = [];
  try {
    // Arabic names are what the UI shows; English names are what the image
    // search and the Google Maps deep link work best with. One call each.
    [arPlaces, enPlaces] = await Promise.all([
      searchRestaurantsInLanguage(cityEn, centerLat, centerLng, 'ar'),
      searchRestaurantsInLanguage(cityEn, centerLat, centerLng, 'en'),
    ]);
  } catch (err) {
    const apiError = err.response?.data?.error;
    console.error('[RESTAURANTS] Places search failed:', apiError?.message || err.message);
    return [];
  }

  const enById = new Map(enPlaces.map((p) => [p.id, p]));
  const halalByDefault = HALAL_DEFAULT_COUNTRIES.has((countryCode || '').toUpperCase());

  const candidates = arPlaces
    .filter((p) => {
      if (!p.location || !p.displayName?.text) return false;
      // `includedType` is a soft filter — Riyadh's top hit for this query is a
      // scenic viewpoint, not a restaurant. Require the real type tag.
      if (!(p.types || []).some((t) => FOOD_PLACE_TYPES.has(t))) return false;
      // Thin listings are usually closed or mis-tagged — skip them.
      if ((p.userRatingCount || 0) < 20) return false;
      if ((p.rating || 0) < 3.8) return false;
      if (centerLat && centerLng) {
        const distKm = haversineDistance(
          parseFloat(centerLat), parseFloat(centerLng),
          p.location.latitude, p.location.longitude
        );
        if (distKm > PLACES_MAX_DISTANCE_KM) return false;
      }
      return true;
    })
    // Rank by rating weighted with review volume so a lone 5.0 with 21 reviews
    // doesn't outrank a 4.6 with 8000.
    .sort((a, b) =>
      (b.rating * Math.log10(b.userRatingCount + 10)) -
      (a.rating * Math.log10(a.userRatingCount + 10))
    )
    .slice(0, limit);

  const mapped = candidates.map((p) => {
    // The en/ar searches don't return identical result sets, so this misses
    // fairly often — every use below falls back to the Arabic record.
    const en = enById.get(p.id);
    const cuisine = p.primaryTypeDisplayName?.text || en?.primaryTypeDisplayName?.text || '';
    // Image search only works with Latin text. When we have no English name,
    // describe the cuisine in English from the type tags instead of sending
    // Arabic through and getting unrelated photos back.
    const cuisineEn = (p.types || []).find((t) => FOOD_PLACE_TYPES.has(t)) || 'restaurant';
    const imageQuery = en?.displayName?.text
      ? `${en.displayName.text} restaurant food`
      : `${cuisineEn.replace(/_/g, ' ')} ${cityEn} food`;
    const editorial = p.editorialSummary?.text;
    // Latin digits throughout — the app renders ratings as Latin everywhere
    // else, and 'ar-EG' grouping would mix ٣٬١٧٣ with a Latin "4.1".
    const ratingText =
      `تقييم ${p.rating} من ${p.userRatingCount.toLocaleString('en-US')} زائر على خرائط Google`;

    return {
      name: p.displayName.text,
      name_en: en?.displayName?.text || p.displayName.text,
      cuisine_type: cuisine,
      halal_certified: halalByDefault,
      rating: p.rating,
      price_per_person_usd: PRICE_LEVEL_USD[p.priceLevel] ?? 20,
      address: p.formattedAddress || '',
      latitude: p.location.latitude,
      longitude: p.location.longitude,
      opening_hours: (p.regularOpeningHours?.weekdayDescriptions || []).join(' • '),
      ai_description: editorial ? `${editorial} — ${ratingText}.` : `${ratingText}.`,
      image_search_query: imageQuery,
      booking_url: p.websiteUri || null,
      place_id: p.id,
      coords_verified: true,
    };
  });

  placesCache.set(cacheKey, { data: mapped, timestamp: now });
  console.log(`[RESTAURANTS] ${mapped.length} real restaurants sourced for "${cityEn}"`);
  return mapped;
}

// Swap the LLM's restaurants for the real ones. Each day gets its own
// recommended restaurant (no repeats), and the rest fill all_restaurants.
function applyRealRestaurants(tripData, realRestaurants) {
  if (!realRestaurants.length) return tripData;

  const dayCount = Array.isArray(tripData.days) ? tripData.days.length : 0;
  // Highest-ranked go to the per-day recommendations.
  const recommended = realRestaurants.slice(0, dayCount);
  const rest = realRestaurants.slice(dayCount);

  for (let i = 0; i < dayCount; i++) {
    if (recommended[i]) {
      tripData.days[i].recommended_restaurant = { ...recommended[i] };
    } else {
      delete tripData.days[i].recommended_restaurant;
    }
  }

  // Keep the recommended ones in the full list too — the app dedupes by name
  // and flags them with is_recommended, so the Restaurants tab shows everything.
  tripData.all_restaurants = rest.length ? rest : realRestaurants;
  return tripData;
}

// ─── POST /api/generate-trip ────────────────────────────────────────────────
// Resolve a possibly-Arabic destination string to a canonical English city
// name + country using Google Places (New). Doing this here — rather than
// asking the LLM — is both more reliable (Google knows Arabic place names)
// and frees the whole Groq token-per-minute budget for the actual trip
// generation. Bonus: it returns real coordinates we can use to bias/verify
// the Places lookups later. Returns null if Places isn't configured or the
// destination can't be resolved.
async function resolveDestinationEN(rawDestination) {
  // 1. Zero-cost static dictionary first (covers common destinations without
  //    spending any Google Places quota).
  const dict = lookupCityDictionary(rawDestination);
  if (dict) {
    return { cityEn: dict.en, country: dict.country, countryCode: dict.code, lat: null, lng: null };
  }

  // 2. Latin-script input (any non-Arabic city worldwide): pass it straight
  //    through — the model reads it fine, so no Places lookup is needed.
  if (isLatinScriptDestination(rawDestination)) {
    return { cityEn: rawDestination.trim(), country: '', countryCode: '', lat: null, lng: null };
  }

  // 3. Arabic name not in the dictionary → fall back to Google Places.
  const placesKey = process.env.GOOGLE_PLACES_API_KEY;
  if (!placesKey || placesKey === 'your_google_places_api_key_here') return null;
  try {
    const res = await axios.post(
      'https://places.googleapis.com/v1/places:searchText',
      { textQuery: rawDestination, languageCode: 'en' },
      {
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': placesKey,
          'X-Goog-FieldMask': 'places.displayName,places.formattedAddress,places.location,places.addressComponents',
        },
        timeout: 8000,
      }
    );
    const p = res.data?.places?.[0];
    const cityEn = p?.displayName?.text?.trim();
    if (!cityEn) return null;

    let country = '';
    let countryCode = '';
    for (const comp of (p.addressComponents || [])) {
      if ((comp.types || []).includes('country')) {
        country = comp.longText || comp.shortText || '';
        countryCode = comp.shortText || '';
        break;
      }
    }
    if (!country && p.formattedAddress) {
      const parts = p.formattedAddress.split(',');
      country = parts[parts.length - 1].trim();
    }

    return {
      cityEn,
      country,
      countryCode,
      lat: p.location?.latitude ?? null,
      lng: p.location?.longitude ?? null,
    };
  } catch (err) {
    console.warn('[RESOLVE] Places resolution failed:', err.response?.data?.error?.message || err.message);
    return null;
  }
}

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

  // Resolve the (possibly Arabic) destination to a canonical English city so
  // the model can't quietly swap it for a more famous one.
  const resolved = await resolveDestinationEN(destination);
  if (resolved) {
    console.log(`[RESOLVE] "${destination}" -> ${resolved.cityEn}, ${resolved.country}`);
  }
  const resolvedDirective = resolved
    ? `\nAUTHORITATIVE DESTINATION: The user's destination "${destination}" refers to the city "${resolved.cityEn}" in ${resolved.country}. You MUST build the ENTIRE itinerary for "${resolved.cityEn}, ${resolved.country}" and nothing else. NEVER substitute a different or more famous city. Every stop and restaurant must be a real place physically located in ${resolved.cityEn}. Set destination_en to "${resolved.cityEn}".\n`
    : '';

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
${resolvedDirective}
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

RULE 4 — RESTAURANT VARIETY & LOCATION:
Each day's recommended_restaurant must be a DIFFERENT restaurant.
all_restaurants list must contain UNIQUE restaurants (not repeating recommended_restaurant).
EVERY restaurant (recommended_restaurant AND all_restaurants) MUST be physically located inside ${destination} itself — the same city/governorate as the trip destination. Do NOT suggest a restaurant from a different city, even if it shares a name with a well-known chain that also has a branch elsewhere.

RULE 5 — ACCURATE COORDINATES:
Every latitude/longitude must be the actual GPS coordinates of that specific real place, located within ${destination}. Google Maps-verifiable coordinates only.
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
    // Arabic JSON runs about 1.3 characters per token, so a 3-day trip needs
    // roughly 6000 output tokens for its ~8k characters. Measured the hard
    // way: trimming the reservation to 5000 truncated the reply mid-JSON,
    // which then burned a retry and fell through to the slow fallback. Keep
    // the budget generous — a truncated reply costs far more than the tokens.
    const estimatedTokens = 2000 + durationDays * 1500;
    const MAX_TOKENS = Math.min(Math.max(estimatedTokens, 6000), 40000);

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

      // The model occasionally ignores the requested destination and
      // generates a trip for a different, more "famous" city instead
      // (observed live: asked for "كربلاء", got a full Cairo itinerary).
      // Since every downstream piece — stops, restaurants, Places
      // verification — inherits this, catch it here and force a retry
      // rather than silently returning a trip for the wrong place.
      const normalizeCityName = (str) => (str || '')
        .toString()
        .trim()
        .toLowerCase()
        .replace(/[ً-ٰٟ]/g, '') // strip Arabic diacritics
        .replace(/[^\p{L}\p{N}]/gu, ''); // strip spaces/punctuation

      const returnedArNorm = normalizeCityName(parsed.destination);
      const returnedEnNorm = normalizeCityName(parsed.destination_en);
      // Prefer matching against the resolved English city (reliable, same
      // script as destination_en); fall back to the raw (possibly Arabic)
      // destination when resolution wasn't available.
      const requestedNorm = normalizeCityName(resolved ? resolved.cityEn : destination);
      const rawRequestedNorm = normalizeCityName(destination);
      const matchesOne = (a, b) => a && b && (a.includes(b) || b.includes(a));
      const destinationMatches = (requestedNorm && (
        matchesOne(returnedEnNorm, requestedNorm) || matchesOne(returnedArNorm, requestedNorm)
      )) || (rawRequestedNorm && (
        matchesOne(returnedArNorm, rawRequestedNorm) || matchesOne(returnedEnNorm, rawRequestedNorm)
      ));
      if (!destinationMatches) {
        console.warn(
          `[TRIP] Destination mismatch: requested "${destination}", AI returned "${parsed.destination}" / "${parsed.destination_en}"`
        );
        throw new Error('wrong-destination');
      }

      return parsed;
    }

    let parsedData;
    let lastError;
    // Now that the destination is resolved to English up-front, attempt 1
    // succeeds in the normal case, so a single retry is enough insurance.
    // A wall-clock budget stops us starting an attempt that would push the
    // user past the point where the request just feels broken — three full
    // attempts (each ~5.5s, plus the Gemini fallback inside callAI) used to
    // stretch a failed generation past 30 seconds.
    const maxAttempts = 2;
    const GENERATION_BUDGET_MS = 22000;
    const startedAt = Date.now();
    for (let attempt = 0; attempt < maxAttempts; attempt++) {
      if (attempt > 0 && Date.now() - startedAt > GENERATION_BUDGET_MS) {
        console.warn('[TRIP] generation budget exhausted — not starting another attempt');
        break;
      }
      try {
        const extraInstruction = attempt === 0
          ? undefined
          : lastError && lastError.message === 'wrong-destination'
            ? `IMPORTANT: your previous reply generated a trip for the WRONG destination. You MUST generate this itinerary specifically for "${destination}" — do NOT substitute a different, more famous city. Every stop, restaurant, and coordinate must be a real place located inside "${destination}".`
            : `IMPORTANT REMINDER: your previous reply was truncated, incomplete, or had invalid JSON syntax. Return ALL ${durationDays} days as a single complete, valid, non-truncated JSON object with correct JSON syntax (no trailing commas, properly escaped quotes inside strings). Keep descriptions concise if needed to fit within the token limit, but NEVER omit a day.`;
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
    // Prefer the resolved English city name for Places lookups, and fall back
    // to the resolved city's real coordinates as the search/verify center when
    // the user gave no GPS — both make the "wrong city" rejection far tighter.
    const destinationEn = (resolved && resolved.cityEn) || parsedData.destination_en || destination;
    const centerLat = userLat || (resolved && resolved.lat) || null;
    const centerLng = userLng || (resolved && resolved.lng) || null;
    parsedData = await verifyAllPlacesInTrip(parsedData, destinationEn, centerLat, centerLng);

    // Replace the model's invented restaurants with real, currently-open ones
    // from Places. Runs AFTER verification so the stop centroid is available as
    // a search center when the user gave no GPS. No-ops if Places is off.
    const restaurantLimit = Math.min(20, Math.max(8, (parseInt(durationDays, 10) || 3) * 3));
    const restaurantCentroid = tripStopCentroid(parsedData);
    const realRestaurants = await fetchRealRestaurants(
      destinationEn,
      centerLat || restaurantCentroid?.lat,
      centerLng || restaurantCentroid?.lng,
      (resolved && resolved.countryCode) || countryCode,
      restaurantLimit
    );
    parsedData = applyRealRestaurants(parsedData, realRestaurants);

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
            // Previously this only warned and kept the duplicate, so the same
            // restaurant could headline several days of the same trip.
            console.warn(`[DEDUP] Removed repeated restaurant: ${day.recommended_restaurant.name_en || day.recommended_restaurant.name}`);
            delete day.recommended_restaurant;
          } else {
            seenRestaurants.add(rKey);
          }
        }
      }
    }
  }

  // Share seenRestaurants rather than starting a fresh set: a restaurant that
  // already headlines a day must not show up again in the general list.
  if (plan.all_restaurants && Array.isArray(plan.all_restaurants)) {
    plan.all_restaurants = plan.all_restaurants.filter(r => {
      const key = r.name_en?.toLowerCase().trim() || r.name?.toLowerCase().trim();
      if (!key) return true;
      if (seenRestaurants.has(key)) return false;
      seenRestaurants.add(key);
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

  // Overpass rejects a raw text/plain body (406) and wants the query as a
  // form-encoded `data=` field with a real User-Agent. Try the main endpoint,
  // then a mirror, before giving up.
  const overpassHosts = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
  ];

  const postOverpass = async (host) => axios.post(
    host,
    new URLSearchParams({ data: overpassQuery }).toString(),
    {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'User-Agent': 'RahhalAI/1.0 (trip planner nearby-places)',
      },
      // Public Overpass instances usually answer in ~2s but occasionally 504 /
      // stall under load; give each host a generous window before failing over.
      timeout: 28000,
    },
  );

  try {
    let response;
    let lastErr;
    for (const host of overpassHosts) {
      try {
        response = await postOverpass(host);
        break;
      } catch (e) {
        lastErr = e;
        console.warn(`[NEARBY] ${host} failed: ${e.response?.status || e.message}`);
      }
    }
    if (!response) throw lastErr || new Error('all-overpass-hosts-failed');

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
// Free hosting tiers spin the container down after some minutes of inactivity,
// which makes the user's first trip wait ~30s for a cold start. Pinging the
// PUBLIC url every few minutes generates real inbound traffic that keeps it
// awake. Pinging localhost does NOT — it never leaves the container, so the
// platform still sees no traffic and sleeps anyway (the previous bug on
// Railway, which doesn't set RENDER_EXTERNAL_URL).
const SELF_PING_INTERVAL_MS = 4 * 60 * 1000; // 4 minutes — under typical idle windows

// Resolve the public base URL from whichever platform we're on.
function resolvePublicUrl() {
  if (process.env.PUBLIC_URL) return process.env.PUBLIC_URL;
  if (process.env.RENDER_EXTERNAL_URL) return process.env.RENDER_EXTERNAL_URL;
  // Railway exposes the domain without a scheme.
  if (process.env.RAILWAY_PUBLIC_DOMAIN) return `https://${process.env.RAILWAY_PUBLIC_DOMAIN}`;
  if (process.env.RAILWAY_STATIC_URL) {
    const u = process.env.RAILWAY_STATIC_URL;
    return u.startsWith('http') ? u : `https://${u}`;
  }
  return null;
}

function startSelfPing() {
  const publicUrl = resolvePublicUrl();
  if (!publicUrl) {
    // Local dev (or an unknown platform) — a localhost ping wouldn't prevent
    // any real sleep, so skip it rather than log misleading "success".
    console.log('[KEEP-ALIVE] No public URL detected — self-ping disabled (local dev).');
    return;
  }
  console.log(`[KEEP-ALIVE] Self-ping enabled → ${publicUrl}/health every 4min`);

  setInterval(async () => {
    try {
      await axios.get(`${publicUrl}/health`, { timeout: 10000 });
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
