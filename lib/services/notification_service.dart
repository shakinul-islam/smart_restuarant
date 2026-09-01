import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';

class NotificationService {
  // Singleton Pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // ===================== ONESIGNAL CREDENTIALS =====================
  static const String _oneSignalAppId = '10d6da1a-c359-447c-92c2-2be53d9a2ec5';
  // REST API Key রিমুভ করা হয়েছে! এটি এখন সুরক্ষিতভাবে Cloudflare Worker-এর ভেতরে আছে।

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

  // 4. Base Function: Send Targeted Notification via Cloudflare Proxy
  Future<bool> _sendPushToRole({
    required String restaurantId,
    required String targetRole,
    required String title,
    required String message,
  }) async {
    try {
      final headers = {
        'Content-Type': 'application/json; charset=utf-8',
        // Authorization লাইনটি রিমুভ করা হয়েছে (এটি Cloudflare সামলাবে)
      };

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

      // ================= FIXED: UNIFIED CLOUDFLARE PROXY =================
      // ওয়েব এবং অ্যান্ড্রয়েড—উভয় ক্ষেত্রেই আমরা Cloudflare Worker ব্যবহার করছি।
      // এতে অ্যাপ ডিকম্পাইল করলেও হ্যাকাররা আপনার API Key পাবে না।
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
  }) async {
    String location = tableNo > 0 ? 'Table $tableNo' : orderType;
    await _sendPushToRole(
      restaurantId: restaurantId,
      targetRole: 'kitchen',
      title: '🔔 New Order Received ($location)',
      message: '$customerName placed a new order. Start cooking!',
    );
  }

  Future<void> notifyWaiterFoodReady({
    required String restaurantId,
    required int tableNo,
    required String customerName,
  }) async {
    String location = tableNo > 0 ? 'Table $tableNo' : 'Parcel';
    await _sendPushToRole(
      restaurantId: restaurantId,
      targetRole: 'waiter',
      title: '🍽️ Food is Ready to Serve!',
      message:
          'Order for $customerName ($location) is ready. Please serve to table.',
    );
  }

  Future<void> notifyAdminDigitalPayment({
    required String restaurantId,
    required int tableNo,
    required String customerName,
    required String paymentMethod,
    required double amount,
  }) async {
    String location = tableNo > 0 ? 'Table $tableNo' : 'Parcel';
    await _sendPushToRole(
      restaurantId: restaurantId,
      targetRole: 'admin',
      title: '💳 $paymentMethod Payment Pending Verification',
      message:
          '$customerName ($location) submitted ৳${amount.toStringAsFixed(0)} via $paymentMethod.',
    );
  }
}
