import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class WaiterScreen extends StatefulWidget {
  final String restaurantId;

  const WaiterScreen({super.key, required this.restaurantId});

  @override
  State<WaiterScreen> createState() => _WaiterScreenState();
}

class _WaiterScreenState extends State<WaiterScreen> {
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;

  // ================= NEW: Sales History Filter Variables =================
  DateTime _selectedFilterDate = DateTime.now();
  String _filterType = 'Daily'; // Options: Daily, Monthly, Yearly

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _authService.logout();
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.redAccent;
      case 'Cooking':
        return Colors.orange;
      case 'Ready':
        return Colors.green;
      case 'Served':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  void _startCookingWithTime(String orderId) {
    final TextEditingController timeController = TextEditingController(
      text: '15',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Set Preparation Time'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How many minutes will it take?'),
            const SizedBox(height: 16),
            TextField(
              controller: timeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Minutes',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.timer),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              int time = int.tryParse(timeController.text) ?? 15;
              _dbService.updateOrderStatus(
                orderId,
                'Cooking',
                estimatedTime: time,
              );
              Navigator.pop(ctx);
            },
            child: const Text(
              'Start Cooking',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ================= PAYMENT VERIFICATION SHEET =================
  void _showPaymentVerificationSheet({
    required int tableNo,
    required double totalBill,
    required String paymentMethod,
    required String senderNumber,
    required String trxId,
  }) {
    final TextEditingController receivedCtrl = TextEditingController(
      text: totalBill.toStringAsFixed(2),
    );
    final TextEditingController messageCtrl = TextEditingController(
      text: 'Thank you for dining with us! Hope to see you again soon. 🎉',
    );
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          double receivedAmount = double.tryParse(receivedCtrl.text) ?? 0.0;
          bool isShortPayment = receivedAmount < totalBill;

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Clear Table $tableNo',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),

                  // Payment Summary Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.teal.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Bill:',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              '\$${totalBill.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Payment Method:',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              paymentMethod,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (paymentMethod != 'Cash') ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Sender Number:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              Text(
                                senderNumber,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TrxID:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              Text(
                                trxId,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Amount Received Input
                  const Text(
                    'Amount Received',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: receivedCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (val) => setSheetState(() {}),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.attach_money),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (isShortPayment)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Warning: Customer paid \$${(totalBill - receivedAmount).toStringAsFixed(2)} less!',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Thank you message
                  const Text(
                    'Customer Message (Optional)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: messageCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Type a thank you message...',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Confirm Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: isProcessing
                          ? null
                          : () async {
                              setSheetState(() => isProcessing = true);
                              bool success = await _dbService.clearTable(
                                restaurantId: widget.restaurantId,
                                tableNo: tableNo,
                                amountReceived:
                                    double.tryParse(receivedCtrl.text) ?? 0.0,
                                thankYouMessage: messageCtrl.text.trim(),
                              );
                              setSheetState(() => isProcessing = false);

                              if (success && mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Payment Confirmed & Table Cleared!',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                      child: isProcessing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Confirm Payment & Clear Table',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ================= SHOW ORDER DETAILS =================
  void _showOrderDetails(Map<String, dynamic> data, int tableNo, String time) {
    final List items = data['items'] ?? [];
    final double totalBill = (data['total_amount'] ?? 0.0).toDouble();
    final double receivedAmount = (data['amount_received'] ?? totalBill)
        .toDouble();
    final String paymentMethod = data['payment_method'] ?? 'Cash';
    final double change = receivedAmount - totalBill;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Table $tableNo - Receipt',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),

            // BD Dhaka Time
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Time (BD Dhaka): $time',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Text(
              'Ordered Items:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Divider(thickness: 1, height: 20),

            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item['quantity']}x ${item['name']}',
                            style: const TextStyle(
                              fontSize: 16,
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
                },
              ),
            ),

            const Divider(thickness: 1, height: 20),

            // Total Bill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Bill:',
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                Text(
                  '\$${totalBill.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Received Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Received Amount ($paymentMethod):',
                  style: const TextStyle(fontSize: 16, color: Colors.teal),
                ),
                Text(
                  '\$${receivedAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),

            // Change Returned (If applicable)
            if (change > 0 && paymentMethod == 'Cash') ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Change Returned:',
                    style: TextStyle(fontSize: 16, color: Colors.deepOrange),
                  ),
                  Text(
                    '\$${change.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ===================== TAB 1: ACTIVE ORDERS =====================
  Widget _buildActiveOrders() {
    return StreamBuilder<QuerySnapshot>(
      stream: _dbService.getOrders(widget.restaurantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.teal),
          );
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading orders!'));
        }

        final allOrders = snapshot.data?.docs ?? [];

        final activeOrders = allOrders.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          bool isNotPaid =
              data['payment_status'] == 'Unpaid' ||
              data['payment_status'] == 'Pending Verification';
          return isNotPaid && data['status'] != 'Cancelled';
        }).toList();

        if (activeOrders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.restaurant_outlined,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                const Text(
                  'No active orders right now.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        Map<int, List<DocumentSnapshot>> groupedOrders = {};
        Map<int, DateTime> tableEarliestTime = {};

        for (var order in activeOrders) {
          final data = order.data() as Map<String, dynamic>;
          int tableNo = data['table_no'] ?? 0;

          if (!groupedOrders.containsKey(tableNo)) {
            groupedOrders[tableNo] = [];
          }
          groupedOrders[tableNo]!.add(order);

          Timestamp? ts = data['created_at'] as Timestamp?;
          DateTime orderTime = ts?.toDate() ?? DateTime.now();

          if (!tableEarliestTime.containsKey(tableNo)) {
            tableEarliestTime[tableNo] = orderTime;
          } else {
            if (orderTime.isBefore(tableEarliestTime[tableNo]!)) {
              tableEarliestTime[tableNo] = orderTime;
            }
          }
        }

        List<int> sortedTables = groupedOrders.keys.toList();
        sortedTables.sort(
          (a, b) => tableEarliestTime[a]!.compareTo(tableEarliestTime[b]!),
        );

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: sortedTables.length,
          itemBuilder: (context, index) {
            int tableNo = sortedTables[index];
            List<DocumentSnapshot> tableOrders = groupedOrders[tableNo]!;

            double tableTotal = 0.0;
            List<Widget> combinedItemsWidget = [];
            bool hasPending = false;
            bool hasCooking = false;
            bool hasReady = false;

            String paymentMethod = 'Cash';
            String senderNumber = '';
            String trxId = '';

            for (var order in tableOrders) {
              final data = order.data() as Map<String, dynamic>;
              final String status = data['status'] ?? 'Pending';
              tableTotal += (data['total_amount'] ?? 0.0).toDouble();

              if (data['payment_method'] != null &&
                  data['payment_method'] != 'Cash') {
                paymentMethod = data['payment_method'];
                senderNumber = data['sender_number'] ?? '';
                trxId = data['trx_id'] ?? '';
              }

              if (status == 'Pending')
                hasPending = true;
              else if (status == 'Cooking')
                hasCooking = true;
              else if (status == 'Ready')
                hasReady = true;

              final List items = data['items'] ?? [];
              for (var item in items) {
                combinedItemsWidget.add(
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item['quantity']}x ${item['name']}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '\$${(item['totalPrice'] ?? 0.0).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            }

            String tableStatus = 'Served';
            if (hasPending)
              tableStatus = 'Pending';
            else if (hasCooking)
              tableStatus = 'Cooking';
            else if (hasReady)
              tableStatus = 'Ready';

            return Card(
              elevation: 4,
              shadowColor: Colors.black12,
              margin: const EdgeInsets.only(bottom: 20.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.table_restaurant,
                                color: Colors.teal,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Table $tableNo',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              tableStatus,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getStatusColor(tableStatus),
                            ),
                          ),
                          child: Text(
                            tableStatus,
                            style: TextStyle(
                              color: _getStatusColor(tableStatus),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, thickness: 1),
                    ...combinedItemsWidget,
                    const Divider(height: 24, thickness: 1),

                    if (paymentMethod != 'Cash') ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$paymentMethod Verification Required',
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Customer Sent From: $senderNumber',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'TrxID: $trxId',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Bill',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '\$${tableTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),

                        if (tableStatus == 'Pending')
                          ElevatedButton.icon(
                            onPressed: () {
                              for (var order in tableOrders) {
                                if ((order.data() as Map)['status'] ==
                                    'Pending')
                                  _startCookingWithTime(order.id);
                              }
                            },
                            icon: const Icon(
                              Icons.local_fire_department,
                              size: 18,
                            ),
                            label: const Text('Start Cooking'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          )
                        else if (tableStatus == 'Cooking')
                          ElevatedButton.icon(
                            onPressed: () {
                              for (var order in tableOrders) {
                                if ((order.data() as Map)['status'] ==
                                    'Cooking')
                                  _dbService.updateOrderStatus(
                                    order.id,
                                    'Ready',
                                  );
                              }
                            },
                            icon: const Icon(Icons.done_all, size: 18),
                            label: const Text('Mark Ready'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          )
                        else if (tableStatus == 'Ready')
                          ElevatedButton.icon(
                            onPressed: () {
                              for (var order in tableOrders) {
                                if ((order.data() as Map)['status'] == 'Ready')
                                  _dbService.updateOrderStatus(
                                    order.id,
                                    'Served',
                                  );
                              }
                            },
                            icon: const Icon(Icons.room_service, size: 18),
                            label: const Text('Mark Served'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: () => _showPaymentVerificationSheet(
                              tableNo: tableNo,
                              totalBill: tableTotal,
                              paymentMethod: paymentMethod,
                              senderNumber: senderNumber,
                              trxId: trxId,
                            ),
                            icon: const Icon(Icons.price_check, size: 18),
                            label: Text(
                              paymentMethod == 'Cash'
                                  ? 'Clear / Pay'
                                  : 'Verify & Clear',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===================== NEW: DATE FILTER LOGIC =====================
  String _getFormattedDateLabel() {
    if (_filterType == 'Daily') {
      return DateFormat('dd MMM yyyy').format(_selectedFilterDate);
    } else if (_filterType == 'Monthly') {
      return DateFormat('MMMM yyyy').format(_selectedFilterDate);
    } else {
      return DateFormat('yyyy').format(_selectedFilterDate);
    }
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedFilterDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedFilterDate = picked;
      });
    }
  }

  // ===================== TAB 2: TODAY'S SALES (HISTORY) =====================
  Widget _buildSalesHistory() {
    return Column(
      children: [
        // --- Filter Section ---
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Filter Dropdown
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _filterType,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.teal),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                    items: ['Daily', 'Monthly', 'Yearly'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _filterType = newValue!;
                      });
                    },
                  ),
                ),
              ),

              // Date Picker Button
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.teal,
                ),
                label: Text(
                  _getFormattedDateLabel(),
                  style: const TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.teal),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),

        // --- Sales Data Stream ---
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _dbService.getOrders(widget.restaurantId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.teal),
                );
              }

              final allOrders = snapshot.data?.docs ?? [];

              // ================= FILTER LOGIC: Paid & Date Match =================
              final paidOrders = allOrders.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                if (data['payment_status'] != 'Paid') return false;

                Timestamp? ts = data['created_at'] as Timestamp?;
                if (ts == null) return false;

                // UTC +6 Conversion (BD Time)
                DateTime orderDate = ts.toDate().toUtc().add(
                  const Duration(hours: 6),
                );

                if (_filterType == 'Daily') {
                  return orderDate.year == _selectedFilterDate.year &&
                      orderDate.month == _selectedFilterDate.month &&
                      orderDate.day == _selectedFilterDate.day;
                } else if (_filterType == 'Monthly') {
                  return orderDate.year == _selectedFilterDate.year &&
                      orderDate.month == _selectedFilterDate.month;
                } else if (_filterType == 'Yearly') {
                  return orderDate.year == _selectedFilterDate.year;
                }
                return true;
              }).toList();

              if (paidOrders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy_outlined,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No sales recorded for this period.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              double totalIncome = 0.0;
              int totalItemsSold = 0;
              for (var order in paidOrders) {
                final data = order.data() as Map<String, dynamic>;
                totalIncome += (data['total_amount'] ?? 0.0).toDouble();
                totalItemsSold += (data['items'] as List).length;
              }

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.teal, Colors.tealAccent],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text(
                              'Total Revenue',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '\$${totalIncome.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(width: 1, height: 40, color: Colors.white30),
                        Column(
                          children: [
                            const Text(
                              'Orders Completed',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '$totalItemsSold',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: paidOrders.length,
                      itemBuilder: (context, index) {
                        final data =
                            paidOrders[index].data() as Map<String, dynamic>;
                        final int tableNo = data['table_no'] ?? 0;
                        final double amount = (data['total_amount'] ?? 0.0)
                            .toDouble();
                        final Timestamp? timestamp =
                            data['created_at'] as Timestamp?;
                        final String paymentMethod =
                            data['payment_method'] ?? 'Cash';

                        String formattedTime = 'Unknown Time';
                        if (timestamp != null) {
                          DateTime dt = timestamp.toDate().toUtc().add(
                            const Duration(hours: 6),
                          );
                          formattedTime = DateFormat(
                            'hh:mm a, dd MMM yyyy',
                          ).format(dt);
                        }

                        return Card(
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            onTap: () =>
                                _showOrderDetails(data, tableNo, formattedTime),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: paymentMethod == 'Cash'
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.pink.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                paymentMethod == 'Cash'
                                    ? Icons.money
                                    : Icons.phone_android,
                                color: paymentMethod == 'Cash'
                                    ? Colors.green
                                    : Colors.pink,
                              ),
                            ),
                            title: Text(
                              'Table $tableNo ($paymentMethod)',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              formattedTime,
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Text(
                              '\$${amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.teal,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedIndex == 0 ? 'Active Orders' : 'Sales History',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            Text(
              'Restaurant ID: ${widget.restaurantId}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _confirmLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _selectedIndex == 0 ? _buildActiveOrders() : _buildSalesHistory(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: Colors.teal,
          unselectedItemColor: Colors.grey[500],
          backgroundColor: Colors.white,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant),
              label: 'Live Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_edu),
              label: 'Sales History',
            ),
          ],
        ),
      ),
    );
  }
}
