import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';

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

  // ================= NEW: EMPTY STATE UI =================
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

  // ================= NEW: PAYMENT SUCCESS & THANK YOU UI =================
  Widget _buildPaymentSuccess(String message, double amountReceived) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.celebration,
                color: Colors.teal,
                size: 80,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Payment Successful! 🎉',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Amount Paid: \$${amountReceived.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 32),

            // Thank You Message Card
            if (message.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  border: Border.all(color: Colors.teal.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.favorite,
                      color: Colors.redAccent,
                      size: 36,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '"$message"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '- The Chef & Waiter Team',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.restaurant_menu),
                label: const Text(
                  'Start New Order',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.deepOrange),
            );
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error tracking orders!'));
          }

          final allOrders = snapshot.data?.docs ?? [];

          // এই টেবিলের নন-ক্যানসেলড সব অর্ডার
          final tableOrders = allOrders.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['table_no'] == widget.tableNumber &&
                data['status'] != 'Cancelled';
          }).toList();

          // ================= SMART FILTERING LOGIC =================
          // Unpaid বা Pending Verification থাকা মানে এখনো খাওয়া শেষ হয়নি
          final activeOrders = tableOrders.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['payment_status'] == 'Unpaid' ||
                data['payment_status'] == 'Pending Verification';
          }).toList();

          // যদি কোনো রানিং অর্ডার না থাকে
          if (activeOrders.isEmpty) {
            if (tableOrders.isNotEmpty) {
              // সর্বশেষ অর্ডারটি চেক করা হচ্ছে (Stream এমনিতেই descending অর্ডারে ডেটা দেয়)
              final latestOrder =
                  tableOrders.first.data() as Map<String, dynamic>;

              if (latestOrder['payment_status'] == 'Paid') {
                Timestamp? clearedAt = latestOrder['cleared_at'];

                // যদি পেমেন্ট ক্লিয়ার হওয়ার সময়টি গত ৩০ মিনিটের মধ্যে হয়, তবেই Thank You স্ক্রিন দেখাবে
                if (clearedAt != null &&
                    DateTime.now().difference(clearedAt.toDate()).inMinutes <
                        30) {
                  return _buildPaymentSuccess(
                    latestOrder['thank_you_message'] ?? '',
                    (latestOrder['amount_received'] ??
                            latestOrder['total_amount'] ??
                            0.0)
                        .toDouble(),
                  );
                }
              }
            }
            return _buildEmptyState();
          }

          // যদি রানিং অর্ডার থাকে, তবে রেগুলার ট্র্যাকিং লিস্ট দেখাবে
          double tableGrandTotal = 0.0;
          for (var order in activeOrders) {
            final data = order.data() as Map<String, dynamic>;
            tableGrandTotal += (data['total_amount'] ?? 0.0).toDouble();
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: activeOrders.length,
                  itemBuilder: (context, index) {
                    final order = activeOrders[index];
                    final data = order.data() as Map<String, dynamic>;
                    final String orderId = order.id;
                    final String status = data['status'] ?? 'Pending';
                    final int? estimatedTime = data['estimatedTime'];
                    final String paymentStatus =
                        data['payment_status'] ?? 'Unpaid';
                    final double totalAmount = (data['total_amount'] ?? 0.0)
                        .toDouble();
                    final List items = data['items'] ?? [];

                    return Card(
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
                                Text(
                                  'Order #${orderId.substring(0, 5).toUpperCase()}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                if (paymentStatus == 'Pending Verification')
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
                            const Text(
                              'Items Ordered:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
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
                                        border: Border.all(
                                          color: Colors.grey[300]!,
                                        ),
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
                                      '\$${(item['totalPrice'] ?? 0.0).toStringAsFixed(2)}',
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
                                  '\$${totalAmount.toStringAsFixed(2)}',
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
                                color: _getStatusColor(
                                  status,
                                ).withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _getStatusColor(
                                    status,
                                  ).withOpacity(0.2),
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
                    );
                  },
                ),
              ),

              // Bottom Grand Total Bar
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
                            'Total Bill (All Orders)',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '\$${tableGrandTotal.toStringAsFixed(2)}',
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
}
