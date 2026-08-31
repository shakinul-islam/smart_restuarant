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
  static const String _restApiKey =
      'os_v2_app_cdlnugwdlfchzewcfpst3groyvuejozqbodetqn6bn4muk3muy4gkes2fy6jc7ecqyxoosxsbvldaol6ah6zh2h3doqdfdmvk3vtohy';

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

  // 4. Base Function: Send Targeted Notification via OneSignal REST API
  Future<bool> _sendPushToRole({
    required String restaurantId,
    required String targetRole,
    required String title,
    required String message,
  }) async {
    try {
      final headers = {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Basic $_restApiKey',
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

      // ================= FIXED: BULLETPROOF PROXY FALLBACK =================
      List<String> endpoints = [];

      if (kIsWeb) {
        // ওয়েবের ক্ষেত্রে আমরা ৩টি আলাদা প্রক্সি সার্ভার লিস্ট করে দিয়েছি।
        // কোনো কারণে একটি ডাউন থাকলে অ্যাপ অটোমেটিক পরেরটি ট্রাই করবে।
        endpoints = [
          'https://corsproxy.io/?https://onesignal.com/api/v1/notifications',
          'https://api.codetabs.com/v1/proxy?quest=https://onesignal.com/api/v1/notifications',
          'https://cors-proxy.fringe.zone/https://onesignal.com/api/v1/notifications',
        ];
      } else {
        // অ্যান্ড্রয়েড অ্যাপ থেকে সরাসরি কল হবে, কোনো প্রক্সি লাগবে না।
        endpoints = ['https://onesignal.com/api/v1/notifications'];
      }

      // লুপ চালিয়ে প্রক্সিগুলো চেক করা হচ্ছে
      for (String endpoint in endpoints) {
        try {
          final response = await http.post(
            Uri.parse(endpoint),
            headers: headers,
            body: jsonEncode(body),
          );

          if (response.statusCode == 200) {
            debugPrint('Push notification sent successfully via: $endpoint');
            return true; // নোটিফিকেশন চলে গেলে লুপ থেকে বের হয়ে যাবে
          }
        } catch (e) {
          debugPrint('Proxy failed ($endpoint), trying next proxy...');
        }
      }

      debugPrint('All notification proxies failed.');
      return false;
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
