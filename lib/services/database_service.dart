import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<bool> placeOrder({
    required List<CartItem> cartItems,
    required double totalAmount,
    required int tableNumber,
    required String restaurantId,
    required String paymentMethod,
    required String customerName,
    required String orderType,
    String? senderNumber,
    String? trxId,
  }) async {
    try {
      List<Map<String, dynamic>> orderItems = cartItems.map((item) {
        return {
          'productId': item.menuItem.id,
          'name': item.menuItem.name,
          'price': item.menuItem.price,
          'quantity': item.quantity,
          'totalPrice': item.totalPrice,
        };
      }).toList();

      await _db.collection('orders').add({
        'restaurant_id': restaurantId,
        'table_no': tableNumber,
        'customer_name': customerName,
        'order_type': orderType,
        'items': orderItems,
        'total_amount': totalAmount,
        'status': 'Pending',
        'created_at': FieldValue.serverTimestamp(),
        'payment_method': paymentMethod,
        'sender_number': senderNumber ?? '',
        'trx_id': trxId ?? '',
        'payment_status': paymentMethod == 'Cash'
            ? 'Unpaid'
            : 'Pending Verification',
      });

      return true;
    } catch (e) {
      print('Error placing order: $e');
      return false;
    }
  }

  Stream<List<MenuItem>> getMenuItems(String restaurantId) {
    return _db
        .collection('MenuItems')
        .where('restaurant_id', isEqualTo: restaurantId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return MenuItem.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  Future<bool> addMenuItem({
    required String name,
    required String description,
    required double price,
    required double discountPrice,
    required int prepTime,
    required bool isAvailable,
    required String category,
    required String imageUrl,
    required List<String> imageUrls,
    required String restaurantId,
  }) async {
    try {
      await _db.collection('MenuItems').add({
        'restaurant_id': restaurantId,
        'name': name,
        'description': description,
        'price': price,
        'discountPrice': discountPrice,
        'prepTime': prepTime,
        'category': category,
        'imageUrl': imageUrl,
        'imageUrls': imageUrls,
        'isAvailable': isAvailable,
      });
      return true;
    } catch (e) {
      print('Error adding menu item: $e');
      return false;
    }
  }

  Stream<QuerySnapshot> getOrders(String restaurantId) {
    return _db
        .collection('orders')
        .where('restaurant_id', isEqualTo: restaurantId)
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  Future<void> updateOrderStatus(
    String orderId,
    String newStatus, {
    int? estimatedTime,
    String? thankYouMessage,
  }) async {
    try {
      Map<String, dynamic> updateData = {'status': newStatus};
      if (estimatedTime != null) {
        updateData['estimatedTime'] = estimatedTime;
      }
      if (thankYouMessage != null) {
        updateData['thank_you_message'] = thankYouMessage;
      }

      // ================= FIXED: ONLY SET CLEARED_AT WHEN FOOD IS SERVED =================
      if (newStatus == 'Served') {
        updateData['cleared_at'] = FieldValue.serverTimestamp();
      }

      await _db.collection('orders').doc(orderId).update(updateData);
    } catch (e) {
      print('Error updating order status: $e');
    }
  }

  Future<bool> deleteMenuItem(String docId) async {
    try {
      await _db.collection('MenuItems').doc(docId).delete();
      return true;
    } catch (e) {
      print('Error deleting item: $e');
      return false;
    }
  }

  Future<bool> updateMenuItem(
    String docId,
    Map<String, dynamic> updatedData,
  ) async {
    try {
      await _db.collection('MenuItems').doc(docId).update(updatedData);
      return true;
    } catch (e) {
      print('Error updating item: $e');
      return false;
    }
  }

  Future<bool> cancelOrder(String orderId) async {
    try {
      await _db.collection('orders').doc(orderId).delete();
      return true;
    } catch (e) {
      print('Error canceling order: $e');
      return false;
    }
  }

  Future<bool> confirmPaymentAndClearTable({
    required String restaurantId,
    required int tableNo,
    required String customerName,
    required double amountReceived,
  }) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('orders')
          .where('restaurant_id', isEqualTo: restaurantId)
          .where('table_no', isEqualTo: tableNo)
          .where('customer_name', isEqualTo: customerName)
          .where('payment_status', whereIn: ['Unpaid', 'Pending Verification'])
          .get();

      WriteBatch batch = _db.batch();
      for (var doc in snapshot.docs) {
        // ================= FIXED: DO NOT OVERRIDE FOOD STATUS =================
        // It only updates payment information. Food status remains Pending/Cooking/Ready.
        batch.update(doc.reference, {
          'payment_status': 'Paid',
          'amount_received': amountReceived,
        });
      }
      await batch.commit();
      return true;
    } catch (e) {
      print('Error confirming payment: $e');
      return false;
    }
  }

  Future<bool> savePaymentSettings(
    String restaurantId,
    String bkashNumber,
    String nagadNumber,
  ) async {
    try {
      await _db.collection('restaurant_settings').doc(restaurantId).set({
        'bkash_number': bkashNumber,
        'nagad_number': nagadNumber,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      print('Error saving payment settings: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getPaymentSettings(String restaurantId) async {
    try {
      DocumentSnapshot doc = await _db
          .collection('restaurant_settings')
          .doc(restaurantId)
          .get();
      if (doc.exists) return doc.data() as Map<String, dynamic>;
      return null;
    } catch (e) {
      print('Error fetching payment settings: $e');
      return null;
    }
  }

  Future<List<QueryDocumentSnapshot>> getOrdersForAnalytics(
    String restaurantId,
  ) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('orders')
          .where('restaurant_id', isEqualTo: restaurantId)
          .where('payment_status', isEqualTo: 'Paid')
          .get();
      return snapshot.docs;
    } catch (e) {
      print('Error fetching analytics: $e');
      return [];
    }
  }

  Stream<QuerySnapshot> getActiveTableOrders(String restaurantId) {
    return _db
        .collection('orders')
        .where('restaurant_id', isEqualTo: restaurantId)
        .where('payment_status', whereIn: ['Unpaid', 'Pending Verification'])
        .snapshots();
  }

  Stream<QuerySnapshot> getKitchenOrders(String restaurantId) {
    return _db
        .collection('orders')
        .where('restaurant_id', isEqualTo: restaurantId)
        .where('status', whereIn: ['Pending', 'Cooking'])
        .snapshots();
  }

  // ================= NEW: SUBMIT DEVELOPER PAYMENT =================
  Future<bool> submitDeveloperPayment({
    required String restaurantId,
    required String senderNumber,
    required String trxId,
    required String amount,
  }) async {
    try {
      await _db.collection('developer_payments').add({
        'restaurant_id': restaurantId,
        'sender_number': senderNumber,
        'trx_id': trxId,
        'amount': double.tryParse(amount) ?? 0.0,
        'status': 'Pending Verification',
        'submitted_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error submitting payment: $e');
      return false;
    }
  }

  // ================= NEW: UPDATE ORDER ITEMS (EDIT FEATURE) =================
  Future<bool> updateOrderItems(
    String orderId,
    List<Map<String, dynamic>> updatedItems,
    double newTotalAmount,
  ) async {
    try {
      if (updatedItems.isEmpty || newTotalAmount <= 0) {
        // Cancel order if all items are removed by the customer
        await cancelOrder(orderId);
        return true;
      }
      await _db.collection('orders').doc(orderId).update({
        'items': updatedItems,
        'total_amount': newTotalAmount,
      });
      return true;
    } catch (e) {
      print('Error updating order items: $e');
      return false;
    }
  }
}
/*
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<bool> placeOrder({
    required List<CartItem> cartItems,
    required double totalAmount,
    required int tableNumber,
    required String restaurantId,
    required String paymentMethod,
    required String customerName,
    required String orderType,
    String? senderNumber,
    String? trxId,
  }) async {
    try {
      List<Map<String, dynamic>> orderItems = cartItems.map((item) {
        return {
          'productId': item.menuItem.id,
          'name': item.menuItem.name,
          'price': item.menuItem.price,
          'quantity': item.quantity,
          'totalPrice': item.totalPrice,
        };
      }).toList();

      await _db.collection('orders').add({
        'restaurant_id': restaurantId,
        'table_no': tableNumber,
        'customer_name': customerName,
        'order_type': orderType,
        'items': orderItems,
        'total_amount': totalAmount,
        'status': 'Pending',
        'created_at': FieldValue.serverTimestamp(),
        'payment_method': paymentMethod,
        'sender_number': senderNumber ?? '',
        'trx_id': trxId ?? '',
        'payment_status': paymentMethod == 'Cash'
            ? 'Unpaid'
            : 'Pending Verification',
      });

      return true;
    } catch (e) {
      print('Error placing order: $e');
      return false;
    }
  }

  Stream<List<MenuItem>> getMenuItems(String restaurantId) {
    return _db
        .collection('MenuItems')
        .where('restaurant_id', isEqualTo: restaurantId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return MenuItem.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  Future<bool> addMenuItem({
    required String name,
    required String description,
    required double price,
    required double discountPrice,
    required int prepTime,
    required bool isAvailable,
    required String category,
    required String imageUrl,
    required List<String> imageUrls,
    required String restaurantId,
  }) async {
    try {
      await _db.collection('MenuItems').add({
        'restaurant_id': restaurantId,
        'name': name,
        'description': description,
        'price': price,
        'discountPrice': discountPrice,
        'prepTime': prepTime,
        'category': category,
        'imageUrl': imageUrl,
        'imageUrls': imageUrls,
        'isAvailable': isAvailable,
      });
      return true;
    } catch (e) {
      print('Error adding menu item: $e');
      return false;
    }
  }

  Stream<QuerySnapshot> getOrders(String restaurantId) {
    return _db
        .collection('orders')
        .where('restaurant_id', isEqualTo: restaurantId)
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  Future<void> updateOrderStatus(
    String orderId,
    String newStatus, {
    int? estimatedTime,
    String? thankYouMessage,
  }) async {
    try {
      Map<String, dynamic> updateData = {'status': newStatus};
      if (estimatedTime != null) {
        updateData['estimatedTime'] = estimatedTime;
      }
      if (thankYouMessage != null) {
        updateData['thank_you_message'] = thankYouMessage;
      }

      // ================= FIXED: ONLY SET CLEARED_AT WHEN FOOD IS SERVED =================
      if (newStatus == 'Served') {
        updateData['cleared_at'] = FieldValue.serverTimestamp();
      }

      await _db.collection('orders').doc(orderId).update(updateData);
    } catch (e) {
      print('Error updating order status: $e');
    }
  }

  Future<bool> deleteMenuItem(String docId) async {
    try {
      await _db.collection('MenuItems').doc(docId).delete();
      return true;
    } catch (e) {
      print('Error deleting item: $e');
      return false;
    }
  }

  Future<bool> updateMenuItem(
    String docId,
    Map<String, dynamic> updatedData,
  ) async {
    try {
      await _db.collection('MenuItems').doc(docId).update(updatedData);
      return true;
    } catch (e) {
      print('Error updating item: $e');
      return false;
    }
  }

  Future<bool> cancelOrder(String orderId) async {
    try {
      await _db.collection('orders').doc(orderId).delete();
      return true;
    } catch (e) {
      print('Error canceling order: $e');
      return false;
    }
  }

  Future<bool> confirmPaymentAndClearTable({
    required String restaurantId,
    required int tableNo,
    required String customerName,
    required double amountReceived,
  }) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('orders')
          .where('restaurant_id', isEqualTo: restaurantId)
          .where('table_no', isEqualTo: tableNo)
          .where('customer_name', isEqualTo: customerName)
          .where('payment_status', whereIn: ['Unpaid', 'Pending Verification'])
          .get();

      WriteBatch batch = _db.batch();
      for (var doc in snapshot.docs) {
        // ================= FIXED: DO NOT OVERRIDE FOOD STATUS =================
        // It only updates payment information. Food status remains Pending/Cooking/Ready.
        batch.update(doc.reference, {
          'payment_status': 'Paid',
          'amount_received': amountReceived,
        });
      }
      await batch.commit();
      return true;
    } catch (e) {
      print('Error confirming payment: $e');
      return false;
    }
  }

  Future<bool> savePaymentSettings(
    String restaurantId,
    String bkashNumber,
    String nagadNumber,
  ) async {
    try {
      await _db.collection('restaurant_settings').doc(restaurantId).set({
        'bkash_number': bkashNumber,
        'nagad_number': nagadNumber,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      print('Error saving payment settings: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getPaymentSettings(String restaurantId) async {
    try {
      DocumentSnapshot doc = await _db
          .collection('restaurant_settings')
          .doc(restaurantId)
          .get();
      if (doc.exists) return doc.data() as Map<String, dynamic>;
      return null;
    } catch (e) {
      print('Error fetching payment settings: $e');
      return null;
    }
  }

  Future<List<QueryDocumentSnapshot>> getOrdersForAnalytics(
    String restaurantId,
  ) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('orders')
          .where('restaurant_id', isEqualTo: restaurantId)
          .where('payment_status', isEqualTo: 'Paid')
          .get();
      return snapshot.docs;
    } catch (e) {
      print('Error fetching analytics: $e');
      return [];
    }
  }

  Stream<QuerySnapshot> getActiveTableOrders(String restaurantId) {
    return _db
        .collection('orders')
        .where('restaurant_id', isEqualTo: restaurantId)
        .where('payment_status', whereIn: ['Unpaid', 'Pending Verification'])
        .snapshots();
  }

  Stream<QuerySnapshot> getKitchenOrders(String restaurantId) {
    return _db
        .collection('orders')
        .where('restaurant_id', isEqualTo: restaurantId)
        .where('status', whereIn: ['Pending', 'Cooking'])
        .snapshots();
  }

  // ================= NEW: SUBMIT DEVELOPER PAYMENT =================
  Future<bool> submitDeveloperPayment({
    required String restaurantId,
    required String senderNumber,
    required String trxId,
    required String amount,
  }) async {
    try {
      await _db.collection('developer_payments').add({
        'restaurant_id': restaurantId,
        'sender_number': senderNumber,
        'trx_id': trxId,
        'amount': double.tryParse(amount) ?? 0.0,
        'status': 'Pending Verification',
        'submitted_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error submitting payment: $e');
      return false;
    }
  }
}
*/