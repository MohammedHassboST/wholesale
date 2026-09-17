import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../../domain/entities/order_entity.dart';

class VendorOrdersPage extends StatelessWidget {
  const VendorOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final myOrders = appState.orders;

        return Scaffold(
          appBar: AppBar(
            title: const Text('إدارة الطلبات الواردة', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: myOrders.isEmpty
              ? const Center(child: Text('لا توجد طلبات حالياً'))
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: myOrders.length,
            itemBuilder: (context, index) {
              final order = myOrders[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('طلب رقم: ${order.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Chip(
                            label: Text(order.status, style: const TextStyle(color: Colors.white, fontSize: 12)),
                            backgroundColor: _getStatusColor(order.status),
                          ),
                        ],
                      ),
                      const Divider(),
                      Text('العميل: ${order.clientName} | ${order.clientPhone}'),
                      const SizedBox(height: 8),
                      ...order.items.map((item) => Text('- ${item.product.name} (×${item.qty})')),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('الإجمالي: ${order.total} ج.م', style: const TextStyle(fontWeight: FontWeight.bold)),
                          // أزرار التحديث اليدوي للحالة
                          _buildActionButtons(order),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'قيد المراجعة': return Colors.orange;
      case 'مؤكد': return Colors.blue;
      case 'جاري التجهيز': return Colors.purple;
      case 'في الطريق': return Colors.amber;
      case 'تم التسليم': return Colors.green;
      default: return Colors.grey;
    }
  }

  Widget _buildActionButtons(OrderEntity order) {
    if (order.status == 'قيد المراجعة') {
      return Row(
        children: [
          TextButton(onPressed: () => appState.rejectOrder(order.id), child: const Text('رفض', style: TextStyle(color: Colors.red))),
          ElevatedButton(onPressed: () => appState.acceptOrder(order.id), child: const Text('قبول')),
        ],
      );
    } else if (order.status != 'تم التسليم' && order.status != 'مرفوض') {
      return ElevatedButton(
        onPressed: () => appState.advanceOrderStatus(order.id, order.status),
        child: const Text('تحديث الحالة التالى'),
      );
    }
    return const SizedBox.shrink();
  }
}