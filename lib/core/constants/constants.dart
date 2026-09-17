import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  static const ink = Color(0xFF0F172A);
  static const inkSoft = Color(0xFF64748B);
  static const paper = Color(0xFFF8FAFC);
  static const card = Color(0xFFFFFFFF);
  static const line = Color(0xFFE2E8F0);
  static const brand = Color(0xFF059669);
  static const brandDeep = Color(0xFF064E3B);
  static const brandLight = Color(0xFFD1FAE5);
  static const amber = Color(0xFFF59E0B);
  static const amberSoft = Color(0xFFFEF3C7);
  static const danger = Color(0xFFDC2626);
  static const dangerSoft = Color(0xFFFEE2E2);
  static const dangerLight = Color(0xFFFEF2F2);
  static const purple = Color(0xFF7C3AED);
  static const purpleSoft = Color(0xFFEDE9FE);
}

const List<String> kWholesaleUnits = [
  'كرتونة',
  'قطعة',
  'دستة',
  'شكارة / شوال',
  'طرد / باكت',
  'صندوق',
  'علبة / كيس',
  'جالون',
  'برميل',
  'كيلو',
  'طن',
  'أخرى (تحديد يدوي)',
];


String currency(double n) {
  return '${n.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')} ج.م';
}

// ========== توقيت مصر العالمي (EET/EEST) ==========
DateTime _toEgyptTime(DateTime date) {
  final utc = date.toUtc();
  final year = utc.year;

  // بداية التوقيت الصيفي: الجمعة الأخيرة من أبريل
  var dstStart = DateTime.utc(year, 4, 30);
  while (dstStart.weekday != DateTime.friday) {
    dstStart = dstStart.subtract(const Duration(days: 1));
  }
  // يبدأ في الساعة 12 منتصف الليل (التي تصبح الواحدة صباحاً)
  dstStart = DateTime.utc(year, 4, dstStart.day, 0, 0);

  // نهاية التوقيت الصيفي: الخميس الأخير من أكتوبر
  var dstEnd = DateTime.utc(year, 10, 31);
  while (dstEnd.weekday != DateTime.thursday) {
    dstEnd = dstEnd.subtract(const Duration(days: 1));
  }
  // ينتهي في الساعة 11:59 مساءً (التي تصبح 11:00 مساءً أو ما شابه)
  dstEnd = DateTime.utc(year, 10, dstEnd.day, 23, 59);

  final isDST = utc.isAfter(dstStart) && utc.isBefore(dstEnd);
  return utc.add(Duration(hours: isDST ? 3 : 2));
}

DateTime getEgyptTime() {
  return _toEgyptTime(DateTime.now());
}

String formatEgyptDate(DateTime dt) {
  final egypt = _toEgyptTime(dt);
  final months = [
    'يناير', 'فبراير', 'مارس', 'إبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
  ];
  return '${egypt.day} ${months[egypt.month - 1]} ${egypt.year}';
}

String formatEgyptDateTime(DateTime dt) {
  final egypt = _toEgyptTime(dt);
  final months = [
    'يناير', 'فبراير', 'مارس', 'إبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
  ];
  final hour = egypt.hour.toString().padLeft(2, '0');
  final minute = egypt.minute.toString().padLeft(2, '0');
  return '${egypt.day} ${months[egypt.month - 1]} ${egypt.year} - $hour:$minute';
}

// ========== التحقق من Gmail ==========
bool isValidGmail(String email) {
  return RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$').hasMatch(email.trim());
}

void setSystemUI() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFFF8FAFC),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
}