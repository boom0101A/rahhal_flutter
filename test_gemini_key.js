// Quick test: Does the Gemini API key actually work?
require('dotenv').config();
const axios = require('axios');
const { GoogleGenerativeAI } = require('@google/generative-ai');

const apiKey = process.env.GEMINI_API_KEY;
console.log('Testing GEMINI_API_KEY:', apiKey ? `${apiKey.substring(0, 8)}...` : 'NOT SET');

async function testSDK() {
  console.log('\n--- Test 1: Google AI SDK ---');
  try {
    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });
    const result = await model.generateContent('Say hello in Arabic in 5 words');
    console.log('✅ SDK SUCCESS:', result.response.text().substring(0, 100));
    return true;
  } catch (e) {
    console.error('❌ SDK FAILED:', e.message);
    return false;
  }
}

async function testREST() {
  console.log('\n--- Test 2: REST API (v1beta) ---');
  try {
    const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`;
    const res = await axios.post(url, {
      contents: [{ role: 'user', parts: [{ text: 'Say hello in Arabic in 5 words' }] }],
    }, { timeout: 15000 });
    const text = res.data?.candidates?.[0]?.content?.parts?.[0]?.text;
    console.log('✅ REST SUCCESS:', text?.substring(0, 100));
    return true;
  } catch (e) {
    console.error('❌ REST FAILED:', e.response?.data?.error?.message || e.message);
    return false;
  }
}

async function testPlacesKeyAsGemini() {
  const placesKey = process.env.GOOGLE_PLACES_API_KEY;
  if (!placesKey) return false;
  console.log('\n--- Test 3: GOOGLE_PLACES_API_KEY as Gemini key ---');
  try {
    const genAI = new GoogleGenerativeAI(placesKey);
    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });
    const result = await model.generateContent('Say hello in Arabic in 5 words');
    console.log('✅ PLACES KEY as GEMINI SUCCESS:', result.response.text().substring(0, 100));
    return true;
  } catch (e) {
    console.error('❌ PLACES KEY FAILED:', e.message);
    return false;
  }
}

(async () => {
  const sdk = await testSDK();
  const rest = await testREST();
  const places = await testPlacesKeyAsGemini();
  
  console.log('\n═══════════════════════════════════════════');
  console.log('RESULTS:');
  console.log(`  SDK:        ${sdk ? '✅ WORKS' : '❌ BROKEN'}`);
  console.log(`  REST API:   ${rest ? '✅ WORKS' : '❌ BROKEN'}`);
  console.log(`  Places Key: ${places ? '✅ WORKS as Gemini' : '❌ NOT USABLE'}`);
  console.log('═══════════════════════════════════════════');
  
  if (!sdk && !rest && !places) {
    console.log('\n⚠️  NONE of the API keys work for Gemini AI.');
    console.log('   You need a valid Gemini API key from: https://aistudio.google.com/app/apikey');
  }
})();
