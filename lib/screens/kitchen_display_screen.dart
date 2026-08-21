import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';

class KitchenDisplayScreen extends StatefulWidget {
  final String restaurantId;
  const KitchenDisplayScreen({super.key, required this.restaurantId});

  @override
  State<KitchenDisplayScreen> createState() => _KitchenDisplayScreenState();
}

class _KitchenDisplayScreenState extends State<KitchenDisplayScreen> {
  final DatabaseService _dbService = DatabaseService();
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _getTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    final duration = DateTime.now().difference(timestamp.toDate());
    if (duration.inMinutes < 1) return 'Just now';
    if (duration.inMinutes < 60) return '${duration.inMinutes} mins ago';
    return '${duration.inHours} hrs ago';
  }

  void _startCookingWithTime(String orderId) {
    final TextEditingController timeController = TextEditingController(
      text: '15',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          'Set Preparation Time',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
        ),
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
                prefixIcon: Icon(Icons.timer, color: Colors.brown),
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

  void _markOrderAsReady(String orderId) async {
    await _dbService.updateOrderStatus(orderId, 'Ready');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order marked as Ready ✅'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.soup_kitchen, size: 28),
            SizedBox(width: 8),
            Text(
              'Kitchen Display System (KDS)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.brown[800],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _dbService.getKitchenOrders(widget.restaurantId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(
              child: CircularProgressIndicator(color: Colors.brown),
            );
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.done_all, size: 80, color: Colors.green[300]),
                  const SizedBox(height: 16),
                  const Text(
                    'Kitchen is Clear!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const Text(
                    'Waiting for new orders...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final orders = snapshot.data!.docs.toList();
          orders.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;
            Timestamp? timeA = dataA['created_at'];
            Timestamp? timeB = dataB['created_at'];
            if (timeA == null && timeB == null) return 0;
            if (timeA == null) return 1;
            if (timeB == null) return -1;
            return timeA.compareTo(timeB);
          });

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 350,
              childAspectRatio: 0.85,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final doc = orders[index];
              final data = doc.data() as Map<String, dynamic>;
              final tableNo = data['table_no'] ?? 0;
              final customerName =
                  data['customer_name'] ?? 'Guest'; // NEW: Added Customer Name
              final status = data['status'] ?? 'Pending';
              final timestamp = data['created_at'] as Timestamp?;
              final items = List<dynamic>.from(data['items'] ?? []);

              bool isUrgent = false;
              if (timestamp != null && status == 'Pending') {
                isUrgent =
                    DateTime.now().difference(timestamp.toDate()).inMinutes >
                    15;
              }

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(
                    color: isUrgent
                        ? Colors.red
                        : (status == 'Cooking'
                              ? Colors.orange
                              : Colors.transparent),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: status == 'Cooking'
                            ? Colors.orange[50]
                            : (isUrgent ? Colors.red[50] : Colors.brown[50]),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(15),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'T$tableNo - $customerName', // UPDATED UI
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: status == 'Cooking'
                                    ? Colors.orange[800]
                                    : (isUrgent
                                          ? Colors.red[800]
                                          : Colors.brown[800]),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 16,
                                color: status == 'Cooking'
                                    ? Colors.orange[800]
                                    : (isUrgent
                                          ? Colors.red
                                          : Colors.grey[700]),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getTimeAgo(timestamp),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: status == 'Cooking'
                                      ? Colors.orange[800]
                                      : (isUrgent
                                            ? Colors.red
                                            : Colors.grey[700]),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: items.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, i) {
                          final item = items[i];
                          return Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${item['quantity']}x',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item['name'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: status == 'Pending'
                          ? ElevatedButton.icon(
                              onPressed: () => _startCookingWithTime(doc.id),
                              icon: const Icon(Icons.local_fire_department),
                              label: const Text('Accept & Cook'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            )
                          : ElevatedButton.icon(
                              onPressed: () => _markOrderAsReady(doc.id),
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Mark as Ready'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
