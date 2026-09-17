import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../../core/constants/constants.dart';

class AdminOrdersPage extends StatefulWidget {
  final String? initialFilter;
  const AdminOrdersPage({super.key, this.initialFilter});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  late String activeFilter;
  final List<String> filters = ['الكل', 'قيد المراجعة', 'مؤكد', 'جاري التجهيز', 'في الطريق', 'تم التسليم'];

  @override
  void initState() {
    super.initState();
    activeFilter = widget.initialFilter ?? 'الكل';
  }

  Color statusColor(String s) {
    switch (s) {
      case 'قيد المراجعة': return AppColors.amber;
      case 'مؤكد': return AppColors.brand;
      case 'جاري التجهيز': return const Color(0xFF3B82F6);
      case 'في الطريق': return Colors.amber.shade800;
      case 'تم التسليم': return const Color(0xFF10B981);
      default: return AppColors.inkSoft;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        var orders = List.of(appState.orders)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (activeFilter != 'الكل') {
          orders = orders.where((o) => o.status == activeFilter).toList();
        }

        return Scaffold(
          backgroundColor: AppColors.paper,
          appBar: AppBar(title: const Text('الطلبات الواردة', style: TextStyle(fontWeight: FontWeight.w900)), centerTitle: true),
          body: Column(
            children: [
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: filters.length,
                  itemBuilder: (context, i) {
                    final f = filters[i];
                    final active = activeFilter == f;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        label: Text(f),
                        selected: active,
                        selectedColor: statusColor(f == 'الكل' ? 'مؤكد' : f),
                        backgroundColor: AppColors.card,
                        labelStyle: TextStyle(color: active ? Colors.white : AppColors.inkSoft, fontWeight: FontWeight.w800, fontSize: 12),
                        onSelected: (_) => setState(() => activeFilter = f),
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: orders.isEmpty
                    ? Center(child: Text('مفيش طلبات ${activeFilter == 'الكل' ? 'واردة' : 'بـ$activeFilter'}'))
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, i) {
                    final o = orders[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(o.id, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                                      Text('العميل: ${o.clientName} · ${o.clientPhone}', style: TextStyle(fontSize: 11, color: AppColors.inkSoft.withValues(alpha: 0.7))),
                                      Text(formatEgyptDateTime(o.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
                                    ],
                                  ),
                                ),
                                Chip(label: Text(o.status, style: const TextStyle(color: Colors.white, fontSize: 11)), backgroundColor: statusColor(o.status)),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              children: o.items.map((it) => Row(
                                children: [
                                  Expanded(child: Text(it.product.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                                  Text('× ${it.qty}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                ],
                              )).toList(),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('الإجمالي: ${currency(o.total)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                                PopupMenuButton<String>(
                                  onSelected: (v) => appState.updateOrderStatus(o.id, v),
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(value: 'قيد المراجعة', child: Text('قيد المراجعة')),
                                    const PopupMenuItem(value: 'مؤكد', child: Text('مؤكد')),
                                    const PopupMenuItem(value: 'جاري التجهيز', child: Text('جاري التجهيز')),
                                    const PopupMenuItem(value: 'في الطريق', child: Text('في الطريق')),
                                    const PopupMenuItem(value: 'تم التسليم', child: Text('تم التسليم')),
                                  ],
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(8)),
                                    child: const Text('تحديث الحالة', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}