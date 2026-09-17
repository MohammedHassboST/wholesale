import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../../core/constants/constants.dart';
import '../../../domain/entities/user_entity.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  int _currentIndex = 0;

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: AppColors.danger),
            SizedBox(width: 8),
            Text('تسجيل الخروج', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        content: const Text('هل تريد الخروج من لوحة تحكم مدير المنصة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              appState.logout();
            },
            child: const Text('نعم، الخروج', style: TextStyle(fontWeight: FontWeight.bold)),
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
        return Scaffold(
          backgroundColor: AppColors.paper,
          appBar: AppBar(
            title: const Text('لوحة إدارة المنصة (Super Admin)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            backgroundColor: AppColors.brandDeep,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.language),
                tooltip: 'تغيير اللغة',
                onPressed: () => appState.toggleLocale(),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'تسجيل الخروج',
                onPressed: () => _confirmLogout(context),
              ),
            ],
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: [
              _buildOverviewTab(),
              _buildVendorsManagementTab(),
              _buildAllOrdersTab(),
              _buildCategoriesManagementTab(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            selectedItemColor: AppColors.brand,
            unselectedItemColor: AppColors.inkSoft,
            backgroundColor: AppColors.card,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics), label: 'التقارير الشاملة'),
              BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), activeIcon: Icon(Icons.storefront), label: 'إدارة الموردين'),
              BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'كافة الطلبات'),
              BottomNavigationBarItem(icon: Icon(Icons.category_outlined), activeIcon: Icon(Icons.category), label: 'التصنيفات'),
            ],
          ),
        );
      },
    );
  }

  // ─── 1. تبويب النظرة العامة والتقارير المفصلة ───
  Widget _buildOverviewTab() {
    final totalRevenue = appState.totalPlatformRevenue;
    final totalOrdersCount = appState.totalPlatformOrders;
    final totalVendorsCount = appState.vendors.length;
    final activeVendors = appState.vendors.where((v) => v.isApproved).length;

    final topVendors = appState.vendorSalesMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topProducts = appState.topProductsMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topClients = appState.topClientsMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('نظرة عامة وتقارير المبيعات الشاملة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),

        // بطاقات المؤشرات الأساسية
        Row(
          children: [
            Expanded(child: _metricCard('إجمالي المبيعات', currency(totalRevenue), Icons.payments_outlined, AppColors.brand)),
            const SizedBox(width: 12),
            Expanded(child: _metricCard('إجمالي الطلبات', '$totalOrdersCount طلب', Icons.shopping_bag_outlined, Colors.blue)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _metricCard('الموردين المعتمدين', '$activeVendors مورد نشط', Icons.store, AppColors.purple)),
            const SizedBox(width: 12),
            Expanded(child: _metricCard('طلبات انضمام الموردين', '${totalVendorsCount - activeVendors} بانتظار الموافقة', Icons.hourglass_top, AppColors.amber)),
          ],
        ),
        const SizedBox(height: 20),

        // قائمة أفضل الموردين وأكثرهم بيعاً
        _buildReportSection(
          title: 'أفضل الموردين وأكثرهم مبيعاً',
          icon: Icons.leaderboard,
          child: topVendors.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('لا توجد مبيعات مسجلة للموردين حتى الآن', style: TextStyle(color: AppColors.inkSoft)),
                )
              : Column(
                  children: topVendors.take(5).map((entry) {
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppColors.brandLight,
                        child: Text('${topVendors.indexOf(entry) + 1}', style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Text(currency(entry.value), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.brandDeep)),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 16),

        // قائمة أكثر الأصناف مبيعاً
        _buildReportSection(
          title: 'الأصناف الأكثر طلباً ومبيعاً',
          icon: Icons.inventory_2_outlined,
          child: topProducts.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('لم يتم بيع أي منتجات بعد', style: TextStyle(color: AppColors.inkSoft)),
                )
              : Column(
                  children: topProducts.take(5).map((entry) {
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.amberSoft,
                        child: Icon(Icons.star, color: AppColors.amber, size: 18),
                      ),
                      title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Text('${entry.value} وحدة مباعة', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink)),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 16),

        // قائمة أفضل العملاء (الأكثر شراءً)
        _buildReportSection(
          title: 'أفضل العملاء (الأعلى شراءً في المنصة)',
          icon: Icons.verified_user_outlined,
          child: topClients.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('لا يوجد طلبات عملاء مسجلة بعد', style: TextStyle(color: AppColors.inkSoft)),
                )
              : Column(
                  children: topClients.take(5).map((entry) {
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppColors.brandLight,
                        child: const Icon(Icons.person, color: AppColors.brand, size: 18),
                      ),
                      title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('عميل معتمد', style: TextStyle(fontSize: 10, color: AppColors.inkSoft)),
                      trailing: Text(currency(entry.value), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.brand)),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 20),

        // زر تهيئة البيانات الحسابية (خاص بالمدير فقط ومحذوف من المورد)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.settings_suggest, color: AppColors.brand),
                  SizedBox(width: 8),
                  Text('إدارة وتهيئة النظام (للمدير حصرياً)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'يمكنك تهيئة وإعادة ضبط البيانات الحسابية الأساسية والتصنيفات والموردين الافتراضيين في أي وقت.',
                style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandDeep,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await appState.seedInitialData();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('تمت تهيئة البيانات الحسابية بنجاح!')),
                    );
                  },
                  icon: const Icon(Icons.cloud_sync),
                  label: const Text('تهيئة البيانات الحسابية الأساسية', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(color: AppColors.ink.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 11, color: AppColors.inkSoft, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildReportSection({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.brand, size: 18),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const Divider(height: 16),
          child,
        ],
      ),
    );
  }

  // ─── 2. تبويب إدارة الموردين (قبول، رفض، نشط، غير نشط، حذف، إضافة مورد) ───
  Widget _buildVendorsManagementTab() {
    final vendors = appState.vendors;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('إدارة واعتماد موردي المنصة', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, foregroundColor: Colors.white),
                onPressed: () => _showAddVendorDialog(context),
                icon: const Icon(Icons.person_add, size: 16),
                label: const Text('إضافة مورد جديد', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (vendors.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
              child: const Center(child: Text('لا يوجد موردين مسجلين بعد. يمكنك إضافة مورد يدوياً أو انتظار تسجيل الموردين.')),
            )
          else
            ...vendors.map((vendor) {
              Color statusColor;
              String statusText;
              switch (vendor.status) {
                case 'active':
                  statusColor = Colors.green;
                  statusText = 'نشط ومعتمد';
                  break;
                case 'inactive':
                  statusColor = Colors.grey;
                  statusText = 'غير نشط (معطل)';
                  break;
                case 'rejected':
                  statusColor = AppColors.danger;
                  statusText = 'مرفوض';
                  break;
                default:
                  statusColor = AppColors.amber;
                  statusText = 'بانتظار الموافقة';
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: vendor.isPending ? AppColors.amber : AppColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: vendor.isPending ? AppColors.amberSoft : AppColors.brandLight,
                          child: Icon(Icons.store, color: vendor.isPending ? AppColors.amber : AppColors.brand),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(vendor.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('${vendor.phone} - ${vendor.businessActivity ?? vendor.shopName ?? "نشاط عام"}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
                              if (vendor.address != null)
                                Text('المقر: ${vendor.address}', style: const TextStyle(fontSize: 10, color: AppColors.inkSoft)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(statusText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (vendor.isPending) ...[
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.green, side: const BorderSide(color: Colors.green)),
                            onPressed: () => appState.updateVendorStatus(vendor.id, 'active'),
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('قبول وتفعيل'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
                            onPressed: () => appState.updateVendorStatus(vendor.id, 'rejected'),
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text('رفض'),
                          ),
                        ] else ...[
                          PopupMenuButton<String>(
                            onSelected: (val) {
                              if (val == 'delete') {
                                appState.deleteVendor(vendor.id);
                              } else {
                                appState.updateVendorStatus(vendor.id, val);
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 'active', child: Text('تغيير الحالة إلى: نشط')),
                              const PopupMenuItem(value: 'inactive', child: Text('تغيير الحالة إلى: غير نشط')),
                              const PopupMenuItem(value: 'rejected', child: Text('تغيير الحالة إلى: مرفوض')),
                              const PopupMenuDivider(),
                              const PopupMenuItem(value: 'delete', child: Text('حذف المورد نهائياً', style: TextStyle(color: AppColors.danger))),
                            ],
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.paper,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.line),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.tune, size: 16, color: AppColors.inkSoft),
                                  SizedBox(width: 4),
                                  Text('تغيير الحالة / إجراءات', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  void _showAddVendorDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final activityCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('إضافة مورد جديد يدوياً', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم المورد ثلاثي')),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'رقم الهاتف'), keyboardType: TextInputType.phone),
              const SizedBox(height: 10),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'العنوان التفصيلي')),
              const SizedBox(height: 10),
              TextField(controller: activityCtrl, decoration: const InputDecoration(labelText: 'النشاط التجاري')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, foregroundColor: Colors.white),
            onPressed: () {
              if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty) return;
              final vendor = UserEntity(
                id: 'vendor_${phoneCtrl.text.trim()}',
                name: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                role: 'vendor',
                address: addressCtrl.text.trim(),
                businessActivity: activityCtrl.text.trim(),
                status: 'active',
              );
              appState.addVendorByAdmin(vendor);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة المورد وتفعيله بنجاح!')));
            },
            child: const Text('إضافة وتفعيل'),
          ),
        ],
      ),
    );
  }

  // ─── 3. تبويب كافة الطلبات لجميع الموردين والعملاء (تعديل، حذف، تغيير الحالة) ───
  Widget _buildAllOrdersTab() {
    final allOrders = appState.orders;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: allOrders.isEmpty
          ? const Center(child: Text('لا توجد أي طلبات مسجلة في المنصة بعد'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: allOrders.length,
              itemBuilder: (context, i) {
                final o = allOrders[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('طلب: ${o.id}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                          DropdownButton<String>(
                            value: ['قيد المراجعة', 'مؤكد', 'جاري التجهيز', 'في الطريق', 'تم التسليم', 'مرفوض', 'ملغي'].contains(o.status)
                                ? o.status
                                : 'قيد المراجعة',
                            items: ['قيد المراجعة', 'مؤكد', 'جاري التجهيز', 'في الطريق', 'تم التسليم', 'مرفوض', 'ملغي']
                                .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12)))).toList(),
                            onChanged: (newStatus) {
                              if (newStatus != null) {
                                appState.updateOrderStatus(o.id, newStatus);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('العميل: ${o.clientName} (${o.clientPhone}) | المورد: ${o.vendorId}',
                          style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
                      if (o.clientAddress != null)
                        Text('العنوان: ${o.clientAddress}', style: const TextStyle(fontSize: 10, color: AppColors.inkSoft)),
                      const Divider(height: 12),
                      ...o.items.map((it) => Text('• ${it.product.name} × ${it.qty} (${currency(it.unitPrice)})', style: const TextStyle(fontSize: 12))),
                      const Divider(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('الإجمالي: ${currency(o.total)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.brandDeep)),
                              Text('طريقة الدفع: ${o.paymentMethod}', style: const TextStyle(fontSize: 10, color: AppColors.inkSoft)),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                                tooltip: 'حذف الطلب',
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('حذف الطلب'),
                                      content: Text('هل أنت متأكد من حذف الطلب ${o.id} نهائياً؟'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            appState.deleteOrder(o.id);
                                          },
                                          child: const Text('حذف', style: TextStyle(color: AppColors.danger)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // ─── 4. تبويب التصنيفات (حصرية للمدير للإضافة والحذف) ───
  Widget _buildCategoriesManagementTab() {
    final categories = appState.categories;
    final catCtrl = TextEditingController();

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('إضافة تصنيف جديد للمنصة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: catCtrl,
                        decoration: const InputDecoration(
                          hintText: 'اسم التصنيف الجديد...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, foregroundColor: Colors.white),
                      onPressed: () {
                        if (catCtrl.text.trim().isNotEmpty) {
                          appState.addCategory(catCtrl.text.trim());
                          catCtrl.clear();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة التصنيف بنجاح')));
                        }
                      },
                      child: const Text('إضافة'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('التصنيفات المعتمدة حالياً', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          const SizedBox(height: 10),
          ...categories.map((c) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.folder_outlined, color: AppColors.brand, size: 20),
                      const SizedBox(width: 10),
                      Text(c, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  if (c != 'الكل')
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 18),
                      onPressed: () => appState.deleteCategory(c),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}