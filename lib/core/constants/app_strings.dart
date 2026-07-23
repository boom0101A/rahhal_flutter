import 'package:flutter/widgets.dart';

class AppStrings {
  final String _lang;
  const AppStrings(this._lang);

  static AppStrings of(BuildContext context) {
    try {
      final locale = Localizations.localeOf(context);
      return AppStrings(locale.languageCode);
    } catch (_) {
      return const AppStrings('ar');
    }
  }

  T _t<T>(T ar, T en) {
    return _lang == 'en' ? en : ar;
  }

  String get languageCode => _lang;

  // App
  String get appName => _t('رحّال AI', 'Rahhal AI');
  String get appTagline => _t('رحلتك، مُخطَّطة بالذكاء الاصطناعي', 'Your trip, planned by AI');

  // Splash
  String get splashSubtitle => _t('مساعدك الذكي للسفر', 'Your smart travel assistant');
  String get splashStart => _t('ابدأ رحلتك', 'Start your trip');
  String get splashTagline => _t('رحلاتك، مخططة بذكاء', 'Your trips, planned smartly');

  // Onboarding
  String get onboardingSkip => _t('تخطى', 'Skip');
  String get onboardingNext => _t('التالي', 'Next');
  String get onboardingGetStarted => _t('ابدأ الآن', 'Get Started');
  String get onboardingTitle1 => _t('خطط رحلتك بالذكاء الاصطناعي', 'Plan with AI');
  String get onboardingDesc1 => _t('أخبر رحّال AI عن وجهتك وميزانيتك، وسيُنشئ خطة رحلة متكاملة خصيصاً لك', 'Tell Rahhal AI your destination and budget, and it will generate a personalized trip plan for you');
  String get onboardingTitle2 => _t('جداول يومية تفصيلية', 'Detailed Daily Itineraries');
  String get onboardingDesc2 => _t('كل يوم من رحلتك مُخطَّطة بعناية مع أوقات الزيارة ونصائح الخبراء والتكاليف التقديرية', 'Every day is meticulously planned with visiting hours, expert tips, and estimated costs');
  String get onboardingTitle3 => _t('مساعد سفر دائم معك', 'Travel Assistant 24/7');
  String get onboardingDesc3 => _t('تحدث مع مساعد رحّال في أي وقت للحصول على توصيات واقتراحات وإجابات فورية', 'Chat with Rahhal assistant anytime for recommendations, suggestions, and instant answers');

  // Auth
  String get authLogin => _t('تسجيل الدخول', 'Login');
  String get authRegister => _t('إنشاء حساب', 'Register');
  String get authEmail => _t('البريد الإلكتروني', 'Email Address');
  String get authPassword => _t('كلمة المرور', 'Password');
  String get authName => _t('الاسم الكامل', 'Full Name');
  String get authGoogleSignIn => _t('الدخول بـ Google', 'Sign in with Google');
  String get authGuestMode => _t('تصفح كضيف', 'Browse as Guest');
  String get authForgotPassword => _t('نسيت كلمة المرور؟', 'Forgot Password?');
  String get authHaveAccount => _t('لديك حساب بالفعل؟', 'Already have an account?');
  String get authNoAccount => _t('ليس لديك حساب؟', 'Don\'t have an account?');
  String get authWelcomeBack => _t('أهلاً بعودتك! سجّل دخولك للمتابعة', 'Welcome back! Login to continue');
  String get authCreateAccount => _t('أنشئ حسابك وابدأ رحلتك الأولى', 'Create an account and start your first trip');
  String get authEnterName => _t('أدخل اسمك', 'Enter your name');
  String get authInvalidEmail => _t('بريد إلكتروني غير صالح', 'Invalid email address');
  String get authWeakPassword => _t('كلمة مرور يجب أن تكون 6 أحرف على الأقل', 'Password must be at least 6 characters');
  String get authOr => _t('أو', 'OR');
  String get loading => _t('جارٍ التحميل...', 'Loading...');

  // Navigation Bar Labels
  String get navMyTrips   => _t('رحلاتي',   'My Trips');
  String get navPlan      => _t('خطط رحلة', 'Plan Trip');
  String get navFavorites => _t('المفضلة',  'Favorites');
  String get navAccount   => _t('حسابي',    'Account');

  // Trip Input / Wizard
  String get planTitle => _t('خطط رحلتي', 'Plan My Trip');
  String get planAIGreeting => _t('مرحباً! أخبرني عن رحلتك القادمة 🌍', 'Welcome! Tell me about your next trip 🌍');
  String get planDestination => _t('إلى أين تريد السفر؟', 'Where do you want to travel?');
  String get planDestinationHint => _t('اكتب اسم المدينة...', 'Type city name...');
  String get planDuration => _t('مدة الرحلة', 'Trip Duration');
  String get planDurationDays => _t('أيام', 'days');
  String get planBudget => _t('الميزانية', 'Budget');
  String get planBudgetEconomy => _t('اقتصادي', 'Economy');
  String get planBudgetMid => _t('متوسط', 'Mid-range');
  String get planBudgetLuxury => _t('فاخر', 'Luxury');
  String get planBudgetEconomySub => _t('فنادق اقتصادية وطعام شعبي', 'Economy hotels & local food');
  String get planBudgetMidSub => _t('فنادق 3-4 نجوم ومطاعم متنوعة', '3-4 star hotels & mixed dining');
  String get planBudgetLuxurySub => _t('فنادق 5 نجوم وتجارب راقية', '5 star hotels & premium experience');
  String get planTravelStyle => _t('نمط السفر', 'Travel Style');
  String get planTravelers => _t('عدد المسافرين', 'Number of Travelers');
  String get planAdults => _t('بالغون', 'Adults');
  String get planChildren => _t('أطفال', 'Children');
  String get planGenerateButton => _t('خطط رحلتي بالذكاء الاصطناعي', 'Plan My Trip with AI');
  String get defaultDestination => _t('إسطنبول', 'Istanbul');
  String get startDateTitle => _t('تاريخ بدء الرحلة', 'Trip Start Date');
  String get startDateHint => _t('اختر تاريخ البدء (اختياري)', 'Select start date (optional)');
  String get validationEmptyDestination => _t('الرجاء إدخال اسم الوجهة', 'Please enter a destination');
  String get validationShortDestination => _t('اسم الوجهة قصير جداً', 'Destination name is too short');
  String get validationEmptyStyles => _t('الرجاء اختيار نمط سفر واحد على الأقل', 'Please select at least one travel style');
  String get discoverNearbyTitle => _t('اكتشف المعالم السياحية القريبة منك 📍', 'Discover Tourist Spots Near You 📍');
  String get discoverNearbySubtitle => _t('اضغط هنا لاستخدام موقعك الحالي واكتشاف أفضل الأماكن والمطاعم في مدينتك', 'Tap to use your current location and discover top attractions in your city');
  String get detectingLocation => _t('جاري تحديد موقعك الجغرافي...', 'Detecting your location...');
  String get locationPermissionDenied => _t('تعذر الوصول إلى موقعك. يرجى تفعيل إذن الموقع في الإعدادات.', 'Unable to access location. Please grant permission in settings.');
  String get discoverCurrentCityButton => _t('استكشف مدينتي الحالية', 'Explore My Current City');
  String get openInMaps => _t('افتح في الخرائط 📍', 'Open in Maps 📍');
  String get mapsOpenFailed => _t('تعذر فتح خرائط Google', 'Could not open Google Maps');
  String get orderUber => _t('اطلب Uber 🚗', 'Order Uber 🚗');
  String get orderCareem => _t('اطلب Careem 🚕', 'Order Careem 🚕');

  // Travel Styles
  String get styleCulture => _t('ثقافة', 'Culture');
  String get styleAdventure => _t('مغامرة', 'Adventure');
  String get styleFood => _t('طعام', 'Food');
  String get styleShopping => _t('تسوق', 'Shopping');
  String get styleNature => _t('طبيعة', 'Nature');
  String get styleRelax => _t('استرخاء', 'Relax');

  // Generating Screen
  String get generatingTitle => _t('يُحلّل رحّال AI طلبك', 'Rahhal AI is analyzing your request');
  String get generatingSubtitle => _t('جاري إنشاء خطة رحلتك المثالية...', 'Generating your perfect trip plan...');
  String get generatingStep1 => _t('البحث عن أفضل الوجهات', 'Searching for the best destinations');
  String get generatingStep2 => _t('تحليل الميزانية والتفضيلات', 'Analyzing budget and preferences');
  String get generatingStep3 => _t('إنشاء الجدول اليومي', 'Creating daily itinerary');
  String get generatingStep4 => _t('اختيار المطاعم والأنشطة', 'Selecting restaurants and activities');
  String get generatingStep5 => _t('إضافة نصائح الذكاء الاصطناعي', 'Adding smart AI tips');
  List<String> get travelFacts => _t(
        [
          'أكثر من 90% من قرارات السفر تتأثر بالصور — لهذا نبحث عن صور حقيقية لكل مكان في رحلتك.',
          'رحّال AI يتحقق من إحداثيات كل مكان عبر خرائط Google لضمان دقتها.',
          'أفضل وقت لحجز الفنادق عادة قبل الرحلة بـ 3-4 أسابيع.',
          'المشي أفضل وسيلة لاكتشاف روح أي مدينة جديدة — نرتب لك محطات قريبة من بعضها.',
          'خذ صورة لجواز سفرك وتذاكرك واحفظها في قسم "الوثائق" داخل التطبيق.',
          'تناول الطعام كما يفعل السكان المحليون غالبًا أوفر وألذ من المطاعم السياحية.',
          'نحاول دائمًا اقتراح مطعم واحد على الأقل قريب من كل نشاط رئيسي في يومك.',
        ],
        [
          'Over 90% of travel decisions are influenced by photos — that\'s why we search for real photos of every place in your trip.',
          'Rahhal AI verifies every location\'s coordinates against Google Maps for accuracy.',
          'The best time to book hotels is usually 3-4 weeks before your trip.',
          'Walking is the best way to discover a new city\'s soul — we place stops close to each other.',
          'Snap a photo of your passport and tickets and save them in the "Documents" section.',
          'Eating where locals eat is often cheaper and tastier than tourist restaurants.',
          'We always try to suggest at least one nearby restaurant for each major activity in your day.',
        ],
      );
  String get errorTitle => _t('خطأ', 'Error');

  // Dashboard Tabs
  String get tabSchedule => _t('الجدول', 'Schedule');
  String get tabMap => _t('الخريطة', 'Map');
  String get tabRestaurants => _t('المطاعم', 'Restaurants');
  String get tabCost => _t('التكاليف', 'Costs');

  // Trip Stats
  String get statsDays => _t('أيام', 'Days');
  String get statsPlaces => _t('مكان', 'Places');
  String get statsRestaurants => _t('مطعم', 'Restaurants');
  String get statsPerDay => _t('/يوم', '/day');
  String get statsTravelers => _t('مسافر', 'traveler');

  // Itinerary
  String get itineraryTitle => _t('الجدول اليومي', 'Daily Itinerary');
  String get dayPrefix => _t('اليوم', 'Day');
  String get morning => _t('صباحاً', 'Morning');
  String get afternoon => _t('ظهراً', 'Afternoon');
  String get evening => _t('مساءً', 'Evening');
  String get duration => _t('المدة', 'Duration');
  String get cost => _t('التكلفة', 'Cost');
  String get aiTip => _t('نصيحة رحّال', 'Rahhal Tip');
  String get bookingRequired => _t('يحتاج حجز مسبق', 'Booking Required');
  String get bookNow => _t('احجز الآن', 'Book Now');
  String get suggestedDuration => _t('المدة المقترحة', 'Suggested Duration');
  String get estimatedCost => _t('التكلفة التقديرية', 'Estimated Cost');
  String get addressLabel => _t('العنوان', 'Address');
  String get aiSmartTip => _t('نصيحة رحّال الذكية ✨', 'Smart Rahhal Tip ✨');
  String get geoPosition => _t('الموقع الجغرافي', 'Geographic Location');
  String get latLngLabel => _t('خط العرض: %s • خط الطول: %s', 'Latitude: %s • Longitude: %s');
  String get bookTicketsNow => _t('حجز التذاكر الآن', 'Book Tickets Now');
  String get viewOnFullMap => _t('عرض على الخريطة الكاملة', 'View on Full Map');
  String get noStopsForDay => _t('لا توجد محطات لهذا اليوم', 'No stops planned for this day');
  String get infoChipBook => _t('حجز', 'Book');

  // Map
  String get mapTitle => _t('خريطة الرحلة', 'Trip Map');
  String get mapFilterAll => _t('الكل', 'All');
  String get mapStopsCount => _t('محطة', 'Stops');
  String get fullItineraryMap => _t('مسار الرحلة الكامل', 'Full Itinerary Map');

  // Restaurants
  String get restaurantsTitle => _t('المطاعم الموصى بها', 'Recommended Restaurants');
  String get restaurantFilterAll => _t('الكل', 'All');
  String get restaurantHalal => _t('حلال', 'Halal');
  String get restaurantOpenNow => _t('مفتوح الآن', 'Open Now');
  String get restaurantClosed => _t('مغلق', 'Closed');
  String get restaurantRecommended => _t('موصى به', 'Recommended');
  String get restaurantRating => _t('التقييم', 'Rating');
  String get restaurantPrice => _t('السعر/شخص', 'Price/Person');
  String get restaurantFilterHalal => _t('✓ حلال', '✓ Halal');
  String get restaurantFilterRecommended => _t('✨ موصى به', '✨ Recommended');
  String get noRestaurantsForFilter => _t('لا توجد مطاعم بهذا الفلتر', 'No restaurants found with this filter');
  String get seafoodStyle => _t('بحري', 'Seafood');
  String get traditionalStyle => _t('تقليدي', 'Traditional');
  String get modernStyle => _t('عصري', 'Modern');

  // Budget / Cost
  String get budgetTitle => _t('تفاصيل التكاليف', 'Cost Details');
  String get budgetTotal => _t('إجمالي التكلفة التقديرية', 'Total Estimated Cost');
  String get budgetAccommodation => _t('السكن', 'Accommodation');
  String get budgetFood => _t('الطعام', 'Food');
  String get budgetTransport => _t('المواصلات', 'Transport');
  String get budgetActivities => _t('الزيارات', 'Activities');
  String get budgetShopping => _t('التسوق', 'Shopping');
  String get budgetOther => _t('أخرى', 'Other');
  String get budgetPerDay => _t('يومياً', 'Daily');
  String get budgetEstimated => _t('تقديري', 'Estimated');
  String get budgetDistribution => _t('توزيع الميزانية', 'Budget Distribution');
  String get budgetDetails => _t('تفاصيل البنود', 'Item Details');
  String get budgetEmpty => _t('لا توجد ميزانية متاحة لهذه الرحلة', 'No budget data available for this trip');

  // Saved Trips
  String get savedTitle => _t('رحلاتي', 'My Trips');
  String get savedEmpty => _t('لا توجد رحلات محفوظة', 'No saved trips');
  String get savedEmptySubtitle => _t('ابدأ رحلة جديدة مع رحّال AI', 'Start a new trip with Rahhal AI');
  String get savedNewTrip => _t('رحلة جديدة', 'New Trip');
  String get statusPlanned => _t('مخططة', 'Planned');
  String get statusActive => _t('جارية', 'Active');
  String get statusDone => _t('مكتملة', 'Completed');
  String get greeting => _t('مرحباً! 👋', 'Welcome! 👋');
  String get deleteTripTitle => _t('حذف الرحلة', 'Delete Trip');
  String get startFirstTrip => _t('ابدأ رحلتك الأولى', 'Start your first trip');

  String deleteTripConfirm(String destination) {
    return _t('هل تريد حذف رحلة $destination؟', 'Do you want to delete the trip to $destination?');
  }

  // AI Chat
  String get chatTitle => _t('مساعد رحّال', 'Rahhal Assistant');
  String get chatHint => _t('اسأل عن رحلتك...', 'Ask about your trip...');
  String get chatTyping => _t('رحّال يكتب...', 'Rahhal is typing...');
  // Smart, action-oriented replan prompts (answered with the trip's context).
  String get chatQuickReply1 =>
      _t('الطقس سيئ اليوم — اقترح بديلاً داخلياً', 'Bad weather today — suggest an indoor alternative');
  String get chatQuickReply2 =>
      _t('ما أفضل ترتيب لمحطات اليوم؟', 'What\'s the best order for today\'s stops?');
  String get chatQuickReply3 =>
      _t('لو كان لديّ يوم إضافي، ماذا أزور؟', 'If I had an extra day, what should I add?');
  String get chatQuickReply4 =>
      _t('أفضل الأكلات المحلية لأجربها', 'Best local dishes I should try');
  String get chatQuickReply5 =>
      _t('نصائح وآداب محلية مهمة', 'Important local tips & etiquette');
  String get chatQuickReply6 =>
      _t('كيف أوفّر في الميزانية؟', 'How can I save on budget?');
  String get chatOnlineStatus => _t('متصل الآن', 'Online');
  String get chatIntroTitle => _t('أهلاً! أنا مساعد رحّال', 'Hi! I\'m Rahhal Assistant');
  String get chatIntroSubtitle => _t('اسألني عن أي شيء يتعلق برحلتك وسأساعدك فوراً', 'Ask me anything about your trip and I\'ll help you');
  String get chatSuggestions => _t('اقتراحات:', 'Suggestions:');

  // Settings
  String get settingsTitle => _t('الإعدادات', 'Settings');
  String get settingsProfile => _t('الملف الشخصي', 'Profile');
  String get settingsLanguage => _t('اللغة', 'Language');
  String get settingsCurrency => _t('العملة', 'Currency');
  String get settingsDarkMode => _t('الوضع الليلي', 'Dark Mode');
  String get settingsNotifications => _t('الإشعارات', 'Notifications');
  String get settingsLogout => _t('تسجيل الخروج', 'Logout');
  String get settingsSignOut => _t('تسجيل الخروج', 'Sign Out');
  String get settingsVersion => _t('الإصدار', 'Version');
  String get selectLanguageTitle => _t('اختر اللغة / Select Language', 'Select Language');
  String get languageArabic => _t('العربية', 'Arabic');
  String get languageEnglish => _t('الإنجليزية', 'English');
  String get languageArabicDefault => _t('العربية (افتراضي)', 'Arabic (Default)');
  String get themeTitle => _t('المظهر', 'Theme');
  String get themeDark => _t('داكن دائماً', 'Always Dark');
  String get themeLight => _t('فاتح دائماً', 'Always Light');
  String get themeSystem => _t('حسب النظام', 'System Default');
  String get themeDarkDefault => _t('داكن دائماً (افتراضي)', 'Always Dark (Default)');
  String get mailErrorCantOpen => _t('لا يمكن فتح تطبيق البريد الإلكتروني', 'Cannot open mail application');
  String get mailErrorGeneral => _t('حدث خطأ أثناء محاولة فتح البريد الإلكتروني', 'An error occurred while opening email');
  String get copyrightText => _t('© 2026 رحّال AI. جميع الحقوق محفوظة.', '© 2026 Rahhal AI. All rights reserved.');
  String get appSettingsSection => _t('التطبيق', 'App settings');
  String get legalSection => _t('الدعم القانوني', 'Legal');
  String get helpSupport => _t('المساعدة والدعم', 'Help & Support');
  String get aboutApp => _t('حول التطبيق', 'About App');
  String get notificationReminderTitle => _t('تذكير الرحلات القادمة', 'Upcoming trip reminder');
  String get notificationReminderSub => _t('تلقي إشعارات لتذكيرك بمواعيد رحلاتك المجدولة', 'Receive notifications to remind you of your scheduled trips');
  String get notificationAITitle => _t('اقتراحات ذكية من الذكاء الاصطناعي', 'Smart AI recommendations');
  String get notificationAISub => _t('احصل على نصائح سفر وتوصيات مخصصة لرحلاتك القادمة', 'Get travel tips and personalized recommendations for your trips');

  String get notifTripReminders => _t('تذكير الرحلات القادمة', 'Upcoming Trip Reminders');
  String get notifTripRemindersDesc => _t(
    'تلقي إشعارات لتذكيرك بمواعيد رحلاتك المجدولة',
    'Receive notifications to remind you of your scheduled trips',
  );
  String get notifAiSuggestions => _t('اقتراحات ذكية من الذكاء الاصطناعي', 'Smart AI Suggestions');
  String get notifAiSuggestionsDesc => _t(
    'احصل على نصائح سفر وتوصيات مخصصة',
    'Get personalized travel tips and recommendations',
  );
  String get notifComingSoon => _t(
    'الإشعارات الفعلية قادمة في تحديث قريب',
    'Actual notifications coming in a future update',
  );

  // Errors
  String get errorNetwork => _t('تحقق من اتصالك بالإنترنت', 'Please check your internet connection');
  String get errorAI => _t('تعذّر إنشاء الخطة. حاول مرة أخرى.', 'Failed to generate plan. Please try again.');
  String get errorGeneral => _t('حدث خطأ غير متوقع', 'An unexpected error occurred');
  String get errorRetry => _t('إعادة المحاولة', 'Retry');
  String get errorOffline => _t('أنت غير متصل بالإنترنت', 'You are offline');
  String get errorOfflineAI => _t('يحتاج إنشاء الرحلة إلى اتصال بالإنترنت', 'Trip generation requires an internet connection');
  String get errorInvalidApiKey => _t('مفتاح API غير صالح', 'Invalid API key');
  String get errorRateLimit => _t('تجاوزت حد الطلبات. انتظر قليلاً.', 'Rate limit exceeded. Please wait a bit.');
  String get errorServerFormat => _t('خطأ في الخادم: %s', 'Server error: %s');
  String get errorPageNotFound => _t('الصفحة غير موجودة', 'Page not found');
  String get backToHome => _t('العودة للرئيسية', 'Back to Home');
  String get exceptionNetwork => _t('لا يوجد اتصال بالإنترنت', 'No internet connection');
  String get exceptionAI => _t('خطأ من الذكاء الاصطناعي', 'AI server error');
  String get exceptionDatabase => _t('خطأ في قاعدة البيانات', 'Database error');
  String get exceptionAuth => _t('خطأ في المصادقة', 'Authentication error');
  String get exceptionParse => _t('تعذّر قراءة البيانات', 'Failed to parse data');
  String get failureDatabaseLocal => _t('خطأ في قاعدة البيانات المحلية', 'Local database error');
  String get failureAuthLogin => _t('تعذّر تسجيل الدخول', 'Failed to login');
  String get failureCache => _t('خطأ في التخزين المؤقت', 'Caching error');
  String get failureServer => _t('خطأ في الخادم', 'Server failure');
  String get failureValidation => _t('بيانات غير صالحة', 'Invalid inputs');
  String get failurePermission => _t('تم رفض الإذن المطلوب', 'Required permission denied');

  // Misc
  String get free => _t('مجاني', 'Free');
  String get perPerson => _t('/شخص', '/person');
  String get usd => _t('USD', 'USD');
  String get share => _t('مشاركة', 'Share');
  String get save => _t('حفظ', 'Save');
  String get delete => _t('حذف', 'Delete');
  String get edit => _t('تعديل', 'Edit');
  String get reorder => _t('ترتيب', 'Reorder');
  String get retry => _t('إعادة المحاولة', 'Retry');
  String get refresh => _t('تحديث', 'Refresh');

  // Nearby ("What's around me")
  String get nearbyTitle => _t('ماذا حولي؟', 'What\'s Around Me?');
  String get nearbyAround => _t('حول', 'Around');
  String get nearbyDiscoverSubtitle =>
      _t('اكتشف المعالم والمطاعم قرب موقعك الآن',
         'Discover attractions & restaurants near you now');

  // Offline map
  String get offlineMapDownload => _t('تحميل الخريطة للاستخدام دون إنترنت', 'Download map for offline use');
  String get offlineMapDownloading =>
      _t('جارٍ تحميل خريطة الرحلة للاستخدام دون إنترنت...', 'Downloading the trip map for offline use...');
  String get offlineMapNoStops =>
      _t('لا توجد محطات بإحداثيات لتحميل خريطتها.', 'No stops with coordinates to download a map for.');
  String offlineMapDone(int tiles) =>
      _t('تم حفظ الخريطة للاستخدام دون إنترنت ($tiles جزء).',
         'Map saved for offline use ($tiles tiles).');
  String get nearbyFilterAll => _t('الكل', 'All');
  String get nearbyFilterAttractions => _t('معالم', 'Attractions');
  String get nearbyFilterHistoric => _t('مواقع تاريخية', 'Historic');
  String get nearbyFilterMuseums => _t('متاحف', 'Museums');
  String get nearbyFilterRestaurants => _t('مطاعم', 'Restaurants');
  String get nearbyFilterCafes => _t('مقاهي', 'Cafés');
  String get nearbyFilterParks => _t('حدائق', 'Parks');
  String get nearbyFilterShopping => _t('تسوق', 'Shopping');
  String get nearbyFilterWorship => _t('دور عبادة', 'Worship');
  String get nearbyFilterViewpoints => _t('مطلات', 'Viewpoints');
  String get nearbyFilterOther => _t('أخرى', 'Other');
  String get nearbyNoLocationTitle => _t('تعذّر تحديد موقعك', 'Couldn\'t get your location');
  String get nearbyNoLocationSubtitle =>
      _t('فعّل إذن الموقع لاكتشاف الأماكن القريبة منك.',
         'Enable location permission to discover places near you.');
  String get nearbyErrorTitle => _t('حدث خطأ', 'Something went wrong');
  String get nearbyErrorSubtitle =>
      _t('تعذّر جلب الأماكن القريبة. تحقّق من اتصالك وحاول مجددًا.',
         'Couldn\'t load nearby places. Check your connection and try again.');
  String get nearbyEmptyTitle => _t('لا توجد أماكن قريبة', 'No places nearby');
  String get nearbyEmptySubtitle =>
      _t('لم نعثر على أماكن مميزة في نطاق قريب منك الآن.',
         'We couldn\'t find notable places within range right now.');
  String get itineraryStopsTitle => _t('محطات اليوم', 'Today\'s Stops');
  String get markVisited => _t('وضع علامة زُرت', 'Mark as visited');
  String get markNotVisited => _t('إلغاء علامة زُرت', 'Mark as not visited');
  String dayProgressLabel(int visited, int total) =>
      _t('زُرت $visited من $total', 'Visited $visited of $total');
  String get dayProgressComplete => _t('أنجزت كل محطات اليوم! 🎉', 'All stops done! 🎉');
  String travelWalk(int minutes) =>
      _t('~$minutes دقيقة سيرًا', '~$minutes min walk');
  String travelDrive(int minutes) =>
      _t('~$minutes دقيقة بالسيارة', '~$minutes min drive');
  String get reorderStopsTitle => _t('إعادة ترتيب المحطات', 'Reorder Stops');
  String get reorderStopsHint =>
      _t('اسحب المحطات لتغيير ترتيب زيارتها خلال اليوم.',
         'Drag the stops to change the order you visit them.');
  String get back => _t('رجوع', 'Back');
  String get confirm => _t('تأكيد', 'Confirm');
  String get cancel => _t('إلغاء', 'Cancel');
  String get total => _t('الإجمالي', 'Total');

  // Popular cities
  List<String> get popularCities => _t(
    ['إسطنبول', 'دبي', 'باريس', 'القاهرة', 'لندن', 'طوكيو', 'روما', 'مراكش'],
    ['Istanbul', 'Dubai', 'Paris', 'Cairo', 'London', 'Tokyo', 'Rome', 'Marrakech']
  );

  String get iraqiGovernoratesLabel => _t('محافظات العراق', 'Iraqi Governorates');

  // All 19 Iraqi governorates (by their common capital/name, which the
  // destination resolver maps to real places). Tapping one plans a trip for it.
  List<String> get iraqiGovernorates => _t(
    [
      'بغداد', 'البصرة', 'الموصل', 'أربيل', 'كركوك', 'النجف', 'كربلاء',
      'الحلة', 'الرمادي', 'الناصرية', 'العمارة', 'الديوانية', 'الكوت',
      'السماوة', 'بعقوبة', 'تكريت', 'دهوك', 'السليمانية', 'حلبجة',
    ],
    [
      'Baghdad', 'Basra', 'Mosul', 'Erbil', 'Kirkuk', 'Najaf', 'Karbala',
      'Hillah', 'Ramadi', 'Nasiriyah', 'Amarah', 'Diwaniyah', 'Kut',
      'Samawah', 'Baqubah', 'Tikrit', 'Duhok', 'Sulaymaniyah', 'Halabja',
    ],
  );

  // Stop types & category names
  String categoryName(String category) {
    return _t(
      switch (category) {
        'museum' => 'متحف',
        'restaurant' => 'مطعم',
        'park' => 'حديقة',
        'shopping' => 'تسوق',
        'landmark' => 'معلم',
        'beach' => 'شاطئ',
        'mosque' => 'مسجد',
        'palace' => 'قصر',
        'market' => 'سوق',
        'viewpoint' => 'منظر',
        _ => 'أخرى',
      },
      switch (category) {
        'museum' => 'Museum',
        'restaurant' => 'Restaurant',
        'park' => 'Park',
        'shopping' => 'Shopping',
        'landmark' => 'Landmark',
        'beach' => 'Beach',
        'mosque' => 'Mosque',
        'palace' => 'Palace',
        'market' => 'Market',
        'viewpoint' => 'Viewpoint',
        _ => 'Other',
      }
    );
  }

  // Month names helper
  String monthName(int index) {
    if (index < 1 || index > 12) return '';
    final arMonths = ['', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    final enMonths = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return _t(arMonths[index], enMonths[index]);
  }

  // Duration Formatter Helper
  String durationFormat(int hours, int minutes) {
    if (hours == 0) return _t('$minutes دقيقة', '$minutes mins');
    
    final String arHours = hours == 1
        ? 'ساعة'
        : hours == 2
            ? 'ساعتان'
            : hours <= 10
                ? '$hours ساعات'
                : '$hours ساعة';
                
    final String enHours = hours == 1 ? '1 hour' : '$hours hours';
    final hourText = _t(arHours, enHours);

    if (minutes == 0) {
      return hourText;
    }
    
    return _t('$hourText و$minutes دقيقة', '$hourText $minutes mins');
  }

  // Budget Tier Name Helper
  String budgetTierName(String tier) {
    return _t(
      switch (tier) {
        'economy' => 'اقتصادي',
        'mid' => 'متوسط',
        'luxury' => 'فاخر',
        _ => tier,
      },
      switch (tier) {
        'economy' => 'Economy',
        'mid' => 'Mid-range',
        'luxury' => 'Luxury',
        _ => tier,
      }
    );
  }

  // Trip Status Name Helper
  String statusName(String status) {
    return _t(
      switch (status) {
        'planned' => 'مخططة',
        'active' => 'جارية',
        'completed' => 'مكتملة',
        _ => status,
      },
      switch (status) {
        'planned' => 'Planned',
        'active' => 'Active',
        'completed' => 'Completed',
        _ => status,
      }
    );
  }

  // Additional dynamic getters & compatibility helpers
  String get costFree => free;
  String get planDayLabelPrefix => dayPrefix;
  String get periodMorning => morning;
  String get periodAfternoon => afternoon;
  String get periodEvening => evening;
  String get statusCompleted => statusDone;
  String get budgetEstimatedUsd => _t('USD • تقديري', 'USD • Estimated');

  String formatDuration(int minutes) {
    final hrs = minutes ~/ 60;
    final mins = minutes % 60;
    return durationFormat(hrs, mins);
  }

  String budgetItemCategory(String key) {
    return _t(
      switch (key) {
        'accommodation' => 'السكن',
        'food' => 'الطعام والمطاعم',
        'transport' => 'المواصلات',
        'activities' => 'الأنشطة والزيارات',
        'shopping' => 'التسوق',
        _ => key,
      },
      switch (key) {
        'accommodation' => 'Accommodation',
        'food' => 'Food & Dining',
        'transport' => 'Transportation',
        'activities' => 'Activities & Visits',
        'shopping' => 'Shopping',
        _ => key,
      },
    );
  }

  String get errorTripNotFound => _t('الرحلة غير موجودة', 'Trip not found');
  String get snackTripNotFound => _t('الرحلة غير موجودة', 'Trip not found');

  // Error translating helper
  String authErrorMessage(String errorCode) {
    return switch (errorCode) {
      'auth/user-not-found' || 'auth/invalid-credential' =>
        _t('البريد الإلكتروني أو كلمة المرور غير صحيحة.', 'Incorrect email or password.'),
      'auth/wrong-password' =>
        _t('كلمة المرور غير صحيحة.', 'Incorrect password.'),
      'auth/invalid-email' =>
        _t('البريد الإلكتروني غير صالح.', 'Invalid email address.'),
      'auth/user-disabled' =>
        _t('تم تعطيل هذا الحساب.', 'This account has been disabled.'),
      'auth/too-many-requests' =>
        _t('محاولات كثيرة. يرجى الانتظار قليلاً.', 'Too many failed attempts. Please wait.'),
      'auth/email-already-in-use' =>
        _t('البريد الإلكتروني مستخدم بالفعل.', 'Email already in use.'),
      'auth/weak-password' =>
        _t('كلمة المرور ضعيفة. 6 أحرف على الأقل.', 'Password too weak. Min 6 characters.'),
      'auth/failed-retrieve-user-data' =>
        _t('تعذر الحصول على بيانات المستخدم بعد تسجيل الدخول.', 'Failed to retrieve user data after login.'),
      'auth/failed-create-account' =>
        _t('تعذر إنشاء حساب مستخدم.', 'Failed to create user account.'),
      'auth/guest-sign-in-failed' =>
        _t('حدث خطأ أثناء تسجيل الدخول كزائر.', 'An error occurred while signing in as guest.'),
      'auth/network-request-failed' =>
        _t('لا يوجد اتصال بالإنترنت. تحقق من الشبكة.', 'No internet connection. Check your network.'),
      'auth/operation-not-allowed' =>
        _t('طريقة الدخول هذه غير مفعّلة. تواصل مع الدعم.', 'This sign-in method is not enabled.'),
      'auth/app-not-authorized' =>
        _t('التطبيق غير مصرح له. تحقق من إعدادات Firebase.', 'App not authorized. Check Firebase settings.'),
      _ => _t(
          'خطأ: $errorCode', // ← يعرض الكود الكامل للمطور
          'Error: $errorCode',
        ),
    };
  }

  String get authConfirmPassword => _t('تأكيد كلمة المرور', 'Confirm Password');
  String get authPasswordMismatch => _t('كلمتا المرور غير متطابقتين', 'Passwords do not match');

  String get restaurantNotFound => _t('المطعم غير موجود', 'Restaurant not found');
  String get stopNotFound => _t('المحطة غير موجودة', 'Stop not found');
  String get tripNotFound => _t('الرحلة غير موجودة', 'Trip not found');
  String get noDaysFound => _t('لا توجد أيام في هذه الرحلة', 'No days found in this trip');

  // Expenses
  String get expenseAdd => _t('إضافة مصروف جديد', 'Add New Expense');
  String get expenseAmount => _t('المبلغ', 'Amount');
  String get expenseDescription => _t('الوصف (اختياري)', 'Description (Optional)');
  String get expenseDay => _t('اليوم', 'Day');
  String get expenseCategory => _t('الفئة', 'Category');
  String get expenseActual => _t('المصروف الفعلي', 'Actual Expense');
  String get expenseComparison => _t('مقارنة الميزانية', 'Budget Comparison');
  String get expenseGeneral => _t('عام / غير محدد', 'General / Unspecified');
  String get expenseNoExpenses => _t('لا توجد مصاريف مضافة بعد.', 'No expenses added yet.');
  String get expenseCategoryTitle => _t('الفئة والمبلغ', 'Category & Amount');
  String get expenseAmountHint => _t('أدخل المبلغ...', 'Enter amount...');
  String get expenseDescriptionHint => _t('مثال: تذاكر المترو، غداء...', 'e.g. Metro tickets, Lunch...');
  String get expenseSelectCategory => _t('اختر الفئة', 'Select Category');
  String get expenseSelectDay => _t('اختر اليوم', 'Select Day');
  String get expenseDeleteConfirm => _t('هل تريد حذف هذا المصروف؟', 'Do you want to delete this expense?');
  String get expenseActualTotal => _t('إجمالي المصاريف الفعلية', 'Total Actual Expenses');
  String get expenseEstimatedTotal => _t('إجمالي الميزانية المقدرة', 'Total Estimated Budget');
  String get expenseStatusSpentOf => _t('صُرف من الميزانية', 'spent of budget');
  String get expenseStatusOver => _t('تجاوزت الميزانية بـ', 'over budget by');
  String get expenseAllDays => _t('الكل', 'All');

  // Favorites
  String get tabFavorites => _t('المفضلة', 'Favorites');
  String get favoritesEmpty => _t('قائمتك المفضلة فارغة حالياً.', 'Your favorites list is empty.');
  String get favoritesEmptySubtitle => _t('اضغط على رمز القلب في أي مكان أو مطعم لحفظه هنا.', 'Tap the heart icon on any stop or restaurant to save it here.');
  String get favoritesStops => _t('الأماكن المميزة', 'Favorite Stops');
  String get favoritesRestaurants => _t('المطاعم المميزة', 'Favorite Restaurants');

  String get favoriteAdded => _t('تمت الإضافة إلى المفضلة', 'Added to favorites');
  String get favoriteRemoved => _t('تمت الإزالة من المفضلة', 'Removed from favorites');
  String get addToFavorites => _t('إضافة إلى المفضلة', 'Add to favorites');
  String get removeFromFavorites => _t('إزالة من المفضلة', 'Remove from favorites');
  String get myTripsTab => _t('رحلاتي', 'My Trips');

  // Trip generation errors
  String get genErrorServerAsleep => _t(
      '⏳ السيرفر كان في وضع السكون.\nيرجى الانتظار 30-60 ثانية ثم إعادة المحاولة.',
      '⏳ The server was asleep.\nPlease wait 30-60 seconds and try again.');
  String get genErrorApiKey => _t(
      '🔑 مفتاح API غير صالح أو غير موجود.\nتحقق من ملف .env في السيرفر:\nGEMINI_API_KEY أو ANTHROPIC_API_KEY',
      '🔑 The API key is invalid or missing.\nCheck the server .env file:\nGEMINI_API_KEY or ANTHROPIC_API_KEY');
  String get genErrorRateLimit => _t(
      '⏱ تجاوزت الحد المسموح من الطلبات.\nانتظر دقيقة ثم أعد المحاولة.',
      '⏱ You have exceeded the request limit.\nWait a minute and try again.');
  String get genErrorServer => _t(
      '🛠 خطأ في الخادم.\nيرجى المحاولة مجدداً بعد قليل.',
      '🛠 Server error.\nPlease try again shortly.');
  String get genErrorGeneric => _t(
      '❌ حدث خطأ أثناء توليد الرحلة.\nتحقق من اتصالك بالإنترنت وأعد المحاولة.',
      '❌ Something went wrong while generating the trip.\nCheck your connection and try again.');

  String get genFirstRunHint => _t('قد يستغرق الأمر حتى دقيقة عند أول استخدام',
      'This can take up to a minute on first use');
  String get genServerSlow => _t('الخادم يستغرق وقتاً أطول من المعتاد...',
      'The server is taking longer than usual...');
  String get genRetryNow => _t('إعادة المحاولة الآن', 'Retry now');
  String get genCancelAndBack => _t('إلغاء والعودة', 'Cancel and go back');

  // Generic / shared
  String get errorGeneric => _t('حدث خطأ ما', 'Something went wrong');
  String get appTitle => _t('رحّال AI', 'Rahhal AI');
  String get offlineMessage => _t('لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة.',
      'No internet connection. Please check your network.');
  String get cloudUnavailable => _t(
      'تعذّر الاتصال بالخدمات السحابية. التطبيق يعمل في وضع محلي.',
      'Could not reach cloud services. The app is running in local mode.');
  String get mockTripWarning => _t(
      '⚠️ هذه خطة تجريبية (بيانات وهمية) بسبب عدم الاتصال بالسيرفر. يرجى التحقق من تشغيل خادم backend.',
      '⚠️ This is a sample plan (mock data) because the server is unreachable. Check that the backend is running.');

  // Booking / stop detail
  String get bookingNoLink =>
      _t('لا يوجد رابط حجز متاح لهذا المكان', 'No booking link is available for this place');
  String get bookingInvalidLink => _t('رابط الحجز غير صالح', 'The booking link is invalid');
  String get copyAction => _t('نسخ', 'Copy');
  String get linkOpenError => _t('خطأ في فتح الرابط', 'Error opening the link');
  String bookingOpenFailed(String url) => _t(
      'تعذّر فتح رابط الحجز. انسخ الرابط يدوياً: $url',
      'Could not open the booking link. Copy it manually: $url');

  // Map
  String get locationPermissionHint => _t('تعذّر الوصول للموقع. فعّل الإذن من الإعدادات.',
      'Could not access your location. Enable the permission in Settings.');
  String stopsCount(int count) => _t('$count محطة', '$count stops');
  String get fullRouteTitle => _t('مسار الرحلة الكامل', 'Full trip route');
  String locationDetected(String location) =>
      _t('📍 تم تحديد موقعك: $location', '📍 Location detected: $location');

  // Weather
  String get weatherApproximate =>
      _t('طقس تقريبي (بيانات محاكاة)', 'Approximate weather (simulated data)');
  String get weatherSimulatedBadge => _t('محاكاة', 'Simulated');
  String get weatherForecast => _t('توقعات الطقس', 'Weather Forecast');

  // Chat
  String get chatIntroHint => _t(
      'يمكنك سؤالي عن أي شيء: أفضل المطاعم، المواصلات، التكاليف، الطقس، ساعات الزيارة، أماكن التسوق، الثقافة المحلية، أو أي تساؤل آخر عن رحلتك! 💬',
      'Ask me anything: best restaurants, transport, costs, weather, opening hours, shopping, local culture, or any other question about your trip! 💬');
  String get chatSuggestedQuestions => _t('أسئلة مقترحة', 'Suggested Questions');

  // Notifications
  String notifTripSoonTitle(String destination) =>
      _t('✈️ رحلتك إلى $destination تقترب!', '✈️ Your trip to $destination is coming up!');
  String get notifTripSoonBody =>
      _t('بعد 3 أيام فقط — تأكد من استعداداتك ووثائقك.', 'Only 3 days to go — check your prep and documents.');
  String get notifDocExpiryTitle =>
      _t('⚠️ وثيقة سفر تقترب من الانتهاء', '⚠️ A travel document is expiring soon');
  String notifDocExpiryBody(String docTitle) =>
      _t('"$docTitle" ستنتهي صلاحيتها خلال شهر. جدّدها قبل سفرك.',
         '"$docTitle" expires within a month. Renew it before you travel.');

  // Auth
  String passwordResetSent(String email) => _t(
      'تم إرسال رابط إعادة تعيين كلمة المرور إلى $email',
      'A password reset link has been sent to $email');

  // Travel Documents
  String get documentsTitle => _t('مستندات السفر', 'Travel Documents');
  String get documentsEmptyTitle => _t('لا توجد مستندات بعد', 'No documents yet');
  String get documentsEmptySubtitle => _t(
      'احفظ جوازات سفرك، التأشيرات، وتذاكر الطيران للوصول السريع إليها أثناء السفر.',
      'Save your passports, visas and flight tickets for quick access while travelling.');
  String get documentAddNew => _t('إضافة مستند جديد', 'Add new document');
  String get documentAddTitle => _t('إضافة مستند سفر جديد', 'Add a new travel document');
  String get documentSave => _t('حفظ المستند', 'Save document');
  String get documentDeleteTitle => _t('حذف المستند', 'Delete document');
  String documentDeleteConfirm(String title) => _t(
      'هل أنت متأكد من رغبتك في حذف "$title"؟',
      'Are you sure you want to delete "$title"?');
  String get documentTitleLabel =>
      _t('عنوان المستند (مثال: جواز سفر أحمد)', 'Document title (e.g. Ahmed\'s passport)');
  String get documentTitleRequired =>
      _t('الرجاء إدخال عنوان للمستند', 'Please enter a document title');
  String get documentTypeLabel => _t('نوع المستند', 'Document type');
  String get documentNotesLabel =>
      _t('ملاحظات إضافية (اختياري)', 'Additional notes (optional)');
  String get documentAttachmentLabel =>
      _t('صورة المستند / المرفق', 'Document photo / attachment');
  String get documentExpiryOptional =>
      _t('تاريخ الانتهاء (اختياري)', 'Expiry date (optional)');
  String documentExpiryOn(String date) =>
      _t('تاريخ الانتهاء: $date', 'Expires: $date');
  String get documentExpired => _t('منتهي', 'Expired');
  String get documentPickGallery => _t('المعرض', 'Gallery');
  String get documentPickCamera => _t('الكاميرا', 'Camera');
  String documentTypeLabelFor(String type) => _t(
        switch (type) {
          'passport' => 'جواز سفر / هوية',
          'visa' => 'تأشيرة دخول',
          'ticket' => 'تذكرة سفر',
          'booking' => 'حجز إقامة / سيارة',
          _ => 'مستند آخر',
        },
        switch (type) {
          'passport' => 'Passport / ID',
          'visa' => 'Entry visa',
          'ticket' => 'Travel ticket',
          'booking' => 'Stay / car booking',
          _ => 'Other document',
        },
      );
}
