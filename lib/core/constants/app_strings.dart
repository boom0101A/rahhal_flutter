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
  String get chatQuickReply1 => _t('ما أفضل وقت للزيارة؟', 'What\'s the best time to visit?');
  String get chatQuickReply2 => _t('اقترح أنشطة إضافية', 'Suggest additional activities');
  String get chatQuickReply3 => _t('كيف أوفر في الميزانية؟', 'How do I save budget?');
  String get chatQuickReply4 => _t('أفضل وسائل النقل', 'What are the best transport options?');
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
  String get back => _t('رجوع', 'Back');
  String get confirm => _t('تأكيد', 'Confirm');
  String get cancel => _t('إلغاء', 'Cancel');
  String get total => _t('الإجمالي', 'Total');

  // Popular cities
  List<String> get popularCities => _t(
    ['إسطنبول', 'دبي', 'باريس', 'القاهرة', 'لندن', 'طوكيو', 'روما', 'مراكش'],
    ['Istanbul', 'Dubai', 'Paris', 'Cairo', 'London', 'Tokyo', 'Rome', 'Marrakech']
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

  // Packing List
  String get tabPackingList => _t('حقيبة السفر', 'Packing List');
  String get packingProgress => _t('مكتمل', 'Packed');
  String get packingEmptyState => _t('حقيبة السفر فارغة. دع الذكاء الاصطناعي يقترح عليك ما تحتاجه!', 'Your bag is empty. Let AI suggest what you need!');
  String get packingGenerateAI => _t('توليد القائمة بالذكاء الاصطناعي ✨', 'Generate List with AI ✨');
  String get packingAddItem => _t('إضافة غرض جديد', 'Add Item');
  String get packingItemNameHint => _t('اسم الغرض (مثال: شاحن، قميص...)', 'Item name (e.g. Charger, Shirt...)');
  String get packingCategoryClothing => _t('الملابس 👕', 'Clothing 👕');
  String get packingCategoryToiletries => _t('أدوات العناية 🪥', 'Toiletries 🪥');
  String get packingCategoryElectronics => _t('الإلكترونيات 🔌', 'Electronics 🔌');
  String get packingCategoryDocuments => _t('وثائق السفر 📄', 'Documents 📄');
  String get packingCategoryOther => _t('أخرى 📦', 'Other 📦');

  String packingCategoryLabel(String category) {
    return _t(
      switch (category.toLowerCase()) {
        'clothing' => 'الملابس 👕',
        'toiletries' => 'أدوات العناية 🪥',
        'electronics' => 'الإلكترونيات 🔌',
        'documents' => 'وثائق السفر 📄',
        _ => 'أخرى 📦',
      },
      switch (category.toLowerCase()) {
        'clothing' => 'Clothing 👕',
        'toiletries' => 'Toiletries 🪥',
        'electronics' => 'Electronics 🔌',
        'documents' => 'Documents 📄',
        _ => 'Other 📦',
      }
    );
  }

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
}
