import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';

class AdminSalesDashboard extends StatefulWidget {
  final String restaurantId;

  const AdminSalesDashboard({super.key, required this.restaurantId});

  @override
  State<AdminSalesDashboard> createState() => _AdminSalesDashboardState();
}

class _AdminSalesDashboardState extends State<AdminSalesDashboard> {
  final DatabaseService _dbService = DatabaseService();
  String _selectedFilter = 'Today';
  bool _sortByRevenue = false;

  DateTime _getStartDate() {
    DateTime now = DateTime.now();
    if (_selectedFilter == 'Today')
      return DateTime(now.year, now.month, now.day);
    if (_selectedFilter == 'This Week')
      return now.subtract(Duration(days: now.weekday - 1));
    if (_selectedFilter == 'This Month')
      return DateTime(now.year, now.month, 1);
    if (_selectedFilter == 'This Year') return DateTime(now.year, 1, 1);
    return DateTime(2000); // All time
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
    final double amountReceived = (data['amount_received'] ?? 0.0).toDouble();

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
                      color: Colors.indigo,
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
                    color: Colors.indigo,
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
            if (paymentMethod != 'Cash') ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Sender Number:',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Text(
                    data['sender_number'] ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TrxID:',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Text(
                    data['trx_id'] ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
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
            if (paymentStatus == 'Paid') ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Amount Received:',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Text(
                    '৳${amountReceived.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text(
            'Sales Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 4,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 16,
            ),
            tabs: [
              Tab(text: 'Analytics'),
              Tab(text: 'Sales History'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Shared Filter Dropdown for both tabs
            Container(
              color: Colors.indigo,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  const Icon(Icons.date_range, color: Colors.white70),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: Colors.indigo[400],
                        value: _selectedFilter,
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        items:
                            [
                                  'Today',
                                  'This Week',
                                  'This Month',
                                  'This Year',
                                  'All Time',
                                ]
                                .map(
                                  (val) => DropdownMenuItem(
                                    value: val,
                                    child: Text(val),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedFilter = val!;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: FutureBuilder<List<QueryDocumentSnapshot>>(
                future: _dbService.getOrdersForAnalytics(widget.restaurantId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.indigo),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'No paid orders found yet.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  // Filtering Data Locally based on selected date
                  DateTime startLimit = _getStartDate();
                  double totalRevenue = 0;
                  int totalOrders = 0;
                  Map<String, int> itemQtyMap = {};
                  Map<String, double> itemRevenueMap = {};

                  List<QueryDocumentSnapshot> filteredOrders = [];

                  for (var doc in snapshot.data!) {
                    Map<String, dynamic> data =
                        doc.data() as Map<String, dynamic>;
                    if (data['created_at'] == null) continue;

                    DateTime orderDate = (data['created_at'] as Timestamp)
                        .toDate();
                    if (orderDate.isBefore(startLimit)) continue;

                    filteredOrders.add(doc);
                    totalRevenue += (data['total_amount'] ?? 0).toDouble();
                    totalOrders++;

                    List items = data['items'] ?? [];
                    for (var item in items) {
                      String name = item['name'];
                      int qty = item['quantity'];
                      double price = (item['totalPrice'] ?? 0).toDouble();

                      itemQtyMap[name] = (itemQtyMap[name] ?? 0) + qty;
                      itemRevenueMap[name] =
                          (itemRevenueMap[name] ?? 0) + price;
                    }
                  }

                  // Sort orders newest first for the history tab
                  filteredOrders.sort((a, b) {
                    Timestamp timeA =
                        (a.data() as Map<String, dynamic>)['created_at'];
                    Timestamp timeB =
                        (b.data() as Map<String, dynamic>)['created_at'];
                    return timeB.compareTo(timeA);
                  });

                  double avgOrderValue = totalOrders > 0
                      ? (totalRevenue / totalOrders)
                      : 0;

                  // Sort Items for Analytics Tab
                  List<String> sortedItems = itemQtyMap.keys.toList();
                  sortedItems.sort((a, b) {
                    if (_sortByRevenue) {
                      return itemRevenueMap[b]!.compareTo(itemRevenueMap[a]!);
                    } else {
                      return itemQtyMap[b]!.compareTo(itemQtyMap[a]!);
                    }
                  });

                  return TabBarView(
                    children: [
                      // ================= TAB 1: ANALYTICS =================
                      ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildSummaryCard(
                                  'Revenue',
                                  '৳${totalRevenue.toStringAsFixed(0)}',
                                  Icons.monetization_on,
                                  Colors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSummaryCard(
                                  'Orders',
                                  '$totalOrders',
                                  Icons.receipt_long,
                                  Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildSummaryCard(
                            'Avg. Order Value',
                            '৳${avgOrderValue.toStringAsFixed(2)}',
                            Icons.analytics,
                            Colors.orange,
                          ),

                          const SizedBox(height: 30),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Top Selling Items',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              ToggleButtons(
                                isSelected: [!_sortByRevenue, _sortByRevenue],
                                borderRadius: BorderRadius.circular(8),
                                constraints: const BoxConstraints(
                                  minHeight: 30,
                                  minWidth: 60,
                                ),
                                fillColor: Colors.indigo,
                                selectedColor: Colors.white,
                                color: Colors.grey,
                                onPressed: (index) {
                                  setState(() {
                                    _sortByRevenue = index == 1;
                                  });
                                },
                                children: const [
                                  Text(' Qty '),
                                  Text(' ৳ Rev '),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          if (sortedItems.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Center(
                                child: Text(
                                  'No item sales in this period',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                          else
                            ...sortedItems.map((itemName) {
                              int qty = itemQtyMap[itemName]!;
                              double rev = itemRevenueMap[itemName]!;
                              double maxValue = _sortByRevenue
                                  ? itemRevenueMap[sortedItems.first]!
                                  : itemQtyMap[sortedItems.first]!.toDouble();
                              double percent = _sortByRevenue
                                  ? (rev / maxValue)
                                  : (qty / maxValue);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            itemName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          _sortByRevenue
                                              ? '৳${rev.toStringAsFixed(0)}'
                                              : '$qty pics',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _sortByRevenue
                                                ? Colors.green
                                                : Colors.blue,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        return Container(
                                          height: 8,
                                          width: constraints.maxWidth * percent,
                                          decoration: BoxDecoration(
                                            color: _sortByRevenue
                                                ? Colors.green[400]
                                                : Colors.blue[400],
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      !_sortByRevenue
                                          ? 'Revenue: ৳${rev.toStringAsFixed(0)}'
                                          : 'Sold: $qty pics',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),

                      // ================= TAB 2: FULL SALES HISTORY =================
                      filteredOrders.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.event_busy_outlined,
                                    size: 80,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No sales recorded for this period.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              itemCount: filteredOrders.length,
                              itemBuilder: (context, index) {
                                final data =
                                    filteredOrders[index].data()
                                        as Map<String, dynamic>;
                                final int tableNo = data['table_no'] ?? 0;
                                final String customerName =
                                    data['customer_name'] ?? 'Guest';
                                final double amount =
                                    (data['total_amount'] ?? 0.0).toDouble();
                                final String paymentMethod =
                                    data['payment_method'] ?? 'Cash';

                                Timestamp? timestamp =
                                    data['created_at'] as Timestamp?;
                                String formattedTime = 'Unknown Time';
                                if (timestamp != null) {
                                  DateTime dt = timestamp.toDate().toUtc().add(
                                    const Duration(hours: 6),
                                  );
                                  formattedTime = DateFormat(
                                    'hh:mm a, dd MMM',
                                  ).format(dt);
                                }

                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    onTap: () => _showOrderHistoryDetails(
                                      data,
                                      tableNo,
                                      formattedTime,
                                    ),
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
                                    title: Text(
                                      'Table $tableNo - $customerName',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      '$paymentMethod  •  $formattedTime',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    trailing: Text(
                                      '৳${amount.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.indigo,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
