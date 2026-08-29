import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SuperAdminScreen extends StatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _showMessage(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ===================== RESTAURANT CONTROL LOGIC =====================
  Future<void> _toggleStatus(String restaurantId, bool currentStatus) async {
    try {
      await _firestore.collection('restaurant_settings').doc(restaurantId).set({
        'is_active': !currentStatus,
      }, SetOptions(merge: true));
      _showMessage(
        !currentStatus ? 'Restaurant Unblocked ✅' : 'Restaurant Blocked ⛔',
        !currentStatus ? Colors.green : Colors.red,
      );
    } catch (e) {
      _showMessage('Failed to update status.', Colors.red);
    }
  }

  void _showNoticeDialog(String restaurantId, String currentNotice) {
    final TextEditingController noticeCtrl = TextEditingController(
      text: currentNotice,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.campaign, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text('Send Notice', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This message will show as an alert banner in the restaurant\'s admin dashboard. Clear text to remove notice.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noticeCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g., Please clear your monthly bill.',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.blueAccent),
                ),
              ),
            ),
          ],
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
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _firestore
                  .collection('restaurant_settings')
                  .doc(restaurantId)
                  .set({
                    'notice_message': noticeCtrl.text.trim(),
                  }, SetOptions(merge: true));
              _showMessage('Notice updated successfully!', Colors.green);
            },
            child: const Text(
              'Save Notice',
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

  // ===================== PAYMENT VERIFICATION LOGIC =====================
  Future<void> _verifyPaymentAndUnblock(
    String paymentId,
    String restaurantId,
  ) async {
    try {
      WriteBatch batch = _firestore.batch();

      // 1. Update Payment Status
      DocumentReference paymentRef = _firestore
          .collection('developer_payments')
          .doc(paymentId);
      batch.update(paymentRef, {'status': 'Verified'});

      // 2. Unblock Restaurant and Clear Notice
      DocumentReference restaurantRef = _firestore
          .collection('restaurant_settings')
          .doc(restaurantId);
      batch.set(restaurantRef, {
        'is_active': true,
        'notice_message': '', // Auto-clear notice
      }, SetOptions(merge: true));

      await batch.commit();
      _showMessage('Payment Verified & Restaurant Unblocked! ✅', Colors.green);
    } catch (e) {
      _showMessage('Error verifying payment.', Colors.red);
    }
  }

  // ===================== TAB 1: RESTAURANTS =====================
  Widget _buildRestaurantsTab() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          color: Colors.redAccent,
          child: const Text(
            'Manage all registered restaurants from here. Send billing notices or temporarily block access.',
            style: TextStyle(color: Colors.white, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('restaurant_settings').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.redAccent),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No restaurants found.'));
              }

              final docs = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                physics: const BouncingScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final String restaurantId = docs[index].id;
                  final bool isActive = data.containsKey('is_active')
                      ? data['is_active']
                      : true;
                  final String notice = data.containsKey('notice_message')
                      ? data['notice_message']
                      : '';

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    color: isActive ? Colors.white : Colors.red[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.storefront,
                                color: isActive ? Colors.indigo : Colors.red,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  restaurantId,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isActive ? Colors.green : Colors.red,
                                  ),
                                ),
                                child: Text(
                                  isActive ? 'Active' : 'Blocked',
                                  style: TextStyle(
                                    color: isActive ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (notice.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.amber),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.campaign,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Notice: $notice',
                                      style: const TextStyle(
                                        color: Colors.brown,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton.icon(
                                onPressed: () =>
                                    _showNoticeDialog(restaurantId, notice),
                                icon: const Icon(
                                  Icons.edit_notifications,
                                  color: Colors.blueAccent,
                                ),
                                label: const Text(
                                  'Edit Notice',
                                  style: TextStyle(
                                    color: Colors.blueAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Switch(
                                value: isActive,
                                activeColor: Colors.green,
                                inactiveThumbColor: Colors.red,
                                inactiveTrackColor: Colors.red.withOpacity(0.3),
                                onChanged: (val) =>
                                    _toggleStatus(restaurantId, isActive),
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
          ),
        ),
      ],
    );
  }

  // ===================== TAB 2: PAYMENTS =====================
  Widget _buildPaymentsTab() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          color: Colors.indigo,
          child: const Text(
            'Check submitted TrxIDs and verify payments. Verifying a payment will automatically unblock the restaurant.',
            style: TextStyle(color: Colors.white, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('developer_payments')
                .orderBy('submitted_at', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.indigo),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.payments_outlined,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No payment submissions yet.',
                        style: TextStyle(color: Colors.grey[500], fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              final docs = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                physics: const BouncingScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final String paymentId = docs[index].id;
                  final String restaurantId =
                      data['restaurant_id'] ?? 'Unknown';
                  final String senderNumber = data['sender_number'] ?? '';
                  final String trxId = data['trx_id'] ?? '';
                  final double amount = (data['amount'] ?? 0).toDouble();
                  final String status =
                      data['status'] ?? 'Pending Verification';
                  final Timestamp? time = data['submitted_at'];

                  String formattedTime = time != null
                      ? DateFormat('dd MMM yyyy, hh:mm a').format(time.toDate())
                      : 'Unknown Date';
                  bool isVerified = status == 'Verified';

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(
                        color: isVerified
                            ? Colors.green.withOpacity(0.3)
                            : Colors.orange.withOpacity(0.3),
                      ),
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
                                child: Text(
                                  restaurantId,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isVerified
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: isVerified
                                        ? Colors.green
                                        : Colors.orange[800],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formattedTime,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          const Divider(height: 24),

                          _buildDetailRow(
                            'Amount Paid:',
                            '৳${amount.toStringAsFixed(0)}',
                            true,
                            Colors.green[700],
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            'Sender bKash:',
                            senderNumber,
                            false,
                            null,
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow('TrxID:', trxId, true, Colors.indigo),

                          if (!isVerified) ...[
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                onPressed: () => _verifyPaymentAndUnblock(
                                  paymentId,
                                  restaurantId,
                                ),
                                icon: const Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Verify Payment & Unblock App',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
  }

  Widget _buildDetailRow(
    String label,
    String value,
    bool isBold,
    Color? valueColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontSize: 15,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
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
            'Super Admin Master',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 4,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
            tabs: [
              Tab(text: 'Restaurants', icon: Icon(Icons.storefront)),
              Tab(text: 'Payments', icon: Icon(Icons.account_balance_wallet)),
            ],
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: TabBarView(
              physics: const BouncingScrollPhysics(),
              children: [_buildRestaurantsTab(), _buildPaymentsTab()],
            ),
          ),
        ),
      ),
    );
  }
}
