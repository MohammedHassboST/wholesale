import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../../core/constants/constants.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد أنك تريد الخروج من حسابك؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              appState.logout(); // تنفيذ تسجيل الخروج والعودة لشاشة الدخول تلقائياً
            },
            child: const Text(
              'تأكيد الخروج',
              style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final user = appState.currentUser;
        return Scaffold(
          backgroundColor: AppColors.paper,
          appBar: AppBar(
            title: const Text('حساب العميل / صاحب المحل', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            backgroundColor: AppColors.brandDeep,
            foregroundColor: Colors.white,
            centerTitle: true,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // بطاقة بيانات العميل الأساسية
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.brandLight,
                          child: Icon(Icons.storefront, size: 30, color: AppColors.brand),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name ?? 'مستخدم',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.phone ?? '',
                                style: const TextStyle(color: AppColors.inkSoft, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('اسم المحل التجاري (اختياري)', style: TextStyle(color: AppColors.inkSoft, fontSize: 11)),
                      subtitle: Text(user?.shopName ?? 'غير مسجل', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('العنوان التفصيلي', style: TextStyle(color: AppColors.inkSoft, fontSize: 11)),
                      subtitle: Text(user?.address ?? 'غير محدد', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // بطاقة خيارات الحساب وتسجيل الخروج
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.logout, color: AppColors.danger),
                      title: const Text('تسجيل الخروج من الحساب', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.danger),
                      onTap: () => _confirmLogout(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}