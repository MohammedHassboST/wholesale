import 'package:flutter/material.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../core/constants/constants.dart';
import '../state/app_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 0: العميل أو صاحب المحل، 1: المورد، 2: مدير المنصة
  int selectedRoleIndex = 0;

  final phoneCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final shopCtrl = TextEditingController();
  final businessActivityCtrl = TextEditingController();
  final otpCtrl = TextEditingController();

  bool isRegisteringForVendor = false; // مورد جديد ينضم للمرة الأولى

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.brand,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الشعار والعنوان
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.brandLight,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.brand.withValues(alpha: 0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.storefront_rounded, size: 40, color: AppColors.brand),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'منصة وُفّرت - Waffart B2B',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.ink),
                    ),
                  ),
                  const Center(
                    child: Text(
                      'سوق الجملة الذكي ومنصة التجارة المتكاملة',
                      style: TextStyle(fontSize: 12, color: AppColors.inkSoft, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 1. شريط الاختيار المستقيم المقسم بالتساوي لـ 3 أدوار
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.line),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ink.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _buildRoleTab('العميل / المحل', 0, Icons.person_outline)),
                        const SizedBox(width: 4),
                        Expanded(child: _buildRoleTab('المورد', 1, Icons.business_outlined)),
                        const SizedBox(width: 4),
                        Expanded(child: _buildRoleTab('المدير', 2, Icons.admin_panel_settings_outlined)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. محتوى الحقول حسب الدور المختار
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.line),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ink.withValues(alpha: 0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (selectedRoleIndex == 2) ...[
                          // --- مسار المدير ---
                          const Row(
                            children: [
                              Icon(Icons.security, color: AppColors.brand, size: 20),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'دخول مدير المنصة (Super Admin)',
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            controller: phoneCtrl,
                            label: 'معرف المدير أو رقم الهاتف',
                            hint: '01000000000',
                            icon: Icons.badge_outlined,
                          ),
                          const SizedBox(height: 14),
                          _buildField(
                            controller: otpCtrl,
                            label: 'كلمة المرور / الكود الخاص (admin123)',
                            hint: '••••••••',
                            icon: Icons.lock_outline,
                            obscure: true,
                          ),
                        ] else if (selectedRoleIndex == 1) ...[
                          // --- مسار المورد ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  isRegisteringForVendor ? 'تسجيل حساب مورد جديد' : 'تسجيل دخول المورد الحالي',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() => isRegisteringForVendor = !isRegisteringForVendor);
                                },
                                child: Text(
                                  isRegisteringForVendor ? 'لديك حساب؟ سجل دخول' : 'مورد جديد؟ انضم الآن',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.brand),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildField(
                            controller: phoneCtrl,
                            label: 'رقم الهاتف (إجباري)',
                            hint: '01xxxxxxxxx',
                            icon: Icons.phone_outlined,
                            type: TextInputType.phone,
                          ),
                          const SizedBox(height: 14),
                          if (isRegisteringForVendor) ...[
                            _buildField(
                              controller: nameCtrl,
                              label: 'الاسم ثلاثي (إجباري)',
                              hint: 'أحمد محمد علي',
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 14),
                            _buildField(
                              controller: addressCtrl,
                              label: 'العنوان التفصيلي ومقر العمل (إجباري)',
                              hint: 'المنطقة الصناعية - العبور',
                              icon: Icons.location_on_outlined,
                            ),
                            const SizedBox(height: 14),
                            _buildField(
                              controller: businessActivityCtrl,
                              label: 'النشاط التجاري (إجباري)',
                              hint: 'تجارة مواد غذائية وزيوت بالجملة',
                              icon: Icons.storefront_outlined,
                            ),
                            const SizedBox(height: 14),
                          ],
                          _buildField(
                            controller: otpCtrl,
                            label: 'كود التأكيد / المرور (إجباري)',
                            hint: '123456',
                            icon: Icons.verified_user_outlined,
                            type: TextInputType.number,
                          ),
                        ] else ...[
                          // --- مسار العميل أو صاحب المحل ---
                          const Row(
                            children: [
                              Icon(Icons.shopping_bag_outlined, color: AppColors.brand, size: 20),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'تسجيل دخول العميل أو صاحب المحل',
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            controller: phoneCtrl,
                            label: 'رقم الهاتف (إجباري)',
                            hint: '01xxxxxxxxx',
                            icon: Icons.phone_outlined,
                            type: TextInputType.phone,
                          ),
                          const SizedBox(height: 14),
                          _buildField(
                            controller: nameCtrl,
                            label: 'الاسم بالكامل (إجباري)',
                            hint: 'محمد أحمد إبراهيم',
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 14),
                          _buildField(
                            controller: addressCtrl,
                            label: 'العنوان التفصيلي للاستلام (إجباري)',
                            hint: 'شارع الجمهورية - الجيزة',
                            icon: Icons.location_on_outlined,
                          ),
                          const SizedBox(height: 14),
                          _buildField(
                            controller: shopCtrl,
                            label: 'اسم المحل التجاري (اختياري)',
                            hint: 'سوبر ماركت الإخلاص',
                            icon: Icons.store_outlined,
                          ),
                          const SizedBox(height: 14),
                          _buildField(
                            controller: otpCtrl,
                            label: 'كود التأكيد (OTP)',
                            hint: '123456',
                            icon: Icons.lock_clock_outlined,
                            type: TextInputType.number,
                          ),
                        ],

                        const SizedBox(height: 24),

                        // زر التأكيد / الدخول
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brand,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: _handleLoginSubmit,
                            child: Text(
                              selectedRoleIndex == 1 && isRegisteringForVendor ? 'إرسال طلب الانضمام' : 'دخول / تأكيد الحساب',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => appState.toggleLocale(),
                      icon: const Icon(Icons.language, size: 16, color: AppColors.inkSoft),
                      label: Text(
                        appState.isRtl ? 'English' : 'عربي',
                        style: const TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTab(String title, int index, IconData icon) {
    bool isSelected = selectedRoleIndex == index;
    return GestureDetector(
      onTap: () => setState(() {
        selectedRoleIndex = index;
        phoneCtrl.clear();
        nameCtrl.clear();
        addressCtrl.clear();
        shopCtrl.clear();
        businessActivityCtrl.clear();
        otpCtrl.clear();
        isRegisteringForVendor = false;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brand : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.inkSoft),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.inkSoft,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? type,
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.ink)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: type,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 12, color: AppColors.inkSoft.withValues(alpha: 0.5)),
            prefixIcon: Icon(icon, color: AppColors.brand, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.brand, width: 2)),
            filled: true,
            fillColor: AppColors.paper,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }

  void _handleLoginSubmit() {
    final phone = phoneCtrl.text.trim();
    if (phone.isEmpty) {
      _showError('يرجى إدخال رقم الهاتف أو المعرف أولاً');
      return;
    }

    if (selectedRoleIndex == 2) {
      // 1. مسار المدير
      if (otpCtrl.text.trim() == 'admin123') {
        appState.login(UserEntity(
          id: 'super_admin_1',
          name: 'مدير المنصة',
          phone: phone,
          role: 'super_admin',
          status: 'active',
        ));
      } else {
        _showError('كود مرور المدير غير صحيح (استخدم: admin123)');
      }
    } else if (selectedRoleIndex == 1) {
      // 2. مسار المورد
      if (isRegisteringForVendor) {
        // حقول إجبارية للمورد الجديد: رقم الهاتف، الاسم ثلاثي، العنوان، النشاط التجاري، كود التأكيد
        if (nameCtrl.text.trim().isEmpty || addressCtrl.text.trim().isEmpty || businessActivityCtrl.text.trim().isEmpty || otpCtrl.text.trim().isEmpty) {
          _showError('جميع الحقول إجبارية للمورد الجديد (الهاتف، الاسم ثلاثي، العنوان، النشاط، الكود)');
          return;
        }

        final newVendor = UserEntity(
          id: 'vendor_$phone',
          name: nameCtrl.text.trim(),
          phone: phone,
          role: 'vendor',
          address: addressCtrl.text.trim(),
          businessActivity: businessActivityCtrl.text.trim(),
          shopName: businessActivityCtrl.text.trim(),
          status: 'pending', // يدخل بحالة بانتظار الموافقة من قبل المدير
        );

        appState.login(newVendor);
        _showSuccess('تم إرسال طلب الانضمام بنجاح! سيتم تفعيل حسابك فور مراجعة مدير المنصة');
      } else {
        // مورد له حساب بالفعل: رقم الهاتف والكود
        if (otpCtrl.text.trim().isEmpty) {
          _showError('يرجى إدخال كود التأكيد للدخول');
          return;
        }

        appState.login(UserEntity(
          id: 'vendor_$phone',
          name: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : 'مورد معتمد',
          phone: phone,
          role: 'vendor',
          status: 'active',
        ));
      }
    } else {
      // 3. مسار العميل أو صاحب المحل: إجباري الهاتف، الاسم، العنوان. أما اسم المحل اختياري.
      if (nameCtrl.text.trim().isEmpty || addressCtrl.text.trim().isEmpty) {
        _showError('الاسم بالكامل والعنوان التفصيلي إجباريان للعميل');
        return;
      }

      appState.login(UserEntity(
        id: 'client_$phone',
        name: nameCtrl.text.trim(),
        phone: phone,
        role: 'customer',
        address: addressCtrl.text.trim(),
        shopName: shopCtrl.text.trim().isEmpty ? null : shopCtrl.text.trim(),
        status: 'active',
      ));
    }
  }
}