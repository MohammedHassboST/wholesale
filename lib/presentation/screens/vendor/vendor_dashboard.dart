import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../state/app_state.dart';
import '../../../core/constants/constants.dart';
import '../../../domain/entities/product_entity.dart';

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
        title: const Row(
          children: [
            Icon(Icons.logout, color: AppColors.danger),
            SizedBox(width: 8),
            Text('تسجيل الخروج', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        content: const Text('هل تريد الخروج من لوحة حساب المورد؟'),
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
        final vendor = appState.currentUser;
        final isPending = vendor?.status == 'pending';

        return Scaffold(
          backgroundColor: AppColors.paper,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('لوحة المورد: ${vendor?.name ?? ""}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                Text(
                  isPending ? '⚠️ الحساب قيد المراجعة والاعتماد' : 'حساب نشط ومعتمد',
                  style: TextStyle(fontSize: 10, color: isPending ? AppColors.amberSoft : AppColors.brandLight),
                ),
              ],
            ),
            backgroundColor: AppColors.brand,
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
          body: isPending
              ? _buildPendingNotice()
              : IndexedStack(
                  index: _currentIndex,
                  children: [
                    _buildVendorOrdersTab(),
                    _buildVendorProductsTab(),
                    _buildVendorOffersTab(),
                    _buildVendorReportsTab(),
                  ],
                ),
          bottomNavigationBar: isPending
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
                  items: const [
                    BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'طلباتي'),
                    BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), activeIcon: Icon(Icons.inventory_2), label: 'الأصناف والمخزون'),
                    BottomNavigationBarItem(icon: Icon(Icons.local_offer_outlined), activeIcon: Icon(Icons.local_offer), label: 'إدارة العروض'),
                    BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: 'التقارير والأداء'),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildPendingNotice() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_empty_rounded, size: 70, color: AppColors.amber),
            const SizedBox(height: 16),
            const Text(
              'حسابك قيد مراجعة الإدارة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'شكراً لانضمامك إلى منصة وُفّرت. يقوم مدير المنصة بمراجعة بيانات نشاطك التجاري، وسيتم تفعيل حسابك فور الانتهاء.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.inkSoft, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, foregroundColor: Colors.white),
              onPressed: () => appState.logout(),
              child: const Text('تسجيل الخروج والعودة لاحقاً'),
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
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 50, color: AppColors.inkSoft),
                  SizedBox(height: 10),
                  Text('لا توجد طلبات واردة لك حتى الآن', style: TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.bold)),
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
                          Text('طلب رقم: ${o.id}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.brand.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(o.status, style: const TextStyle(color: AppColors.brandDeep, fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('العميل: ${o.clientName} | هاتف: ${o.clientPhone}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      if (o.clientAddress != null)
                        Text('العنوان التفصيلي: ${o.clientAddress}', style: const TextStyle(color: AppColors.inkSoft, fontSize: 11)),
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
                              Text('المستحق لك: ${currency(o.total)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.brandDeep)),
                              const Text('الدفع: كاش عند الاستلام (COD)', style: TextStyle(fontSize: 10, color: AppColors.inkSoft)),
                            ],
                          ),
                          DropdownButton<String>(
                            value: ['قيد المراجعة', 'مؤكد', 'جاري التجهيز', 'في الطريق', 'تم التسليم', 'مرفوض'].contains(o.status)
                                ? o.status
                                : 'قيد المراجعة',
                            items: ['قيد المراجعة', 'مؤكد', 'جاري التجهيز', 'في الطريق', 'تم التسليم', 'مرفوض']
                                .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 11)))).toList(),
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
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 50, color: AppColors.inkSoft),
                  SizedBox(height: 10),
                  Text('لم تقم بإضافة أي أصناف بعد', style: TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.bold)),
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
                            Text('السعر: ${currency(p.price)} / ${p.unit}', style: const TextStyle(color: AppColors.brandDeep, fontWeight: FontWeight.bold, fontSize: 12)),
                            Text('القسم: ${p.category} | الحد الأدنى: ${p.minOrderQty}', style: const TextStyle(color: AppColors.inkSoft, fontSize: 10)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                        onPressed: () => appState.deleteProduct(p.id),
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
        label: const Text('إضافة صنف جديد'),
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
                const Row(
                  children: [
                    Icon(Icons.add_box, color: AppColors.brand),
                    SizedBox(width: 8),
                    Text('إضافة صنف جديد للمتجر', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم الصنف التجاري')),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعر بيع الجملة (ج.م)'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: minQtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الحد الأدنى للطلب'))),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: kWholesaleUnits.contains(selectedUnit) ? selectedUnit : kWholesaleUnits.first,
                  items: kWholesaleUnits.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                  onChanged: (v) => setModalState(() => selectedUnit = v!),
                  decoration: const InputDecoration(labelText: 'وحدة بيع الجملة'),
                ),
                if (selectedUnit == 'أخرى (تحديد يدوي)') ...[
                  const SizedBox(height: 10),
                  TextField(controller: customUnitCtrl, decoration: const InputDecoration(labelText: 'اسم الوحدة المخصصة (مثال: طرد 24 قطعة)')),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedCat,
                  items: validCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setModalState(() => selectedCat = v!),
                  decoration: const InputDecoration(labelText: 'التصنيف'),
                ),
                const SizedBox(height: 12),
                TextField(controller: imageUrlCtrl, decoration: const InputDecoration(labelText: 'رابط صورة المنتج (اختياري)')),
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
                      label: const Text('رفع من استوديو الهاتف'),
                    ),
                    const SizedBox(width: 10),
                    if (pickedFile != null)
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 16),
                          SizedBox(width: 4),
                          Text('تم اختيار الصورة', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
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
                      ));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الصنف بنجاح')));
                    },
                    child: const Text('حفظ وإضافة الصنف', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  const Text('لا توجد عروض مخصصة حالياً', style: TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, foregroundColor: Colors.white),
                    onPressed: () => _showCreateOfferDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('إنشاء وتجهيز عرض جديد'),
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
                    const Text('العروض المجدولة والحالية', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, foregroundColor: Colors.white),
                      onPressed: () => _showCreateOfferDialog(context),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('عرض جديد'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...myOffers.map((offer) {
                  final isScheduled = offer.offerStartDate != null && DateTime.now().isBefore(offer.offerStartDate!);
                  final isExpired = (offer.offerEndDate != null && DateTime.now().isAfter(offer.offerEndDate!)) || offer.offerRemainingQty <= 0;

                  String badgeText = 'عرض نشط 🔥';
                  Color badgeColor = Colors.green;
                  if (isScheduled) {
                    badgeText = 'مجدول لتاريخ قادم ⏳';
                    badgeColor = AppColors.amber;
                  } else if (isExpired) {
                    badgeText = 'منتهي (يعود للسعر الأصلي) ⚠️';
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
                        Text('سعر العرض: ${currency(offer.offerPrice)} (السعر الأصلي: ${currency(offer.price)}) / ${offer.unit}',
                            style: const TextStyle(fontSize: 12, color: AppColors.brandDeep, fontWeight: FontWeight.bold)),
                        Text('الكمية المتبقية: ${offer.offerRemainingQty} من ${offer.offerTotalQty}',
                            style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
                        if (offer.offerStartDate != null || offer.offerEndDate != null)
                          Text(
                            'الفترة: ${offer.offerStartDate != null ? formatEgyptDate(offer.offerStartDate!) : "الآن"} إلى ${offer.offerEndDate != null ? formatEgyptDate(offer.offerEndDate!) : "حتى نفاذ الكمية"}',
                            style: const TextStyle(fontSize: 10, color: AppColors.inkSoft),
                          ),
                        const Divider(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => appState.deleteOffer(offer.id),
                              icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                              label: const Text('إلغاء العرض', style: TextStyle(color: AppColors.danger, fontSize: 12)),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إضافة أصناف أولاً قبل عمل عروض عليها')));
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
          title: const Text('تجهيز وجدولة عرض جديد', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedProdId,
                  items: availableProducts.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                  onChanged: (v) => setDialogState(() => selectedProdId = v!),
                  decoration: const InputDecoration(labelText: 'اختر الصنف'),
                ),
                const SizedBox(height: 10),
                TextField(controller: offerPriceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعر العرض المخفض (ج.م)')),
                const SizedBox(height: 10),
                TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الكمية الإجمالية المخصصة للعرض')),
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
                        child: Text(startDate == null ? 'تاريخ البداية' : formatEgyptDate(startDate!), style: const TextStyle(fontSize: 11)),
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
                        child: Text(endDate == null ? 'تاريخ النهاية' : formatEgyptDate(endDate!), style: const TextStyle(fontSize: 11)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
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
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تجهيز وتفعيل العرض بنجاح!')));
              },
              child: const Text('تأكيد العرض'),
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('تقارير وأداء المبيعات والعروض', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _reportCard('إجمالي المبيعات المستحقة', currency(totalSales), Icons.monetization_on_outlined, AppColors.brand)),
            const SizedBox(width: 12),
            Expanded(child: _reportCard('عدد الطلبات الواردة', '$ordersCount طلب', Icons.local_shipping_outlined, Colors.blue)),
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
              const Row(
                children: [
                  Icon(Icons.trending_up, color: AppColors.brand, size: 18),
                  SizedBox(width: 8),
                  Text('الأصناف الأكثر مبيعاً من منتجاتك', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const Divider(height: 16),
              if (topItems.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('لا توجد مبيعات مسجلة حتى الآن', style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                )
              else
                ...topItems.take(5).map((it) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(it.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      trailing: Text('${it.value} وحدة مباعة', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandDeep)),
                    )),
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
              const Row(
                children: [
                  Icon(Icons.people_outline, color: AppColors.brand, size: 18),
                  SizedBox(width: 8),
                  Text('العملاء الأكثر شراءً من متجرك', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const Divider(height: 16),
              if (topClients.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('لا يوجد طلبات عملاء حتى الآن', style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
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