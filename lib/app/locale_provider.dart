import 'package:flutter/material.dart';

/// Singleton ChangeNotifier that manages the app's language across the app —
/// same shape as [ThemeProvider], the app's existing pattern for a small
/// piece of global, persisted UI state.
class LocaleProvider extends ChangeNotifier {
  static final LocaleProvider instance = LocaleProvider._();
  LocaleProvider._();

  static const supportedLocales = [Locale('en'), Locale('ur')];

  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  /// Setting this to `Locale('ur')` is what actually flips the app to RTL —
  /// `Locale('ur')` is on Flutter's built-in RTL language list, so once
  /// `MaterialApp.router`'s `locale` is bound to this value (see main.dart),
  /// `Directionality.of(context)` switches automatically everywhere; nothing
  /// else in the widget tree needs to know about RTL directly.
  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }

  bool get isUrdu => _locale.languageCode == 'ur';
}

// ----------------------------------------------------------- Strings ----------

/// Same `AppStrings.t(key)` map-lookup architecture as `transit_pro`'s own
/// `lib/app/language_provider.dart` — a plain `Map<String, String>` per
/// language plus a static `t()` accessor, not ARB files/`AppLocalizations`
/// or GetX's `.tr`. Kept in this file, next to [LocaleProvider], mirroring
/// how `transit_pro` keeps its own `LanguageProvider` and `AppStrings`
/// together in one file. Driven off [LocaleProvider.isUrdu] rather than a
/// second, separate language flag, so the one flip that already produces
/// real RTL layout (`MaterialApp.locale`, see main.dart — `transit_pro`'s
/// own `LanguageProvider` has no such RTL wiring) is also what selects
/// which string map is read.
class AppStrings {
  AppStrings._();

  static String t(String key) {
    final isUrdu = LocaleProvider.instance.isUrdu;
    return isUrdu ? (_ur[key] ?? _en[key] ?? key) : (_en[key] ?? key);
  }

  /// Wraps an untranslatable Latin/English run (a proper noun like a
  /// school name) in Unicode First Strong Isolate marks (U+2066/U+2069) so
  /// it renders as a self-contained LTR unit inside an RTL paragraph — the
  /// neutral characters around it (e.g. a '•' separator) then resolve
  /// against the surrounding strong-direction text instead of the isolated
  /// run, fixing the "bullet lands on the wrong side" scrambling that a
  /// plain concatenation causes under RTL.
  static String isolateLtr(String text) => '\u2066$text\u2069';

  static final Map<String, String> _en = {
    // Profile screen (wired in the 2026-09-06 (profile translations) pass)
    'admin_role': 'Admin',
    'users_lbl': 'Users',
    'routes_lbl': 'Routes',
    'buses_lbl': 'Buses',
    'profile_information': 'Profile Information',
    'role_lbl': 'Role',
    'email_lbl': 'Email',
    'phone_lbl': 'Phone',
    'fee_management': 'Fee Management',
    'route_management': 'Route Management',

    // Bottom nav (admin_layout.dart)
    'nav_dashboard': 'Dashboard',
    'nav_student': 'Student',
    'nav_parent': 'Parent',
    'nav_driver': 'Driver',
    'nav_profile': 'Profile',

    // Other screen headers / Profile menu rows not yet wired to AppStrings —
    // reserved here so every screen's eventual migration reads from the same
    // dictionary rather than re-typing these strings.
    'vehicle_management': 'Vehicle Management',
    'notification_preferences': 'Notification Preferences',
    'subscription_management': 'Subscription Management',
    'security': 'Security',
    'language_settings': 'Language Settings',

    // Detail-screen tabs (student & driver detail)
    'attendance_tab': 'Attendance',
    'trip_history_tab': 'Trip History',
    'missed_logs_tab': 'Missed Logs',
    'access_tab': 'Access',
    'sos_history_tab': 'SOS History',
    'earnings_tab': 'Earnings',

    // Status & metrics
    'total_lbl': 'Total',
    'active_lbl': 'Active',
    'pending_lbl': 'Pending',
    'overdue_lbl': 'Overdue',
    'collected_lbl': 'Collected',
    'service_lbl': 'Service',
    'present_status': 'Present',
    'absent_status': 'Absent',
    'late_status': 'Late',
    'on_time_status': 'On time',
    'completed_status': 'Completed',
    'delayed_status': 'Delayed',
    'unverified_status': 'Unverified',
    'good_status': 'Good',

    // Empty states
    'no_routes_created': 'No routes have been created yet.',
    'no_payments_found': 'No payments found in this category.',
    'driver_pending_verification': 'Driver is pending verification.',
    'no_attendance_records': 'No attendance records yet.',

    // Profile screen — Settings/Security/System Controls sections
    'change_password': 'Change Password',
    'login_session_history': 'Login Session History',
    'active_devices': 'Active Devices',
    'logout_all_sessions': 'Logout All Sessions',
    'role_based_permissions': 'Role-Based Permissions',
    'system_controls': 'System Controls',
    'soon_badge': 'Soon',
    'advanced_badge': 'Advanced',
    'not_available_yet': 'Not available yet',
    'single_admin_role_desc': 'Single Admin role — no sub-roles yet',

    // System Controls rows, theme toggle, sign out
    'system_logs': 'System Logs',
    'audit_history': 'Audit History',
    'admin_activity_tracking': 'Admin Activity Tracking',
    'now_recording_viewer_soon': 'Now recording — viewer coming soon',
    'light_mode': 'Light Mode',
    'dark_mode': 'Dark Mode',
    'sign_out': 'Sign Out',

    // Driver Management screen
    'driver_management': 'Driver Management',
    // `{count}` is a literal placeholder — replaced at the call site with
    // `.replaceFirst('{count}', ...)`, the same pattern `transit_pro`'s own
    // dictionary uses for its `{name}`/`{stars}` placeholders (see e.g.
    // `remove_child_confirm` in transit_pro/lib/app/language_provider.dart).
    'drivers_registered': '{count} drivers registered',
    'search_drivers_hint': 'Search drivers...',
    'status_prefix': 'Status',
    'status_all': 'All',
    'suspended_status': 'Suspended',
    'offline_status': 'Offline',
    'bus_prefix': 'Bus',

    // Parent Management screen
    'parent_management': 'Parent Management',
    'parents_registered': '{count} parents registered',
    'search_parents_hint': 'Search parents...',
    'inactive_status': 'Inactive',
    'child_singular': 'child',
    'children_plural': 'children',

    // Student Management screen
    'student_management': 'Student Management',
    'students_enrolled': '{count} students enrolled',
    'search_students_hint': 'Search students...',
    'with_driver_status': 'With Driver',
    'no_driver_status': 'No driver',
    'university_type': 'University',
    'college_type': 'College',

    // Command Center (main dashboard) screen
    'command_center': 'Command Center',
    'system_online_realtime': 'System Online • Real-time',
    'drivers_lbl': 'Drivers',
    'parents_lbl': 'Parents',
    'students_lbl': 'Students',
    'online_status': 'Online',
    'active_trips_lbl': 'Active Trips',
    'revenue_mtd_lbl': 'Revenue (MTD)',
    'revenue_mtd_sub': 'this month, collected',
    'expired_status': 'Expired',
    'expired_sub_cycle': 'this billing cycle',
    'active_subs_lbl': 'Active Subs',
    'active_subs_sub': 'of {count} students',
    'subscription_analytics': 'Subscription Analytics',
    'trial_status': 'Trial',
    'monthly_revenue': 'Monthly Revenue',

    // Command Center — Analytics & Alerts panels (bottom half)
    'payment_success': 'Payment\nSuccess',
    'payment_failure': 'Payment\nFailure',
    'renewal_rate': 'Renewal\nRate',
    'alerts_title': 'Alerts',
    'all_clear': 'All clear',
    'no_overdue_alerts_desc':
        'No overdue payments or lapsed subscriptions right now.',
    'analytics_title': 'Analytics',
    'attendance_rate_lbl': 'Attendance Rate',
    'daily_trips_lbl': 'Daily Trips',
    'trips_completed_count': '{count} completed',

    // Notifications screen
    'notifications_title': 'Notifications',
    'admin_notifications_title': 'Admin Notifications',
    'admin_notifications_desc':
        'New driver, student, and parent accounts appear here for review.',
    'new_account_activity_title': 'New Account Activity',
    'new_account_activity_desc':
        'Recent account creations from drivers, students, and parents.',
    'parent_account_created': 'Parent account created',
    'student_account_created': 'Student account created',
    'driver_account_created': 'Driver account created',
    // `{name}` is the placeholder — same convention as every other dynamic
    // string in this dictionary (`replaceFirst` at the call site).
    'registered_as_parent': '{name} registered as a parent.',
    'registered_as_student': '{name} registered as a student.',
    'registered_as_driver': '{name} registered as a driver.',
    // Composed at the call site as `'$n${AppStrings.t('day_unit')} ${AppStrings.t('ago_suffix')}'`
    // — English's 'd' sits directly against the number, Urdu's unit needs a
    // leading space before it, so that space lives inside this value rather
    // than being assumed at the call site (see admin_notifications.dart).
    'day_unit': 'd',
    'ago_suffix': 'ago',

    // Notifications screen — Driver Verification Queue empty state
    'driver_verification_queue': 'Driver Verification Queue',
    'no_drivers_pending_verification':
        'No drivers are waiting for verification right now.',

    // Driver Detail screen
    'driver_detail_title': 'Driver Detail',
    'no_route_status': 'No route',
    'approved_status': 'Approved',
    'details_title': 'Details',
    'license_lbl': 'License',
    'contact_lbl': 'Contact',
    'route_lbl': 'Route',
    'unassigned_status': 'Unassigned',
    'experience_lbl': 'Experience',
    // `{count}` placeholder — see the note on `_InfoRow` in
    // admin_driver_detail.dart for why the English 'yrs' unit visually
    // reversed under RTL and how translating the whole value fixes it.
    'experience_years_value': '{count} yrs',
    'performance_lbl': 'Performance',
    'reliability_lbl': 'Reliability',
    'rating_lbl': 'Rating',
    'safety_lbl': 'Safety',

    // Driver Detail — Controls, Compliance Documents, Tab Bar
    'controls_title': 'Controls',
    'suspend_action': 'Suspend',
    'message_driver_action': 'Message Driver',
    'compliance_documents_title': 'Compliance Documents',
    'driving_license_doc': 'Driving License',
    'vehicle_registration_doc': 'Vehicle Registration',
    'verified_status': 'Verified',
    'view_action': 'View',
    'no_trips_recorded_driver': 'No trips recorded for this driver yet.',
    'no_attendance_logged_driver': 'No attendance logged for this driver yet.',
    'no_sos_alerts_clean_record':
        'Zero SOS alerts. This driver has a clean safety record.',
    'no_earnings_recorded_driver': 'No earnings recorded for this driver yet.',

    // Parent Detail — header, Children list, Controls
    'parent_detail_title': 'Parent Detail',
    'children_section_title': 'Children',
    'message_action': 'Message',
    'deactivate_action': 'Deactivate',

    // Edit Profile form — labels & actions
    'name_lbl': 'Name',
    'save_action': 'Save',
    'cancel_action': 'Cancel',
    'saving_action': 'Saving…',

    // Student Detail — header, Details, Controls
    'student_detail_title': 'Student Detail',
    'school_lbl': 'School',
    'grade_lbl': 'Grade',
    'driver_lbl': 'Driver',
    'no_attendance_records_student':
        'No attendance records exist for this student.',
    'ensure_driver_assigned_desc':
        'Ensure a driver is assigned to begin tracking trips.',
    'no_trip_history_student': 'No trip history exists for this student.',
    'no_missed_logs_student': 'No missed logs exist for this student.',
    'no_access_events_student':
        'No access or subscription events recorded for this student.',
    'access_events_appear_desc':
        'Events appear here once a subscription change is recorded.',
    'medical_notes_lbl': 'Medical notes',

    // Fee Management — summary cards, filters
    'total_collected_lbl': 'Total Collected',
    'paid_status': 'Paid',
    'all_filter': 'All',

    // Route Management — summary cards, empty state
    'stops_lbl': 'Stops',
    'total_routes_lbl': 'Total Routes',
    'create_route_action': 'Create Route',

    // Vehicle card — route/driver line, stats row
    'unassigned_route': 'Unassigned route',
    'driver_prefix': 'Driver: {name}',
    'capacity_lbl': 'Capacity',
    'mileage_lbl': 'Mileage',
    'mileage_value': '{value} km',
    'next_service_lbl': 'Next Service',
    'not_scheduled_status': 'Not scheduled',

    // Subscription screen — header, fee collection, students list
    'subscription_title': 'Subscription',
    'subscription_desc':
        "Each student's transport subscription status, and what's been collected in fees.",
    'fee_collection_title': 'Fee Collection',
    'view_full_fee_breakdown_action': 'View full fee breakdown',
  };

  static final Map<String, String> _ur = {
    // Profile screen
    'admin_role': 'ایڈمن',
    'users_lbl': 'صارفین',
    'routes_lbl': 'روٹس',
    'buses_lbl': 'بسیں',
    'profile_information': 'پروفائل کی معلومات',
    'role_lbl': 'کردار',
    'email_lbl': 'ای میل',
    'phone_lbl': 'فون',
    'fee_management': 'فیس مینجمنٹ',
    'route_management': 'روٹ مینجمنٹ',

    // Bottom nav
    'nav_dashboard': 'ڈیش بورڈ',
    'nav_student': 'طالب علم',
    'nav_parent': 'والدین',
    'nav_driver': 'ڈرائیور',
    'nav_profile': 'پروفائل',

    // Other screen headers / Profile menu rows
    'vehicle_management': 'گاڑیوں کا انتظام',
    'notification_preferences': 'اطلاعات کی ترجیحات',
    'subscription_management': 'سبسکرپشن مینجمنٹ',
    'security': 'سیکیورٹی',
    'language_settings': 'زبان کی ترتیبات',

    // Detail-screen tabs
    'attendance_tab': 'حاضری',
    'trip_history_tab': 'سفر کی تاریخ',
    'missed_logs_tab': 'مسڈ لاگز',
    'access_tab': 'رسائی',
    'sos_history_tab': 'ایس او ایس ہسٹری',
    'earnings_tab': 'کمائی',

    // Status & metrics
    'total_lbl': 'کل',
    'active_lbl': 'فعال',
    'pending_lbl': 'زیر التواء',
    'overdue_lbl': 'میعاد ختم',
    'collected_lbl': 'وصول شدہ',
    'service_lbl': 'سروس',
    'present_status': 'حاضر',
    'absent_status': 'غیر حاضر',
    'late_status': 'تاخیر سے',
    'on_time_status': 'وقت پر',
    'completed_status': 'مکمل',
    'delayed_status': 'تاخیر',
    'unverified_status': 'غیر تصدیق شدہ',
    'good_status': 'اچھا',

    // Empty states
    'no_routes_created': 'ابھی تک کوئی روٹ نہیں بنایا گیا۔',
    'no_payments_found': 'اس زمرے میں کوئی ادائیگی نہیں ملی۔',
    'driver_pending_verification': 'ڈرائیور کی تصدیق زیر التواء ہے۔',
    'no_attendance_records': 'ابھی تک کوئی حاضری کا ریکارڈ نہیں ہے۔',

    // Profile screen — Settings/Security/System Controls sections
    'change_password': 'پاس ورڈ تبدیل کریں',
    'login_session_history': 'لاگ ان سیشن کی تاریخ',
    'active_devices': 'فعال آلات',
    'logout_all_sessions': 'تمام سیشنز سے لاگ آؤٹ کریں',
    'role_based_permissions': 'کردار پر مبنی اجازتیں',
    'system_controls': 'سسٹم کنٹرولز',
    'soon_badge': 'جلد',
    'advanced_badge': 'جدید',
    'not_available_yet': 'ابھی دستیاب نہیں',
    'single_admin_role_desc': 'صرف ایک ایڈمن کردار — ابھی کوئی ذیلی کردار نہیں',

    // System Controls rows, theme toggle, sign out
    'system_logs': 'سسٹم لاگز',
    'audit_history': 'آڈٹ ہسٹری',
    'admin_activity_tracking': 'ایڈمن سرگرمی ٹریکنگ',
    'now_recording_viewer_soon': 'ابھی ریکارڈ ہو رہا ہے — ویور جلد آ رہا ہے',
    'light_mode': 'لائٹ موڈ',
    'dark_mode': 'ڈارک موڈ',
    'sign_out': 'لاگ آؤٹ',

    // Driver Management screen
    'driver_management': 'ڈرائیور مینجمنٹ',
    'drivers_registered': '{count} ڈرائیورز رجسٹرڈ ہیں',
    'search_drivers_hint': 'ڈرائیورز تلاش کریں...',
    'status_prefix': 'حیثیت',
    'status_all': 'تمام',
    'suspended_status': 'معطل',
    'offline_status': 'آف لائن',
    'bus_prefix': 'بس',

    // Parent Management screen — kept deliberately plain/conversational
    // (per this task's ask), avoiding heavier Persian/Arabic-derived
    // phrasing where a simpler everyday word says the same thing.
    'parent_management': 'والدین کا انتظام',
    'parents_registered': '{count} رجسٹرڈ والدین',
    'search_parents_hint': 'والدین تلاش کریں...',
    'inactive_status': 'غیر فعال',
    'child_singular': 'بچہ',
    'children_plural': 'بچے',

    // Student Management screen
    'student_management': 'طلباء کا انتظام',
    'students_enrolled': '{count} رجسٹرڈ طلباء',
    'search_students_hint': 'طلباء تلاش کریں...',
    'with_driver_status': 'ڈرائیور کے ساتھ',
    'no_driver_status': 'کوئی ڈرائیور نہیں',
    'university_type': 'یونیورسٹی',
    'college_type': 'کالج',

    // Command Center (main dashboard) screen — kept conversational, mixing
    // plain Urdu with the transliterated tech terms Pakistani admins
    // actually say out loud ("آن لائن", "ٹرائل", "سبسکرپشن"), per this
    // task's explicit ask, rather than forcing a stiffer formal translation.
    'command_center': 'کمانڈ سینٹر',
    'system_online_realtime': 'سسٹم آن لائن • ریئل ٹائم',
    'drivers_lbl': 'ڈرائیورز',
    'parents_lbl': 'والدین',
    'students_lbl': 'طلباء',
    'online_status': 'آن لائن',
    'active_trips_lbl': 'ایکٹو ٹرپس',
    'revenue_mtd_lbl': 'آمدنی (اس مہینے)',
    'revenue_mtd_sub': 'اس مہینے وصول شدہ',
    'expired_status': 'ختم شدہ',
    'expired_sub_cycle': 'اس بلنگ سائیکل میں',
    'active_subs_lbl': 'ایکٹو سبسکرپشنز',
    'active_subs_sub': '{count} طلباء میں سے',
    'subscription_analytics': 'سبسکرپشن اینالیٹکس',
    'trial_status': 'ٹرائل',
    'monthly_revenue': 'ماہانہ آمدنی',

    // Command Center — Analytics & Alerts panels (bottom half)
    'payment_success': 'ادائیگی\nکامیاب',
    'payment_failure': 'ادائیگی\nناکام',
    'renewal_rate': 'تجدید کی\nشرح',
    'alerts_title': 'الرٹس',
    'all_clear': 'سب ٹھیک ہے',
    'no_overdue_alerts_desc':
        'ابھی کوئی واجب الادا رقم یا ختم شدہ سبسکرپشن نہیں ہے۔',
    'analytics_title': 'اینالیٹکس',
    'attendance_rate_lbl': 'حاضری کی شرح',
    'daily_trips_lbl': 'روزانہ ٹرپس',
    'trips_completed_count': '{count} مکمل',

    // Notifications screen
    'notifications_title': 'اطلاعات',
    'admin_notifications_title': 'ایڈمن اطلاعات',
    'admin_notifications_desc':
        'نئے ڈرائیور، طالب علم اور والدین کے اکاؤنٹس یہاں جائزے کے لیے نظر آئیں گے۔',
    'new_account_activity_title': 'نئی اکاؤنٹ سرگرمی',
    'new_account_activity_desc':
        'ڈرائیورز، طلباء اور والدین کے حالیہ بنائے گئے اکاؤنٹس۔',
    'parent_account_created': 'پیرنٹ اکاؤنٹ بن گیا',
    'student_account_created': 'طالب علم کا اکاؤنٹ بن گیا',
    'driver_account_created': 'ڈرائیور کا اکاؤنٹ بن گیا',
    'registered_as_parent': '{name} نے بطور پیرنٹ رجسٹر کیا۔',
    'registered_as_student': '{name} نے بطور طالب علم رجسٹر کیا۔',
    'registered_as_driver': '{name} نے بطور ڈرائیور رجسٹر کیا۔',
    'day_unit': ' دن',
    'ago_suffix': 'پہلے',

    // Notifications screen — Driver Verification Queue empty state
    'driver_verification_queue': 'ڈرائیور تصدیق کی قطار',
    'no_drivers_pending_verification':
        'ابھی کوئی ڈرائیور تصدیق کا انتظار نہیں کر رہا۔',

    // Driver Detail screen
    'driver_detail_title': 'ڈرائیور کی تفصیل',
    'no_route_status': 'کوئی روٹ نہیں',
    'approved_status': 'منظور شدہ',
    'details_title': 'تفصیلات',
    'license_lbl': 'لائسنس',
    'contact_lbl': 'رابطہ',
    'route_lbl': 'روٹ',
    'unassigned_status': 'غیر مقرر',
    'experience_lbl': 'تجربہ',
    'experience_years_value': '{count} سال',
    'performance_lbl': 'کارکردگی',
    'reliability_lbl': 'بھروسہ',
    'rating_lbl': 'ریٹنگ',
    'safety_lbl': 'حفاظت',

    // Driver Detail — Controls, Compliance Documents, Tab Bar
    'controls_title': 'کنٹرولز',
    'suspend_action': 'معطل کریں',
    'message_driver_action': 'ڈرائیور کو پیغام بھیجیں',
    'compliance_documents_title': 'مطلوبہ دستاویزات',
    'driving_license_doc': 'ڈرائیونگ لائسنس',
    'vehicle_registration_doc': 'گاڑی کی رجسٹریشن',
    'verified_status': 'تصدیق شدہ',
    'view_action': 'دیکھیں',
    'no_trips_recorded_driver': 'ابھی تک اس ڈرائیور کا کوئی سفر ریکارڈ نہیں ہوا۔',
    'no_attendance_logged_driver':
        'ابھی تک اس ڈرائیور کی کوئی حاضری درج نہیں ہوئی۔',
    'no_sos_alerts_clean_record':
        'کوئی ایس او ایس الرٹ نہیں۔ ڈرائیور کا سیفٹی ریکارڈ بالکل صاف ہے۔',
    'no_earnings_recorded_driver':
        'ابھی تک اس ڈرائیور کی کوئی آمدنی درج نہیں ہوئی۔',

    // Parent Detail — header, Children list, Controls
    'parent_detail_title': 'والدین کی تفصیل',
    'children_section_title': 'بچے',
    'message_action': 'پیغام',
    'deactivate_action': 'غیر فعال کریں',

    // Edit Profile form — labels & actions
    'name_lbl': 'نام',
    'save_action': 'محفوظ کریں',
    'cancel_action': 'منسوخ کریں',
    'saving_action': 'محفوظ ہو رہا ہے…',

    // Student Detail — header, Details, Controls
    'student_detail_title': 'طالب علم کی تفصیل',
    'school_lbl': 'اسکول',
    'grade_lbl': 'کلاس',
    'driver_lbl': 'ڈرائیور',
    'no_attendance_records_student':
        'اس طالب علم کی کوئی حاضری کا ریکارڈ موجود نہیں۔',
    'ensure_driver_assigned_desc':
        'سفر کی ٹریکنگ شروع کرنے کے لیے ڈرائیور کا تعین یقینی بنائیں۔',
    'no_trip_history_student': 'اس طالب علم کے سفر کی کوئی تاریخ موجود نہیں۔',
    'no_missed_logs_student': 'اس طالب علم کا کوئی مسڈ لاگ موجود نہیں۔',
    'no_access_events_student':
        'اس طالب علم کے لیے کوئی رسائی یا سبسکرپشن ایونٹ درج نہیں۔',
    'access_events_appear_desc':
        'سبسکرپشن میں تبدیلی درج ہوتے ہی ایونٹس یہاں نظر آئیں گے۔',
    'medical_notes_lbl': 'طبی نوٹس',

    // Fee Management — summary cards, filters
    'total_collected_lbl': 'کل وصولی',
    'paid_status': 'ادا شدہ',
    'all_filter': 'تمام',

    // Route Management — summary cards, empty state
    'stops_lbl': 'اسٹاپس',
    'total_routes_lbl': 'کل روٹس',
    'create_route_action': 'روٹ بنائیں',

    // Vehicle card — route/driver line, stats row
    'unassigned_route': 'غیر مقرر روٹ',
    'driver_prefix': 'ڈرائیور: {name}',
    'capacity_lbl': 'گنجائش',
    'mileage_lbl': 'مائلیج',
    'mileage_value': '{value} کلومیٹر',
    'next_service_lbl': 'اگلی سروس',
    'not_scheduled_status': 'شیڈول نہیں',

    // Subscription screen — header, fee collection, students list
    'subscription_title': 'سبسکرپشن',
    'subscription_desc':
        'ہر طالب علم کی ٹرانسپورٹ سبسکرپشن کی صورتحال، اور فیس میں کتنی رقم وصول ہوئی۔',
    'fee_collection_title': 'فیس وصولی',
    'view_full_fee_breakdown_action': 'مکمل فیس تفصیل دیکھیں',
  };
}
