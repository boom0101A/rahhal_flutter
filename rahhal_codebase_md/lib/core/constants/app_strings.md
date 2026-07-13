# ملف كود Dart: lib\core\constants\app_strings.dart

```dart
class AppStrings {
  AppStrings._();

  static String _lang = 'ar';

  static void setLanguage(String lang) {
    _lang = lang;
  }

  static String get languageCode => _lang;

  static T _t<T>(T ar, T en) {
    return _lang == 'en' ? en : ar;
  }

  // App
  static String get appName => _t('رحّال AI', 'Rahhal AI');
  static String get appTagline => _t('رحلتك، مُخطَّطة بالذكاء الاصطناعي', 'Your trip, planned by AI');

  // Splash
  static String get splashSubtitle => _t('مساعدك الذكي للسفر', 'Your smart travel assistant');
  static String get splashStart => _t('ابدأ رحلتك', 'Start your trip');
  static String get splashTagline => _t('رحلاتك، مخططة بذكاء', 'Your trips, planned smartly');

  // Onboarding
  static String get onboardingSkip => _t('تخطى', 'Skip');
  static String get onboardingNext => _t('التالي', 'Next');
  static String get onboardingGetStarted => _t('ابدأ الآن', 'Get Started');
  static String get onboardingTitle1 => _t('خطط رحلتك بالذكاء الاصطناعي', 'Plan with AI');
  static String get onboardingDesc1 => _t('أخبر رحّال AI عن وجهتك وميزانيتك، وسيُنشئ خطة رحلة متكاملة خصيصاً لك', 'Tell Rahhal AI your destination and budget, and it will generate a personalized trip plan for you');
  static String get onboardingTitle2 => _t('جداول يومية تفصيلية', 'Detailed Daily Itineraries');
  static String get onboardingDesc2 => _t('كل يوم من رحلتك مُخطَّطة بعناية مع أوقات الزيارة ونصائح الخبراء والتكاليف التقديرية', 'Every day is meticulously planned with visiting hours, expert tips, and estimated costs');
  static String get onboardingTitle3 => _t('مساعد سفر دائم معك', 'Travel Assistant 24/7');
  static String get onboardingDesc3 => _t('تحدث مع مساعد رحّال في أي وقت للحصول على توصيات واقتراحات وإجابات فورية', 'Chat with Rahhal assistant anytime for recommendations, suggestions, and instant answers');

  // Auth
  static String get authLogin => _t('تسجيل الدخول', 'Login');
  static String get authRegister => _t('إنشاء حساب', 'Register');
  static String get authEmail => _t('البريد الإلكتروني', 'Email Address');
  static String get authPassword => _t('كلمة المرور', 'Password');
  static String get authName => _t('الاسم الكامل', 'Full Name');
  static String get authGoogleSignIn => _t('الدخول بـ Google', 'Sign in with Google');
  static String get authGuestMode => _t('تصفح كضيف', 'Browse as Guest');
  static String get authForgotPassword => _t('نسيت كلمة المرور؟', 'Forgot Password?');
  static String get authHaveAccount => _t('لديك حساب بالفعل؟', 'Already have an account?');
  static String get authNoAccount => _t('ليس لديك حساب؟', 'Don\'t have an account?');
  static String get authWelcomeBack => _t('أهلاً بعودتك! سجّل دخولك للمتابعة', 'Welcome back! Login to continue');
  static String get authCreateAccount => _t('أنشئ حسابك وابدأ رحلتك الأولى', 'Create an account and start your first trip');
  static String get authEnterName => _t('أدخل اسمك', 'Enter your name');
  static String get authInvalidEmail => _t('بريد إلكتروني غير صالح', 'Invalid email address');
  static String get authWeakPassword => _t('كلمة مرور يجب أن تكون 6 أحرف على الأقل', 'Password must be at least 6 characters');
  static String get authOr => _t('أو', 'OR');

  // Trip Input / Wizard
  static String get planTitle => _t('خطط رحلتي', 'Plan My Trip');
  static String get planAIGreeting => _t('مرحباً! أخبرني عن رحلتك القادمة 🌍', 'Welcome! Tell me about your next trip 🌍');
  static String get planDestination => _t('إلى أين تريد السفر؟', 'Where do you want to travel?');
  static String get planDestinationHint => _t('اكتب اسم المدينة...', 'Type city name...');
  static String get planDuration => _t('مدة الرحلة', 'Trip Duration');
  static String get planDurationDays => _t('أيام', 'days');
  static String get planBudget => _t('الميزانية', 'Budget');
  static String get planBudgetEconomy => _t('اقتصادي', 'Economy');
  static String get planBudgetMid => _t('متوسط', 'Mid-range');
  static String get planBudgetLuxury => _t('فاخر', 'Luxury');
  static String get planBudgetEconomySub => _t('فنادق اقتصادية وطعام شعبي', 'Economy hotels & local food');
  static String get planBudgetMidSub => _t('فنادق 3-4 نجوم ومطاعم متنوعة', '3-4 star hotels & mixed dining');
  static String get planBudgetLuxurySub => _t('فنادق 5 نجوم وتجارب راقية', '5 star hotels & premium experience');
  static String get planTravelStyle => _t('نمط السفر', 'Travel Style');
  static String get planTravelers => _t('عدد المسافرين', 'Number of Travelers');
  static String get planAdults => _t('بالغون', 'Adults');
  static String get planChildren => _t('أطفال', 'Children');
  static String get planGenerateButton => _t('خطط رحلتي بالذكاء الاصطناعي', 'Plan My Trip with AI');
  static String get defaultDestination => _t('إسطنبول', 'Istanbul');
  static String get startDateTitle => _t('تاريخ بدء الرحلة', 'Trip Start Date');
  static String get startDateHint => _t('اختر تاريخ البدء (اختياري)', 'Select start date (optional)');

  // Travel Styles
  static String get styleCulture => _t('ثقافة', 'Culture');
  static String get styleAdventure => _t('مغامرة', 'Adventure');
  static String get styleFood => _t('طعام', 'Food');
  static String get styleShopping => _t('تسوق', 'Shopping');
  static String get styleNature => _t('طبيعة', 'Nature');
  static String get styleRelax => _t('استرخاء', 'Relax');

  // Generating Screen
  static String get generatingTitle => _t('يُحلّل رحّال AI طلبك', 'Rahhal AI is analyzing your request');
  static String get generatingSubtitle => _t('جاري إنشاء خطة رحلتك المثالية...', 'Generating your perfect trip plan...');
  static String get generatingStep1 => _t('البحث عن أفضل الوجهات', 'Searching for the best destinations');
  static String get generatingStep2 => _t('تحليل الميزانية والتفضيلات', 'Analyzing budget and preferences');
  static String get generatingStep3 => _t('إنشاء الجدول اليومي', 'Creating daily itinerary');
  static String get generatingStep4 => _t('اختيار المطاعم والأنشطة', 'Selecting restaurants and activities');
  static String get generatingStep5 => _t('إضافة نصائح الذكاء الاصطناعي', 'Adding smart AI tips');
  static String get errorTitle => _t('خطأ', 'Error');

  // Dashboard Tabs
  static String get tabSchedule => _t('الجدول', 'Schedule');
  static String get tabMap => _t('الخريطة', 'Map');
  static String get tabRestaurants => _t('المطاعم', 'Restaurants');
  static String get tabCost => _t('التكاليف', 'Costs');

  // Trip Stats
  static String get statsDays => _t('أيام', 'Days');
  static String get statsPlaces => _t('مكان', 'Places');
  static String get statsRestaurants => _t('مطعم', 'Restaurants');
  static String get statsPerDay => _t('/يوم', '/day');
  static String get statsTravelers => _t('مسافر', 'traveler');

  // Itinerary
  static String get itineraryTitle => _t('الجدول اليومي', 'Daily Itinerary');
  static String get dayPrefix => _t('اليوم', 'Day');
  static String get morning => _t('صباحاً', 'Morning');
  static String get afternoon => _t('ظهراً', 'Afternoon');
  static String get evening => _t('مساءً', 'Evening');
  static String get duration => _t('المدة', 'Duration');
  static String get cost => _t('التكلفة', 'Cost');
  static String get aiTip => _t('نصيحة رحّال', 'Rahhal Tip');
  static String get bookingRequired => _t('يحتاج حجز مسبق', 'Booking Required');
  static String get bookNow => _t('احجز الآن', 'Book Now');
  static String get suggestedDuration => _t('المدة المقترحة', 'Suggested Duration');
  static String get estimatedCost => _t('التكلفة التقديرية', 'Estimated Cost');
  static String get addressLabel => _t('العنوان', 'Address');
  static String get aiSmartTip => _t('نصيحة رحّال الذكية ✨', 'Smart Rahhal Tip ✨');
  static String get geoPosition => _t('الموقع الجغرافي', 'Geographic Location');
  static String get latLngLabel => _t('خط العرض: %s • خط الطول: %s', 'Latitude: %s • Longitude: %s');
  static String get bookTicketsNow => _t('حجز التذاكر الآن', 'Book Tickets Now');
  static String get noStopsForDay => _t('لا توجد محطات لهذا اليوم', 'No stops planned for this day');
  static String get infoChipBook => _t('حجز', 'Book');

  // Map
  static String get mapTitle => _t('خريطة الرحلة', 'Trip Map');
  static String get mapFilterAll => _t('الكل', 'All');
  static String get mapStopsCount => _t('محطة', 'Stops');
  static String get fullItineraryMap => _t('مسار الرحلة الكامل', 'Full Itinerary Map');

  // Restaurants
  static String get restaurantsTitle => _t('المطاعم الموصى بها', 'Recommended Restaurants');
  static String get restaurantFilterAll => _t('الكل', 'All');
  static String get restaurantHalal => _t('حلال', 'Halal');
  static String get restaurantOpenNow => _t('مفتوح الآن', 'Open Now');
  static String get restaurantClosed => _t('مغلق', 'Closed');
  static String get restaurantRecommended => _t('موصى به', 'Recommended');
  static String get restaurantRating => _t('التقييم', 'Rating');
  static String get restaurantPrice => _t('السعر/شخص', 'Price/Person');
  static String get restaurantFilterHalal => _t('✓ حلال', '✓ Halal');
  static String get restaurantFilterRecommended => _t('✨ موصى به', '✨ Recommended');
  static String get noRestaurantsForFilter => _t('لا توجد مطاعم بهذا الفلتر', 'No restaurants found with this filter');
  static String get seafoodStyle => _t('بحري', 'Seafood');
  static String get traditionalStyle => _t('تقليدي', 'Traditional');
  static String get modernStyle => _t('عصري', 'Modern');

  // Budget / Cost
  static String get budgetTitle => _t('تفاصيل التكاليف', 'Cost Details');
  static String get budgetTotal => _t('إجمالي التكلفة التقديرية', 'Total Estimated Cost');
  static String get budgetAccommodation => _t('السكن', 'Accommodation');
  static String get budgetFood => _t('الطعام', 'Food');
  static String get budgetTransport => _t('المواصلات', 'Transport');
  static String get budgetActivities => _t('الزيارات', 'Activities');
  static String get budgetShopping => _t('التسوق', 'Shopping');
  static String get budgetOther => _t('أخرى', 'Other');
  static String get budgetPerDay => _t('يومياً', 'Daily');
  static String get budgetEstimated => _t('تقديري', 'Estimated');
  static String get budgetDistribution => _t('توزيع الميزانية', 'Budget Distribution');
  static String get budgetDetails => _t('تفاصيل البنود', 'Item Details');

  // Saved Trips
  static String get savedTitle => _t('رحلاتي', 'My Trips');
  static String get savedEmpty => _t('لا توجد رحلات محفوظة', 'No saved trips');
  static String get savedEmptySubtitle => _t('ابدأ رحلة جديدة مع رحّال AI', 'Start a new trip with Rahhal AI');
  static String get savedNewTrip => _t('رحلة جديدة', 'New Trip');
  static String get statusPlanned => _t('مخططة', 'Planned');
  static String get statusActive => _t('جارية', 'Active');
  static String get statusDone => _t('مكتملة', 'Completed');
  static String get greeting => _t('مرحباً! 👋', 'Welcome! 👋');
  static String get deleteTripTitle => _t('حذف الرحلة', 'Delete Trip');
  static String get startFirstTrip => _t('ابدأ رحلتك الأولى', 'Start your first trip');

  static String deleteTripConfirm(String destination) {
    return _t('هل تريد حذف رحلة $destination؟', 'Do you want to delete the trip to $destination?');
  }

  // AI Chat
  static String get chatTitle => _t('مساعد رحّال', 'Rahhal Assistant');
  static String get chatHint => _t('اسأل عن رحلتك...', 'Ask about your trip...');
  static String get chatTyping => _t('رحّال يكتب...', 'Rahhal is typing...');
  static String get chatQuickReply1 => _t('ما أفضل وقت للزيارة؟', 'What\'s the best time to visit?');
  static String get chatQuickReply2 => _t('اقترح أنشطة إضافية', 'Suggest additional activities');
  static String get chatQuickReply3 => _t('كيف أوفر في الميزانية؟', 'How do I save budget?');
  static String get chatQuickReply4 => _t('أفضل وسائل النقل', 'What are the best transport options?');
  static String get chatOnlineStatus => _t('متصل الآن', 'Online');
  static String get chatIntroTitle => _t('أهلاً! أنا مساعد رحّال', 'Hi! I\'m Rahhal Assistant');
  static String get chatIntroSubtitle => _t('اسألني عن أي شيء يتعلق برحلتك وسأساعدك فوراً', 'Ask me anything about your trip and I\'ll help you');
  static String get chatSuggestions => _t('اقتراحات:', 'Suggestions:');

  // Settings
  static String get settingsTitle => _t('الإعدادات', 'Settings');
  static String get settingsProfile => _t('الملف الشخصي', 'Profile');
  static String get settingsLanguage => _t('اللغة', 'Language');
  static String get settingsCurrency => _t('العملة', 'Currency');
  static String get settingsDarkMode => _t('الوضع الليلي', 'Dark Mode');
  static String get settingsNotifications => _t('الإشعارات', 'Notifications');
  static String get settingsLogout => _t('تسجيل الخروج', 'Logout');
  static String get settingsVersion => _t('الإصدار', 'Version');
  static String get selectLanguageTitle => _t('اختر اللغة / Select Language', 'Select Language');
  static String get languageArabic => _t('العربية', 'Arabic');
  static String get languageEnglish => _t('الإنجليزية', 'English');
  static String get languageArabicDefault => _t('العربية (افتراضي)', 'Arabic (Default)');
  static String get themeTitle => _t('المظهر', 'Theme');
  static String get themeDark => _t('داكن دائماً', 'Always Dark');
  static String get themeLight => _t('فاتح دائماً', 'Always Light');
  static String get themeSystem => _t('حسب النظام', 'System Default');
  static String get themeDarkDefault => _t('داكن دائماً (افتراضي)', 'Always Dark (Default)');
  static String get mailErrorCantOpen => _t('لا يمكن فتح تطبيق البريد الإلكتروني', 'Cannot open mail application');
  static String get mailErrorGeneral => _t('حدث خطأ أثناء محاولة فتح البريد الإلكتروني', 'An error occurred while opening email');
  static String get copyrightText => _t('© 2026 رحّال AI. جميع الحقوق محفوظة.', '© 2026 Rahhal AI. All rights reserved.');
  static String get appSettingsSection => _t('التطبيق', 'App settings');
  static String get legalSection => _t('الدعم القانوني', 'Legal');
  static String get helpSupport => _t('المساعدة والدعم', 'Help & Support');
  static String get aboutApp => _t('حول التطبيق', 'About App');
  static String get notificationReminderTitle => _t('تذكير الرحلات القادمة', 'Upcoming trip reminder');
  static String get notificationReminderSub => _t('تلقي إشعارات لتذكيرك بمواعيد رحلاتك المجدولة', 'Receive notifications to remind you of your scheduled trips');
  static String get notificationAITitle => _t('اقتراحات ذكية من الذكاء الاصطناعي', 'Smart AI recommendations');
  static String get notificationAISub => _t('احصل على نصائح سفر وتوصيات مخصصة لرحلاتك القادمة', 'Get travel tips and personalized recommendations for your trips');

  // Errors
  static String get errorNetwork => _t('تحقق من اتصالك بالإنترنت', 'Please check your internet connection');
  static String get errorAI => _t('تعذّر إنشاء الخطة. حاول مرة أخرى.', 'Failed to generate plan. Please try again.');
  static String get errorGeneral => _t('حدث خطأ غير متوقع', 'An unexpected error occurred');
  static String get errorRetry => _t('إعادة المحاولة', 'Retry');
  static String get errorOffline => _t('أنت غير متصل بالإنترنت', 'You are offline');
  static String get errorOfflineAI => _t('يحتاج إنشاء الرحلة إلى اتصال بالإنترنت', 'Trip generation requires an internet connection');
  static String get errorInvalidApiKey => _t('مفتاح API غير صالح', 'Invalid API key');
  static String get errorRateLimit => _t('تجاوزت حد الطلبات. انتظر قليلاً.', 'Rate limit exceeded. Please wait a bit.');
  static String get errorServerFormat => _t('خطأ في الخادم: %s', 'Server error: %s');
  static String get errorPageNotFound => _t('الصفحة غير موجودة', 'Page not found');
  static String get backToHome => _t('العودة للرئيسية', 'Back to Home');
  static String get exceptionNetwork => _t('لا يوجد اتصال بالإنترنت', 'No internet connection');
  static String get exceptionAI => _t('خطأ من الذكاء الاصطناعي', 'AI server error');
  static String get exceptionDatabase => _t('خطأ في قاعدة البيانات', 'Database error');
  static String get exceptionAuth => _t('خطأ في المصادقة', 'Authentication error');
  static String get exceptionParse => _t('تعذّر قراءة البيانات', 'Failed to parse data');
  static String get failureDatabaseLocal => _t('خطأ في قاعدة البيانات المحلية', 'Local database error');
  static String get failureAuthLogin => _t('تعذّر تسجيل الدخول', 'Failed to login');
  static String get failureCache => _t('خطأ في التخزين المؤقت', 'Caching error');
  static String get failureServer => _t('خطأ في الخادم', 'Server failure');
  static String get failureValidation => _t('بيانات غير صالحة', 'Invalid inputs');
  static String get failurePermission => _t('تم رفض الإذن المطلوب', 'Required permission denied');

  // Misc
  static String get free => _t('مجاني', 'Free');
  static String get perPerson => _t('/شخص', '/person');
  static String get usd => _t('USD', 'USD');
  static String get share => _t('مشاركة', 'Share');
  static String get save => _t('حفظ', 'Save');
  static String get delete => _t('حذف', 'Delete');
  static String get edit => _t('تعديل', 'Edit');
  static String get back => _t('رجوع', 'Back');
  static String get confirm => _t('تأكيد', 'Confirm');
  static String get cancel => _t('إلغاء', 'Cancel');
  static String get total => _t('الإجمالي', 'Total');

  // Popular cities
  static List<String> get popularCities => _t(
    ['إسطنبول', 'دبي', 'باريس', 'القاهرة', 'لندن', 'طوكيو', 'روما', 'مراكش'],
    ['Istanbul', 'Dubai', 'Paris', 'Cairo', 'London', 'Tokyo', 'Rome', 'Marrakech']
  );

  // Stop types & category names
  static String categoryName(String category) {
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
  static String monthName(int index) {
    if (index < 1 || index > 12) return '';
    final arMonths = ['', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    final enMonths = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return _t(arMonths[index], enMonths[index]);
  }

  // Duration Formatter Helper
  static String durationFormat(int hours, int minutes) {
    if (hours == 0) return _t('$minutes دقيقة', '$minutes mins');
    if (minutes == 0) {
      return hours == 1 ? _t('ساعة', '1 hour') : _t('$hours ساعات', '$hours hours');
    }
    return _t('$hours ساعة و$minutes دقيقة', '$hours hr $minutes mins');
  }

  // Budget Tier Name Helper
  static String budgetTierName(String tier) {
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
  static String statusName(String status) {
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
  static String get costFree => free;
  static String get planDayLabelPrefix => dayPrefix;
  static String get periodMorning => morning;
  static String get periodAfternoon => afternoon;
  static String get periodEvening => evening;
  static String get statusCompleted => statusDone;
  static String get budgetEstimatedUsd => _t('USD • تقديري', 'USD • Estimated');

  static String formatDuration(int minutes) {
    final hrs = minutes ~/ 60;
    final mins = minutes % 60;
    return durationFormat(hrs, mins);
  }

  static String budgetItemCategory(String key) {
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

  static String get errorTripNotFound => _t('الرحلة غير موجودة', 'Trip not found');
  static String get snackTripNotFound => _t('الرحلة غير موجودة', 'Trip not found');
}

```
