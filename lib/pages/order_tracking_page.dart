import 'package:flutter/material.dart';
import 'package:uniperks/services/order_service.dart';
import 'package:uniperks/services/user_service.dart';
import 'package:uniperks/models/order.dart';
import 'package:uniperks/models/order_item.dart';

class OrderTrackingPage extends StatefulWidget {
  final String username;
  const OrderTrackingPage({super.key, required this.username});

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  late Future<List<Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = OrderService.getOrdersForUser(widget.username);
  }

  Future<void> _reload() async {
    setState(() {
      _ordersFuture = OrderService.getOrdersForUser(widget.username);
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: FutureBuilder<List<Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long, size: 72, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No orders yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('Your purchases will appear here'),
                    ],
                  ),
                ),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, i) => _buildOrderCard(orders[i]),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(Order o) {
    final isDelivery = o.deliveryMethod == 'delivery';
    String statusMessage;
    switch (o.status) {
      case 'accepted':
        statusMessage = isDelivery
            ? 'Preparing for dispatch'
            : 'Ready for pickup at UPSI Holding';
        break;
      case 'on_the_way':
        statusMessage = 'On the way to your address';
        break;
      case 'delivered':
        statusMessage = 'Delivered. Thank you for your purchase!';
        break;
      case 'declined':
        statusMessage = 'Order declined by admin, waiting for refund';
        break;
      case 'paid':
      default:
        statusMessage = 'Awaiting review';
        break;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: FutureBuilder<List<OrderItem>>(
                    future: OrderService.getOrderItems(o.id),
                    builder: (context, itemsSnap) {
                      final names = (itemsSnap.data ?? [])
                          .map((it) => it.productName)
                          .where((n) => n != null && n.isNotEmpty)
                          .join(', ');
                      final title = names.isNotEmpty ? names : 'Order';
                      return Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                _statusChip(o.status),
              ],
            ),
            const SizedBox(height: 8),
            Text('Total: RM${o.totalAmount.toStringAsFixed(2)}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(isDelivery ? Icons.local_shipping : Icons.store, size: 16),
                const SizedBox(width: 6),
                Text(isDelivery ? 'Delivery' : 'Self pickup'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              statusMessage,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (isDelivery) ...[
              const SizedBox(height: 8),
              FutureBuilder<Map<String, dynamic>?>(
                future: UserService.getUserProfile(o.username),
                builder: (context, snap) {
                  final profile = snap.data;
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Text('Loading address...');
                  }
                  final address = [
                    profile?['address_line'],
                    profile?['city'],
                    profile?['postal_code'],
                  ].where((e) => (e as String?)?.isNotEmpty == true).join(', ');
                  final phone = profile?['phone'] as String?;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        address.isNotEmpty
                            ? 'Address: $address'
                            : 'Address: (not provided)',
                      ),
                      if (phone != null && phone.isNotEmpty)
                        Text('Contact: $phone'),
                    ],
                  );
                },
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Placed: ${_formatDate(o.createdAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case 'accepted':
        bg = Colors.green.withOpacity(0.1);
        fg = Colors.green;
        label = 'Accepted';
        break;
      case 'on_the_way':
        bg = Colors.orange.withOpacity(0.1);
        fg = Colors.orange;
        label = 'On the Way';
        break;
      case 'delivered':
        bg = Colors.teal.withOpacity(0.1);
        fg = Colors.teal;
        label = 'Delivered';
        break;
      case 'declined':
        bg = Colors.red.withOpacity(0.1);
        fg = Colors.red;
        label = 'Declined';
        break;
      case 'paid':
      default:
        bg = Colors.blue.withOpacity(0.1);
        fg = Colors.blue;
        label = 'Paid';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
