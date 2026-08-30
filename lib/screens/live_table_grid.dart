import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';

class LiveTableGridScreen extends StatefulWidget {
  final String restaurantId;
  const LiveTableGridScreen({super.key, required this.restaurantId});

  @override
  State<LiveTableGridScreen> createState() => _LiveTableGridScreenState();
}

class _LiveTableGridScreenState extends State<LiveTableGridScreen> {
  final DatabaseService _dbService = DatabaseService();

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

  // ===================== MODERN PAYMENT VERIFICATION SHEET =====================
  void _showAdminPaymentVerificationSheet({
    required int tableNo,
    required String customerName,
    required double totalBill,
    required String paymentMethod,
    required String senderNumber,
    required String trxId,
    required String overallStatus,
    required List<Map<String, dynamic>> itemsList,
    required bool hasParcel,
    required bool hasDineIn,
  }) {
    final TextEditingController receivedCtrl = TextEditingController(
      text: totalBill.toStringAsFixed(0),
    );
    bool isProcessing = false;

    String typeBadge = (hasParcel && hasDineIn)
        ? 'Mixed Order 🍽️🛍️'
        : (hasParcel ? 'Parcel Order 🛍️' : 'Dine-in Order 🍽️');

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
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 24,
              right: 24,
              top: 16,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
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

                  // Header
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

                  // Current Status & Type Badges
                  Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 4, bottom: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            overallStatus,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Status: $overallStatus',
                          style: TextStyle(
                            color: _getStatusColor(overallStatus),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        margin: const EdgeInsets.only(top: 4, bottom: 16),
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
                    ],
                  ),

                  // Order Details
                  const Text(
                    'Order Details:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const Divider(thickness: 1, height: 16),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.25,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: itemsList.length,
                      itemBuilder: (context, i) {
                        final itemData = itemsList[i];
                        final bool isParcel = itemData['isParcel'];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 14,
                                color: isParcel
                                    ? Colors.deepOrange
                                    : Colors.indigo,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  itemData['text'],
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: isParcel
                                        ? Colors.deepOrange[700]
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              if (isParcel)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
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
                                          fontSize: 10,
                                          color: Colors.deepOrange,
                                          fontWeight: FontWeight.bold,
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

                  // Billing Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.indigo.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          'Total Bill:',
                          '৳${totalBill.toStringAsFixed(0)}',
                          valueColor: Colors.indigo,
                          isBold: true,
                          size: 18,
                        ),
                        const Divider(height: 20),
                        _buildDetailRow('Payment Method:', paymentMethod),
                        if (paymentMethod != 'Cash') ...[
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            'Sender Number:',
                            senderNumber,
                            isBold: true,
                            valueColor: Colors.indigo,
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            'TrxID:',
                            trxId,
                            isBold: true,
                            valueColor: Colors.indigo,
                          ),
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Please verify the TrxID in your merchant app.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Payment Input
                  if (overallStatus != 'Served')
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Warning: Food is not fully served yet!',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  const Text(
                    'Amount Received',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: receivedCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (val) => setSheetState(() {}),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.attach_money,
                        color: Colors.indigo,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.indigo),
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
                            'Warning: Received ৳${(totalBill - receivedAmount).toStringAsFixed(0)} less!',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: isProcessing
                          ? null
                          : () async {
                              setSheetState(() => isProcessing = true);
                              bool success = await _dbService
                                  .confirmPaymentAndClearTable(
                                    restaurantId: widget.restaurantId,
                                    tableNo: tableNo,
                                    customerName: customerName,
                                    amountReceived:
                                        double.tryParse(receivedCtrl.text) ??
                                        0.0,
                                  );
                              setSheetState(() => isProcessing = false);

                              if (success && mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Payment Confirmed for $customerName! ✅',
                                      style: const TextStyle(
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
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Confirm Payment & Clear Bill',
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

  Widget _buildDetailRow(
    String title,
    String value, {
    bool isBold = false,
    Color? valueColor,
    double size = 14,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: size,
            color: Colors.black54,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: size,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? Colors.black87,
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
        title: const Text(
          'Live Table Status',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('restaurant_id', isEqualTo: widget.restaurantId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(
              child: CircularProgressIndicator(color: Colors.indigo),
            );

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final activeOrders = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['status'] == 'Cancelled') return false;
            bool isNotPaid = data['payment_status'] != 'Paid';
            bool isNotServed = data['status'] != 'Served';
            return isNotPaid || isNotServed;
          }).toList();

          if (activeOrders.isEmpty) {
            return _buildEmptyState();
          }

          // GROUP BY TABLE AND CUSTOMER NAME
          Map<String, double> tableDueAmount = {};
          Map<String, List<Map<String, dynamic>>> tableItemsList = {};
          Map<String, Map<String, dynamic>> tablePaymentDetails = {};
          Map<String, String> tableStatusMap = {};
          Map<String, bool> tableHasParcel = {};
          Map<String, bool> tableHasDineIn = {};

          for (var doc in activeOrders) {
            var data = doc.data() as Map<String, dynamic>;
            String groupKey =
                '${data['table_no']}|${data['customer_name'] ?? 'Guest'}';
            double amount = (data['total_amount'] ?? 0).toDouble();
            List items = data['items'] ?? [];
            String currentStatus = data['status'] ?? 'Pending';
            String orderType = data['order_type'] ?? 'Dine-in';

            tableDueAmount[groupKey] = (tableDueAmount[groupKey] ?? 0) + amount;

            if (orderType == 'Parcel') {
              tableHasParcel[groupKey] = true;
            } else {
              tableHasDineIn[groupKey] = true;
            }

            if (!tableItemsList.containsKey(groupKey))
              tableItemsList[groupKey] = [];
            for (var item in items) {
              tableItemsList[groupKey]!.add({
                'text': '${item['quantity']}x ${item['name']}',
                'isParcel': orderType == 'Parcel',
              });
            }

            if (data['payment_method'] != null &&
                data['payment_method'] != 'Cash') {
              tablePaymentDetails[groupKey] = {
                'method': data['payment_method'],
                'sender': data['sender_number'] ?? '',
                'trx': data['trx_id'] ?? '',
                'pay_status': data['payment_status'] ?? 'Unpaid',
              };
            }

            if (!tableStatusMap.containsKey(groupKey)) {
              tableStatusMap[groupKey] = currentStatus;
            } else {
              if (currentStatus == 'Pending')
                tableStatusMap[groupKey] = 'Pending';
              else if (currentStatus == 'Cooking' &&
                  tableStatusMap[groupKey] != 'Pending')
                tableStatusMap[groupKey] = 'Cooking';
              else if (currentStatus == 'Ready' &&
                  (tableStatusMap[groupKey] == 'Served' ||
                      tableStatusMap[groupKey] == 'Ready'))
                tableStatusMap[groupKey] = 'Ready';
            }
          }

          List<String> activeGroups = tableDueAmount.keys.toList()
            ..sort((a, b) {
              int tA = int.parse(a.split('|')[0]);
              int tB = int.parse(b.split('|')[0]);
              int comp = tA.compareTo(tB);
              if (comp != 0) return comp;
              return a.split('|')[1].compareTo(b.split('|')[1]);
            });

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                color: Colors.indigo,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.people_alt, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Active Tickets: ${activeGroups.length}',
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
                    // Responsive Columns setup
                    int crossAxisCount = constraints.maxWidth < 600
                        ? 1
                        : constraints.maxWidth < 900
                        ? 2
                        : constraints.maxWidth < 1300
                        ? 3
                        : 4;

                    return GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisExtent: 260,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                      ),
                      itemCount: activeGroups.length,
                      itemBuilder: (context, index) {
                        String groupKey = activeGroups[index];
                        int tableNo = int.parse(groupKey.split('|')[0]);
                        String customerName = groupKey.split('|')[1];

                        // ================= FIX: Unique Controller for Each Card =================
                        final ScrollController _cardScrollController =
                            ScrollController();

                        double due = tableDueAmount[groupKey]!;
                        List<Map<String, dynamic>> itemsList =
                            tableItemsList[groupKey]!;
                        var pmtInfo = tablePaymentDetails[groupKey];
                        String overallStatus =
                            tableStatusMap[groupKey] ?? 'Pending';

                        bool hasParcel = tableHasParcel[groupKey] ?? false;
                        bool hasDineIn = tableHasDineIn[groupKey] ?? false;
                        bool isPaid =
                            pmtInfo != null && pmtInfo['pay_status'] == 'Paid';

                        String typeBadge = (hasParcel && hasDineIn)
                            ? 'Mixed 🍽️🛍️'
                            : (hasParcel ? 'Parcel 🛍️' : 'Dine-in 🍽️');
                        Color typeColor = hasParcel
                            ? Colors.deepOrange
                            : Colors.indigo;

                        String displayTitle = tableNo > 0
                            ? 'Table $tableNo'
                            : ((hasParcel && hasDineIn)
                                  ? 'Mixed'
                                  : (hasParcel ? 'Parcel' : 'Dine-in'));

                        return GestureDetector(
                          onTap: () => _showAdminPaymentVerificationSheet(
                            tableNo: tableNo,
                            customerName: customerName,
                            totalBill: due,
                            paymentMethod: pmtInfo != null
                                ? pmtInfo['method']
                                : 'Cash',
                            senderNumber: pmtInfo != null
                                ? pmtInfo['sender']
                                : '',
                            trxId: pmtInfo != null ? pmtInfo['trx'] : '',
                            overallStatus: overallStatus,
                            itemsList: itemsList,
                            hasParcel: hasParcel,
                            hasDineIn: hasDineIn,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.indigo.withOpacity(0.08),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.indigo.withOpacity(0.15),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Header
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.withOpacity(0.05),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(18),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  displayTitle,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.indigo,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                                                          .withOpacity(0.3),
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
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              customerName,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[700],
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(
                                            overallStatus,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: _getStatusColor(
                                              overallStatus,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          overallStatus,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _getStatusColor(
                                              overallStatus,
                                            ),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Items Hint
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${itemsList.length} Items Ordered:',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        // ================= FIXED: Attached controller to Scrollbar and ListView =================
                                        Expanded(
                                          child: Scrollbar(
                                            controller: _cardScrollController,
                                            thumbVisibility: true,
                                            child: ListView.builder(
                                              controller: _cardScrollController,
                                              physics:
                                                  const BouncingScrollPhysics(),
                                              itemCount: itemsList.length,
                                              itemBuilder: (ctx, i) {
                                                final itemData = itemsList[i];
                                                final isParcel =
                                                    itemData['isParcel'];

                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        bottom: 4.0,
                                                      ),
                                                  child: Row(
                                                    children: [
                                                      Flexible(
                                                        child: Text(
                                                          '• ${itemData['text']}',
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: isParcel
                                                                ? Colors
                                                                      .deepOrange
                                                                : Colors
                                                                      .black87,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                      if (isParcel) ...[
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 4,
                                                                vertical: 1,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: Colors
                                                                .deepOrange
                                                                .withOpacity(
                                                                  0.1,
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  4,
                                                                ),
                                                          ),
                                                          child: const Text(
                                                            '🛍️',
                                                            style: TextStyle(
                                                              fontSize: 8,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const Divider(height: 1),

                                // Footer
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Due Amount',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '৳${due.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.indigo,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (isPaid)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
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
                                            'Paid ✅',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        )
                                      else if (pmtInfo != null)
                                        Text(
                                          'Verify ${pmtInfo['method']}!',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.deepOrange,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      else
                                        const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                          color: Colors.indigo,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 100, color: Colors.green[300]),
          const SizedBox(height: 20),
          const Text(
            'All tables are empty.',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No active orders right now.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
/* scroll problm only
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';

class LiveTableGridScreen extends StatefulWidget {
  final String restaurantId;
  const LiveTableGridScreen({super.key, required this.restaurantId});

  @override
  State<LiveTableGridScreen> createState() => _LiveTableGridScreenState();
}

class _LiveTableGridScreenState extends State<LiveTableGridScreen> {
  final DatabaseService _dbService = DatabaseService();

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

  // ===================== MODERN PAYMENT VERIFICATION SHEET =====================
  void _showAdminPaymentVerificationSheet({
    required int tableNo,
    required String customerName,
    required double totalBill,
    required String paymentMethod,
    required String senderNumber,
    required String trxId,
    required String overallStatus,
    required List<Map<String, dynamic>> itemsList,
    required bool hasParcel,
    required bool hasDineIn,
  }) {
    final TextEditingController receivedCtrl = TextEditingController(
      text: totalBill.toStringAsFixed(0),
    );
    bool isProcessing = false;

    String typeBadge = (hasParcel && hasDineIn)
        ? 'Mixed Order 🍽️🛍️'
        : (hasParcel ? 'Parcel Order 🛍️' : 'Dine-in Order 🍽️');

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
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 24,
              right: 24,
              top: 16,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
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

                  // Header
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

                  // Current Status & Type Badges
                  Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 4, bottom: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            overallStatus,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Status: $overallStatus',
                          style: TextStyle(
                            color: _getStatusColor(overallStatus),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        margin: const EdgeInsets.only(top: 4, bottom: 16),
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
                    ],
                  ),

                  // Order Details
                  const Text(
                    'Order Details:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const Divider(thickness: 1, height: 16),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.25,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: itemsList.length,
                      itemBuilder: (context, i) {
                        final itemData = itemsList[i];
                        final bool isParcel = itemData['isParcel'];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 14,
                                color: isParcel
                                    ? Colors.deepOrange
                                    : Colors.indigo,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  itemData['text'],
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: isParcel
                                        ? Colors.deepOrange[700]
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              if (isParcel)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
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
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Billing Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.indigo.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          'Total Bill:',
                          '৳${totalBill.toStringAsFixed(0)}',
                          valueColor: Colors.indigo,
                          isBold: true,
                          size: 18,
                        ),
                        const Divider(height: 20),
                        _buildDetailRow('Payment Method:', paymentMethod),
                        if (paymentMethod != 'Cash') ...[
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            'Sender Number:',
                            senderNumber,
                            isBold: true,
                            valueColor: Colors.indigo,
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            'TrxID:',
                            trxId,
                            isBold: true,
                            valueColor: Colors.indigo,
                          ),
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Please verify the TrxID in your merchant app.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Payment Input
                  if (overallStatus != 'Served')
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Warning: Food is not fully served yet!',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  const Text(
                    'Amount Received',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: receivedCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (val) => setSheetState(() {}),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.attach_money,
                        color: Colors.indigo,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.indigo),
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
                            'Warning: Received ৳${(totalBill - receivedAmount).toStringAsFixed(0)} less!',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: isProcessing
                          ? null
                          : () async {
                              setSheetState(() => isProcessing = true);
                              bool success = await _dbService
                                  .confirmPaymentAndClearTable(
                                    restaurantId: widget.restaurantId,
                                    tableNo: tableNo,
                                    customerName: customerName,
                                    amountReceived:
                                        double.tryParse(receivedCtrl.text) ??
                                        0.0,
                                  );
                              setSheetState(() => isProcessing = false);

                              if (success && mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Payment Confirmed for $customerName! ✅',
                                      style: const TextStyle(
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
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Confirm Payment & Clear Bill',
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

  Widget _buildDetailRow(
    String title,
    String value, {
    bool isBold = false,
    Color? valueColor,
    double size = 14,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: size,
            color: Colors.black54,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: size,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? Colors.black87,
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
        title: const Text(
          'Live Table Status',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('restaurant_id', isEqualTo: widget.restaurantId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(
              child: CircularProgressIndicator(color: Colors.indigo),
            );

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final activeOrders = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['status'] == 'Cancelled') return false;
            bool isNotPaid = data['payment_status'] != 'Paid';
            bool isNotServed = data['status'] != 'Served';
            return isNotPaid || isNotServed;
          }).toList();

          if (activeOrders.isEmpty) {
            return _buildEmptyState();
          }

          // GROUP BY TABLE AND CUSTOMER NAME
          Map<String, double> tableDueAmount = {};
          Map<String, List<Map<String, dynamic>>> tableItemsList = {};
          Map<String, Map<String, dynamic>> tablePaymentDetails = {};
          Map<String, String> tableStatusMap = {};
          Map<String, bool> tableHasParcel = {};
          Map<String, bool> tableHasDineIn = {};

          for (var doc in activeOrders) {
            var data = doc.data() as Map<String, dynamic>;
            String groupKey =
                '${data['table_no']}|${data['customer_name'] ?? 'Guest'}';
            double amount = (data['total_amount'] ?? 0).toDouble();
            List items = data['items'] ?? [];
            String currentStatus = data['status'] ?? 'Pending';
            String orderType = data['order_type'] ?? 'Dine-in';

            tableDueAmount[groupKey] = (tableDueAmount[groupKey] ?? 0) + amount;

            if (orderType == 'Parcel') {
              tableHasParcel[groupKey] = true;
            } else {
              tableHasDineIn[groupKey] = true;
            }

            if (!tableItemsList.containsKey(groupKey))
              tableItemsList[groupKey] = [];
            for (var item in items) {
              tableItemsList[groupKey]!.add({
                'text': '${item['quantity']}x ${item['name']}',
                'isParcel': orderType == 'Parcel',
              });
            }

            if (data['payment_method'] != null &&
                data['payment_method'] != 'Cash') {
              tablePaymentDetails[groupKey] = {
                'method': data['payment_method'],
                'sender': data['sender_number'] ?? '',
                'trx': data['trx_id'] ?? '',
                'pay_status': data['payment_status'] ?? 'Unpaid',
              };
            }

            if (!tableStatusMap.containsKey(groupKey)) {
              tableStatusMap[groupKey] = currentStatus;
            } else {
              if (currentStatus == 'Pending')
                tableStatusMap[groupKey] = 'Pending';
              else if (currentStatus == 'Cooking' &&
                  tableStatusMap[groupKey] != 'Pending')
                tableStatusMap[groupKey] = 'Cooking';
              else if (currentStatus == 'Ready' &&
                  (tableStatusMap[groupKey] == 'Served' ||
                      tableStatusMap[groupKey] == 'Ready'))
                tableStatusMap[groupKey] = 'Ready';
            }
          }

          List<String> activeGroups = tableDueAmount.keys.toList()
            ..sort((a, b) {
              int tA = int.parse(a.split('|')[0]);
              int tB = int.parse(b.split('|')[0]);
              int comp = tA.compareTo(tB);
              if (comp != 0) return comp;
              return a.split('|')[1].compareTo(b.split('|')[1]);
            });

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                color: Colors.indigo,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.people_alt, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Active Tickets: ${activeGroups.length}',
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
                    // Responsive Columns setup
                    int crossAxisCount = constraints.maxWidth < 600
                        ? 1
                        : constraints.maxWidth < 900
                        ? 2
                        : constraints.maxWidth < 1300
                        ? 3
                        : 4;

                    return GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisExtent: 260, // Fixed height for consistent look
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                      ),
                      itemCount: activeGroups.length,
                      itemBuilder: (context, index) {
                        String groupKey = activeGroups[index];
                        int tableNo = int.parse(groupKey.split('|')[0]);
                        String customerName = groupKey.split('|')[1];

                        double due = tableDueAmount[groupKey]!;
                        List<Map<String, dynamic>> itemsList =
                            tableItemsList[groupKey]!;
                        var pmtInfo = tablePaymentDetails[groupKey];
                        String overallStatus =
                            tableStatusMap[groupKey] ?? 'Pending';

                        bool hasParcel = tableHasParcel[groupKey] ?? false;
                        bool hasDineIn = tableHasDineIn[groupKey] ?? false;
                        bool isPaid =
                            pmtInfo != null && pmtInfo['pay_status'] == 'Paid';

                        String typeBadge = (hasParcel && hasDineIn)
                            ? 'Mixed 🍽️🛍️'
                            : (hasParcel ? 'Parcel 🛍️' : 'Dine-in 🍽️');
                        Color typeColor = hasParcel
                            ? Colors.deepOrange
                            : Colors.indigo;

                        return GestureDetector(
                          onTap: () => _showAdminPaymentVerificationSheet(
                            tableNo: tableNo,
                            customerName: customerName,
                            totalBill: due,
                            paymentMethod: pmtInfo != null
                                ? pmtInfo['method']
                                : 'Cash',
                            senderNumber: pmtInfo != null
                                ? pmtInfo['sender']
                                : '',
                            trxId: pmtInfo != null ? pmtInfo['trx'] : '',
                            overallStatus: overallStatus,
                            itemsList: itemsList,
                            hasParcel: hasParcel,
                            hasDineIn: hasDineIn,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.indigo.withOpacity(0.08),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.indigo.withOpacity(0.15),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Header
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.withOpacity(0.05),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(18),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
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
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.indigo,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                                                          .withOpacity(0.3),
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
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              customerName,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[700],
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(
                                            overallStatus,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: _getStatusColor(
                                              overallStatus,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          overallStatus,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _getStatusColor(
                                              overallStatus,
                                            ),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Items Hint
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${itemsList.length} Items Ordered:',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Expanded(
                                          child: ListView.builder(
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            itemCount: itemsList.length > 3
                                                ? 3
                                                : itemsList.length,
                                            itemBuilder: (ctx, i) {
                                              final itemData = itemsList[i];
                                              final isParcel =
                                                  itemData['isParcel'];

                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 4.0,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        '• ${itemData['text']}',
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: isParcel
                                                              ? Colors
                                                                    .deepOrange
                                                              : Colors.black87,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    if (isParcel) ...[
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 4,
                                                              vertical: 1,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors
                                                              .deepOrange
                                                              .withOpacity(0.1),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                        ),
                                                        child: const Text(
                                                          '🛍️',
                                                          style: TextStyle(
                                                            fontSize: 8,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        if (itemsList.length > 3)
                                          Text(
                                            '+ ${itemsList.length - 3} more items',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.indigo[300],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),

                                const Divider(height: 1),

                                // Footer
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Due Amount',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '৳${due.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.indigo,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (isPaid)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
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
                                            'Paid ✅',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        )
                                      else if (pmtInfo != null)
                                        Text(
                                          'Verify ${pmtInfo['method']}!',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.deepOrange,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      else
                                        const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                          color: Colors.indigo,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 100, color: Colors.green[300]),
          const SizedBox(height: 20),
          const Text(
            'All tables are empty.',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No active orders right now.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
*/