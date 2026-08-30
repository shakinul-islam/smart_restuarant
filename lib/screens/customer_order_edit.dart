import 'package:flutter/material.dart';
import '../services/database_service.dart';

class CustomerOrderEditSheet extends StatefulWidget {
  final String orderId;
  final List initialItems;

  const CustomerOrderEditSheet({
    super.key,
    required this.orderId,
    required this.initialItems,
  });

  @override
  State<CustomerOrderEditSheet> createState() => _CustomerOrderEditSheetState();
}

class _CustomerOrderEditSheetState extends State<CustomerOrderEditSheet> {
  final DatabaseService _dbService = DatabaseService();
  List<Map<String, dynamic>> _items = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Create a deep copy of items to allow editing without modifying original state directly
    for (var item in widget.initialItems) {
      _items.add(Map<String, dynamic>.from(item));
    }
  }

  double get _grandTotal {
    return _items.fold(0.0, (sum, item) => sum + (item['totalPrice'] ?? 0.0));
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      int currentQty = _items[index]['quantity'];
      int newQty = currentQty + delta;

      if (newQty >= 0) {
        // Find accurate unit price based on previous data
        double unitPrice = currentQty > 0
            ? (_items[index]['totalPrice'] / currentQty)
            : (_items[index]['price'] ?? 0.0)
                  .toDouble(); // Fallback if qty was 0

        _items[index]['quantity'] = newQty;
        _items[index]['totalPrice'] = newQty * unitPrice;
      }
    });
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    // Filter out items that have 0 quantity
    List<Map<String, dynamic>> finalItems = _items
        .where((i) => i['quantity'] > 0)
        .toList();
    double finalTotal = finalItems.fold(0.0, (sum, i) => sum + i['totalPrice']);

    bool success = await _dbService.updateOrderItems(
      widget.orderId,
      finalItems,
      finalTotal,
    );

    if (mounted) {
      Navigator.pop(context); // Close the bottom sheet
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? (finalItems.isEmpty
                      ? 'Order Cancelled!'
                      : 'Order updated successfully! ✅')
                : 'Failed to update order.',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          left: 20,
          right: 20,
          top: 12,
        ),
        child: Column(
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
                const Text(
                  'Edit Order Items',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Text(
              'Adjust quantities. Items with 0 quantity will be removed.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const Divider(height: 30),

            Expanded(
              child: ListView.builder(
                controller: controller,
                physics: const BouncingScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final int qty = item['quantity'];
                  final bool isRemoved = qty == 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isRemoved ? Colors.grey[50] : Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: isRemoved
                            ? Colors.grey[300]!
                            : Colors.deepOrange.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isRemoved
                                      ? Colors.grey
                                      : Colors.black87,
                                  decoration: isRemoved
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '৳${(item['totalPrice'] ?? 0.0).toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isRemoved
                                      ? Colors.grey
                                      : Colors.deepOrange,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.remove,
                                  color: qty > 0
                                      ? Colors.deepOrange
                                      : Colors.grey,
                                ),
                                onPressed: qty > 0
                                    ? () => _updateQuantity(index, -1)
                                    : null,
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                                padding: EdgeInsets.zero,
                                iconSize: 20,
                              ),
                              Text(
                                '$qty',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.add,
                                  color: Colors.deepOrange,
                                ),
                                onPressed: () => _updateQuantity(index, 1),
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                                padding: EdgeInsets.zero,
                                iconSize: 20,
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
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'New Total:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '৳${_grandTotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _grandTotal == 0
                      ? Colors.redAccent
                      : Colors.deepOrange,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: _isSaving ? null : _saveChanges,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _grandTotal == 0 ? 'Cancel Order' : 'Save Changes',
                        style: const TextStyle(
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
  }
}
