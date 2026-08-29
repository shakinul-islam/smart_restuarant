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
  DateTime? _customSelectedDate;
  DateTime? _customSelectedMonth;

  // ================= DATE FILTER LOGIC =================
  DateTime _getStartDate() {
    DateTime now = DateTime.now();
    if (_selectedFilter == 'Today')
      return DateTime(now.year, now.month, now.day);
    if (_selectedFilter == 'This Week')
      return DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));
    if (_selectedFilter == 'This Month')
      return DateTime(now.year, now.month, 1);
    if (_selectedFilter == 'This Year') return DateTime(now.year, 1, 1);
    return DateTime(2000); // All time
  }

  // 1. Pick a Specific Date
  Future<void> _pickCustomDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _customSelectedDate ?? DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.indigo,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedFilter = 'CustomDate';
        _customSelectedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
        );
        _customSelectedMonth = null;
      });
    }
  }

  // 2. Pick a Specific Month
  Future<void> _pickCustomMonth() async {
    DateTime initial = _customSelectedMonth ?? DateTime.now();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Select Year',
            style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: SizedBox(
            width: 300,
            height: 300,
            child: YearPicker(
              firstDate: DateTime(2022),
              lastDate: DateTime.now(),
              initialDate: initial,
              selectedDate: initial,
              onChanged: (DateTime dateTime) {
                Navigator.pop(context);
                _showMonthPicker(dateTime.year);
              },
            ),
          ),
        );
      },
    );
  }

  // Helper for Month Picker
  Future<void> _showMonthPicker(int year) async {
    int currentMonth = DateTime.now().month;
    int currentYear = DateTime.now().year;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Select Month ($year)',
            style: const TextStyle(
              color: Colors.indigo,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: 12,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                int month = index + 1;
                bool isFuture = year == currentYear && month > currentMonth;
                String monthName = DateFormat(
                  'MMM',
                ).format(DateTime(year, month));

                return InkWell(
                  onTap: isFuture
                      ? null
                      : () {
                          setState(() {
                            _selectedFilter = 'CustomMonth';
                            _customSelectedMonth = DateTime(year, month, 1);
                            _customSelectedDate = null;
                          });
                          Navigator.pop(context);
                        },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isFuture
                          ? Colors.grey[200]
                          : Colors.indigo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isFuture
                            ? Colors.transparent
                            : Colors.indigo.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      monthName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isFuture ? Colors.grey : Colors.indigo,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ================= ORDER HISTORY DETAILS BOTTOM SHEET =================
  void _showOrderHistoryDetails(Map<String, dynamic> groupData) {
    final int tableNo = groupData['table_no'];
    final String customerName = groupData['customer_name'];
    final double totalBill = groupData['total_amount'];

    // Fixed: Received amount is strictly what the total bill was.
    final double amountReceived = totalBill;

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
            bottom: MediaQuery.of(context).padding.bottom + 10,
            left: 24,
            right: 24,
            top: 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 16),

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
                        color: Colors.indigo,
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

              // ================= SCROLLABLE CONTENT TO FIX OVERFLOW =================
              Expanded(
                child: ListView(
                  controller: controller,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formattedTime,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (hasParcel ? Colors.deepOrange : Colors.indigo)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          typeBadge,
                          style: TextStyle(
                            color: hasParcel
                                ? Colors.deepOrange
                                : Colors.indigo,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),

                    const Divider(
                      thickness: 1,
                      height: 24,
                      color: Colors.black12,
                    ),
                    const Text(
                      'Ordered Items:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final bool isParcel = item['isParcel'] ?? false;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: isParcel
                                    ? Colors.deepOrange
                                    : Colors.indigo,
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
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
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
                                      Text(
                                        '🛍️',
                                        style: TextStyle(fontSize: 10),
                                      ),
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
                                '৳${(item['totalPrice'] ?? 0.0).toStringAsFixed(0)}',
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

                    const Divider(
                      thickness: 1,
                      height: 24,
                      color: Colors.black12,
                    ),

                    _buildDetailRow(
                      'Payment Method',
                      paymentMethod,
                      isBold: false,
                    ),
                    if (paymentMethod != 'Cash') ...[
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        'Sender Number',
                        groupData['sender_number'] ?? '-',
                        isBold: false,
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        'TrxID',
                        groupData['trx_id'] ?? '-',
                        isBold: false,
                      ),
                    ],
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Payment Status',
                      paymentStatus,
                      valueColor: paymentStatus == 'Paid'
                          ? Colors.green
                          : Colors.red,
                      isBold: true,
                    ),
                    if (paymentStatus == 'Paid') ...[
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        'Amount Received',
                        '৳${amountReceived.toStringAsFixed(0)}',
                        valueColor: Colors.green,
                        isBold: true,
                      ),
                    ],

                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.indigo.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Bill',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '৳${totalBill.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
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
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  // ================= FILTER CHIPS UI =================
  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: Colors.white,
        backgroundColor: Colors.indigo[400],
        labelStyle: TextStyle(
          color: isSelected ? Colors.indigo : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.transparent),
        ),
        onSelected: (_) {
          setState(() {
            _selectedFilter = label;
            _customSelectedDate = null;
            _customSelectedMonth = null;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'Sales Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.indigo[300],
                borderRadius: BorderRadius.circular(25),
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: Colors.white,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: Colors.indigo,
                unselectedLabelColor: Colors.white,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                ),
                tabs: const [
                  Tab(text: 'Analytics'),
                  Tab(text: 'Sales History'),
                ],
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            // ================= PREMIUM FILTER BAR =================
            Container(
              width: double.infinity,
              color: Colors.indigo,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildFilterChip('Today'),
                    _buildFilterChip('This Week'),
                    _buildFilterChip('This Month'),
                    _buildFilterChip('This Year'),
                    _buildFilterChip('All Time'),
                    const SizedBox(width: 8),

                    // Custom Month Picker Button
                    ActionChip(
                      avatar: const Icon(
                        Icons.calendar_month_outlined,
                        size: 18,
                        color: Colors.indigo,
                      ),
                      label: Text(
                        _selectedFilter == 'CustomMonth' &&
                                _customSelectedMonth != null
                            ? DateFormat(
                                'MMM, yyyy',
                              ).format(_customSelectedMonth!)
                            : 'Pick Month',
                        style: const TextStyle(
                          color: Colors.indigo,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: Colors.indigo[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Colors.white),
                      ),
                      onPressed: _pickCustomMonth,
                    ),
                    const SizedBox(width: 8),

                    // Custom Date Picker Button
                    ActionChip(
                      avatar: const Icon(
                        Icons.date_range,
                        size: 18,
                        color: Colors.indigo,
                      ),
                      label: Text(
                        _selectedFilter == 'CustomDate' &&
                                _customSelectedDate != null
                            ? DateFormat(
                                'dd MMM, yy',
                              ).format(_customSelectedDate!)
                            : 'Pick Date',
                        style: const TextStyle(
                          color: Colors.indigo,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: Colors.indigo[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Colors.white),
                      ),
                      onPressed: _pickCustomDate,
                    ),
                  ],
                ),
              ),
            ),

            // ================= MAIN CONTENT AREA =================
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
                    return _buildEmptyState('No paid orders found yet.');
                  }

                  DateTime startLimit = _getStartDate();
                  double totalRevenue = 0;
                  int totalOrdersCount = 0;
                  Map<String, int> itemQtyMap = {};
                  Map<String, double> itemRevenueMap = {};

                  Map<String, Map<String, dynamic>> groupedOrders = {};

                  // Filtering & Grouping Logic
                  for (var doc in snapshot.data!) {
                    Map<String, dynamic> data =
                        doc.data() as Map<String, dynamic>;
                    if (data['created_at'] == null) continue;

                    DateTime orderDate = (data['created_at'] as Timestamp)
                        .toDate()
                        .toLocal();
                    bool include = false;

                    if (_selectedFilter == 'CustomDate' &&
                        _customSelectedDate != null) {
                      if (orderDate.year == _customSelectedDate!.year &&
                          orderDate.month == _customSelectedDate!.month &&
                          orderDate.day == _customSelectedDate!.day) {
                        include = true;
                      }
                    } else if (_selectedFilter == 'CustomMonth' &&
                        _customSelectedMonth != null) {
                      if (orderDate.year == _customSelectedMonth!.year &&
                          orderDate.month == _customSelectedMonth!.month) {
                        include = true;
                      }
                    } else if (_selectedFilter == 'All Time') {
                      include = true;
                    } else {
                      if (orderDate.isAfter(startLimit) ||
                          orderDate.isAtSameMomentAs(startLimit)) {
                        include = true;
                      }
                    }

                    if (!include) continue;

                    double amount = (data['total_amount'] ?? 0.0).toDouble();
                    totalRevenue += amount;
                    totalOrdersCount++;

                    int tableNo = data['table_no'] ?? 0;
                    String customerName = data['customer_name'] ?? 'Guest';
                    String orderType = data['order_type'] ?? 'Dine-in';
                    String paymentMethod = data['payment_method'] ?? 'Cash';
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
                        'sender_number': data['sender_number'] ?? '',
                        'trx_id': data['trx_id'] ?? '',
                        'payment_status': data['payment_status'] ?? 'Paid',
                      };
                    } else {
                      groupedOrders[groupKey]!['total_amount'] += amount;
                      if (orderType == 'Parcel')
                        groupedOrders[groupKey]!['has_parcel'] = true;
                      else
                        groupedOrders[groupKey]!['has_dine_in'] = true;

                      // ================= NEW: BKASH/NAGAD PRIORITY FIX =================
                      // If grouped orders contain a digital payment, update it to the digital payment method
                      if (paymentMethod != 'Cash') {
                        groupedOrders[groupKey]!['payment_method'] =
                            paymentMethod;
                        groupedOrders[groupKey]!['sender_number'] =
                            data['sender_number'] ?? '';
                        groupedOrders[groupKey]!['trx_id'] =
                            data['trx_id'] ?? '';
                      }

                      if (orderDate.isAfter(
                        groupedOrders[groupKey]!['created_dt'],
                      )) {
                        groupedOrders[groupKey]!['created_dt'] = orderDate;
                        groupedOrders[groupKey]!['formatted_time'] =
                            formattedTime;
                      }
                    }

                    List items = data['items'] ?? [];
                    for (var item in items) {
                      String name = item['name'];
                      int qty = item['quantity'];
                      double price = (item['totalPrice'] ?? 0).toDouble();

                      itemQtyMap[name] = (itemQtyMap[name] ?? 0) + qty;
                      itemRevenueMap[name] =
                          (itemRevenueMap[name] ?? 0) + price;

                      groupedOrders[groupKey]!['items'].add({
                        'name': name,
                        'quantity': qty,
                        'totalPrice': price,
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

                  double avgOrderValue = totalOrdersCount > 0
                      ? (totalRevenue / totalOrdersCount)
                      : 0;

                  List<String> sortedItems = itemQtyMap.keys.toList();
                  sortedItems.sort((a, b) {
                    if (_sortByRevenue) {
                      return itemRevenueMap[b]!.compareTo(itemRevenueMap[a]!);
                    } else {
                      return itemQtyMap[b]!.compareTo(itemQtyMap[a]!);
                    }
                  });

                  return TabBarView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // ================= TAB 1: ANALYTICS =================
                      LayoutBuilder(
                        builder: (context, constraints) {
                          bool isMobile = constraints.maxWidth < 600;
                          return ListView(
                            padding: const EdgeInsets.all(16),
                            physics: const BouncingScrollPhysics(),
                            children: [
                              GridView.count(
                                crossAxisCount: isMobile ? 2 : 4,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                childAspectRatio: isMobile ? 1.3 : 1.5,
                                children: [
                                  _buildSummaryCard(
                                    'Revenue',
                                    '৳${totalRevenue.toStringAsFixed(0)}',
                                    Icons.monetization_on,
                                    Colors.green,
                                  ),
                                  _buildSummaryCard(
                                    'Total Orders',
                                    '$totalOrdersCount',
                                    Icons.receipt_long,
                                    Colors.blue,
                                  ),
                                  _buildSummaryCard(
                                    'Avg. Value',
                                    '৳${avgOrderValue.toStringAsFixed(0)}',
                                    Icons.analytics,
                                    Colors.orange,
                                  ),
                                  _buildSummaryCard(
                                    'Items Sold',
                                    '${itemQtyMap.values.fold(0, (sum, val) => sum + val)}',
                                    Icons.fastfood,
                                    Colors.purple,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 30),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                    isSelected: [
                                      !_sortByRevenue,
                                      _sortByRevenue,
                                    ],
                                    borderRadius: BorderRadius.circular(8),
                                    constraints: const BoxConstraints(
                                      minHeight: 32,
                                      minWidth: 60,
                                    ),
                                    fillColor: Colors.indigo.withOpacity(0.1),
                                    selectedColor: Colors.indigo,
                                    color: Colors.grey,
                                    borderColor: Colors.indigo.withOpacity(0.3),
                                    selectedBorderColor: Colors.indigo,
                                    onPressed: (index) => setState(
                                      () => _sortByRevenue = index == 1,
                                    ),
                                    children: const [
                                      Text(
                                        ' Qty ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        ' ৳ Rev ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (sortedItems.isEmpty)
                                _buildEmptyState(
                                  'No items sold in this period.',
                                )
                              else
                                ...sortedItems.map((itemName) {
                                  int qty = itemQtyMap[itemName]!;
                                  double rev = itemRevenueMap[itemName]!;
                                  double maxValue = _sortByRevenue
                                      ? itemRevenueMap[sortedItems.first]!
                                      : itemQtyMap[sortedItems.first]!
                                            .toDouble();
                                  double percent = _sortByRevenue
                                      ? (rev / maxValue)
                                      : (qty / maxValue);

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: Colors.grey[200]!,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                        const SizedBox(height: 10),
                                        LayoutBuilder(
                                          builder: (context, constraints) {
                                            return Stack(
                                              children: [
                                                Container(
                                                  height: 8,
                                                  width: double.infinity,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[200],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                ),
                                                AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 500,
                                                  ),
                                                  height: 8,
                                                  width:
                                                      constraints.maxWidth *
                                                      percent,
                                                  decoration: BoxDecoration(
                                                    color: _sortByRevenue
                                                        ? Colors.green[400]
                                                        : Colors.blue[400],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                            ],
                          );
                        },
                      ),

                      // ================= TAB 2: FULL SALES HISTORY =================
                      finalGroupedOrders.isEmpty
                          ? _buildEmptyState(
                              'No sales recorded for this period.',
                            )
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                int crossAxisCount = constraints.maxWidth < 600
                                    ? 1
                                    : constraints.maxWidth < 900
                                    ? 2
                                    : constraints.maxWidth < 1300
                                    ? 3
                                    : 4;

                                return GridView.builder(
                                  padding: const EdgeInsets.all(16),
                                  physics: const BouncingScrollPhysics(),
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
                                    final bool hasParcel =
                                        groupData['has_parcel'];
                                    final bool hasDineIn =
                                        groupData['has_dine_in'];

                                    String typeBadge = (hasParcel && hasDineIn)
                                        ? 'Mixed 🍽️🛍️'
                                        : (hasParcel
                                              ? 'Parcel 🛍️'
                                              : 'Dine-in 🍽️');
                                    Color typeColor = hasParcel
                                        ? Colors.deepOrange
                                        : Colors.indigo;

                                    return Card(
                                      elevation: 0,
                                      margin: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        side: BorderSide(
                                          color: Colors.grey[200]!,
                                        ),
                                      ),
                                      color: Colors.white,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(15),
                                        onTap: () =>
                                            _showOrderHistoryDetails(groupData),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0,
                                            vertical: 12.0,
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: paymentMethod == 'Cash'
                                                      ? Colors.green
                                                            .withOpacity(0.1)
                                                      : Colors.pink.withOpacity(
                                                          0.1,
                                                        ),
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
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Flexible(
                                                          child: Text(
                                                            tableNo == 0
                                                                ? 'Parcel'
                                                                : 'Table $tableNo',
                                                            style:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 16,
                                                                  color: Colors
                                                                      .black87,
                                                                ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 6,
                                                                vertical: 2,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: typeColor
                                                                .withOpacity(
                                                                  0.1,
                                                                ),
                                                            border: Border.all(
                                                              color: typeColor
                                                                  .withOpacity(
                                                                    0.3,
                                                                  ),
                                                            ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  6,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            typeBadge,
                                                            style: TextStyle(
                                                              color: typeColor,
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            top: 4.0,
                                                          ),
                                                      child: Text(
                                                        '$customerName  •  $formattedTime',
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          color: Colors.grey,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                '৳${groupData['total_amount'].toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                  color: Colors.indigo,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
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
}

/*
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
  DateTime? _customSelectedDate;
  DateTime? _customSelectedMonth; // NEW: Specific Month State

  // ================= DATE FILTER LOGIC =================
  DateTime _getStartDate() {
    DateTime now = DateTime.now();
    if (_selectedFilter == 'Today')
      return DateTime(now.year, now.month, now.day);
    if (_selectedFilter == 'This Week')
      return DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));
    if (_selectedFilter == 'This Month')
      return DateTime(now.year, now.month, 1);
    if (_selectedFilter == 'This Year') return DateTime(now.year, 1, 1);
    return DateTime(2000); // All time
  }

  // 1. Pick a Specific Date
  Future<void> _pickCustomDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _customSelectedDate ?? DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.indigo,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedFilter = 'CustomDate';
        _customSelectedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
        );
        _customSelectedMonth = null;
      });
    }
  }

  // 2. Pick a Specific Month (NEW)
  Future<void> _pickCustomMonth() async {
    DateTime initial = _customSelectedMonth ?? DateTime.now();
    DateTime? pickedMonth;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Select Month',
            style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 300,
            height: 300,
            child: YearPicker(
              firstDate: DateTime(2022),
              lastDate: DateTime.now(),
              initialDate: initial,
              selectedDate: initial,
              onChanged: (DateTime dateTime) {
                // Here we simply picked a year, now let's pick the month
                Navigator.pop(context);
                _showMonthPicker(dateTime.year);
              },
            ),
          ),
        );
      },
    );
  }

  // Helper for Month Picker
  Future<void> _showMonthPicker(int year) async {
    int currentMonth = DateTime.now().month;
    int currentYear = DateTime.now().year;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Select Month ($year)',
            style: const TextStyle(
              color: Colors.indigo,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: 12,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                int month = index + 1;
                bool isFuture = year == currentYear && month > currentMonth;
                String monthName = DateFormat(
                  'MMM',
                ).format(DateTime(year, month));

                return InkWell(
                  onTap: isFuture
                      ? null
                      : () {
                          setState(() {
                            _selectedFilter = 'CustomMonth';
                            _customSelectedMonth = DateTime(year, month, 1);
                            _customSelectedDate = null;
                          });
                          Navigator.pop(context);
                        },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isFuture
                          ? Colors.grey[200]
                          : Colors.indigo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      monthName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isFuture ? Colors.grey : Colors.indigo,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
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
    final String orderType = data['order_type'] ?? 'Dine In';
    final double amountReceived = (data['amount_received'] ?? 0.0).toDouble();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, controller) => Container(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          orderType == 'Parcel'
                              ? 'Parcel Order - $customerName'
                              : 'Table $tableNo - $customerName',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey,
                            ),
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
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: orderType == 'Parcel'
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: orderType == 'Parcel'
                            ? Colors.orange.withOpacity(0.5)
                            : Colors.blue.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          orderType == 'Parcel'
                              ? Icons.takeout_dining
                              : Icons.restaurant,
                          size: 16,
                          color: orderType == 'Parcel'
                              ? Colors.orange
                              : Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          orderType,
                          style: TextStyle(
                            color: orderType == 'Parcel'
                                ? Colors.orange
                                : Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Ordered Items',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
              const Divider(thickness: 1, height: 20),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item['quantity']}x ${item['name']}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Text(
                            '৳${(item['totalPrice'] ?? 0.0).toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(thickness: 1, height: 24),
              _buildDetailRow('Payment Method', paymentMethod, isBold: false),
              const SizedBox(height: 8),
              if (paymentMethod != 'Cash') ...[
                _buildDetailRow(
                  'Sender Number',
                  data['sender_number'] ?? '-',
                  isBold: false,
                ),
                const SizedBox(height: 8),
                _buildDetailRow('TrxID', data['trx_id'] ?? '-', isBold: false),
                const SizedBox(height: 8),
              ],
              _buildDetailRow(
                'Payment Status',
                paymentStatus,
                valueColor: paymentStatus == 'Paid' ? Colors.green : Colors.red,
                isBold: true,
              ),
              if (paymentStatus == 'Paid') ...[
                const SizedBox(height: 8),
                _buildDetailRow(
                  'Amount Received',
                  '৳${amountReceived.toStringAsFixed(0)}',
                  valueColor: Colors.green,
                  isBold: true,
                ),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Bill',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '৳${totalBill.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ],
                ),
              ),
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
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  // ================= FILTER CHIPS UI =================
  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: Colors.white,
        backgroundColor: Colors.indigo[400],
        labelStyle: TextStyle(
          color: isSelected ? Colors.indigo : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.transparent),
        ),
        onSelected: (_) {
          setState(() {
            _selectedFilter = label;
            _customSelectedDate = null;
            _customSelectedMonth = null;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'Sales Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.indigo[300],
                borderRadius: BorderRadius.circular(25),
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: Colors.white,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: Colors.indigo,
                unselectedLabelColor: Colors.white,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                ),
                tabs: const [
                  Tab(text: 'Analytics'),
                  Tab(text: 'Sales History'),
                ],
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            // ================= PREMIUM FILTER BAR =================
            Container(
              width: double.infinity,
              color: Colors.indigo,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildFilterChip('Today'),
                    _buildFilterChip('This Week'),
                    _buildFilterChip('This Month'),
                    _buildFilterChip('This Year'),
                    _buildFilterChip('All Time'),
                    const SizedBox(width: 8),

                    // Custom Month Picker Button (NEW)
                    ActionChip(
                      avatar: const Icon(
                        Icons.calendar_month_outlined,
                        size: 18,
                        color: Colors.indigo,
                      ),
                      label: Text(
                        _selectedFilter == 'CustomMonth' &&
                                _customSelectedMonth != null
                            ? DateFormat(
                                'MMM, yyyy',
                              ).format(_customSelectedMonth!)
                            : 'Pick Month',
                        style: const TextStyle(
                          color: Colors.indigo,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: Colors.indigo[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Colors.white),
                      ),
                      onPressed: _pickCustomMonth,
                    ),
                    const SizedBox(width: 8),

                    // Custom Date Picker Button
                    ActionChip(
                      avatar: const Icon(
                        Icons.date_range,
                        size: 18,
                        color: Colors.indigo,
                      ),
                      label: Text(
                        _selectedFilter == 'CustomDate' &&
                                _customSelectedDate != null
                            ? DateFormat(
                                'dd MMM, yy',
                              ).format(_customSelectedDate!)
                            : 'Pick Date',
                        style: const TextStyle(
                          color: Colors.indigo,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: Colors.indigo[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Colors.white),
                      ),
                      onPressed: _pickCustomDate,
                    ),
                  ],
                ),
              ),
            ),

            // ================= MAIN CONTENT AREA =================
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
                    return _buildEmptyState('No paid orders found yet.');
                  }

                  // Data Processing variables
                  DateTime startLimit = _getStartDate();
                  double totalRevenue = 0;
                  int totalOrders = 0;
                  Map<String, int> itemQtyMap = {};
                  Map<String, double> itemRevenueMap = {};
                  List<QueryDocumentSnapshot> filteredOrders = [];

                  // Filtering Logic
                  for (var doc in snapshot.data!) {
                    Map<String, dynamic> data =
                        doc.data() as Map<String, dynamic>;
                    if (data['created_at'] == null) continue;

                    DateTime orderDate = (data['created_at'] as Timestamp)
                        .toDate()
                        .toLocal();
                    bool include = false;

                    if (_selectedFilter == 'CustomDate' &&
                        _customSelectedDate != null) {
                      // Exact Date Match
                      if (orderDate.year == _customSelectedDate!.year &&
                          orderDate.month == _customSelectedDate!.month &&
                          orderDate.day == _customSelectedDate!.day) {
                        include = true;
                      }
                    } else if (_selectedFilter == 'CustomMonth' &&
                        _customSelectedMonth != null) {
                      // Exact Month Match
                      if (orderDate.year == _customSelectedMonth!.year &&
                          orderDate.month == _customSelectedMonth!.month) {
                        include = true;
                      }
                    } else if (_selectedFilter == 'All Time') {
                      include = true;
                    } else {
                      // Date Range Match (Today, This Week, etc)
                      if (orderDate.isAfter(startLimit) ||
                          orderDate.isAtSameMomentAs(startLimit)) {
                        include = true;
                      }
                    }

                    if (!include) continue;

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

                  // Sort orders newest first for History Tab
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
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // ================= TAB 1: ANALYTICS =================
                      LayoutBuilder(
                        builder: (context, constraints) {
                          bool isMobile = constraints.maxWidth < 600;
                          return ListView(
                            padding: const EdgeInsets.all(16),
                            physics: const BouncingScrollPhysics(),
                            children: [
                              GridView.count(
                                crossAxisCount: isMobile ? 2 : 4,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                childAspectRatio: isMobile ? 1.3 : 1.5,
                                children: [
                                  _buildSummaryCard(
                                    'Revenue',
                                    '৳${totalRevenue.toStringAsFixed(0)}',
                                    Icons.monetization_on,
                                    Colors.green,
                                  ),
                                  _buildSummaryCard(
                                    'Total Orders',
                                    '$totalOrders',
                                    Icons.receipt_long,
                                    Colors.blue,
                                  ),
                                  _buildSummaryCard(
                                    'Avg. Value',
                                    '৳${avgOrderValue.toStringAsFixed(0)}',
                                    Icons.analytics,
                                    Colors.orange,
                                  ),
                                  _buildSummaryCard(
                                    'Items Sold',
                                    '${itemQtyMap.values.fold(0, (sum, val) => sum + val)}',
                                    Icons.fastfood,
                                    Colors.purple,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 30),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                    isSelected: [
                                      !_sortByRevenue,
                                      _sortByRevenue,
                                    ],
                                    borderRadius: BorderRadius.circular(8),
                                    constraints: const BoxConstraints(
                                      minHeight: 32,
                                      minWidth: 60,
                                    ),
                                    fillColor: Colors.indigo.withOpacity(0.1),
                                    selectedColor: Colors.indigo,
                                    color: Colors.grey,
                                    borderColor: Colors.indigo.withOpacity(0.3),
                                    selectedBorderColor: Colors.indigo,
                                    onPressed: (index) => setState(
                                      () => _sortByRevenue = index == 1,
                                    ),
                                    children: const [
                                      Text(
                                        ' Qty ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        ' ৳ Rev ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (sortedItems.isEmpty)
                                _buildEmptyState(
                                  'No items sold in this period.',
                                )
                              else
                                ...sortedItems.map((itemName) {
                                  int qty = itemQtyMap[itemName]!;
                                  double rev = itemRevenueMap[itemName]!;
                                  double maxValue = _sortByRevenue
                                      ? itemRevenueMap[sortedItems.first]!
                                      : itemQtyMap[sortedItems.first]!
                                            .toDouble();
                                  double percent = _sortByRevenue
                                      ? (rev / maxValue)
                                      : (qty / maxValue);

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: Colors.grey[200]!,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                        const SizedBox(height: 10),
                                        LayoutBuilder(
                                          builder: (context, constraints) {
                                            return Stack(
                                              children: [
                                                Container(
                                                  height: 8,
                                                  width: double.infinity,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[200],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                ),
                                                AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 500,
                                                  ),
                                                  height: 8,
                                                  width:
                                                      constraints.maxWidth *
                                                      percent,
                                                  decoration: BoxDecoration(
                                                    color: _sortByRevenue
                                                        ? Colors.green[400]
                                                        : Colors.blue[400],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                            ],
                          );
                        },
                      ),

                      // ================= TAB 2: FULL SALES HISTORY =================
                      filteredOrders.isEmpty
                          ? _buildEmptyState(
                              'No sales recorded for this period.',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              physics: const BouncingScrollPhysics(),
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
                                final String orderType =
                                    data['order_type'] ?? 'Dine In';

                                Timestamp? timestamp =
                                    data['created_at'] as Timestamp?;
                                String formattedTime = 'Unknown Time';
                                if (timestamp != null) {
                                  DateTime dt = timestamp.toDate().toLocal();
                                  formattedTime = DateFormat(
                                    'hh:mm a, dd MMM',
                                  ).format(dt);
                                }

                                return Card(
                                  elevation: 0,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    side: BorderSide(color: Colors.grey[200]!),
                                  ),
                                  color: Colors.white,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(15),
                                    onTap: () => _showOrderHistoryDetails(
                                      data,
                                      tableNo,
                                      formattedTime,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: orderType == 'Parcel'
                                                  ? Colors.orange.withOpacity(
                                                      0.1,
                                                    )
                                                  : Colors.indigo.withOpacity(
                                                      0.1,
                                                    ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              orderType == 'Parcel'
                                                  ? Icons.takeout_dining
                                                  : Icons.restaurant,
                                              color: orderType == 'Parcel'
                                                  ? Colors.orange
                                                  : Colors.indigo,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  orderType == 'Parcel'
                                                      ? 'Parcel - $customerName'
                                                      : 'Table $tableNo - $customerName',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Colors.black87,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      paymentMethod == 'Cash'
                                                          ? Icons.money
                                                          : Icons.phone_android,
                                                      size: 14,
                                                      color: Colors.grey,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      paymentMethod,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const Text(
                                                      ' • ',
                                                      style: TextStyle(
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                    Text(
                                                      formattedTime,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            '৳${amount.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: Colors.indigo,
                                            ),
                                          ),
                                        ],
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

  // ================= UTILITY WIDGETS =================
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
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
}
*/
