import 'package:flutter/material.dart';
import '../../../domain/entities/product_entity.dart';
import '../../state/app_state.dart';
import '../../../core/constants/constants.dart';
import 'admin_orders.dart';
import 'admin_products.dart';
import 'account_info_page.dart';
import '../vendor/manage_offers_page.dart';
import '../vendor/manage_products_page.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  void _seedDatabase(BuildContext context) async {
    try {
      final seedProducts = [
        ProductEntity(id: '1', vendorId: 'vendor_1', name: 'زيت عباد الشمس 1 لتر', category: 'مواد غذائية', price: 480, unit: 'كرتونة', isOffer: true, offerPrice: 410, offerTotalQty: 40, offerRemainingQty: 9),
        ProductEntity(id: '2', vendorId: 'vendor_1', name: 'أرز أبيض 5 كيلو', category: 'مواد غذائية', price: 210, unit: 'كيس'),
      ];

      for (var p in seedProducts) {
        await appState.addProduct(p);
      }
      appState.addCategory('مواد غذائية');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التهيئة بنجاح!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final totalOrders = appState.orders.length;
        final pending = appState.orders.where((o) => o.status == 'قيد المراجعة').length;

        return Scaffold(
          backgroundColor: AppColors.paper,
          appBar: AppBar(title: const Text('لوحة التحكم', style: TextStyle(fontWeight: FontWeight.w900)), centerTitle: true),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    _statCard('الطلبات', '$totalOrders', Icons.receipt_long, AppColors.brand, AppColors.brandLight, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminOrdersPage()));
                    }),
                    _statCard('بانتظار المراجعة', '$pending', Icons.pending_actions, AppColors.amber, AppColors.amberSoft, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminOrdersPage(initialFilter: 'قيد المراجعة')));
                    }),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => _seedDatabase(context),
                  icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                  label: const Text('تهيئة البيانات السحابية'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.brand),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    children: [
                      _actionTile(Icons.local_offer, AppColors.amber, AppColors.amberSoft, 'إدارة العروض', 'إدارة عروض المنتجات', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageOffersPage()))),
                      const Divider(height: 1),
                      _actionTile(Icons.add_box, AppColors.brand, AppColors.brandLight, 'إدارة الأصناف', 'إضافة وتعديل الأصناف', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageProductsPage()))),
                      const Divider(height: 1),
                      _actionTile(Icons.inventory, Colors.blue, Colors.blue.shade50, 'إدارة المخزون', 'تعديل كميات الأصناف', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminProductsPage()))),
                      const Divider(height: 1),
                      _actionTile(Icons.person, Colors.purple, Colors.purple.shade50, 'بيانات الحساب', 'تعديل البيانات الشخصية', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountInfoPage()))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color, Color bgColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
              Text(title, style: TextStyle(fontSize: 11, color: AppColors.inkSoft.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _actionTile(IconData icon, Color color, Color bgColor, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.inkSoft.withValues(alpha: 0.7))),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
    );
  }
}