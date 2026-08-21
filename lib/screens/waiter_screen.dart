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

  DateTime _selectedFilterDate = DateTime.now();
  String _filterType = 'Daily';

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

  // ================= ORDER HISTORY DETAILS BOTTOM SHEET =================
  void _showOrderHistoryDetails(
    Map<String, dynamic> data,
    int tableNo,
    String time,
  ) {
    final String customerName = data['customer_name'] ?? 'Guest';
    final List items = data['items'] ?? [];
    final double totalBill = (data['total_amount'] ?? 0.0).toDouble();
    final String paymentMethod = data['payment_method'] ?? 'Cash';
    final String paymentStatus = data['payment_status'] ?? 'Unpaid';

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
                Expanded(
                  child: Text(
                    'Table $tableNo - $customerName',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  time,
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
                          '৳${(item['totalPrice'] ?? 0.0).toStringAsFixed(2)}',
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount:',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '৳${totalBill.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
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
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  paymentMethod,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Payment Status:',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  paymentStatus,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: paymentStatus == 'Paid' ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ================= WAITER SERVE ACTION (No Payment Logic Here) =================
  void _markTableAsServed(
    int tableNo,
    String customerName,
    List<DocumentSnapshot> tableOrders,
  ) {
    final TextEditingController messageCtrl = TextEditingController(
      text: 'Hope you enjoy the food! Have a great time! 😊',
    );
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Serve $customerName (T$tableNo)',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(),
                const Text(
                  'Send a greeting message to the customer (This will show on their tracking screen):',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: isProcessing
                        ? null
                        : () async {
                            setSheetState(() => isProcessing = true);
                            for (var order in tableOrders) {
                              if ((order.data() as Map)['status'] == 'Ready') {
                                await _dbService.updateOrderStatus(
                                  order.id,
                                  'Served',
                                  thankYouMessage: messageCtrl.text.trim(),
                                );
                              }
                            }
                            setSheetState(() => isProcessing = false);

                            if (mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Food Served to Customer! ✅'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                    child: isProcessing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Mark as Served',
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
          );
        },
      ),
    );
  }

  // ===================== TAB 1: ACTIVE ORDERS =====================
  Widget _buildActiveOrders() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('restaurant_id', isEqualTo: widget.restaurantId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(
            child: CircularProgressIndicator(color: Colors.teal),
          );
        if (snapshot.hasError)
          return const Center(child: Text('Error loading orders!'));

        final allOrders = snapshot.data?.docs ?? [];

        final activeOrders = allOrders.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['status'] == 'Cancelled') return false;
          bool isNotPaid = data['payment_status'] != 'Paid';
          bool isNotServed = data['status'] != 'Served';
          return isNotPaid || isNotServed;
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

        // GROUP BY BOTH TABLE NO & CUSTOMER NAME
        Map<String, List<DocumentSnapshot>> groupedOrders = {};
        for (var order in activeOrders) {
          final data = order.data() as Map<String, dynamic>;
          String groupKey =
              '${data['table_no']}|${data['customer_name'] ?? 'Guest'}';
          if (!groupedOrders.containsKey(groupKey))
            groupedOrders[groupKey] = [];
          groupedOrders[groupKey]!.add(order);
        }

        List<String> sortedGroups = groupedOrders.keys.toList()
          ..sort((a, b) {
            int tA = int.parse(a.split('|')[0]);
            int tB = int.parse(b.split('|')[0]);
            int comp = tA.compareTo(tB);
            if (comp != 0) return comp;
            return a.split('|')[1].compareTo(b.split('|')[1]);
          });

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: sortedGroups.length,
          itemBuilder: (context, index) {
            String groupKey = sortedGroups[index];
            int tableNo = int.parse(groupKey.split('|')[0]);
            String customerName = groupKey.split('|')[1];
            List<DocumentSnapshot> tableOrders = groupedOrders[groupKey]!;

            List<Widget> combinedItemsWidget = [];
            bool hasPending = false;
            bool hasCooking = false;
            bool hasReady = false;
            bool hasServed = false;
            bool isAllPaid = true;

            for (var order in tableOrders) {
              final data = order.data() as Map<String, dynamic>;
              final String status = data['status'] ?? 'Pending';

              if (data['payment_status'] != 'Paid') isAllPaid = false;

              if (status == 'Pending')
                hasPending = true;
              else if (status == 'Cooking')
                hasCooking = true;
              else if (status == 'Ready')
                hasReady = true;
              else if (status == 'Served')
                hasServed = true;

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
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.teal.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.teal,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Table $tableNo',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      customerName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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

                    if (isAllPaid && tableStatus != 'Served')
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Payment Received by Admin ✅',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),

                    // Waiter Action
                    if (tableStatus == 'Ready')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _markTableAsServed(
                            tableNo,
                            customerName,
                            tableOrders,
                          ),
                          icon: const Icon(Icons.room_service, size: 18),
                          label: const Text('Mark Served & Send Greeting'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      )
                    else if (tableStatus == 'Served' && !isAllPaid)
                      const Text(
                        'Food served! Waiting for Admin to confirm payment. 💵',
                        style: TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else if (tableStatus == 'Pending' ||
                        tableStatus == 'Cooking')
                      const Text(
                        'Cooking in Kitchen 🧑‍🍳',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
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

  // ===================== DATE FILTER LOGIC =====================
  String _getFormattedDateLabel() {
    if (_filterType == 'Daily')
      return DateFormat('dd MMM yyyy').format(_selectedFilterDate);
    else if (_filterType == 'Monthly')
      return DateFormat('MMMM yyyy').format(_selectedFilterDate);
    else
      return DateFormat('yyyy').format(_selectedFilterDate);
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedFilterDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Colors.teal,
            onPrimary: Colors.white,
            onSurface: Colors.black87,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedFilterDate = picked);
  }

  // ===================== TAB 2: TODAY'S SALES (HISTORY) =====================
  Widget _buildSalesHistory() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
                    onChanged: (newValue) =>
                        setState(() => _filterType = newValue!),
                  ),
                ),
              ),
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

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _dbService.getOrders(widget.restaurantId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(
                  child: CircularProgressIndicator(color: Colors.teal),
                );
              final allOrders = snapshot.data?.docs ?? [];
              final paidOrders = allOrders.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                if (data['payment_status'] != 'Paid') return false;
                Timestamp? ts = data['created_at'] as Timestamp?;
                if (ts == null) return false;
                DateTime orderDate = ts.toDate().toUtc().add(
                  const Duration(hours: 6),
                );
                if (_filterType == 'Daily')
                  return orderDate.year == _selectedFilterDate.year &&
                      orderDate.month == _selectedFilterDate.month &&
                      orderDate.day == _selectedFilterDate.day;
                else if (_filterType == 'Monthly')
                  return orderDate.year == _selectedFilterDate.year &&
                      orderDate.month == _selectedFilterDate.month;
                else if (_filterType == 'Yearly')
                  return orderDate.year == _selectedFilterDate.year;
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

              // Only calculation for Orders and Items (Removed Revenue)
              int totalItemsSold = 0;
              int totalOrdersCompleted = paidOrders.length;
              for (var order in paidOrders) {
                final data = order.data() as Map<String, dynamic>;
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
                              'Orders Completed',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '$totalOrdersCompleted',
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
                              'Items Served',
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
                        final String customerName =
                            data['customer_name'] ?? 'Guest';
                        final String paymentMethod =
                            data['payment_method'] ?? 'Cash';

                        // formatting time
                        Timestamp? timestamp = data['created_at'] as Timestamp?;
                        String formattedTime = 'Unknown Time';
                        if (timestamp != null) {
                          DateTime dt = timestamp.toDate().toUtc().add(
                            const Duration(hours: 6),
                          );
                          formattedTime = DateFormat('hh:mm a').format(dt);
                        }

                        return Card(
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            onTap: () => _showOrderHistoryDetails(
                              data,
                              tableNo,
                              formattedTime,
                            ),
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
                              'Table $tableNo - $customerName ($paymentMethod)',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Colors.grey,
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

/*
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

  DateTime _selectedFilterDate = DateTime.now();
  String _filterType = 'Daily';

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

  // ================= WAITER SERVE ACTION =================
  void _markTableAsServed(
    int tableNo,
    String customerName,
    List<DocumentSnapshot> tableOrders,
  ) {
    final TextEditingController messageCtrl = TextEditingController(
      text: 'Hope you enjoy the food! Have a great time! 😊',
    );
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Serve $customerName (T$tableNo)',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(),
                const Text(
                  'Send a greeting message to the customer (This will show on their tracking screen):',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: isProcessing
                        ? null
                        : () async {
                            setSheetState(() => isProcessing = true);
                            for (var order in tableOrders) {
                              if ((order.data() as Map)['status'] == 'Ready') {
                                await _dbService.updateOrderStatus(
                                  order.id,
                                  'Served',
                                  thankYouMessage: messageCtrl.text.trim(),
                                );
                              }
                            }
                            setSheetState(() => isProcessing = false);

                            if (mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Food Served to Customer! ✅'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                    child: isProcessing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Mark as Served',
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
          );
        },
      ),
    );
  }

  Widget _buildActiveOrders() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('restaurant_id', isEqualTo: widget.restaurantId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(
            child: CircularProgressIndicator(color: Colors.teal),
          );
        if (snapshot.hasError)
          return const Center(child: Text('Error loading orders!'));

        final allOrders = snapshot.data?.docs ?? [];

        final activeOrders = allOrders.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['status'] == 'Cancelled') return false;
          bool isNotPaid = data['payment_status'] != 'Paid';
          bool isNotServed = data['status'] != 'Served';
          return isNotPaid || isNotServed;
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

        // GROUP BY BOTH TABLE NO & CUSTOMER NAME
        Map<String, List<DocumentSnapshot>> groupedOrders = {};
        for (var order in activeOrders) {
          final data = order.data() as Map<String, dynamic>;
          String groupKey =
              '${data['table_no']}|${data['customer_name'] ?? 'Guest'}';
          if (!groupedOrders.containsKey(groupKey))
            groupedOrders[groupKey] = [];
          groupedOrders[groupKey]!.add(order);
        }

        List<String> sortedGroups = groupedOrders.keys.toList()
          ..sort((a, b) {
            int tA = int.parse(a.split('|')[0]);
            int tB = int.parse(b.split('|')[0]);
            int comp = tA.compareTo(tB);
            if (comp != 0) return comp;
            return a.split('|')[1].compareTo(b.split('|')[1]);
          });

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: sortedGroups.length,
          itemBuilder: (context, index) {
            String groupKey = sortedGroups[index];
            int tableNo = int.parse(groupKey.split('|')[0]);
            String customerName = groupKey.split('|')[1];
            List<DocumentSnapshot> tableOrders = groupedOrders[groupKey]!;

            List<Widget> combinedItemsWidget = [];
            bool hasPending = false;
            bool hasCooking = false;
            bool hasReady = false;
            bool hasServed = false;
            bool isAllPaid = true;

            for (var order in tableOrders) {
              final data = order.data() as Map<String, dynamic>;
              final String status = data['status'] ?? 'Pending';

              if (data['payment_status'] != 'Paid') isAllPaid = false;

              if (status == 'Pending')
                hasPending = true;
              else if (status == 'Cooking')
                hasCooking = true;
              else if (status == 'Ready')
                hasReady = true;
              else if (status == 'Served')
                hasServed = true;

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
                                Icons.person,
                                color: Colors.teal,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Table $tableNo',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  customerName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                              ],
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

                    if (isAllPaid && tableStatus != 'Served')
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Payment Received by Admin ✅',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),

                    if (tableStatus == 'Ready')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _markTableAsServed(
                            tableNo,
                            customerName,
                            tableOrders,
                          ),
                          icon: const Icon(Icons.room_service, size: 18),
                          label: const Text('Mark Served & Send Greeting'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      )
                    else if (tableStatus == 'Served' && !isAllPaid)
                      const Text(
                        'Food served! Waiting for Admin to confirm payment. 💵',
                        style: TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else if (tableStatus == 'Pending' ||
                        tableStatus == 'Cooking')
                      const Text(
                        'Cooking in Kitchen 🧑‍🍳',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
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

  String _getFormattedDateLabel() {
    if (_filterType == 'Daily')
      return DateFormat('dd MMM yyyy').format(_selectedFilterDate);
    else if (_filterType == 'Monthly')
      return DateFormat('MMMM yyyy').format(_selectedFilterDate);
    else
      return DateFormat('yyyy').format(_selectedFilterDate);
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedFilterDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Colors.teal,
            onPrimary: Colors.white,
            onSurface: Colors.black87,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedFilterDate = picked);
  }

  Widget _buildSalesHistory() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
                    items: ['Daily', 'Monthly', 'Yearly']
                        .map(
                          (String value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (newValue) =>
                        setState(() => _filterType = newValue!),
                  ),
                ),
              ),
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

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _dbService.getOrders(widget.restaurantId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(
                  child: CircularProgressIndicator(color: Colors.teal),
                );
              final allOrders = snapshot.data?.docs ?? [];
              final paidOrders = allOrders.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                if (data['payment_status'] != 'Paid') return false;
                Timestamp? ts = data['created_at'] as Timestamp?;
                if (ts == null) return false;
                DateTime orderDate = ts.toDate().toUtc().add(
                  const Duration(hours: 6),
                );
                if (_filterType == 'Daily')
                  return orderDate.year == _selectedFilterDate.year &&
                      orderDate.month == _selectedFilterDate.month &&
                      orderDate.day == _selectedFilterDate.day;
                else if (_filterType == 'Monthly')
                  return orderDate.year == _selectedFilterDate.year &&
                      orderDate.month == _selectedFilterDate.month;
                else if (_filterType == 'Yearly')
                  return orderDate.year == _selectedFilterDate.year;
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
                              '৳${totalIncome.toStringAsFixed(2)}',
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
                        final String customerName =
                            data['customer_name'] ?? 'Guest';
                        final double amount = (data['total_amount'] ?? 0.0)
                            .toDouble();
                        final String paymentMethod =
                            data['payment_method'] ?? 'Cash';
                        return Card(
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
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
                              'Table $tableNo - $customerName ($paymentMethod)',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: Text(
                              '৳${amount.toStringAsFixed(2)}',
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
*/
