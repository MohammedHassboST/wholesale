import 'package:flutter/material.dart';
import '../../common/widgets/cart_drawer.dart';
import '../../state/app_state.dart';
import '../../../core/constants/constants.dart';
import '../../common/widgets/product_card.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  String activeCategory = 'الكل';
  String sortBy = 'الافتراضي';
  String? selectedVendorFilter;
  String unitFilter = 'الكل';
  final searchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        var filtered = appState.getProductsByCategory(activeCategory);
        final List<String> availableVendors = appState.products.map((p) => p.vendorId).toSet().toList();

        // 1. فلترة المورد المعين
        if (selectedVendorFilter != null && selectedVendorFilter != 'الكل') {
          filtered = filtered.where((p) => p.vendorId == selectedVendorFilter).toList();
        }

        // 2. فلترة الجملة / بالوحدة
        if (unitFilter == 'بالجملة') {
          filtered = filtered.where((p) => p.unit.contains('كرتونة') || p.unit.contains('طرد') || p.unit.contains('شكارة') || p.unit.contains('صندوق') || p.unit.contains('دستة')).toList();
        } else if (unitFilter == 'بالقطعة') {
          filtered = filtered.where((p) => p.unit.contains('قطعة') || p.unit.contains('كيلو') || p.unit.contains('علبة')).toList();
        }

        // 3. البحث بالاسم، الصنف، السعر، أو الوحدة
        if (searchCtrl.text.isNotEmpty) {
          final query = searchCtrl.text.toLowerCase().trim();
          filtered = filtered.where((p) =>
              p.name.toLowerCase().contains(query) ||
              p.category.toLowerCase().contains(query) ||
              p.unit.toLowerCase().contains(query) ||
              p.price.toString().contains(query) ||
              p.vendorId.toLowerCase().contains(query)).toList();
        }

        // 4. الترتيب
        if (sortBy == 'الأقرب للنفاذ') {
          filtered.sort((a, b) {
            final aQty = a.isOffer ? a.offerRemainingQty : 999999;
            final bQty = b.isOffer ? b.offerRemainingQty : 999999;
            return aQty.compareTo(bQty);
          });
        } else if (sortBy == 'الأحدث') {
          filtered = filtered.reversed.toList();
        } else if (sortBy == 'السعر: الأقل') {
          filtered.sort((a, b) => a.currentPrice.compareTo(b.currentPrice));
        } else if (sortBy == 'السعر: الأعلى') {
          filtered.sort((a, b) => b.currentPrice.compareTo(a.currentPrice));
        }

        return Scaffold(
          backgroundColor: AppColors.paper,
          appBar: AppBar(
            title: const Text('سوق الجملة وفيد العروض المجمع', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            backgroundColor: AppColors.brandDeep,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.language),
                tooltip: 'تغيير اللغة',
                onPressed: () => appState.toggleLocale(),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_bag_outlined),
                    tooltip: 'سلة الشراء',
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const CartDrawer(),
                    ),
                  ),
                  if (appState.cartCount > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                        child: Text(
                          '${appState.cartCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              // شريط البحث والفرز
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchCtrl,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'ابحث بالاسم، الصنف، السعر، أو الوحدة...',
                          hintStyle: TextStyle(fontSize: 12, color: AppColors.inkSoft.withValues(alpha: 0.6)),
                          prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.brand),
                          filled: true,
                          fillColor: AppColors.card,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
                      child: DropdownButton<String>(
                        value: sortBy,
                        underline: const SizedBox(),
                        items: ['الافتراضي', 'الأقرب للنفاذ', 'الأحدث', 'السعر: الأقل', 'السعر: الأعلى']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)))).toList(),
                        onChanged: (v) => setState(() => sortBy = v!),
                      ),
                    ),
                  ],
                ),
              ),

              // فلترة (جملة / بالوحدة)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    const Text('نوع البيع: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.inkSoft)),
                    const SizedBox(width: 6),
                    _unitChip('الكل'),
                    const SizedBox(width: 6),
                    _unitChip('بالجملة'),
                    const SizedBox(width: 6),
                    _unitChip('بالقطعة'),
                  ],
                ),
              ),

              // فلترة الموردين
              if (availableVendors.isNotEmpty)
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _vendorChip('كل الموردين', null, selectedVendorFilter == null),
                      ...availableVendors.map((vId) => _vendorChip(vId, vId, selectedVendorFilter == vId)),
                    ],
                  ),
                ),
              const SizedBox(height: 6),

              // شريط التصنيفات
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: appState.categories.length,
                  itemBuilder: (context, i) {
                    final cat = appState.categories[i];
                    final active = activeCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: ChoiceChip(
                        label: Text(cat, style: const TextStyle(fontSize: 12)),
                        selected: active,
                        selectedColor: AppColors.brand,
                        backgroundColor: AppColors.card,
                        labelStyle: TextStyle(color: active ? Colors.white : AppColors.inkSoft, fontWeight: FontWeight.bold),
                        onSelected: (_) => setState(() => activeCategory = cat),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),

              // شبكة الأصناف والعروض
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text('لا توجد عروض أو أصناف مطابقة للبحث أو الفلتر المختار', style: TextStyle(color: AppColors.inkSoft)),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.68,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return ProductCard(product: filtered[index]);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _unitChip(String label) {
    final active = unitFilter == label;
    return GestureDetector(
      onTap: () => setState(() => unitFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppColors.brand : AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? AppColors.brand : AppColors.line),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: active ? Colors.white : AppColors.inkSoft),
        ),
      ),
    );
  }

  Widget _vendorChip(String label, String? vendorId, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: FilterChip(
        selected: isSelected,
        label: Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppColors.inkSoft, fontWeight: FontWeight.bold)),
        selectedColor: AppColors.brandDeep,
        backgroundColor: AppColors.card,
        onSelected: (_) => setState(() => selectedVendorFilter = vendorId),
      ),
    );
  }
}