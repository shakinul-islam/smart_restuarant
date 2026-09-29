import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  // Singleton Pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // ===================== ONESIGNAL CREDENTIALS =====================
  static const String _oneSignalAppId = '10d6da1a-c359-447c-92c2-2be53d9a2ec5';

  // 1. Initialize OneSignal (Call this in main.dart)
  Future<void> init() async {
    if (kIsWeb) return; // Prevent Web Crash

    try {
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      OneSignal.initialize(_oneSignalAppId);
      OneSignal.Notifications.requestPermission(true);
    } catch (e) {
      debugPrint('Error initializing OneSignal: $e');
    }
  }

  // 2. Set Device Tags on Login
  Future<void> setUserRole({
    required String restaurantId,
    required String role,
  }) async {
    if (kIsWeb) return;

    try {
      await OneSignal.User.addTags({
        'restaurant_id': restaurantId,
        'role': role.toLowerCase(),
      });
      debugPrint(
        'OneSignal tags set -> restaurant_id: $restaurantId, role: $role',
      );
    } catch (e) {
      debugPrint('Error setting OneSignal tags: $e');
    }
  }

  // 3. Clear Tags on Logout
  Future<void> clearUserRole() async {
    if (kIsWeb) return;

    try {
      await OneSignal.User.removeTags(['restaurant_id', 'role']);
      debugPrint('OneSignal tags cleared.');
    } catch (e) {
      debugPrint('Error clearing OneSignal tags: $e');
    }
  }

  // ===================== NEW: CANCEL ORDER / REMOVE NOTIFICATION =====================
  // Kono order cancel hole ei function ti call korle notification panel thekeo delete hoye jabe
  Future<void> removeNotificationForOrder(String orderId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('order_id', isEqualTo: orderId)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      debugPrint('Canceled order notification removed.');
    } catch (e) {
      debugPrint('Error removing notification: $e');
    }
  }

  // ===================== SAVE TO FIRESTORE FOR BELL ICON =====================
  Future<void> _saveToFirestore({
    required String restaurantId,
    required String title,
    required String message,
    required List<String> targetRoles,
    String? orderId, // orderId add kora holo cancel tracking er jonno
  }) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'restaurant_id': restaurantId,
        'order_id':
            orderId ?? '', // Identify korar jonno order_id save kora hocche
        'title': title,
        'message': message,
        'target_roles': targetRoles,
        'is_read': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint('Notification saved to Firestore successfully.');
    } catch (e) {
      debugPrint('Error saving to Firestore: $e');
    }
  }

  // 4. Base Function: Send Targeted Notification via Cloudflare Proxy
  Future<bool> _sendPushToRole({
    required String restaurantId,
    required String targetRole,
    required String title,
    required String message,
  }) async {
    try {
      final headers = {'Content-Type': 'application/json; charset=utf-8'};

      final body = {
        'app_id': _oneSignalAppId,
        'headings': {'en': title},
        'contents': {'en': message},
        'filters': [
          {
            'field': 'tag',
            'key': 'restaurant_id',
            'relation': '=',
            'value': restaurantId,
          },
          {'operator': 'AND'},
          {
            'field': 'tag',
            'key': 'role',
            'relation': '=',
            'value': targetRole.toLowerCase(),
          },
        ],
      };

      final String endpoint =
          'https://onesignal-proxy.shakinulislam017.workers.dev/';

      final response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        debugPrint('Push notification sent successfully via Cloudflare');
        return true;
      } else {
        debugPrint(
          'Failed to send notification. Status: ${response.statusCode}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error sending push notification: $e');
      return false;
    }
  }

  // ===================== ROLE SPECIFIC TRIGGERS =====================

  Future<void> notifyKitchenNewOrder({
    required String restaurantId,
    required int tableNo,
    required String customerName,
    required String orderType,
    String? orderId, // Added orderId
  }) async {
    String location = tableNo > 0 ? 'Table $tableNo' : orderType;
    String title = '🔔 New Order Received ($location)';
    String message = '$customerName placed a new order. Start cooking!';

    // ১. পুশ নোটিফিকেশন পাঠানো
    await _sendPushToRole(
      restaurantId: restaurantId,
      targetRole: 'kitchen',
      title: title,
      message: message,
    );

    // ২. ফায়ারস্টোরে সেভ করা
    await _saveToFirestore(
      restaurantId: restaurantId,
      title: title,
      message: message,
      targetRoles: [
        'kitchen',
      ], // <-- Admin removed, only kitchen will see this in bell
      orderId: orderId,
    );
  }

  Future<void> notifyWaiterFoodReady({
    required String restaurantId,
    required int tableNo,
    required String customerName,
    String? orderId, // Added orderId
  }) async {
    String location = tableNo > 0 ? 'Table $tableNo' : 'Parcel';
    String title = '🍽️ Food is Ready to Serve!';
    String message =
        'Order for $customerName ($location) is ready. Please serve to table.';

    // ১. পুশ নোটিফিকেশন পাঠানো
    await _sendPushToRole(
      restaurantId: restaurantId,
      targetRole: 'waiter',
      title: title,
      message: message,
    );

    // ২. ফায়ারস্টোরে সেভ করা
    await _saveToFirestore(
      restaurantId: restaurantId,
      title: title,
      message: message,
      targetRoles: [
        'waiter',
      ], // <-- Admin removed, only waiter will see this in bell
      orderId: orderId,
    );
  }

  Future<void> notifyAdminDigitalPayment({
    required String restaurantId,
    required int tableNo,
    required String customerName,
    required String paymentMethod,
    required double amount,
    String? orderId, // Added orderId
  }) async {
    String location = tableNo > 0 ? 'Table $tableNo' : 'Parcel';
    String title = '💳 $paymentMethod Payment Pending';
    String message =
        '$customerName ($location) submitted ৳${amount.toStringAsFixed(0)} via $paymentMethod. Please verify.';

    // ১. পুশ নোটিফিকেশন পাঠানো
    await _sendPushToRole(
      restaurantId: restaurantId,
      targetRole: 'admin',
      title: title,
      message: message,
    );

    // ২. ফায়ারস্টোরে সেভ করা
    await _saveToFirestore(
      restaurantId: restaurantId,
      title: title,
      message: message,
      targetRoles: ['admin'], // <-- Only Admin will see this
      orderId: orderId,
    );
  }
}
/*
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  // Singleton Pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // ===================== ONESIGNAL CREDENTIALS =====================
  static const String _oneSignalAppId = '10d6da1a-c359-447c-92c2-2be53d9a2ec5';

  // 1. Initialize OneSignal (Call this in main.dart)
  Future<void> init() async {
    if (kIsWeb) return; // Prevent Web Crash

    try {
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      OneSignal.initialize(_oneSignalAppId);
      OneSignal.Notifications.requestPermission(true);
    } catch (e) {
      debugPrint('Error initializing OneSignal: $e');
    }
  }

  // 2. Set Device Tags on Login
  Future<void> setUserRole({
    required String restaurantId,
    required String role,
  }) async {
    if (kIsWeb) return;

    try {
      await OneSignal.User.addTags({
        'restaurant_id': restaurantId,
        'role': role.toLowerCase(),
      });
      debugPrint(
        'OneSignal tags set -> restaurant_id: $restaurantId, role: $role',
      );
    } catch (e) {
      debugPrint('Error setting OneSignal tags: $e');
    }
  }

  // 3. Clear Tags on Logout
  Future<void> clearUserRole() async {
    if (kIsWeb) return;

    try {
      await OneSignal.User.removeTags(['restaurant_id', 'role']);
      debugPrint('OneSignal tags cleared.');
    } catch (e) {
      debugPrint('Error clearing OneSignal tags: $e');
    }
  }

  // ===================== NEW: CANCEL ORDER / REMOVE NOTIFICATION =====================
  // Kono order cancel hole ei function ti call korle notification panel thekeo delete hoye jabe
  Future<void> removeNotificationForOrder(String orderId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('order_id', isEqualTo: orderId)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      debugPrint('Canceled order notification removed.');
    } catch (e) {
      debugPrint('Error removing notification: $e');
    }
  }

  // ===================== SAVE TO FIRESTORE FOR BELL ICON =====================
  Future<void> _saveToFirestore({
    required String restaurantId,
    required String title,
    required String message,
    required List<String> targetRoles,
    String? orderId, // orderId add kora holo cancel tracking er jonno
  }) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'restaurant_id': restaurantId,
        'order_id':
            orderId ?? '', // Identify korar jonno order_id save kora hocche
        'title': title,
        'message': message,
        'target_roles': targetRoles,
        'is_read': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint('Notification saved to Firestore successfully.');
    } catch (e) {
      debugPrint('Error saving to Firestore: $e');
    }
  }

  // 4. Base Function: Send Targeted Notification via Cloudflare Proxy
  Future<bool> _sendPushToRole({
    required String restaurantId,
    required String targetRole,
    required String title,
    required String message,
  }) async {
    try {
      final headers = {'Content-Type': 'application/json; charset=utf-8'};

      final body = {
        'app_id': _oneSignalAppId,
        'headings': {'en': title},
        'contents': {'en': message},
        'filters': [
          {
            'field': 'tag',
            'key': 'restaurant_id',
            'relation': '=',
            'value': restaurantId,
          },
          {'operator': 'AND'},
          {
            'field': 'tag',
            'key': 'role',
            'relation': '=',
            'value': targetRole.toLowerCase(),
          },
        ],
      };

      final String endpoint =
          'https://onesignal-proxy.shakinulislam017.workers.dev/';

      final response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        debugPrint('Push notification sent successfully via Cloudflare');
        return true;
      } else {
        debugPrint(
          'Failed to send notification. Status: ${response.statusCode}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error sending push notification: $e');
      return false;
    }
  }

  // ===================== ROLE SPECIFIC TRIGGERS =====================

  Future<void> notifyKitchenNewOrder({
    required String restaurantId,
    required int tableNo,
    required String customerName,
    required String orderType,
    String? orderId, // Added orderId
  }) async {
    String location = tableNo > 0 ? 'Table $tableNo' : orderType;
    String title = '🔔 New Order Received ($location)';
    String message = '$customerName placed a new order. Start cooking!';

    // ১. পুশ নোটিফিকেশন পাঠানো
    await _sendPushToRole(
      restaurantId: restaurantId,
      targetRole: 'kitchen',
      title: title,
      message: message,
    );

    // ২. ফায়ারস্টোরে সেভ করা
    await _saveToFirestore(
      restaurantId: restaurantId,
      title: title,
      message: message,
      targetRoles: ['admin', 'kitchen'],
      orderId: orderId,
    );
  }

  Future<void> notifyWaiterFoodReady({
    required String restaurantId,
    required int tableNo,
    required String customerName,
    String? orderId, // Added orderId
  }) async {
    String location = tableNo > 0 ? 'Table $tableNo' : 'Parcel';
    String title = '🍽️ Food is Ready to Serve!';
    String message =
        'Order for $customerName ($location) is ready. Please serve to table.';

    // ১. পুশ নোটিফিকেশন পাঠানো
    await _sendPushToRole(
      restaurantId: restaurantId,
      targetRole: 'waiter',
      title: title,
      message: message,
    );

    // ২. ফায়ারস্টোরে সেভ করা
    await _saveToFirestore(
      restaurantId: restaurantId,
      title: title,
      message: message,
      targetRoles: ['admin', 'waiter'],
      orderId: orderId,
    );
  }

  Future<void> notifyAdminDigitalPayment({
    required String restaurantId,
    required int tableNo,
    required String customerName,
    required String paymentMethod,
    required double amount,
    String? orderId, // Added orderId
  }) async {
    String location = tableNo > 0 ? 'Table $tableNo' : 'Parcel';
    String title = '💳 $paymentMethod Payment Pending';
    String message =
        '$customerName ($location) submitted ৳${amount.toStringAsFixed(0)} via $paymentMethod. Please verify.';

    // ১. পুশ নোটিফিকেশন পাঠানো
    await _sendPushToRole(
      restaurantId: restaurantId,
      targetRole: 'admin',
      title: title,
      message: message,
    );

    // ২. ফায়ারস্টোরে সেভ করা
    await _saveToFirestore(
      restaurantId: restaurantId,
      title: title,
      message: message,
      targetRoles: ['admin'],
      orderId: orderId,
    );
  }
}
*/