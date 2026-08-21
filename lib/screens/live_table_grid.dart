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

  void _showAdminPaymentVerificationSheet({
    required int tableNo,
    required String customerName,
    required double totalBill,
    required String paymentMethod,
    required String senderNumber,
    required String trxId,
  }) {
    final TextEditingController receivedCtrl = TextEditingController(
      text: totalBill.toStringAsFixed(2),
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
                      Expanded(
                        child: Text(
                          'Clear Table $tableNo - $customerName',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
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

                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.redAccent.withOpacity(0.3),
                      ),
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
                              '৳${totalBill.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
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
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
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
                                  color: Colors.deepOrange,
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Please verify the TrxID in your merchant app before confirming.',
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
                            'Warning: Received ৳${(totalBill - receivedAmount).toStringAsFixed(2)} less!',
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
                        backgroundColor: Colors.redAccent,
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
                                      'Payment Confirmed for $customerName!',
                                    ),
                                    backgroundColor: Colors.green,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Live Table Status (Admin)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
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
              child: CircularProgressIndicator(color: Colors.redAccent),
            );

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: Colors.green[300],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'All tables are empty.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const Text(
                    'No active orders right now.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final activeOrders = snapshot.data!.docs.where((doc) {
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
                    Icons.check_circle_outline,
                    size: 80,
                    color: Colors.green[300],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'All tables are empty.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const Text(
                    'No active orders right now.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // GROUP BY TABLE AND CUSTOMER NAME
          Map<String, double> tableDueAmount = {};
          Map<String, List<String>> tableItemsList = {};
          Map<String, Map<String, dynamic>> tablePaymentDetails = {};
          Map<String, String> tableStatusMap = {};

          for (var doc in activeOrders) {
            var data = doc.data() as Map<String, dynamic>;
            String groupKey =
                '${data['table_no']}|${data['customer_name'] ?? 'Guest'}';
            double amount = (data['total_amount'] ?? 0).toDouble();
            List items = data['items'] ?? [];
            String currentStatus = data['status'] ?? 'Pending';

            tableDueAmount[groupKey] = (tableDueAmount[groupKey] ?? 0) + amount;

            if (!tableItemsList.containsKey(groupKey))
              tableItemsList[groupKey] = [];
            for (var item in items) {
              tableItemsList[groupKey]!.add(
                '${item['quantity']}x ${item['name']}',
              );
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
                color: Colors.redAccent,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    const Icon(Icons.people_alt, color: Colors.white),
                    const SizedBox(width: 10),
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
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    mainAxisExtent: 380,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: activeGroups.length,
                  itemBuilder: (context, index) {
                    String groupKey = activeGroups[index];
                    int tableNo = int.parse(groupKey.split('|')[0]);
                    String customerName = groupKey.split('|')[1];

                    double due = tableDueAmount[groupKey]!;
                    List<String> itemsList = tableItemsList[groupKey]!;
                    var pmtInfo = tablePaymentDetails[groupKey];
                    String overallStatus =
                        tableStatusMap[groupKey] ?? 'Pending';
                    bool isPaid =
                        pmtInfo != null && pmtInfo['pay_status'] == 'Paid';

                    return GestureDetector(
                      onTap: () {
                        if (overallStatus != 'Served') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Warning: Food is not served yet!'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                        _showAdminPaymentVerificationSheet(
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
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.redAccent.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.1),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(18),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.person,
                                          color: Colors.redAccent,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'T$tableNo - $customerName',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
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
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: _getStatusColor(overallStatus),
                                      ),
                                    ),
                                    child: Text(
                                      overallStatus,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _getStatusColor(overallStatus),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: itemsList.length,
                                itemBuilder: (ctx, i) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.circle,
                                        size: 8,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          itemsList[i],
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const Divider(height: 1),

                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Due Amount',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '৳${due.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (isPaid)
                                    Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(top: 8),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Payment Already Confirmed ✅',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    )
                                  else if (pmtInfo != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        'Please Verify ${pmtInfo['method']}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.deepPurple,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
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
    );
  }
}
