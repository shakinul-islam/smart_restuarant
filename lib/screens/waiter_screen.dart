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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.redAccent),
            SizedBox(width: 10),
            Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of your shift?',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              elevation: 0,
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
            child: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
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

  void _showOrderHistoryDetails(Map<String, dynamic> groupData) {
    final int tableNo = groupData['table_no'];
    final String customerName = groupData['customer_name'];
    final double totalBill = groupData['total_amount'];
    final String paymentMethod = groupData['payment_method'];
    final String paymentStatus = groupData['payment_status'];
    final List items = groupData['items'];
    final String formattedTime = groupData['formatted_time'];

    final bool hasParcel = groupData['has_parcel'];
    final bool hasDineIn = groupData['has_dine_in'];

    String typeBadge = (hasParcel && hasDineIn)
        ? 'Mixed Order 🍽️🛍️'
        : (hasParcel ? 'Parcel Order 🛍️' : 'Dine-in Order 🍽️');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 24,
            right: 24,
            top: 12,
          ),
          // OVERFLOW FIX: Changed Column to ListView to make the whole sheet scrollable
          child: ListView(
            controller: controller,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      tableNo == 0
                          ? 'Parcel - $customerName'
                          : 'Table $tableNo - $customerName',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    formattedTime,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: (hasParcel ? Colors.deepOrange : Colors.teal)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      typeBadge,
                      style: TextStyle(
                        color: hasParcel ? Colors.deepOrange : Colors.teal,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Ordered Items:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const Divider(thickness: 1, height: 24, color: Colors.black12),

              // OVERFLOW FIX: Removed ConstrainedBox, used shrinkWrap true
              ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final bool isParcel = item['isParcel'] ?? false;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: isParcel ? Colors.deepOrange : Colors.teal,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${item['quantity']}x ${item['name']}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isParcel
                                  ? Colors.deepOrange[700]
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        if (isParcel)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.deepOrange.withOpacity(0.3),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('🛍️', style: TextStyle(fontSize: 10)),
                                SizedBox(width: 4),
                                Text(
                                  'Parcel',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.deepOrange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Text(
                          '৳${(item['totalPrice'] ?? 0.0).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Divider(thickness: 1, height: 24, color: Colors.black12),
              _buildDetailRow(
                'Total Amount:',
                '৳${totalBill.toStringAsFixed(2)}',
                isBold: true,
                valueColor: Colors.teal,
                fontSize: 18,
              ),
              const SizedBox(height: 12),
              _buildDetailRow('Payment Method:', paymentMethod),
              const SizedBox(height: 8),
              _buildDetailRow(
                'Payment Status:',
                paymentStatus,
                valueColor: paymentStatus == 'Paid' ? Colors.green : Colors.red,
                isBold: true,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String title,
    String value, {
    bool isBold = false,
    Color? valueColor,
    double fontSize = 14,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: fontSize,
            color: isBold ? Colors.black87 : Colors.grey,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

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
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 24,
              right: 24,
              top: 12,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Serve $customerName (T$tableNo)',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.black12, height: 24),
                  const Text(
                    'Send a greeting message to the customer (This will show on their tracking screen):',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: messageCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Type a pleasant message...',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Colors.teal),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: isProcessing
                          ? null
                          : () async {
                              setSheetState(() => isProcessing = true);
                              for (var order in tableOrders) {
                                if ((order.data() as Map)['status'] ==
                                    'Ready') {
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
                                    content: Text(
                                      'Food Served to Customer! ✅',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                      child: isProcessing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Mark Served & Send Greeting',
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

  Widget _buildActiveOrders() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: StreamBuilder<QuerySnapshot>(
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
                    Text(
                      'No active orders right now.',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

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

            return Column(
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.teal,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.people_alt,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Active Tickets: ${sortedGroups.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = constraints.maxWidth < 600
                          ? 1
                          : constraints.maxWidth < 900
                          ? 2
                          : constraints.maxWidth < 1300
                          ? 3
                          : 4;
                      return GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(16.0),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisExtent: 280,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: sortedGroups.length,
                        itemBuilder: (context, index) {
                          String groupKey = sortedGroups[index];
                          int tableNo = int.parse(groupKey.split('|')[0]);
                          String customerName = groupKey.split('|')[1];
                          List<DocumentSnapshot> tableOrders =
                              groupedOrders[groupKey]!;

                          List<Map<String, dynamic>> itemsList = [];
                          bool hasPending = false,
                              hasCooking = false,
                              hasReady = false,
                              hasServed = false,
                              isAllPaid = true,
                              hasParcel = false,
                              hasDineIn = false;

                          for (var order in tableOrders) {
                            final data = order.data() as Map<String, dynamic>;
                            final String status = data['status'] ?? 'Pending';
                            final bool isDocParcel =
                                data['order_type'] == 'Parcel';

                            if (isDocParcel)
                              hasParcel = true;
                            else
                              hasDineIn = true;
                            if (data['payment_status'] != 'Paid')
                              isAllPaid = false;

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
                              itemsList.add({
                                'text': '${item['quantity']}x ${item['name']}',
                                'isParcel': isDocParcel,
                              });
                            }
                          }

                          String tableStatus = 'Served';
                          if (hasPending)
                            tableStatus = 'Pending';
                          else if (hasCooking)
                            tableStatus = 'Cooking';
                          else if (hasReady)
                            tableStatus = 'Ready';

                          String typeBadge = (hasParcel && hasDineIn)
                              ? 'Mixed 🍽️🛍️'
                              : (hasParcel ? 'Parcel 🛍️' : 'Dine-in 🍽️');
                          Color typeColor = hasParcel
                              ? Colors.deepOrange
                              : Colors.blue;

                          return Card(
                            elevation: 2,
                            shadowColor: Colors.black12,
                            margin: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                              side: BorderSide(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    16,
                                    16,
                                    12,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.teal.withOpacity(
                                                  0.1,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.person,
                                                color: Colors.teal,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        tableNo == 0
                                                            ? 'Parcel'
                                                            : 'Table $tableNo',
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: typeColor
                                                              .withOpacity(0.1),
                                                          border: Border.all(
                                                            color: typeColor
                                                                .withOpacity(
                                                                  0.3,
                                                                ),
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          typeBadge,
                                                          style: TextStyle(
                                                            color: typeColor,
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    customerName,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.teal,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: _getStatusColor(tableStatus),
                                          ),
                                        ),
                                        child: Text(
                                          tableStatus,
                                          style: TextStyle(
                                            color: _getStatusColor(tableStatus),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1, color: Colors.black12),

                                Expanded(
                                  child: Scrollbar(
                                    thumbVisibility: true,
                                    child: ListView.builder(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: itemsList.length,
                                      itemBuilder: (ctx, i) {
                                        final itemData = itemsList[i];
                                        final bool isItemParcel =
                                            itemData['isParcel'];

                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8.0,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  itemData['text'],
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                    color: isItemParcel
                                                        ? Colors.deepOrange[700]
                                                        : Colors.black87,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isItemParcel)
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                    left: 8,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.deepOrange
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.deepOrange
                                                          .withOpacity(0.3),
                                                    ),
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        '🛍️',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        'Parcel',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color:
                                                              Colors.deepOrange,
                                                          fontWeight:
                                                              FontWeight.bold,
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
                                ),
                                const Divider(height: 1, color: Colors.black12),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    children: [
                                      if (isAllPaid && tableStatus != 'Served')
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
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
                                        )
                                      else if (tableStatus == 'Ready')
                                        SizedBox(
                                          width: double.infinity,
                                          height: 45,
                                          child: ElevatedButton.icon(
                                            onPressed: () => _markTableAsServed(
                                              tableNo,
                                              customerName,
                                              tableOrders,
                                            ),
                                            icon: const Icon(
                                              Icons.room_service,
                                              size: 18,
                                            ),
                                            label: const Text(
                                              'Mark Served & Send Greeting',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.teal,
                                              foregroundColor: Colors.white,
                                              elevation: 1,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),
                                        )
                                      else if (tableStatus == 'Served' &&
                                          !isAllPaid)
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.blueGrey.withOpacity(
                                              0.05,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Row(
                                            children: [
                                              Icon(
                                                Icons.info_outline,
                                                color: Colors.teal,
                                                size: 18,
                                              ),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Food served! Waiting for Admin to confirm payment.',
                                                  style: TextStyle(
                                                    color: Colors.teal,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      else if (tableStatus == 'Pending' ||
                                          tableStatus == 'Cooking')
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(
                                              0.05,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.soup_kitchen,
                                                color: Colors.orange,
                                                size: 18,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Cooking in Kitchen...',
                                                style: TextStyle(
                                                  color: Colors.orange,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
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

  // ===================== TAB 2: SALES HISTORY =====================
  Widget _buildSalesHistory() {
    return Column(
      children: [
        // Modern Filter Bar
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey[200]!),
          ),
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
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _filterType,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.teal),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                      fontSize: 15,
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
                    borderRadius: BorderRadius.circular(10),
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
                DateTime orderDate = ts.toDate().toLocal();
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
                      Text(
                        'No sales recorded for this period.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              Map<String, Map<String, dynamic>> groupedOrders = {};

              for (var doc in paidOrders) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                int tableNo = data['table_no'] ?? 0;
                String customerName = data['customer_name'] ?? 'Guest';
                String orderType = data['order_type'] ?? 'Dine-in';
                String paymentMethod = data['payment_method'] ?? 'Cash';
                DateTime orderDate = (data['created_at'] as Timestamp)
                    .toDate()
                    .toLocal();
                String formattedTime = DateFormat(
                  'hh:mm a, dd MMM',
                ).format(orderDate);

                String timeKey;
                if (data['cleared_at'] != null) {
                  timeKey = (data['cleared_at'] as Timestamp).seconds
                      .toString();
                } else {
                  timeKey = DateFormat('dd MMM yyyy HH').format(orderDate);
                }
                String groupKey = '$tableNo|$customerName|$timeKey';

                double amount = (data['total_amount'] ?? 0.0).toDouble();

                if (!groupedOrders.containsKey(groupKey)) {
                  groupedOrders[groupKey] = {
                    'table_no': tableNo,
                    'customer_name': customerName,
                    'total_amount': amount,
                    'items': [],
                    'has_parcel': orderType == 'Parcel',
                    'has_dine_in': orderType != 'Parcel',
                    'formatted_time': formattedTime,
                    'created_dt': orderDate,
                    'payment_method': paymentMethod,
                    'payment_status': data['payment_status'] ?? 'Paid',
                  };
                } else {
                  groupedOrders[groupKey]!['total_amount'] += amount;
                  if (orderType == 'Parcel')
                    groupedOrders[groupKey]!['has_parcel'] = true;
                  else
                    groupedOrders[groupKey]!['has_dine_in'] = true;

                  if (orderDate.isAfter(
                    groupedOrders[groupKey]!['created_dt'],
                  )) {
                    groupedOrders[groupKey]!['created_dt'] = orderDate;
                    groupedOrders[groupKey]!['formatted_time'] = formattedTime;
                  }
                }

                List items = data['items'] ?? [];
                for (var item in items) {
                  groupedOrders[groupKey]!['items'].add({
                    'name': item['name'],
                    'quantity': item['quantity'],
                    'totalPrice': (item['totalPrice'] ?? 0).toDouble(),
                    'isParcel': orderType == 'Parcel',
                  });
                }
              }

              List<Map<String, dynamic>> finalGroupedOrders = groupedOrders
                  .values
                  .toList();
              finalGroupedOrders.sort(
                (a, b) => b['created_dt'].compareTo(a['created_dt']),
              );

              int totalItemsSold = 0;
              for (var group in finalGroupedOrders) {
                totalItemsSold += (group['items'] as List).length;
              }

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.teal, Color(0xFF26A69A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.receipt_long,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${finalGroupedOrders.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Orders Completed',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Container(width: 1, height: 60, color: Colors.white30),
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.fastfood,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '$totalItemsSold',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Items Served',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = constraints.maxWidth < 600
                            ? 1
                            : constraints.maxWidth < 900
                            ? 2
                            : constraints.maxWidth < 1300
                            ? 3
                            : 4;

                        return GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisExtent: 110,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          itemCount: finalGroupedOrders.length,
                          itemBuilder: (context, index) {
                            final groupData = finalGroupedOrders[index];
                            final int tableNo = groupData['table_no'];
                            final String customerName =
                                groupData['customer_name'];
                            final String paymentMethod =
                                groupData['payment_method'];
                            final String formattedTime =
                                groupData['formatted_time'];

                            final bool hasParcel = groupData['has_parcel'];
                            final bool hasDineIn = groupData['has_dine_in'];

                            String typeBadge = (hasParcel && hasDineIn)
                                ? 'Mixed 🍽️🛍️'
                                : (hasParcel ? 'Parcel 🛍️' : 'Dine-in 🍽️');
                            Color typeColor = hasParcel
                                ? Colors.deepOrange
                                : Colors.teal;

                            return Card(
                              elevation: 1,
                              margin: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                                side: BorderSide(color: Colors.grey[200]!),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                onTap: () =>
                                    _showOrderHistoryDetails(groupData),
                                leading: Container(
                                  padding: const EdgeInsets.all(12),
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
                                title: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        tableNo == 0
                                            ? 'Parcel'
                                            : 'Table $tableNo',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: typeColor.withOpacity(0.1),
                                        border: Border.all(
                                          color: typeColor.withOpacity(0.3),
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        typeBadge,
                                        style: TextStyle(
                                          color: typeColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    '$customerName  •  $formattedTime',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                trailing: Text(
                                  '৳${groupData['total_amount'].toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.teal,
                                  ),
                                ),
                              ),
                            );
                          },
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
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('restaurant_settings')
          .doc(widget.restaurantId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.teal)),
          );

        // ================= NEW: KILL SWITCH & NOTICE LOGIC =================
        bool isActive = true;
        String notice = '';

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          if (data.containsKey('is_active')) isActive = data['is_active'];
          if (data.containsKey('notice_message'))
            notice = data['notice_message'];
        }

        if (!isActive) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.block, size: 80, color: Colors.redAccent),
                    const SizedBox(height: 20),
                    const Text(
                      'Subscription Suspended',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Your access to the Waiter Panel has been temporarily suspended. Please ask your administrator to clear the dues.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        await _authService.logout();
                        if (!mounted) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(
              _selectedIndex == 0 ? 'Active Orders' : 'Sales History',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            elevation: 0,
            bottom: notice.isNotEmpty
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(40),
                    child: Container(
                      width: double.infinity,
                      color: Colors.amber,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.campaign,
                            color: Colors.brown,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              notice,
                              style: const TextStyle(
                                color: Colors.brown,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : null,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                onPressed: _confirmLogout,
                tooltip: 'Logout',
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: _selectedIndex == 0
              ? _buildActiveOrders()
              : _buildSalesHistory(),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 15,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              selectedItemColor: Colors.teal,
              unselectedItemColor: Colors.grey[400],
              backgroundColor: Colors.white,
              elevation: 0,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.restaurant_outlined),
                  ),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.restaurant, size: 28),
                  ),
                  label: 'Live Orders',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.history_edu_outlined),
                  ),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.history_edu, size: 28),
                  ),
                  label: 'Sales History',
                ),
              ],
            ),
          ),
        );
      },
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.redAccent),
            SizedBox(width: 10),
            Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of your shift?',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              elevation: 0,
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
            child: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
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

  void _showOrderHistoryDetails(Map<String, dynamic> groupData) {
    final int tableNo = groupData['table_no'];
    final String customerName = groupData['customer_name'];
    final double totalBill = groupData['total_amount'];
    final String paymentMethod = groupData['payment_method'];
    final String paymentStatus = groupData['payment_status'];
    final List items = groupData['items'];
    final String formattedTime = groupData['formatted_time'];

    final bool hasParcel = groupData['has_parcel'];
    final bool hasDineIn = groupData['has_dine_in'];

    String typeBadge = (hasParcel && hasDineIn)
        ? 'Mixed Order 🍽️🛍️'
        : (hasParcel ? 'Parcel Order 🛍️' : 'Dine-in Order 🍽️');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 24,
            right: 24,
            top: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      tableNo == 0
                          ? 'Parcel - $customerName'
                          : 'Table $tableNo - $customerName',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    formattedTime,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: (hasParcel ? Colors.deepOrange : Colors.teal)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      typeBadge,
                      style: TextStyle(
                        color: hasParcel ? Colors.deepOrange : Colors.teal,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Ordered Items:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const Divider(thickness: 1, height: 24, color: Colors.black12),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.3,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final bool isParcel = item['isParcel'] ?? false;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: isParcel ? Colors.deepOrange : Colors.teal,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${item['quantity']}x ${item['name']}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isParcel
                                    ? Colors.deepOrange[700]
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          if (isParcel)
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.deepOrange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.deepOrange.withOpacity(0.3),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('🛍️', style: TextStyle(fontSize: 10)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Parcel',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.deepOrange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Text(
                            '৳${(item['totalPrice'] ?? 0.0).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(thickness: 1, height: 24, color: Colors.black12),
              _buildDetailRow(
                'Total Amount:',
                '৳${totalBill.toStringAsFixed(2)}',
                isBold: true,
                valueColor: Colors.teal,
                fontSize: 18,
              ),
              const SizedBox(height: 12),
              _buildDetailRow('Payment Method:', paymentMethod),
              const SizedBox(height: 8),
              _buildDetailRow(
                'Payment Status:',
                paymentStatus,
                valueColor: paymentStatus == 'Paid' ? Colors.green : Colors.red,
                isBold: true,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String title,
    String value, {
    bool isBold = false,
    Color? valueColor,
    double fontSize = 14,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: fontSize,
            color: isBold ? Colors.black87 : Colors.grey,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

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
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 24,
              right: 24,
              top: 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Serve $customerName (T$tableNo)',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(color: Colors.black12, height: 24),
                const Text(
                  'Send a greeting message to the customer (This will show on their tracking screen):',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Type a pleasant message...',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Colors.teal),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      elevation: 2,
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
                                  content: Text(
                                    'Food Served to Customer! ✅',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                    child: isProcessing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Mark Served & Send Greeting',
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: StreamBuilder<QuerySnapshot>(
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
              return data['payment_status'] != 'Paid' ||
                  data['status'] != 'Served';
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
                    Text(
                      'No active orders right now.',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

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

            return Column(
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.teal,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.people_alt,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Active Tickets: ${sortedGroups.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = constraints.maxWidth < 600
                          ? 1
                          : constraints.maxWidth < 900
                          ? 2
                          : constraints.maxWidth < 1300
                          ? 3
                          : 4;
                      return GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(16.0),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisExtent: 280,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: sortedGroups.length,
                        itemBuilder: (context, index) {
                          String groupKey = sortedGroups[index];
                          int tableNo = int.parse(groupKey.split('|')[0]);
                          String customerName = groupKey.split('|')[1];
                          List<DocumentSnapshot> tableOrders =
                              groupedOrders[groupKey]!;

                          List<Map<String, dynamic>> itemsList = [];
                          bool hasPending = false,
                              hasCooking = false,
                              hasReady = false,
                              hasServed = false,
                              isAllPaid = true,
                              hasParcel = false,
                              hasDineIn = false;

                          for (var order in tableOrders) {
                            final data = order.data() as Map<String, dynamic>;
                            final String status = data['status'] ?? 'Pending';
                            final bool isDocParcel =
                                data['order_type'] == 'Parcel';

                            if (isDocParcel)
                              hasParcel = true;
                            else
                              hasDineIn = true;
                            if (data['payment_status'] != 'Paid')
                              isAllPaid = false;

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
                              itemsList.add({
                                'text': '${item['quantity']}x ${item['name']}',
                                'isParcel': isDocParcel,
                              });
                            }
                          }

                          String tableStatus = 'Served';
                          if (hasPending)
                            tableStatus = 'Pending';
                          else if (hasCooking)
                            tableStatus = 'Cooking';
                          else if (hasReady)
                            tableStatus = 'Ready';

                          String typeBadge = (hasParcel && hasDineIn)
                              ? 'Mixed 🍽️🛍️'
                              : (hasParcel ? 'Parcel 🛍️' : 'Dine-in 🍽️');
                          Color typeColor = hasParcel
                              ? Colors.deepOrange
                              : Colors.blue;

                          return Card(
                            elevation: 2,
                            shadowColor: Colors.black12,
                            margin: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                              side: BorderSide(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    16,
                                    16,
                                    12,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.teal.withOpacity(
                                                  0.1,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.person,
                                                color: Colors.teal,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        tableNo == 0
                                                            ? 'Parcel'
                                                            : 'Table $tableNo',
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: typeColor
                                                              .withOpacity(0.1),
                                                          border: Border.all(
                                                            color: typeColor
                                                                .withOpacity(
                                                                  0.3,
                                                                ),
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          typeBadge,
                                                          style: TextStyle(
                                                            color: typeColor,
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    customerName,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.teal,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: _getStatusColor(tableStatus),
                                          ),
                                        ),
                                        child: Text(
                                          tableStatus,
                                          style: TextStyle(
                                            color: _getStatusColor(tableStatus),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1, color: Colors.black12),
                                Expanded(
                                  child: Scrollbar(
                                    thumbVisibility: true,
                                    child: ListView.builder(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: itemsList.length,
                                      itemBuilder: (ctx, i) {
                                        final itemData = itemsList[i];
                                        final bool isItemParcel =
                                            itemData['isParcel'];

                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8.0,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  itemData['text'],
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                    color: isItemParcel
                                                        ? Colors.deepOrange[700]
                                                        : Colors.black87,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isItemParcel)
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                    left: 8,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.deepOrange
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.deepOrange
                                                          .withOpacity(0.3),
                                                    ),
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        '🛍️',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        'Parcel',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color:
                                                              Colors.deepOrange,
                                                          fontWeight:
                                                              FontWeight.bold,
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
                                ),
                                const Divider(height: 1, color: Colors.black12),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    children: [
                                      if (isAllPaid && tableStatus != 'Served')
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
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
                                        )
                                      else if (tableStatus == 'Ready')
                                        SizedBox(
                                          width: double.infinity,
                                          height: 45,
                                          child: ElevatedButton.icon(
                                            onPressed: () => _markTableAsServed(
                                              tableNo,
                                              customerName,
                                              tableOrders,
                                            ),
                                            icon: const Icon(
                                              Icons.room_service,
                                              size: 18,
                                            ),
                                            label: const Text(
                                              'Mark Served & Send Greeting',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.teal,
                                              foregroundColor: Colors.white,
                                              elevation: 1,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),
                                        )
                                      else if (tableStatus == 'Served' &&
                                          !isAllPaid)
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.blueGrey.withOpacity(
                                              0.05,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Row(
                                            children: [
                                              Icon(
                                                Icons.info_outline,
                                                color: Colors.teal,
                                                size: 18,
                                              ),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Food served! Waiting for Admin to confirm payment.',
                                                  style: TextStyle(
                                                    color: Colors.teal,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      else if (tableStatus == 'Pending' ||
                                          tableStatus == 'Cooking')
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(
                                              0.05,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.soup_kitchen,
                                                color: Colors.orange,
                                                size: 18,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Cooking in Kitchen...',
                                                style: TextStyle(
                                                  color: Colors.orange,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
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

  // ===================== TAB 2: SALES HISTORY =====================
  Widget _buildSalesHistory() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey[200]!),
          ),
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
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _filterType,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.teal),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                      fontSize: 15,
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
                    borderRadius: BorderRadius.circular(10),
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
                DateTime orderDate = ts.toDate().toLocal();
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
                      Text(
                        'No sales recorded for this period.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              Map<String, Map<String, dynamic>> groupedOrders = {};

              for (var doc in paidOrders) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                int tableNo = data['table_no'] ?? 0;
                String customerName = data['customer_name'] ?? 'Guest';
                String orderType = data['order_type'] ?? 'Dine-in';
                String paymentMethod = data['payment_method'] ?? 'Cash';
                DateTime orderDate = (data['created_at'] as Timestamp)
                    .toDate()
                    .toLocal();
                String formattedTime = DateFormat(
                  'hh:mm a, dd MMM',
                ).format(orderDate);

                String timeKey;
                if (data['cleared_at'] != null) {
                  timeKey = (data['cleared_at'] as Timestamp).seconds
                      .toString();
                } else {
                  timeKey = DateFormat('dd MMM yyyy HH').format(orderDate);
                }
                String groupKey = '$tableNo|$customerName|$timeKey';

                double amount = (data['total_amount'] ?? 0.0).toDouble();

                if (!groupedOrders.containsKey(groupKey)) {
                  groupedOrders[groupKey] = {
                    'table_no': tableNo,
                    'customer_name': customerName,
                    'total_amount': amount,
                    'items': [],
                    'has_parcel': orderType == 'Parcel',
                    'has_dine_in': orderType != 'Parcel',
                    'formatted_time': formattedTime,
                    'created_dt': orderDate,
                    'payment_method': paymentMethod,
                    'payment_status': data['payment_status'] ?? 'Paid',
                  };
                } else {
                  groupedOrders[groupKey]!['total_amount'] += amount;
                  if (orderType == 'Parcel')
                    groupedOrders[groupKey]!['has_parcel'] = true;
                  else
                    groupedOrders[groupKey]!['has_dine_in'] = true;

                  if (orderDate.isAfter(
                    groupedOrders[groupKey]!['created_dt'],
                  )) {
                    groupedOrders[groupKey]!['created_dt'] = orderDate;
                    groupedOrders[groupKey]!['formatted_time'] = formattedTime;
                  }
                }

                List items = data['items'] ?? [];
                for (var item in items) {
                  groupedOrders[groupKey]!['items'].add({
                    'name': item['name'],
                    'quantity': item['quantity'],
                    'totalPrice': (item['totalPrice'] ?? 0).toDouble(),
                    'isParcel': orderType == 'Parcel',
                  });
                }
              }

              List<Map<String, dynamic>> finalGroupedOrders = groupedOrders
                  .values
                  .toList();
              finalGroupedOrders.sort(
                (a, b) => b['created_dt'].compareTo(a['created_dt']),
              );

              int totalItemsSold = 0;
              for (var group in finalGroupedOrders) {
                totalItemsSold += (group['items'] as List).length;
              }

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.teal, Color(0xFF26A69A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.receipt_long,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${finalGroupedOrders.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Orders Completed',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Container(width: 1, height: 60, color: Colors.white30),
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.fastfood,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '$totalItemsSold',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Items Served',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = constraints.maxWidth < 600
                            ? 1
                            : constraints.maxWidth < 900
                            ? 2
                            : constraints.maxWidth < 1300
                            ? 3
                            : 4;

                        return GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisExtent: 110,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          itemCount: finalGroupedOrders.length,
                          itemBuilder: (context, index) {
                            final groupData = finalGroupedOrders[index];
                            final int tableNo = groupData['table_no'];
                            final String customerName =
                                groupData['customer_name'];
                            final String paymentMethod =
                                groupData['payment_method'];
                            final String formattedTime =
                                groupData['formatted_time'];

                            final bool hasParcel = groupData['has_parcel'];
                            final bool hasDineIn = groupData['has_dine_in'];

                            String typeBadge = (hasParcel && hasDineIn)
                                ? 'Mixed 🍽️🛍️'
                                : (hasParcel ? 'Parcel 🛍️' : 'Dine-in 🍽️');
                            Color typeColor = hasParcel
                                ? Colors.deepOrange
                                : Colors.teal;

                            return Card(
                              elevation: 1,
                              margin: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                                side: BorderSide(color: Colors.grey[200]!),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                onTap: () =>
                                    _showOrderHistoryDetails(groupData),
                                leading: Container(
                                  padding: const EdgeInsets.all(12),
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
                                title: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        tableNo == 0
                                            ? 'Parcel'
                                            : 'Table $tableNo',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: typeColor.withOpacity(0.1),
                                        border: Border.all(
                                          color: typeColor.withOpacity(0.3),
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        typeBadge,
                                        style: TextStyle(
                                          color: typeColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    '$customerName  •  $formattedTime',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                trailing: Text(
                                  '৳${groupData['total_amount'].toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.teal,
                                  ),
                                ),
                              ),
                            );
                          },
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
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('restaurant_settings')
          .doc(widget.restaurantId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.teal)),
          );

        // ================= NEW: KILL SWITCH & NOTICE LOGIC =================
        bool isActive = true;
        String notice = '';

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          if (data.containsKey('is_active')) isActive = data['is_active'];
          if (data.containsKey('notice_message'))
            notice = data['notice_message'];
        }

        if (!isActive) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.block, size: 80, color: Colors.redAccent),
                    const SizedBox(height: 20),
                    const Text(
                      'Subscription Suspended',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Your access to the Waiter Panel has been temporarily suspended. Please ask your administrator to clear the dues.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        await AuthService().logout();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(
              _selectedIndex == 0 ? 'Active Orders' : 'Sales History',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            elevation: 0,
            bottom: notice.isNotEmpty
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(40),
                    child: Container(
                      width: double.infinity,
                      color: Colors.amber,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.campaign,
                            color: Colors.brown,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              notice,
                              style: const TextStyle(
                                color: Colors.brown,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : null,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                onPressed: _confirmLogout,
                tooltip: 'Logout',
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: _selectedIndex == 0
              ? _buildActiveOrders()
              : _buildSalesHistory(),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 15,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              selectedItemColor: Colors.teal,
              unselectedItemColor: Colors.grey[400],
              backgroundColor: Colors.white,
              elevation: 0,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.restaurant_outlined),
                  ),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.restaurant, size: 28),
                  ),
                  label: 'Live Orders',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.history_edu_outlined),
                  ),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.history_edu, size: 28),
                  ),
                  label: 'Sales History',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
*/