import 'package:flutter/material.dart';
import 'package:uniperks/services/order_service.dart';
import 'package:uniperks/services/user_service.dart';
import 'package:uniperks/models/order.dart';
import 'package:uniperks/models/order_item.dart';

class OrderTrackingPage extends StatefulWidget {
  final String username;
  final VoidCallback? onStartShopping;
  const OrderTrackingPage({
    super.key,
    required this.username,
    this.onStartShopping,
  });

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  late Future<List<Order>> _ordersFuture;
  Map<int, List<OrderItem>> _orderItemsCache = {};
  Map<String, dynamic>? _userProfileCache;
  bool _isLoadingDetails = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _ordersFuture = OrderService.getOrdersForUser(widget.username);
      _isLoadingDetails = true;
    });

    try {
      final orders = await _ordersFuture;

      // Batch load all order items in parallel
      final itemsFutures = orders.map(
        (o) => OrderService.getOrderItems(
          o.id,
        ).then((items) => MapEntry(o.id, items)),
      );
      final itemsResults = await Future.wait(itemsFutures);

      // Cache all items
      _orderItemsCache = Map.fromEntries(itemsResults);

      // Load user profile once
      _userProfileCache = await UserService.getUserProfile(widget.username);

      if (mounted) {
        setState(() {
          _isLoadingDetails = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDetails = false;
        });
      }
    }
  }

  Future<void> _reload() async {
    _orderItemsCache.clear();
    _userProfileCache = null;
    await _loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF1E3A8A).withOpacity(0.05), Colors.white],
          stops: const [0.0, 0.3],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _reload,
        color: const Color(0xFF1E3A8A),
        child: FutureBuilder<List<Order>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading orders',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: const TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            final orders = snapshot.data ?? [];
            if (orders.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.shopping_bag_outlined,
                            size: 80,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'No orders yet',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Your order history will appear here',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (widget.onStartShopping != null) {
                              widget.onStartShopping!();
                            } else {
                              Navigator.of(context).maybePop();
                            }
                          },
                          icon: const Icon(Icons.store),
                          label: const Text('Start Shopping'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
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
      ),
    );
  }

  Widget _buildOrderCard(Order o) {
    final isDelivery = o.deliveryMethod == 'delivery';
    String statusMessage;
    IconData statusIcon;

    switch (o.status) {
      case 'accepted':
        statusMessage = isDelivery
            ? 'Order accepted and being prepared'
            : 'Ready for pickup';
        statusIcon = Icons.check_circle;
        break;
      case 'on_the_way':
        statusMessage = 'Out for delivery';
        statusIcon = Icons.local_shipping;
        break;
      case 'delivered':
        statusMessage = 'Successfully delivered!';
        statusIcon = Icons.done_all;
        break;
      case 'declined':
        statusMessage = 'Order declined';
        statusIcon = Icons.cancel;
        break;
      case 'paid':
      default:
        statusMessage = 'Payment received';
        statusIcon = Icons.payment;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _getGradientColors(o.status),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(statusIcon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusMessage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(o.createdAt),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _statusChip(o.status),
              ],
            ),
          ),

          // Order details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Items
                Builder(
                  builder: (context) {
                    final items = _orderItemsCache[o.id] ?? [];
                    if (items.isEmpty && _isLoadingDetails) {
                      return const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Loading items...'),
                        ],
                      );
                    }
                    if (items.isEmpty) {
                      return const Text('No items');
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.shopping_basket,
                              size: 18,
                              color: Color(0xFF1E3A8A),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Order Items',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(left: 26, bottom: 4),
                            child: Text(
                              '• ${item.productName ?? 'Product'}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Delivery method
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isDelivery ? Icons.local_shipping : Icons.store,
                        size: 20,
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isDelivery ? 'Home Delivery' : 'Self Pickup',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            isDelivery
                                ? 'We\'ll deliver to your address'
                                : 'Pick up at UPSI Holding',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (isDelivery && o.status != 'declined') ...[
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) {
                      if (_isLoadingDetails && _userProfileCache == null) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: const Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Loading address...'),
                            ],
                          ),
                        );
                      }

                      final profile = _userProfileCache;
                      final address =
                          [
                                profile?['address_line'],
                                profile?['city'],
                                profile?['postal_code'],
                              ]
                              .where((e) => (e as String?)?.isNotEmpty == true)
                              .join(', ');
                      final phone = profile?['phone'] as String?;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Colors.grey[700],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Delivery Address',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              address.isNotEmpty
                                  ? address
                                  : 'Address not provided',
                              style: const TextStyle(fontSize: 13),
                            ),
                            if (phone != null && phone.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone,
                                    size: 14,
                                    color: Colors.grey[700],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    phone,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ],

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Total amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'RM${o.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getGradientColors(String status) {
    switch (status) {
      case 'accepted':
        return [const Color(0xFF10B981), const Color(0xFF059669)];
      case 'on_the_way':
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      case 'delivered':
        return [const Color(0xFF14B8A6), const Color(0xFF0D9488)];
      case 'declined':
        return [const Color(0xFFEF4444), const Color(0xFFDC2626)];
      case 'paid':
      default:
        return [const Color(0xFF3B82F6), const Color(0xFF2563EB)];
    }
  }

  Widget _statusChip(String status) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status) {
      case 'accepted':
        bg = Colors.white;
        fg = Colors.white;
        label = 'Accepted';
        icon = Icons.check_circle;
        break;
      case 'on_the_way':
        bg = Colors.white;
        fg = Colors.white;
        label = 'On the Way';
        icon = Icons.local_shipping;
        break;
      case 'delivered':
        bg = Colors.white;
        fg = Colors.white;
        label = 'Delivered';
        icon = Icons.done_all;
        break;
      case 'declined':
        bg = Colors.white;
        fg = Colors.white;
        label = 'Declined';
        icon = Icons.cancel;
        break;
      case 'paid':
      default:
        bg = Colors.white;
        fg = Colors.white;
        label = 'Paid';
        icon = Icons.payment;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
