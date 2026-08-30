import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import 'cart_screen.dart'; // REQUIRED FOR CustomerSession
import 'customer_order_edit.dart'; // NEW: Edit feature import

class OrderTrackingScreen extends StatefulWidget {
  final String restaurantId;
  final int tableNumber;

  const OrderTrackingScreen({
    super.key,
    required this.restaurantId,
    required this.tableNumber,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final DatabaseService _dbService = DatabaseService();
  String _savedCustomerName = '';
  bool _isLoadingName = true;

  @override
  void initState() {
    super.initState();
    _loadSavedName();
  }

  // ================= FIXED: SAFE SESSION LOAD =================
  Future<void> _loadSavedName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? savedName = prefs.getString('customer_name');
      if (savedName != null && savedName.isNotEmpty) {
        CustomerSession.name = savedName;
      }
    } catch (e) {
      print("SharedPreferences disabled by mobile browser: $e");
    }

    if (mounted) {
      setState(() {
        _savedCustomerName = CustomerSession.name;
        _isLoadingName = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Cooking':
        return Colors.deepPurpleAccent;
      case 'Ready':
        return Colors.green;
      case 'Served':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  void _cancelOrder(String orderId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          'Cancel Order?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              bool success = await _dbService.cancelOrder(orderId);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order Cancelled!'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(String currentStatus) {
    final statuses = ['Pending', 'Cooking', 'Ready', 'Served'];
    int currentIndex = statuses.indexOf(currentStatus);
    if (currentIndex == -1) currentIndex = 0;

    return Row(
      children: List.generate(statuses.length * 2 - 1, (index) {
        if (index % 2 == 0) {
          int statusIndex = index ~/ 2;
          bool isCompleted = statusIndex <= currentIndex;
          bool isActive = statusIndex == currentIndex;
          return Column(
            children: [
              Container(
                width: isActive ? 24 : 16,
                height: isActive ? 24 : 16,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? _getStatusColor(statuses[statusIndex])
                      : Colors.grey[300],
                  shape: BoxShape.circle,
                  border: isActive
                      ? Border.all(
                          color: _getStatusColor(
                            statuses[statusIndex],
                          ).withOpacity(0.3),
                          width: 4,
                        )
                      : null,
                ),
                child: isCompleted && !isActive
                    ? const Icon(Icons.check, size: 10, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 4),
              Text(
                statuses[statusIndex],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isCompleted ? Colors.black87 : Colors.grey,
                ),
              ),
            ],
          );
        } else {
          int lineIndex = index ~/ 2;
          bool isCompleted = lineIndex < currentIndex;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: 2,
              color: isCompleted
                  ? _getStatusColor(statuses[lineIndex])
                  : Colors.grey[200],
            ),
          );
        }
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.green[300]),
          const SizedBox(height: 16),
          const Text(
            'Table is clear!',
            style: TextStyle(
              fontSize: 20,
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No active orders. Ready for new customers!',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.restaurant_menu),
            label: const Text('Browse Menu'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSuccessCard(
    Map<String, dynamic> data,
    String customerName,
  ) {
    double amountReceived =
        (data['amount_received'] ?? data['total_amount'] ?? 0.0).toDouble();
    String message = data['thank_you_message'] ?? '';

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      margin: const EdgeInsets.only(bottom: 20.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      color: Colors.teal.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.teal, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    customerName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),
            const Icon(Icons.celebration, color: Colors.teal, size: 50),
            const SizedBox(height: 12),
            const Text(
              'Payment Successful! 🎉',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Amount Paid: ৳${amountReceived.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            if (message.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.teal.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.favorite,
                      color: Colors.redAccent,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '"$message"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ================= NEW: ADVANCED FOOTER WITH EDIT BUTTON =================
  Widget _buildStatusFooter(String orderId, Map<String, dynamic> data) {
    String status = data['status'] ?? 'Pending';
    int? estimatedTime = data['estimatedTime'];
    String paymentMethod = data['payment_method'] ?? 'Cash';
    String paymentStatus = data['payment_status'] ?? 'Unpaid';
    List items = data['items'] ?? [];

    bool canEdit = paymentMethod == 'Cash' || paymentStatus == 'Unpaid';

    if (status == 'Pending') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Waiting for kitchen to accept...',
            style: TextStyle(
              color: Colors.orange,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (canEdit)
                OutlinedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => CustomerOrderEditSheet(
                        orderId: orderId,
                        initialItems: items,
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit, size: 14),
                  label: const Text(
                    'Edit Order',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.deepPurpleAccent,
                    side: const BorderSide(color: Colors.deepPurpleAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 32),
                  ),
                ),
              if (canEdit) const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _cancelOrder(orderId),
                icon: const Icon(Icons.close, size: 14),
                label: const Text('Cancel', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 32),
                ),
              ),
            ],
          ),
        ],
      );
    } else if (status == 'Cooking') {
      return Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.deepPurpleAccent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chef is preparing your food.',
                  style: TextStyle(
                    color: Colors.deepPurpleAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                if (estimatedTime != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: Colors.deepPurpleAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Estimated time: $estimatedTime mins',
                        style: TextStyle(
                          color: Colors.deepPurpleAccent.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    } else if (status == 'Ready') {
      return const Row(
        children: [
          Icon(Icons.directions_run, color: Colors.green, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Food is ready! Waiter is bringing it to your table.',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      );
    } else {
      return const Row(
        children: [
          Icon(
            Icons.sentiment_very_satisfied,
            color: Colors.blueGrey,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Served! Hope you enjoyed your delicious meal.',
              style: TextStyle(
                color: Colors.blueGrey,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingName) {
      return const Scaffold(
        backgroundColor: Colors.deepOrange,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              'Live Order Tracking',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(
              'Table: ${widget.tableNumber}',
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _dbService.getOrders(widget.restaurantId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(
              child: CircularProgressIndicator(color: Colors.deepOrange),
            );
          if (snapshot.hasError)
            return const Center(child: Text('Error tracking orders!'));

          final allOrders = snapshot.data?.docs ?? [];

          final tableOrders = allOrders.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final String cName = data['customer_name'] ?? 'Guest';

            bool nameMatches =
                _savedCustomerName.isEmpty ||
                cName.trim().toLowerCase() ==
                    _savedCustomerName.trim().toLowerCase();

            return data['table_no'] == widget.tableNumber &&
                data['status'] != 'Cancelled' &&
                nameMatches;
          }).toList();

          if (tableOrders.isEmpty || _savedCustomerName.isEmpty) {
            return _buildEmptyState();
          }

          final activeOrders = tableOrders.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            bool isPaid = data['payment_status'] == 'Paid';
            bool isServed = data['status'] == 'Served';
            return !(isPaid && isServed);
          }).toList();

          if (activeOrders.isEmpty) {
            final latestOrder =
                tableOrders.first.data() as Map<String, dynamic>;
            if (latestOrder['payment_status'] == 'Paid' &&
                latestOrder['status'] == 'Served') {
              Timestamp? clearedAt = latestOrder['cleared_at'];
              if (clearedAt != null &&
                  DateTime.now().difference(clearedAt.toDate()).inMinutes <
                      30) {
                return _buildPaymentSuccessCard(
                  latestOrder,
                  _savedCustomerName,
                );
              }
            }
            return _buildEmptyState();
          }

          double activeGrandTotal = 0.0;
          List<Widget> orderCards = [];

          for (var order in activeOrders) {
            final data = order.data() as Map<String, dynamic>;
            final String orderId = order.id;
            final String status = data['status'] ?? 'Pending';
            final double totalAmount = (data['total_amount'] ?? 0.0).toDouble();
            final List items = data['items'] ?? [];

            activeGrandTotal += totalAmount;

            orderCards.add(
              Card(
                elevation: 2,
                shadowColor: Colors.black12,
                margin: const EdgeInsets.only(bottom: 20.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.person,
                                  color: Colors.deepOrange,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _savedCustomerName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (data['payment_status'] == 'Paid')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 12,
                                    color: Colors.green,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Payment Verified ✅',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (data['payment_status'] ==
                              'Pending Verification')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.3),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.hourglass_top,
                                    size: 12,
                                    color: Colors.orange,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Verifying Payment',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTimeline(status),
                      const SizedBox(height: 20),
                      Text(
                        'Order #${orderId.substring(0, 5).toUpperCase()} Items:',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Text(
                                  '${item['quantity']}x',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepOrange,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item['name'],
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                '৳${(item['totalPrice'] ?? 0.0).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(height: 1, thickness: 1),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Amount',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            '৳${totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _getStatusColor(status).withOpacity(0.2),
                          ),
                        ),
                        // ================= FIXED: Passing the entire data map =================
                        child: _buildStatusFooter(orderId, data),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (orderCards.isEmpty) return _buildEmptyState();

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: orderCards,
                ),
              ),
              if (activeGrandTotal > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(25),
                    ),
                  ),
                  child: SafeArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Bill (Active Orders)',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '৳${activeGrandTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 22,
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.deepOrange,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Please wait for bill',
                                style: TextStyle(
                                  color: Colors.deepOrange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
/*
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import 'cart_screen.dart'; // REQUIRED FOR CustomerSession

class OrderTrackingScreen extends StatefulWidget {
  final String restaurantId;
  final int tableNumber;

  const OrderTrackingScreen({
    super.key,
    required this.restaurantId,
    required this.tableNumber,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final DatabaseService _dbService = DatabaseService();
  String _savedCustomerName = '';
  bool _isLoadingName = true;

  @override
  void initState() {
    super.initState();
    _loadSavedName();
  }

  // ================= FIXED: SAFE SESSION LOAD =================
  Future<void> _loadSavedName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? savedName = prefs.getString('customer_name');
      if (savedName != null && savedName.isNotEmpty) {
        CustomerSession.name = savedName;
      }
    } catch (e) {
      print("SharedPreferences disabled by mobile browser: $e");
    }

    if (mounted) {
      setState(() {
        _savedCustomerName = CustomerSession.name;
        _isLoadingName = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Cooking':
        return Colors.deepPurpleAccent;
      case 'Ready':
        return Colors.green;
      case 'Served':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  void _cancelOrder(String orderId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          'Cancel Order?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              bool success = await _dbService.cancelOrder(orderId);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order Cancelled!'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(String currentStatus) {
    final statuses = ['Pending', 'Cooking', 'Ready', 'Served'];
    int currentIndex = statuses.indexOf(currentStatus);
    if (currentIndex == -1) currentIndex = 0;

    return Row(
      children: List.generate(statuses.length * 2 - 1, (index) {
        if (index % 2 == 0) {
          int statusIndex = index ~/ 2;
          bool isCompleted = statusIndex <= currentIndex;
          bool isActive = statusIndex == currentIndex;
          return Column(
            children: [
              Container(
                width: isActive ? 24 : 16,
                height: isActive ? 24 : 16,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? _getStatusColor(statuses[statusIndex])
                      : Colors.grey[300],
                  shape: BoxShape.circle,
                  border: isActive
                      ? Border.all(
                          color: _getStatusColor(
                            statuses[statusIndex],
                          ).withOpacity(0.3),
                          width: 4,
                        )
                      : null,
                ),
                child: isCompleted && !isActive
                    ? const Icon(Icons.check, size: 10, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 4),
              Text(
                statuses[statusIndex],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isCompleted ? Colors.black87 : Colors.grey,
                ),
              ),
            ],
          );
        } else {
          int lineIndex = index ~/ 2;
          bool isCompleted = lineIndex < currentIndex;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: 2,
              color: isCompleted
                  ? _getStatusColor(statuses[lineIndex])
                  : Colors.grey[200],
            ),
          );
        }
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.green[300]),
          const SizedBox(height: 16),
          const Text(
            'Table is clear!',
            style: TextStyle(
              fontSize: 20,
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No active orders. Ready for new customers!',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.restaurant_menu),
            label: const Text('Browse Menu'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSuccessCard(
    Map<String, dynamic> data,
    String customerName,
  ) {
    double amountReceived =
        (data['amount_received'] ?? data['total_amount'] ?? 0.0).toDouble();
    String message = data['thank_you_message'] ?? '';

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      margin: const EdgeInsets.only(bottom: 20.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      color: Colors.teal.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.teal, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    customerName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),
            const Icon(Icons.celebration, color: Colors.teal, size: 50),
            const SizedBox(height: 12),
            const Text(
              'Payment Successful! 🎉',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Amount Paid: ৳${amountReceived.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            if (message.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.teal.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.favorite,
                      color: Colors.redAccent,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '"$message"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFooter(String status, String orderId, int? estimatedTime) {
    if (status == 'Pending') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Text(
              'Waiting for kitchen to accept...',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 32,
            child: ElevatedButton.icon(
              onPressed: () => _cancelOrder(orderId),
              icon: const Icon(Icons.close, size: 14),
              label: const Text('Cancel', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
          ),
        ],
      );
    } else if (status == 'Cooking') {
      return Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.deepPurpleAccent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chef is preparing your food.',
                  style: TextStyle(
                    color: Colors.deepPurpleAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                if (estimatedTime != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: Colors.deepPurpleAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Estimated time: $estimatedTime mins',
                        style: TextStyle(
                          color: Colors.deepPurpleAccent.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    } else if (status == 'Ready') {
      return const Row(
        children: [
          Icon(Icons.directions_run, color: Colors.green, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Food is ready! Waiter is bringing it to your table.',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      );
    } else {
      return const Row(
        children: [
          Icon(
            Icons.sentiment_very_satisfied,
            color: Colors.blueGrey,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Served! Hope you enjoyed your delicious meal.',
              style: TextStyle(
                color: Colors.blueGrey,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingName) {
      return const Scaffold(
        backgroundColor: Colors.deepOrange,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              'Live Order Tracking',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(
              'Table: ${widget.tableNumber}',
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _dbService.getOrders(widget.restaurantId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(
              child: CircularProgressIndicator(color: Colors.deepOrange),
            );
          if (snapshot.hasError)
            return const Center(child: Text('Error tracking orders!'));

          final allOrders = snapshot.data?.docs ?? [];

          final tableOrders = allOrders.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final String cName = data['customer_name'] ?? 'Guest';

            // SMART LOGIC: If storage blocked or no name yet, show whole table. Otherwise, filter by name.
            bool nameMatches =
                _savedCustomerName.isEmpty ||
                cName.trim().toLowerCase() ==
                    _savedCustomerName.trim().toLowerCase();

            return data['table_no'] == widget.tableNumber &&
                data['status'] != 'Cancelled' &&
                nameMatches;
          }).toList();

          if (tableOrders.isEmpty || _savedCustomerName.isEmpty) {
            return _buildEmptyState();
          }

          final activeOrders = tableOrders.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            bool isPaid = data['payment_status'] == 'Paid';
            bool isServed = data['status'] == 'Served';
            return !(isPaid && isServed);
          }).toList();

          if (activeOrders.isEmpty) {
            final latestOrder =
                tableOrders.first.data() as Map<String, dynamic>;
            if (latestOrder['payment_status'] == 'Paid' &&
                latestOrder['status'] == 'Served') {
              Timestamp? clearedAt = latestOrder['cleared_at'];
              if (clearedAt != null &&
                  DateTime.now().difference(clearedAt.toDate()).inMinutes <
                      30) {
                return _buildPaymentSuccessCard(
                  latestOrder,
                  _savedCustomerName,
                );
              }
            }
            return _buildEmptyState();
          }

          double activeGrandTotal = 0.0;
          List<Widget> orderCards = [];

          for (var order in activeOrders) {
            final data = order.data() as Map<String, dynamic>;
            final String orderId = order.id;
            final String status = data['status'] ?? 'Pending';
            final int? estimatedTime = data['estimatedTime'];
            final String paymentStatus = data['payment_status'] ?? 'Unpaid';
            final double totalAmount = (data['total_amount'] ?? 0.0).toDouble();
            final List items = data['items'] ?? [];

            activeGrandTotal += totalAmount;

            orderCards.add(
              Card(
                elevation: 2,
                shadowColor: Colors.black12,
                margin: const EdgeInsets.only(bottom: 20.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.person,
                                  color: Colors.deepOrange,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _savedCustomerName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (paymentStatus == 'Paid')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 12,
                                    color: Colors.green,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Payment Verified ✅',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (paymentStatus == 'Pending Verification')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.3),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.hourglass_top,
                                    size: 12,
                                    color: Colors.orange,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Verifying Payment',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTimeline(status),
                      const SizedBox(height: 20),
                      Text(
                        'Order #${orderId.substring(0, 5).toUpperCase()} Items:',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Text(
                                  '${item['quantity']}x',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepOrange,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item['name'],
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                '৳${(item['totalPrice'] ?? 0.0).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(height: 1, thickness: 1),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Amount',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            '৳${totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _getStatusColor(status).withOpacity(0.2),
                          ),
                        ),
                        child: _buildStatusFooter(
                          status,
                          orderId,
                          estimatedTime,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (orderCards.isEmpty) return _buildEmptyState();

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: orderCards,
                ),
              ),
              if (activeGrandTotal > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(25),
                    ),
                  ),
                  child: SafeArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Bill (Active Orders)',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '৳${activeGrandTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 22,
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.deepOrange,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Please wait for bill',
                                style: TextStyle(
                                  color: Colors.deepOrange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
*/