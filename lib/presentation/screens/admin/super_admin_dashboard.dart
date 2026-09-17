import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../../core/constants/constants.dart';
import '../../../domain/entities/user_entity.dart';
import '../retailer/notifications_page.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../domain/entities/order_entity.dart';

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
        title: Row(
          children: [
            const Icon(Icons.logout, color: AppColors.danger),
            const SizedBox(width: 8),
            Text(tr('تسجيل الخروج'), style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        content: Text(tr('هل تريد الخروج من لوحة تحكم مدير المنصة؟')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('إلغاء'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              appState.logout();
            },
            child: Text(tr('نعم، الخروج'), style: const TextStyle(fontWeight: FontWeight.bold)),
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
            title: Text(tr('لوحة إدارة المنصة (Super Admin)'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            backgroundColor: AppColors.brandDeep,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.language),
                tooltip: tr('تغيير اللغة'),
                onPressed: () => appState.toggleLocale(),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: tr('تسجيل الخروج'),
                onPressed: () => _confirmLogout(context),
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: IndexedStack(
            index: _currentIndex,
            children: [
              _buildOverviewTab(),
              _buildVendorsManagementTab(),
              _buildAllOrdersTab(),
              _buildCategoriesManagementTab(),
              const NotificationsPage(),
            ],
          ),
          ),
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
            items: [
              BottomNavigationBarItem(icon: const Icon(Icons.analytics_outlined), activeIcon: const Icon(Icons.analytics), label: tr('التقارير الشاملة')),
              BottomNavigationBarItem(icon: const Icon(Icons.storefront_outlined), activeIcon: const Icon(Icons.storefront), label: tr('إدارة الموردين')),
              BottomNavigationBarItem(icon: const Icon(Icons.receipt_long_outlined), activeIcon: const Icon(Icons.receipt_long), label: tr('كافة الطلبات')),
              BottomNavigationBarItem(icon: const Icon(Icons.category_outlined), activeIcon: const Icon(Icons.category), label: tr('التصنيفات')),
              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications_outlined),
                    if (appState.unreadNotificationsCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                          child: Text(
                            '${appState.unreadNotificationsCount}',
                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
                activeIcon: const Icon(Icons.notifications),
                label: tr('الإشعارات'),
              ),
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
        Text(tr('نظرة عامة وتقارير المبيعات الشاملة'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),

        // بطاقات المؤشرات الأساسية
        Row(
          children: [
            Expanded(child: _metricCard(tr('إجمالي المبيعات'), currency(totalRevenue), Icons.payments_outlined, AppColors.brand)),
            const SizedBox(width: 12),
            Expanded(child: _metricCard(tr('إجمالي الطلبات'), trArgs('{n} طلب', {'n': totalOrdersCount}), Icons.shopping_bag_outlined, Colors.blue)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _metricCard(tr('الموردين المعتمدين'), trArgs('{n} مورد نشط', {'n': activeVendors}), Icons.store, AppColors.purple)),
            const SizedBox(width: 12),
            Expanded(child: _metricCard(tr('طلبات انضمام الموردين'), trArgs('{n} بانتظار الموافقة', {'n': totalVendorsCount - activeVendors}), Icons.hourglass_top, AppColors.amber)),
          ],
        ),
        const SizedBox(height: 20),

        // قائمة أفضل الموردين وأكثرهم بيعاً
        _buildReportSection(
          title: tr('أفضل الموردين وأكثرهم مبيعاً'),
          icon: Icons.leaderboard,
          child: topVendors.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(tr('لا توجد مبيعات مسجلة للموردين حتى الآن'), style: const TextStyle(color: AppColors.inkSoft)),
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
          title: tr('الأصناف الأكثر طلباً ومبيعاً'),
          icon: Icons.inventory_2_outlined,
          child: topProducts.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(tr('لم يتم بيع أي منتجات بعد'), style: const TextStyle(color: AppColors.inkSoft)),
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
                      trailing: Text(trArgs('{n} وحدة مباعة', {'n': entry.value}), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink)),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 16),

        // قائمة أفضل العملاء (الأكثر شراءً)
        _buildReportSection(
          title: tr('أفضل العملاء (الأعلى شراءً في المنصة)'),
          icon: Icons.verified_user_outlined,
          child: topClients.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(tr('لا يوجد طلبات عملاء مسجلة بعد'), style: const TextStyle(color: AppColors.inkSoft)),
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
                      subtitle: Text(tr('عميل معتمد'), style: const TextStyle(fontSize: 10, color: AppColors.inkSoft)),
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
              Row(
                children: [
                  const Icon(Icons.settings_suggest, color: AppColors.brand),
                  const SizedBox(width: 8),
                  Text(tr('إدارة وتهيئة النظام (للمدير حصرياً)'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                tr('يمكنك تهيئة وإعادة ضبط البيانات الحسابية الأساسية والتصنيفات والموردين الافتراضيين في أي وقت.'),
                style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
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
                      SnackBar(content: Text(tr('تمت تهيئة البيانات الحسابية بنجاح!'))),
                    );
                  },
                  icon: const Icon(Icons.cloud_sync),
                  label: Text(tr('تهيئة البيانات الحسابية الأساسية'), style: const TextStyle(fontWeight: FontWeight.bold)),
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
              Text(tr('إدارة واعتماد موردي المنصة'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, foregroundColor: Colors.white),
                onPressed: () => _showAddVendorDialog(context),
                icon: const Icon(Icons.person_add, size: 16),
                label: Text(tr('إضافة مورد جديد'), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (vendors.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
              child: Center(child: Text(tr('لا يوجد موردين مسجلين بعد. يمكنك إضافة مورد يدوياً أو انتظار تسجيل الموردين.'))),
            )
          else
            ...vendors.map((vendor) {
              Color statusColor;
              String statusText;
              switch (vendor.status) {
                case 'active':
                  statusColor = Colors.green;
                  statusText = tr('نشط ومعتمد');
                  break;
                case 'inactive':
                  statusColor = Colors.grey;
                  statusText = tr('غير نشط (معطل)');
                  break;
                case 'rejected':
                  statusColor = AppColors.danger;
                  statusText = tr('مرفوض');
                  break;
                default:
                  statusColor = AppColors.amber;
                  statusText = tr('بانتظار الموافقة');
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
                              Text(trArgs('{p} - {a}', {'p': vendor.phone, 'a': vendor.businessActivity ?? vendor.shopName ?? tr('نشاط عام')}),
                                  style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
                              if (vendor.address != null)
                                Text(trArgs('المقر: {a}', {'a': vendor.address}), style: const TextStyle(fontSize: 10, color: AppColors.inkSoft)),
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
                            label: Text(tr('قبول وتفعيل')),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
                            onPressed: () => appState.updateVendorStatus(vendor.id, 'rejected'),
                            icon: const Icon(Icons.close, size: 16),
                            label: Text(tr('رفض')),
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
                              PopupMenuItem(value: 'active', child: Text(tr('تغيير الحالة إلى: نشط'))),
                              PopupMenuItem(value: 'inactive', child: Text(tr('تغيير الحالة إلى: غير نشط'))),
                              PopupMenuItem(value: 'rejected', child: Text(tr('تغيير الحالة إلى: مرفوض'))),
                              const PopupMenuDivider(),
                              PopupMenuItem(value: 'delete', child: Text(tr('حذف المورد نهائياً'), style: const TextStyle(color: AppColors.danger))),
                            ],
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.paper,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.line),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.tune, size: 16, color: AppColors.inkSoft),
                                  const SizedBox(width: 4),
                                  Text(tr('تغيير الحالة / إجراءات'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
        title: Text(tr('إضافة مورد جديد يدوياً'), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: InputDecoration(labelText: tr('اسم المورد ثلاثي'))),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, decoration: InputDecoration(labelText: tr('رقم الهاتف')), keyboardType: TextInputType.phone),
              const SizedBox(height: 10),
              TextField(controller: addressCtrl, decoration: InputDecoration(labelText: tr('العنوان التفصيلي'))),
              const SizedBox(height: 10),
              TextField(controller: activityCtrl, decoration: InputDecoration(labelText: tr('النشاط التجاري'))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('إلغاء'))),
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
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('تم إضافة المورد وتفعيله بنجاح!'))));
            },
            child: Text(tr('إضافة وتفعيل')),
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
          ? Center(child: Text(tr('لا توجد أي طلبات مسجلة في المنصة بعد')))
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
                          Text(trArgs('طلب: {id}', {'id': o.id}), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                          DropdownButton<String>(
                            value: ['قيد المراجعة', 'مؤكد', 'جاري التجهيز', 'في الطريق', 'تم التسليم', 'مرفوض', 'ملغي'].contains(o.status)
                                ? o.status
                                : 'قيد المراجعة',
                            items: ['قيد المراجعة', 'مؤكد', 'جاري التجهيز', 'في الطريق', 'تم التسليم', 'مرفوض', 'ملغي']
                                .map((s) => DropdownMenuItem(value: s, child: Text(orderStatusLabel(s), style: const TextStyle(fontSize: 12)))).toList(),
                            onChanged: (newStatus) {
                              if (newStatus != null) {
                                appState.updateOrderStatus(o.id, newStatus);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(trArgs('العميل: {n} ({p}) | المورد: {v}', {'n': o.clientName, 'p': o.clientPhone, 'v': o.vendorId}),
                          style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
                      if (o.clientAddress != null)
                        Text(trArgs('العنوان: {a}', {'a': o.clientAddress}), style: const TextStyle(fontSize: 10, color: AppColors.inkSoft)),
                      const Divider(height: 12),
                      ...o.items.map((it) => Text(trArgs('• {n} × {q} ({p})', {'n': it.product.name, 'q': it.qty, 'p': currency(it.unitPrice)}), style: const TextStyle(fontSize: 12))),
                      const Divider(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(trArgs('الإجمالي: {t}', {'t': currency(o.total)}), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.brandDeep)),
                              Text(trArgs('طريقة الدفع: {m}', {'m': o.paymentMethod}), style: const TextStyle(fontSize: 10, color: AppColors.inkSoft)),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppColors.brand, size: 20),
                                tooltip: tr('تعديل الطلب'),
                                onPressed: () => _showEditOrderDialog(context, o),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                                tooltip: tr('حذف الطلب'),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text(tr('حذف الطلب')),
                                      content: Text(trArgs('هل أنت متأكد من حذف الطلب {id} نهائياً؟', {'id': o.id})),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('إلغاء'))),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            appState.deleteOrder(o.id);
                                          },
                                          child: Text(tr('حذف'), style: const TextStyle(color: AppColors.danger)),
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

  void _showEditOrderDialog(BuildContext context, OrderEntity o) {
    final nameCtrl = TextEditingController(text: o.clientName);
    final phoneCtrl = TextEditingController(text: o.clientPhone);
    final addressCtrl = TextEditingController(text: o.clientAddress ?? '');
    final qtyByProduct = {for (final it in o.items) it.product.id: it.qty};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('${tr('تعديل الطلب')} ${o.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('بيانات العميل'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                TextField(controller: nameCtrl, decoration: InputDecoration(labelText: tr('اسم العميل'))),
                const SizedBox(height: 8),
                TextField(controller: phoneCtrl, decoration: InputDecoration(labelText: tr('هاتف العميل'))),
                const SizedBox(height: 8),
                TextField(controller: addressCtrl, decoration: InputDecoration(labelText: tr('العنوان'))),
                const SizedBox(height: 16),
                Text(tr('الأصناف والكميات (تصفير الكمية يحذف الصنف)'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                ...o.items.map((it) {
                  final q = qtyByProduct[it.product.id] ?? it.qty;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(child: Text('${it.product.name} (${currency(it.unitPrice)})', style: const TextStyle(fontSize: 12))),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, size: 20, color: AppColors.danger),
                          onPressed: q <= 0 ? null : () => setDialogState(() => qtyByProduct[it.product.id] = q - 1),
                        ),
                        Text('$q', style: const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 20, color: AppColors.brand),
                          onPressed: () => setDialogState(() => qtyByProduct[it.product.id] = q + 1),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('إلغاء'))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, foregroundColor: Colors.white),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(ctx);
                try {
                  await appState.editOrder(
                    o.id,
                    itemsQty: qtyByProduct,
                    clientName: nameCtrl.text.trim(),
                    clientPhone: phoneCtrl.text.trim(),
                    clientAddress: addressCtrl.text.trim(),
                  );
                  navigator.pop();
                  messenger.showSnackBar(SnackBar(content: Text(tr('تم حفظ تعديلات الطلب'))));
                } catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text('${tr('تعذر الحفظ (راجع مخزون العروض)')}: $e'), backgroundColor: AppColors.danger));
                }
              },
              child: Text(tr('حفظ التعديلات')),
            ),
          ],
        ),
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
                Text(tr('إضافة تصنيف جديد للمنصة'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: catCtrl,
                        decoration: InputDecoration(
                          hintText: tr('اسم التصنيف الجديد...'),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('تم إضافة التصنيف بنجاح'))));
                        }
                      },
                      child: Text(tr('إضافة')),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(tr('التصنيفات المعتمدة حالياً'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
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
                      Text(categoryLabel(c), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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