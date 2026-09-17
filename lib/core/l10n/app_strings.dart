/// Minimal bilingual support (Arabic default, English optional).
///
/// Usage:
///   tr('نص عربي')                            → EN map lookup, AR fallback
///   tr('نص عربي', 'English inline')          → inline English in EN mode
///   trArgs('طلب: {id}', {'id': o.id})        → templated, map or fallback
///   orderStatusLabel(o.status)               → localized status (logic-safe:
///                                              DB values stay Arabic)
///   unitLabel / categoryLabel / saleTypeLabel / sortLabel — same idea.
///
/// Logic strings (comparisons, dropdown *values*, DB writes, `.contains`
/// filters) are NEVER wrapped — only display text goes through these.
class AppLocale {
  static String code = 'ar'; // synced by AppState.toggleLocale / session load
  static bool get isArabic => code != 'en';
  static bool get isEnglish => code == 'en';
}

String tr(String arabic, [String? english]) {
  if (!AppLocale.isEnglish) return arabic;
  if (english != null) return english;
  return _en[arabic] ?? arabic;
}

String trArgs(String arabicTemplate, Map<String, Object?> params, [String? englishTemplate]) {
  String t = tr(arabicTemplate, englishTemplate);
  params.forEach((k, v) => t = t.replaceAll('{$k}', '$v'));
  return t;
}

String orderStatusLabel(String status) =>
    AppLocale.isEnglish ? (_enStatus[status] ?? status) : status;

String unitLabel(String unit) =>
    AppLocale.isEnglish ? (_enUnits[unit] ?? unit) : unit;

String categoryLabel(String cat) =>
    AppLocale.isEnglish ? (_enCategories[cat] ?? cat) : cat;

String saleTypeLabel(String v) =>
    AppLocale.isEnglish ? (_enSaleType[v] ?? v) : v;

String sortLabel(String s) =>
    AppLocale.isEnglish ? (_enSort[s] ?? s) : s;

const Map<String, String> _enStatus = {
  'قيد المراجعة': 'Pending review',
  'مؤكد': 'Confirmed',
  'جاري التجهيز': 'Preparing',
  'في الطريق': 'On the way',
  'تم التسليم': 'Delivered',
  'مرفوض': 'Rejected',
  'ملغي': 'Cancelled',
};

const Map<String, String> _enUnits = {
  'كرتونة': 'Carton',
  'قطعة': 'Piece',
  'دستة': 'Dozen',
  'شكارة / شوال': 'Sack',
  'طرد / باكت': 'Parcel/Pack',
  'صندوق': 'Box',
  'علبة / كيس': 'Can/Bag',
  'جالون': 'Gallon',
  'برميل': 'Barrel',
  'كيلو': 'Kilo',
  'طن': 'Ton',
  'أخرى (تحديد يدوي)': 'Other (custom)',
};

const Map<String, String> _enCategories = {
  'الكل': 'All',
  'مواد غذائية': 'Groceries',
  'منظفات وعناية': 'Cleaning & care',
  'مشروبات وعصائر': 'Beverages & juices',
  'بقوليات وحبوب': 'Legumes & grains',
};

const Map<String, String> _enSaleType = {
  'الكل': 'All',
  'بالجملة': 'Wholesale',
  'بالقطعة': 'Per piece',
};

const Map<String, String> _enSort = {
  'الافتراضي': 'Default',
  'الأقرب للنفاذ': 'Almost depleted',
  'الأحدث': 'Newest',
  'السعر: الأقل': 'Price: lowest',
  'السعر: الأعلى': 'Price: highest',
};

const Map<String, String> _en = {
  // ---- login ----
  'منصة وُفّرت - Waffart B2B': 'Waffart B2B platform',
  'سوق الجملة الذكي ومنصة التجارة المتكاملة': 'Smart wholesale marketplace',
  'العميل / المحل': 'Client / Store',
  'المورد': 'Vendor',
  'المدير': 'Admin',
  'دخول مدير المنصة (Super Admin)': 'Platform admin login (Super Admin)',
  'معرف المدير أو رقم الهاتف': 'Admin ID or phone number',
  'كلمة المرور / الكود الخاص (admin123)': 'Password / special code (admin123)',
  'تسجيل حساب مورد جديد': 'Register a new vendor account',
  'تسجيل دخول المورد الحالي': 'Existing vendor login',
  'لديك حساب؟ سجل دخول': 'Have an account? Log in',
  'مورد جديد؟ انضم الآن': 'New vendor? Join now',
  'رقم الهاتف (إجباري)': 'Phone number (required)',
  'الاسم ثلاثي (إجباري)': 'Triple name (required)',
  'أحمد محمد علي': 'Ahmed Mohamed Ali',
  'العنوان التفصيلي ومقر العمل (إجباري)': 'Detailed address & workplace (required)',
  'المنطقة الصناعية - العبور': 'Industrial Zone - Obour',
  'النشاط التجاري (إجباري)': 'Business activity (required)',
  'تجارة مواد غذائية وزيوت بالجملة': 'Wholesale food & oils trade',
  'كود التأكيد / المرور (إجباري)': 'Confirmation / pass code (required)',
  'تسجيل دخول العميل أو صاحب المحل': 'Client / store owner login',
  'الاسم بالكامل (إجباري)': 'Full name (required)',
  'محمد أحمد إبراهيم': 'Mohamed Ahmed Ibrahim',
  'العنوان التفصيلي للاستلام (إجباري)': 'Detailed delivery address (required)',
  'شارع الجمهورية - الجيزة': 'El Gomhoureya St - Giza',
  'اسم المحل التجاري (اختياري)': 'Store trade name (optional)',
  'سوبر ماركت الإخلاص': 'El Ekhlas Supermarket',
  'كود التأكيد (OTP)': 'Confirmation code (OTP)',
  'إرسال طلب الانضمام': 'Send join request',
  'دخول / تأكيد الحساب': 'Login / confirm account',
  'يرجى إدخال رقم الهاتف أو المعرف أولاً': 'Please enter the phone number or ID first',
  'كود مرور المدير غير صحيح (استخدم: admin123)': 'Wrong admin password (use: admin123)',
  'جميع الحقول إجبارية للمورد الجديد (الهاتف، الاسم ثلاثي، العنوان، النشاط، الكود)':
      'All fields are required for a new vendor (phone, triple name, address, activity, code)',
  'تم إرسال طلب الانضمام بنجاح! سيتم تفعيل حسابك فور مراجعة مدير المنصة':
      'Join request sent! Your account will be activated after admin review',
  'يرجى إدخال كود التأكيد للدخول': 'Please enter the confirmation code to log in',
  'الاسم بالكامل والعنوان التفصيلي إجباريان للعميل': 'Full name and detailed address are required for clients',
  'حدث خطأ أثناء تسجيل الدخول: {e}': 'Login error: {e}',
  // ---- product card ----
  'متبقي {r} من {t}': '{r} of {t} left',
  '⚠️ متبقي 10% فقط ({r} {u})!': '⚠️ Only 10% left ({r} {u})!',
  '🔥 متبقي {r} {u}': '🔥 {r} {u} left',
  'عرض خاص 🔥': 'Special offer 🔥',
  'المورد: {id}': 'Vendor: {id}',
  'الوحدة: {u} (الحد الأدنى: {m})': 'Unit: {u} (Min: {m})',
  'انتهى العرض (متاح للشراء بالسعر الأصلي)': 'Offer ended (available at original price)',
  'في السلة ({q})': 'In cart ({q})',
  'أضف للسلة': 'Add to cart',
  // ---- offer bar ----
  'نفذت الكمية': 'Sold out',
  'متبقي {r} فقط! من أصل {t}': 'Only {r} left of {t}!',
  // ---- cart ----
  'سلة المشتريات المجمعة': 'Combined shopping cart',
  '{n} موردين': '{n} vendors',
  'سلة الشراء فارغة حالياً': 'Your cart is empty',
  'الطلب سينقسم تلقائياً لطلب فرعي لكل مورد للتجهيز والشحن المستقل. الدفع كاش عند الاستلام (COD).':
      'The order auto-splits into a sub-order per vendor for independent fulfillment. Cash on delivery (COD).',
  'طلب المورد: {id}': 'Vendor order: {id}',
  'الحد الأدنى: {m}': 'Minimum: {m}',
  'مجموع طلب المورد: {s}': 'Vendor subtotal: {s}',
  'يتبقى {d} للحد الأدنى!': '{d} more to reach the minimum!',
  'استوفى الحد الأدنى': 'Minimum met',
  'إجمالي الخصومات والتوفير:': 'Total discounts & savings:',
  'الإجمالي العام لكافة الطلبات:': 'Grand total for all orders:',
  'طريقة الدفع للمرحلة الأولى: كاش عند الاستلام (COD) لكافة الطلبات الفرعية':
      'Phase-one payment: cash on delivery (COD) for all sub-orders',
  'تم تأكيد الطلب بنجاح وتوزيعه على الموردين بشكل فوري!': 'Order confirmed and instantly split across vendors!',
  'حدث خطأ أو نفذت بعض الكميات المتاحة!': 'Error, or some quantities just sold out!',
  'تأكيد وتقسيم الطلب (COD)': 'Confirm & split order (COD)',
  'لم تكتمل الحدود الدنيا للموردين': 'Vendor minimums not met yet',
  // ---- retailer shell ----
  'سوق الجملة': 'Wholesale market',
  'طلباتي': 'My orders',
  'الإشعارات': 'Notifications',
  'حسابي': 'My account',
  // ---- store ----
  'سوق الجملة وفيد العروض المجمع': 'Wholesale market & offers feed',
  'تغيير اللغة': 'Change language',
  'سلة الشراء': 'Cart',
  'ابحث بالاسم، الصنف، السعر، أو الوحدة...': 'Search by name, category, price, or unit...',
  'نوع البيع:': 'Sale type:',
  'كل الموردين': 'All vendors',
  'لا توجد عروض أو أصناف مطابقة للبحث أو الفلتر المختار': 'No offers or products match your search/filters',
  // ---- client orders ----
  'قائمة طلباتي ومتابعة الحالات': 'My orders & status tracking',
  'لم تقم بإجراء أي طلبات حتى الآن': 'You have no orders yet',
  'طلب: {id}': 'Order: {id}',
  'التاريخ: {d}': 'Date: {d}',
  'الإجمالي: {t}': 'Total: {t}',
  'طريقة الدفع: {m}': 'Payment: {m}',
  'إلغاء الطلب': 'Cancel order',
  'هل أنت متأكد من رغبتك في إلغاء هذا الطلب؟ (متاح أثناء حالة قيد الانتظار فقط)':
      'Are you sure you want to cancel this order? (Only while pending review)',
  'تراجع': 'Back',
  'تأكيد الإلغاء': 'Confirm cancellation',
  'تم إلغاء الطلب': 'Order cancelled',
  'الطلب قيد التنفيذ (لا يمكن الإلغاء)': 'Order in progress (cannot cancel)',
  // ---- notifications ----
  'تحديد الكل كمقروء': 'Mark all as read',
  'مفيش إشعارات حالياً': 'No notifications yet',
  // ---- profile ----
  'تسجيل الخروج': 'Log out',
  'هل أنت متأكد أنك تريد الخروج من حسابك؟': 'Are you sure you want to log out?',
  'إلغاء': 'Cancel',
  'تأكيد الخروج': 'Confirm logout',
  'حساب العميل / صاحب المحل': 'Client / store account',
  'مستخدم': 'User',
  'غير مسجل': 'Not set',
  'العنوان التفصيلي': 'Detailed address',
  'غير محدد': 'Not specified',
  'تسجيل الخروج من الحساب': 'Log out of account',
  // ---- vendor ----
  'هل تريد الخروج من لوحة حساب المورد؟': 'Log out of the vendor dashboard?',
  'نعم، الخروج': 'Yes, log out',
  'لوحة المورد: {n}': 'Vendor dashboard: {n}',
  'الأصناف والمخزون': 'Products & stock',
  'إدارة العروض': 'Offers',
  'التقارير والأداء': 'Reports',
  '⚠️ الحساب قيد المراجعة والاعتماد': '⚠️ Account pending review',
  '⏸️ الحساب موقوف مؤقتاً': '⏸️ Account suspended',
  '⛔ تم رفض الحساب': '⛔ Account rejected',
  'حساب نشط ومعتمد': 'Active verified account',
  'تم رفض طلب انضمامك': 'Your join request was rejected',
  'حسابك موقوف مؤقتاً': 'Your account is suspended',
  'حسابك قيد مراجعة الإدارة': 'Your account is under review',
  'راجع مدير المنصة بيانات نشاطك التجاري وقرر رفض الطلب. يمكنك التواصل مع الإدارة لمعرفة السبب وإعادة التقديم.':
      'The admin reviewed your business and rejected the request. Contact support for details or to re-apply.',
  'قام مدير المنصة بإيقاف حسابك مؤقتاً. تواصل مع الإدارة لمراجعة الموقف وإعادة التفعيل.':
      'The admin suspended your account. Contact support to resolve and reactivate.',
  'شكراً لانضمامك إلى منصة وُفّرت. يقوم مدير المنصة بمراجعة بيانات نشاطك التجاري، وسيتم تفعيل حسابك فور الانتهاء.':
      'Thanks for joining Waffart. The admin is reviewing your business and will activate your account soon.',
  'تسجيل الخروج والعودة لاحقاً': 'Log out and come back later',
  'لا توجد طلبات واردة لك حتى الآن': 'No incoming orders yet',
  'طلب رقم: {id}': 'Order no: {id}',
  'العميل: {n} | هاتف: {p}': 'Client: {n} | Phone: {p}',
  'العنوان التفصيلي: {a}': 'Address: {a}',
  'المستحق لك: {t}': 'Your due: {t}',
  'الدفع: كاش عند الاستلام (COD)': 'Payment: cash on delivery (COD)',
  'لم تقم بإضافة أي أصناف بعد': 'You have not added any products yet',
  'السعر: {p} / {u}': 'Price: {p} / {u}',
  'القسم: {c} | الحد الأدنى: {m}': 'Category: {c} | Min: {m}',
  'إضافة صنف جديد': 'Add product',
  'إضافة صنف جديد للمتجر': 'Add a new product to your store',
  'اسم الصنف التجاري': 'Product trade name',
  'سعر بيع الجملة (ج.م)': 'Wholesale price (EGP)',
  'الحد الأدنى للطلب': 'Minimum order qty',
  'وحدة بيع الجملة': 'Wholesale unit',
  'اسم الوحدة المخصصة (مثال: طرد 24 قطعة)': 'Custom unit name (e.g. pack of 24)',
  'التصنيف': 'Category',
  'رابط صورة المنتج (اختياري)': 'Product image link (optional)',
  'رفع من استوديو الهاتف': 'Upload from gallery',
  'تم اختيار الصورة': 'Image selected',
  'تم حفظ الصنف بنجاح': 'Product saved',
  'حفظ وإضافة الصنف': 'Save product',
  'لا توجد عروض مخصصة حالياً': 'No offers yet',
  'إنشاء وتجهيز عرض جديد': 'Create a new offer',
  'العروض المجدولة والحالية': 'Scheduled & current offers',
  'عرض جديد': 'New offer',
  'عرض نشط 🔥': 'Active offer 🔥',
  'مجدول لتاريخ قادم ⏳': 'Scheduled ⏳',
  'منتهي (يعود للسعر الأصلي) ⚠️': 'Ended (back to original price) ⚠️',
  'سعر العرض: {o} (السعر الأصلي: {p}) / {u}': 'Offer: {o} (was {p}) / {u}',
  'الكمية المتبقية: {r} من {t}': 'Remaining: {r} of {t}',
  'الفترة: {s} إلى {e}': 'Period: {s} to {e}',
  'الآن': 'Now',
  'حتى نفاذ الكمية': 'Until stock runs out',
  'إلغاء العرض': 'Cancel offer',
  'يرجى إضافة أصناف أولاً قبل عمل عروض عليها': 'Add products first before creating offers',
  'تجهيز وجدولة عرض جديد': 'Create & schedule an offer',
  'اختر الصنف': 'Choose product',
  'سعر العرض المخفض (ج.م)': 'Discounted offer price (EGP)',
  'الكمية الإجمالية المخصصة للعرض': 'Total offer quantity',
  'تاريخ البداية': 'Start date',
  'تاريخ النهاية': 'End date',
  'تم تجهيز وتفعيل العرض بنجاح!': 'Offer created and activated!',
  'تأكيد العرض': 'Confirm offer',
  'تقارير وأداء المبيعات والعروض': 'Sales & offers reports',
  'إجمالي المبيعات المستحقة': 'Total sales due',
  'عدد الطلبات الواردة': 'Incoming orders',
  '{n} طلب': '{n} orders',
  'الأصناف الأكثر مبيعاً من منتجاتك': 'Your best-selling products',
  'لا توجد مبيعات مسجلة حتى الآن': 'No sales recorded yet',
  '{n} وحدة مباعة': '{n} units sold',
  'العملاء الأكثر شراءً من متجرك': 'Your top-buying clients',
  'لا يوجد طلبات عملاء حتى الآن': 'No client orders yet',
  // ---- admin ----
  'هل تريد الخروج من لوحة تحكم مدير المنصة؟': 'Log out of the admin dashboard?',
  'لوحة إدارة المنصة (Super Admin)': 'Platform admin (Super Admin)',
  'التقارير الشاملة': 'Reports',
  'إدارة الموردين': 'Vendors',
  'كافة الطلبات': 'All orders',
  'التصنيفات': 'Categories',
  'نظرة عامة وتقارير المبيعات الشاملة': 'Overview & platform sales reports',
  'إجمالي المبيعات': 'Total sales',
  'إجمالي الطلبات': 'Total orders',
  'الموردين المعتمدين': 'Approved vendors',
  '{n} مورد نشط': '{n} active vendors',
  'طلبات انضمام الموردين': 'Vendor join requests',
  '{n} بانتظار الموافقة': '{n} pending approval',
  'أفضل الموردين وأكثرهم مبيعاً': 'Top-selling vendors',
  'لا توجد مبيعات مسجلة للموردين حتى الآن': 'No vendor sales recorded yet',
  'الأصناف الأكثر طلباً ومبيعاً': 'Most ordered products',
  'لم يتم بيع أي منتجات بعد': 'No products sold yet',
  'أفضل العملاء (الأعلى شراءً في المنصة)': 'Best clients (top buyers)',
  'لا يوجد طلبات عملاء مسجلة بعد': 'No client orders recorded yet',
  'عميل معتمد': 'Verified client',
  'إدارة وتهيئة النظام (للمدير حصرياً)': 'System setup (admin only)',
  'يمكنك تهيئة وإعادة ضبط البيانات الحسابية الأساسية والتصنيفات والموردين الافتراضيين في أي وقت.':
      'You can seed or reset core data, categories, and default vendors at any time.',
  'تمت تهيئة البيانات الحسابية بنجاح!': 'Core data seeded successfully!',
  'تهيئة البيانات الحسابية الأساسية': 'Seed core data',
  'إدارة واعتماد موردي المنصة': 'Manage & approve vendors',
  'إضافة مورد جديد': 'Add vendor',
  'لا يوجد موردين مسجلين بعد. يمكنك إضافة مورد يدوياً أو انتظار تسجيل الموردين.':
      'No vendors yet. Add one manually or wait for registrations.',
  'نشط ومعتمد': 'Active & approved',
  'غير نشط (معطل)': 'Inactive (disabled)',
  'مرفوض': 'Rejected',
  'بانتظار الموافقة': 'Pending approval',
  'نشاط عام': 'General activity',
  'المقر: {a}': 'HQ: {a}',
  'قبول وتفعيل': 'Approve & activate',
  'رفض': 'Reject',
  'تغيير الحالة إلى: نشط': 'Set status: active',
  'تغيير الحالة إلى: غير نشط': 'Set status: inactive',
  'تغيير الحالة إلى: مرفوض': 'Set status: rejected',
  'حذف المورد نهائياً': 'Delete vendor permanently',
  'تغيير الحالة / إجراءات': 'Change status / actions',
  'إضافة مورد جديد يدوياً': 'Add a vendor manually',
  'اسم المورد ثلاثي': 'Vendor triple name',
  'رقم الهاتف': 'Phone number',
  'النشاط التجاري': 'Business activity',
  'تم إضافة المورد وتفعيله بنجاح!': 'Vendor added and activated!',
  'إضافة وتفعيل': 'Add & activate',
  'لا توجد أي طلبات مسجلة في المنصة بعد': 'No orders on the platform yet',
  'العميل: {n} ({p}) | المورد: {v}': 'Client: {n} ({p}) | Vendor: {v}',
  'العنوان: {a}': 'Address: {a}',
  'حذف الطلب': 'Delete order',
  'هل أنت متأكد من حذف الطلب {id} نهائياً؟': 'Are you sure you want to permanently delete order {id}?',
  'حذف': 'Delete',
  'إضافة تصنيف جديد للمنصة': 'Add a new platform category',
  'اسم التصنيف الجديد...': 'New category name...',
  'تم إضافة التصنيف بنجاح': 'Category added',
  'إضافة': 'Add',
  'التصنيفات المعتمدة حالياً': 'Current approved categories',
  '{p} - {a}': '{p} - {a}',
  '• {n} ({u}) × {q}': '• {n} ({u}) × {q}',
  '• {n} × {q} ({p})': '• {n} × {q} ({p})',
  // ---- commerce pass (auto-collected) ----
  'أداء العروض': 'Offers performance',
  'إضافة شريحة': 'Add tier',
  'إضافة شريحة سعرية': 'Add price tier',
  'اسم العميل': 'Client name',
  'الأصناف والكميات (تصفير الكمية يحذف الصنف)': 'Items & quantities (0 removes the item)',
  'التسعير المتدرج للكميات': 'Tiered bulk pricing',
  'السعر الأساسي (ج.م)': 'Base price (EGP)',
  'العنوان': 'Address',
  'الكمية من (مثال: 10)': 'From quantity (e.g. 10)',
  'بدون شرائح — سعر ثابت': 'No tiers — fixed price',
  'بدون شرائح — سعر ثابت لكل الكميات': 'No tiers — fixed price for all quantities',
  'بيانات العميل': 'Client info',
  'بيع': 'Sold',
  'تعديل': 'Edit',
  'تعديل السعر والشرائح': 'Edit price & tiers',
  'تعديل الطلب': 'Edit order',
  'تعذر الحفظ (راجع مخزون العروض)': 'Save failed (check offer stock)',
  'تم حفظ التعديلات': 'Changes saved',
  'تم حفظ تعديلات الطلب': 'Order updated',
  'حفظ التعديلات': 'Save changes',
  'سعر الوحدة (ج.م)': 'Unit price (EGP)',
  'شرائح الكميات': 'Quantity tiers',
  'لا توجد عروض حالياً': 'No offers yet',
  'هاتف العميل': 'Client phone',
  '💰 سعر متدرج حتى {price} للكميات': '💰 Tiered price down to {price} in bulk',
};
