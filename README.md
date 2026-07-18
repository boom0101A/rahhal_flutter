# رحّال AI — مساعدك الذكي للسفر ✈️

تطبيق Flutter ذكي لتخطيط الرحلات باستخدام Claude AI.

## المتطلبات
- Flutter SDK >= 3.5.0
- Node.js >= 18
- حساب Firebase
- مفتاح Anthropic API

## إعداد المشروع

### 1. Firebase
```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=rahhal-ai
```

### 2. Backend Proxy
```bash
npm install
cp .env.example .env
# أضف مفاتيحك في .env
node server.js
```

### 3. Flutter
```bash
flutter pub get
flutter run --dart-define=PROXY_BASE_URL=http://YOUR_IP:3000
```

## ملف .env المطلوب
```
ANTHROPIC_API_KEY=sk-ant-...
UNSPLASH_ACCESS_KEY=...       # اختياري
PEXELS_API_KEY=...            # اختياري
OPENWEATHER_API_KEY=...       # للطقس (مستقبلاً)
PORT=3000
```

## الميزات
- 🤖 توليد خطط سفر بالذكاء الاصطناعي
- 🗺️ خريطة تفاعلية للمحطات
- 🍽️ توصيات مطاعم
- 💰 تتبع الميزانية والمصاريف
- 🎒 قائمة التعبئة الذكية
- 📁 إدارة مستندات الرحلة
- ❤️ المفضلة
- 🌐 دعم العربية والإنجليزية
- 🌙 وضع داكن وفاتح
