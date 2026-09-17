import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../state/app_state.dart';
import '../../../core/constants/constants.dart';
import '../../../domain/entities/product_entity.dart';
import '../retailer/notifications_page.dart';
import '../../../core/l10n/app_strings.dart';

class VendorDashboard extends StatefulWidget {
  const VendorDashboard({super.key});

  @override
  State<VendorDashboard> createState() => _VendorDashboardState();
}

class _VendorDashboardState extends State<VendorDashboard> {
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
        content: Text(tr('هل تريد الخروج من لوحة حساب المورد؟')),
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
        final vendor = appState.currentUser;
        final status = vendor?.status ?? 'active';
        final isBlocked = status != 'active';

        return Scaffold(
          backgroundColor: AppColors.paper,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trArgs('لوحة المورد: {n}', {'n': vendor?.name ?? ''}), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                Text(
                  _vendorStatusText(status),
                  style: TextStyle(fontSize: 10, color: status == 'active' ? AppColors.brandLight : AppColors.amberSoft),
                ),
              ],
            ),
            backgroundColor: AppColors.brand,
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
              child: isBlocked
                  ? _buildBlockedNotice(status)
                  : IndexedStack(
                  index: _currentIndex,
                  children: [
                    _buildVendorOrdersTab(),
                    _buildVendorProductsTab(),
                    _buildVendorOffersTab(),
                    _buildVendorReportsTab(),
                    const NotificationsPage(),
                  ],
                ),
          ),
          ),
          bottomNavigationBar: isBlocked
              ? null
              : BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: (i) => setState(() => _currentIndex = i),
                  selectedItemColor: AppColors.brand,
                  unselectedItemColor: AppColors.inkSoft,
                  backgroundColor: AppColors.card,
                  type: BottomNavigationBarType.fixed,
                  selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  unselectedLabelStyle: const TextStyle(fontSize: 11),
                  items: [
                    BottomNavigationBarItem(icon: const Icon(Icons.receipt_long_outlined), activeIcon: const Icon(Icons.receipt_long), label: tr('طلباتي')),
                    BottomNavigationBarItem(icon: const Icon(Icons.inventory_2_outlined), activeIcon: const Icon(Icons.inventory_2), label: tr('الأصناف والمخزون')),
                    BottomNavigationBarItem(icon: const Icon(Icons.local_offer_outlined), activeIcon: const Icon(Icons.local_offer), label: tr('إدارة العروض')),
                    BottomNavigationBarItem(icon: const Icon(Icons.bar_chart_outlined), activeIcon: const Icon(Icons.bar_chart), label: tr('التقارير والأداء')),
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

  String _vendorStatusText(String status) {
    switch (status) {
      case 'pending':
        return tr('⚠️ الحساب قيد المراجعة والاعتماد');
      case 'inactive':
        return tr('⏸️ الحساب موقوف مؤقتاً');
      case 'rejected':
        return tr('⛔ تم رفض الحساب');
      default:
        return tr('حساب نشط ومعتمد');
    }
  }

  Widget _buildBlockedNotice(String status) {
    final title = status == 'rejected'
        ? tr('تم رفض طلب انضمامك')
        : status == 'inactive'
            ? tr('حسابك موقوف مؤقتاً')
            : tr('حسابك قيد مراجعة الإدارة');
    final body = status == 'rejected'
        ? tr('راجع مدير المنصة بيانات نشاطك التجاري وقرر رفض الطلب. يمكنك التواصل مع الإدارة لمعرفة السبب وإعادة التقديم.')
        : status == 'inactive'
            ? tr('قام مدير المنصة بإيقاف حسابك مؤقتاً. تواصل مع الإدارة لمراجعة الموقف وإعادة التفعيل.')
            : tr('شكراً لانضمامك إلى منصة وُفّرت. يقوم مدير المنصة بمراجعة بيانات نشاطك التجاري، وسيتم تفعيل حسابك فور الانتهاء.');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_empty_rounded, size: 70, color: AppColors.amber),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.inkSoft, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, foregroundColor: Colors.white),
              onPressed: () => appState.logout(),
              child: Text(tr('تسجيل الخروج والعودة لاحقاً')),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 1. تبويب الطلبات الفرعية الخاصة بالمورد فقط ───
  Widget _buildVendorOrdersTab() {
    final myOrders = appState.orders;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: myOrders.isEmpty
          ? Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.inbox_outlined, size: 50, color: AppColors.inkSoft),
              const SizedBox(height: 10),
              Text(tr('لا توجد طلبات واردة لك حتى الآن'), style: const TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.bold)),
            ],
          ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: myOrders.length,
              itemBuilder: (context, i) {
                final o = myOrders[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(trArgs('طلب رقم: {id}', {'id': o.id}), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.brand.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(orderStatusLabel(o.status), style: const TextStyle(color: AppColors.brandDeep, fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(trArgs('العميل: {n} | هاتف: {p}', {'n': o.clientName, 'p': o.clientPhone}), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      if (o.clientAddress != null)
                        Text(trArgs('العنوان التفصيلي: {a}', {'a': o.clientAddress}), style: const TextStyle(color: AppColors.inkSoft, fontSize: 11)),
                      const Divider(height: 14),
                      ...o.items.map((it) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('• ${it.product.name} (${it.product.unit}) × ${it.qty}', style: const TextStyle(fontSize: 12)),
                                Text(currency(it.unitPrice * it.qty), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          )),
                      const Divider(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(trArgs('المستحق لك: {t}', {'t': currency(o.total)}), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.brandDeep)),
                              Text(tr('الدفع: كاش عند الاستلام (COD)'), style: TextStyle(fontSize: 10, color: AppColors.inkSoft)),
                            ],
                          ),
                          DropdownButton<String>(
                            value: ['قيد المراجعة', 'مؤكد', 'جاري التجهيز', 'في الطريق', 'تم التسليم', 'مرفوض'].contains(o.status)
                                ? o.status
                                : 'قيد المراجعة',
                            items: ['قيد المراجعة', 'مؤكد', 'جاري التجهيز', 'في الطريق', 'تم التسليم', 'مرفوض']
                                .map((s) => DropdownMenuItem(value: s, child: Text(orderStatusLabel(s), style: const TextStyle(fontSize: 11)))).toList(),
                            onChanged: (newStatus) {
                              if (newStatus != null) appState.updateOrderStatus(o.id, newStatus);
                            },
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

  // ─── 2. تبويب الأصناف والمخزون مع دعم وحدات الجملة ورفع الصور ───
  Widget _buildVendorProductsTab() {
    final myProducts = appState.products;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: myProducts.isEmpty
          ? Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.inventory_2_outlined, size: 50, color: AppColors.inkSoft),
              const SizedBox(height: 10),
              Text(tr('لم تقم بإضافة أي أصناف بعد'), style: const TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.bold)),
            ],
          ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: myProducts.length,
              itemBuilder: (context, i) {
                final p = myProducts[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.brandLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: (p.imagePath != null && p.imagePath!.startsWith('http'))
                              ? Image.network(p.imagePath!, fit: BoxFit.cover, errorBuilder: (ctx, err, stack) => const Icon(Icons.inventory_2, color: AppColors.brand))
                              : (p.imagePath != null && File(p.imagePath!).existsSync())
                                  ? Image.file(File(p.imagePath!), fit: BoxFit.cover)
                                  : const Icon(Icons.inventory_2, color: AppColors.brand),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(trArgs('السعر: {p} / {u}', {'p': currency(p.price), 'u': unitLabel(p.unit)}), style: const TextStyle(color: AppColors.brandDeep, fontWeight: FontWeight.bold, fontSize: 12)),
                            Text(trArgs('القسم: {c} | الحد الأدنى: {m}', {'c': categoryLabel(p.category), 'm': p.minOrderQty}), style: const TextStyle(color: AppColors.inkSoft, fontSize: 10)),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppColors.brand, size: 20),
                            tooltip: tr('تعديل السعر والشرائح'),
                            onPressed: () => _showEditProductDialog(context, p),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                            onPressed: () => appState.deleteProduct(p.id),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(tr('إضافة صنف جديد')),
        onPressed: () => _showAddProductModal(context),
      ),
    );
  }

  void _showAddProductModal(BuildContext context) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final minQtyCtrl = TextEditingController(text: '1');
    final imageUrlCtrl = TextEditingController();
    final customUnitCtrl = TextEditingController();

    String selectedUnit = kWholesaleUnits.first;
    final validCategories = appState.categories.where((c) => c != 'الكل').toList();
    String selectedCat = validCategories.isNotEmpty ? validCategories.first : 'مواد غذائية';
    File? pickedFile;
    final tiers = <PriceTier>[];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.add_box, color: AppColors.brand),
                    const SizedBox(width: 8),
                    Text(tr('إضافة صنف جديد للمتجر'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(controller: nameCtrl, decoration: InputDecoration(labelText: tr('اسم الصنف التجاري'))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: tr('سعر بيع الجملة (ج.م)')))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: minQtyCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: tr('الحد الأدنى للطلب')))),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: kWholesaleUnits.contains(selectedUnit) ? selectedUnit : kWholesaleUnits.first,
                  items: kWholesaleUnits.map((u) => DropdownMenuItem(value: u, child: Text(unitLabel(u)))).toList(),
                  onChanged: (v) => setModalState(() => selectedUnit = v!),
                  decoration: InputDecoration(labelText: tr('وحدة بيع الجملة')),
                ),
                if (selectedUnit == 'أخرى (تحديد يدوي)') ...[
                  const SizedBox(height: 10),
                  TextField(controller: customUnitCtrl, decoration: InputDecoration(labelText: tr('اسم الوحدة المخصصة (مثال: طرد 24 قطعة)'))),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedCat,
                  items: validCategories.map((c) => DropdownMenuItem(value: c, child: Text(categoryLabel(c)))).toList(),
                  onChanged: (v) => setModalState(() => selectedCat = v!),
                  decoration: InputDecoration(labelText: tr('التصنيف')),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tr('التسعير المتدرج للكميات'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          TextButton.icon(
                            onPressed: () => _showAddTierDialog(ctx, tiers, setModalState),
                            icon: const Icon(Icons.add, size: 16),
                            label: Text(tr('إضافة شريحة'), style: const TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      if (tiers.isEmpty)
                        Text(
                          tr('بدون شرائح — سعر ثابت لكل الكميات'),
                          style: const TextStyle(fontSize: 11, color: AppColors.inkSoft),
                        )
                      else
                        Wrap(
                          spacing: 6,
                          children: [
                            for (final t in tiers)
                              Chip(
                                label: Text('≥ ${t.minQty} : ${currency(t.price)}', style: const TextStyle(fontSize: 11)),
                                deleteIcon: const Icon(Icons.close, size: 14),
                                onDeleted: () => setModalState(() => tiers.remove(t)),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(controller: imageUrlCtrl, decoration: InputDecoration(labelText: tr('رابط صورة المنتج (اختياري)'))),
                const SizedBox(height: 12),

                // رفع الصورة من استوديو الهاتف
                Row(
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.brand),
                      onPressed: () async {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(source: ImageSource.gallery);
                        if (picked != null) {
                          setModalState(() => pickedFile = File(picked.path));
                        }
                      },
                      icon: const Icon(Icons.photo_library),
                      label: Text(tr('رفع من استوديو الهاتف')),
                    ),
                    const SizedBox(width: 10),
                    if (pickedFile != null)
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 16),
                          const SizedBox(width: 4),
                          Text(tr('تم اختيار الصورة'), style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, foregroundColor: Colors.white),
                    onPressed: () {
                      if (nameCtrl.text.trim().isEmpty || priceCtrl.text.trim().isEmpty) return;
                      final finalUnit = selectedUnit == 'أخرى (تحديد يدوي)'
                          ? (customUnitCtrl.text.trim().isEmpty ? 'وحدة' : customUnitCtrl.text.trim())
                          : selectedUnit;

                      final imagePath = pickedFile?.path ?? (imageUrlCtrl.text.trim().isNotEmpty ? imageUrlCtrl.text.trim() : null);

                      appState.addProduct(ProductEntity(
                        id: 'prod_${DateTime.now().millisecondsSinceEpoch}',
                        vendorId: appState.currentUser?.id ?? 'vendor_1',
                        name: nameCtrl.text.trim(),
                        category: selectedCat,
                        price: double.tryParse(priceCtrl.text) ?? 0.0,
                        unit: finalUnit,
                        minOrderQty: int.tryParse(minQtyCtrl.text) ?? 1,
                        imagePath: imagePath,
                        priceTiers: List.unmodifiable(tiers),
                      ));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('تم حفظ الصنف بنجاح'))));
                    },
                    child: Text(tr('حفظ وإضافة الصنف'), style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddTierDialog(BuildContext context, List<PriceTier> tiers, void Function(void Function()) refresh) {
    final qtyCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(tr('إضافة شريحة سعرية'), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: tr('الكمية من (مثال: 10)'))),
            const SizedBox(height: 10),
            TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: tr('سعر الوحدة (ج.م)'))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('إلغاء'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, foregroundColor: Colors.white),
            onPressed: () {
              final q = int.tryParse(qtyCtrl.text) ?? 0;
              final pr = double.tryParse(priceCtrl.text) ?? 0.0;
              if (q <= 0 || pr <= 0) return;
              refresh(() {
                tiers.removeWhere((t) => t.minQty == q);
                tiers.add(PriceTier(minQty: q, price: pr));
                tiers.sort((a, b) => a.minQty.compareTo(b.minQty));
              });
              Navigator.pop(ctx);
            },
            child: Text(tr('إضافة')),
          ),
        ],
      ),
    );
  }

  void _showEditProductDialog(BuildContext context, ProductEntity p) {
    final priceCtrl = TextEditingController(text: p.price.toStringAsFixed(0));
    final minQtyCtrl = TextEditingController(text: p.minOrderQty.toString());
    final tiers = p.priceTiers.map((t) => PriceTier(minQty: t.minQty, price: t.price)).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.edit, color: AppColors.brand),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${tr('تعديل')}: ${p.name}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: tr('السعر الأساسي (ج.م)')))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: minQtyCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: tr('الحد الأدنى للطلب')))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(tr('شرائح الكميات'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    TextButton.icon(
                      onPressed: () => _showAddTierDialog(ctx, tiers, setModalState),
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(tr('إضافة شريحة'), style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                if (tiers.isEmpty)
                  Text(tr('بدون شرائح — سعر ثابت'), style: const TextStyle(fontSize: 11, color: AppColors.inkSoft))
                else
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final t in tiers)
                        Chip(
                          label: Text('≥ ${t.minQty} : ${currency(t.price)}', style: const TextStyle(fontSize: 11)),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () => setModalState(() => tiers.remove(t)),
                        ),
                    ],
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, foregroundColor: Colors.white),
                    onPressed: () {
                      appState.updateProduct(p.copyWith(
                        price: double.tryParse(priceCtrl.text) ?? p.price,
                        minOrderQty: int.tryParse(minQtyCtrl.text) ?? p.minOrderQty,
                        priceTiers: List.unmodifiable(tiers),
                      ));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('تم حفظ التعديلات'))));
                    },
                    child: Text(tr('حفظ التعديلات'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── 3. تبويب إدارة العروض وجدولة المواعيد والتفعيل التلقائي ───
  Widget _buildVendorOffersTab() {
    final myOffers = appState.products.where((p) => p.isOffer).toList();

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: myOffers.isEmpty
          ? Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_offer_outlined, size: 50, color: AppColors.inkSoft),
              const SizedBox(height: 10),
              Text(tr('لا توجد عروض مخصصة حالياً'), style: const TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, foregroundColor: Colors.white),
                onPressed: () => _showCreateOfferDialog(context),
                icon: const Icon(Icons.add),
                label: Text(tr('إنشاء وتجهيز عرض جديد')),
              ),
            ],
          ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(tr('العروض المجدولة والحالية'), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, foregroundColor: Colors.white),
                      onPressed: () => _showCreateOfferDialog(context),
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(tr('عرض جديد')),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...myOffers.map((offer) {
                  final isScheduled = offer.offerStartDate != null && DateTime.now().isBefore(offer.offerStartDate!);
                  final isExpired = (offer.offerEndDate != null && DateTime.now().isAfter(offer.offerEndDate!)) || offer.offerRemainingQty <= 0;

                  String badgeText = tr('عرض نشط 🔥');
                  Color badgeColor = Colors.green;
                  if (isScheduled) {
                    badgeText = tr('مجدول لتاريخ قادم ⏳');
                    badgeColor = AppColors.amber;
                  } else if (isExpired) {
                    badgeText = tr('منتهي (يعود للسعر الأصلي) ⚠️');
                    badgeColor = AppColors.danger;
                  }

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
                            Text(offer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                              child: Text(badgeText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(trArgs('سعر العرض: {o} (السعر الأصلي: {p}) / {u}', {'o': currency(offer.offerPrice), 'p': currency(offer.price), 'u': unitLabel(offer.unit)}),
                            style: const TextStyle(fontSize: 12, color: AppColors.brandDeep, fontWeight: FontWeight.bold)),
                        Text(trArgs('الكمية المتبقية: {r} من {t}', {'r': offer.offerRemainingQty, 't': offer.offerTotalQty}),
                            style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
                        if (offer.offerStartDate != null || offer.offerEndDate != null)
                          Text(
                            trArgs('الفترة: {s} إلى {e}', {'s': offer.offerStartDate != null ? formatEgyptDate(offer.offerStartDate!) : tr('الآن'), 'e': offer.offerEndDate != null ? formatEgyptDate(offer.offerEndDate!) : tr('حتى نفاذ الكمية')}),
                            style: const TextStyle(fontSize: 10, color: AppColors.inkSoft),
                          ),
                        const Divider(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => appState.deleteOffer(offer.id),
                              icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                              label: Text(tr('إلغاء العرض'), style: TextStyle(color: AppColors.danger, fontSize: 12)),
                            ),
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

  void _showCreateOfferDialog(BuildContext context) {
    final availableProducts = appState.products.where((p) => !p.isOffer).toList();
    if (availableProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('يرجى إضافة أصناف أولاً قبل عمل عروض عليها'))));
      return;
    }

    String selectedProdId = availableProducts.first.id;
    final offerPriceCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(tr('تجهيز وجدولة عرض جديد'), style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedProdId,
                  items: availableProducts.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                  onChanged: (v) => setDialogState(() => selectedProdId = v!),
                  decoration: InputDecoration(labelText: tr('اختر الصنف')),
                ),
                const SizedBox(height: 10),
                TextField(controller: offerPriceCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: tr('سعر العرض المخفض (ج.م)'))),
                const SizedBox(height: 10),
                TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: tr('الكمية الإجمالية المخصصة للعرض'))),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) setDialogState(() => startDate = picked);
                        },
                        child: Text(startDate == null ? tr('تاريخ البداية') : formatEgyptDate(startDate!), style: const TextStyle(fontSize: 11)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) setDialogState(() => endDate = picked);
                        },
                        child: Text(endDate == null ? tr('تاريخ النهاية') : formatEgyptDate(endDate!), style: const TextStyle(fontSize: 11)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('إلغاء'))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, foregroundColor: Colors.white),
              onPressed: () {
                final price = double.tryParse(offerPriceCtrl.text) ?? 0.0;
                final qty = int.tryParse(qtyCtrl.text) ?? 0;
                if (price <= 0 || qty <= 0) return;

                appState.createOffer(
                  selectedProdId,
                  price,
                  qty,
                  startDate: startDate,
                  endDate: endDate,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('تم تجهيز وتفعيل العرض بنجاح!'))));
              },
              child: Text(tr('تأكيد العرض')),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 4. تبويب تقارير وأداء المبيعات والعروض والعملاء للمورد ───
  Widget _buildVendorReportsTab() {
    final totalSales = appState.vendorTotalSales;
    final ordersCount = appState.vendorOrdersCount;
    final topItems = appState.vendorTopItems.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topClients = appState.vendorTopClients.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final myOffers = appState.products.where((p) => p.isOffer).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(tr('تقارير وأداء المبيعات والعروض'), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _reportCard(tr('إجمالي المبيعات المستحقة'), currency(totalSales), Icons.monetization_on_outlined, AppColors.brand)),
            const SizedBox(width: 12),
            Expanded(child: _reportCard(tr('عدد الطلبات الواردة'), trArgs('{n} طلب', {'n': ordersCount}), Icons.local_shipping_outlined, Colors.blue)),
          ],
        ),
        const SizedBox(height: 18),

        // الأصناف الأكثر مبيعاً
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.trending_up, color: AppColors.brand, size: 18),
                  const SizedBox(width: 8),
                  Text(tr('الأصناف الأكثر مبيعاً من منتجاتك'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const Divider(height: 16),
              if (topItems.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(tr('لا توجد مبيعات مسجلة حتى الآن'), style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                )
              else
                ...topItems.take(5).map((it) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(it.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      trailing: Text(trArgs('{n} وحدة مباعة', {'n': it.value}), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandDeep)),
                    )),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // أداء العروض (المباع مقابل المتبقي لكل عرض)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_offer, color: AppColors.amber, size: 18),
                  const SizedBox(width: 8),
                  Text(tr('أداء العروض'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const Divider(height: 16),
              if (myOffers.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(tr('لا توجد عروض حالياً'), style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                )
              else
                ...myOffers.map((offer) {
                  final sold = (offer.offerTotalQty - offer.offerRemainingQty).clamp(0, offer.offerTotalQty);
                  final pct = offer.offerTotalQty > 0 ? sold / offer.offerTotalQty : 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(offer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Text('${tr('بيع')}: $sold / ${offer.offerTotalQty}', style: const TextStyle(fontSize: 11, color: AppColors.inkSoft, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(value: pct, color: AppColors.amber, backgroundColor: Colors.grey.shade200, minHeight: 6),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // العملاء الأكثر شراءً
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.people_outline, color: AppColors.brand, size: 18),
                  const SizedBox(width: 8),
                  Text(tr('العملاء الأكثر شراءً من متجرك'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const Divider(height: 16),
              if (topClients.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(tr('لا يوجد طلبات عملاء حتى الآن'), style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                )
              else
                ...topClients.take(5).map((c) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(c.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      trailing: Text(currency(c.value), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brand)),
                    )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reportCard(String title, String value, IconData icon, Color color) {
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
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 10, color: AppColors.inkSoft, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}