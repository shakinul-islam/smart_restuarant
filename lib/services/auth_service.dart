import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Login Function
  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      DocumentSnapshot userDoc = await _db
          .collection('staff')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        if (data.containsKey('role') && data.containsKey('restaurant_id')) {
          return data;
        } else {
          await logout();
          throw FirebaseAuthException(
            code: 'invalid-permissions',
            message: 'Corrupted staff record or missing permissions.',
          );
        }
      } else {
        await logout();
        throw FirebaseAuthException(
          code: 'no-record',
          message: 'No staff record found for this user.',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // 2. Session Checker (Auto-Login Support)
  Future<Map<String, dynamic>?> getCurrentStaffData() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc = await _db
            .collection('staff')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          return userDoc.data() as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      print('Session Check Error: $e');
      return null;
    }
  }

  // 3. Restaurant Registration Function (For Admins)
  Future<Map<String, dynamic>?> registerRestaurant({
    required String restaurantName,
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      String baseName = restaurantName.trim().toLowerCase().replaceAll(
        RegExp(r'\s+'),
        '_',
      );
      String uniqueSuffix = userCredential.user!.uid
          .substring(0, 4)
          .toLowerCase();
      String restaurantId = '${baseName}_$uniqueSuffix';

      Map<String, dynamic> userData = {
        'uid': userCredential.user!.uid,
        'email': email,
        'restaurant_name': restaurantName,
        'restaurant_id': restaurantId,
        'role': 'admin',
        'created_at': FieldValue.serverTimestamp(),
      };

      await _db.collection('staff').doc(userCredential.user!.uid).set(userData);

      // ================= NEW: DEFAULT RESTAURANT SETTINGS =================
      await _db.collection('restaurant_settings').doc(restaurantId).set({
        'restaurant_name': restaurantName,
        'is_active': true,
        'notice_message': '',
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return userData;
    } catch (e) {
      rethrow;
    }
  }

  // 4. Create Staff Account
  Future<bool> createStaffAccount({
    required String email,
    required String password,
    required String restaurantId,
    required String role,
  }) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      DocumentSnapshot adminDoc = await _db
          .collection('staff')
          .doc(currentUser.uid)
          .get();
      if (!adminDoc.exists) return false;

      final adminData = adminDoc.data() as Map<String, dynamic>;
      if (adminData['role'] != 'admin' ||
          adminData['restaurant_id'] != restaurantId) {
        return false;
      }

      FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'TemporaryRegisterApp',
        options: Firebase.app().options,
      );

      UserCredential userCredential = await FirebaseAuth.instanceFor(
        app: tempApp,
      ).createUserWithEmailAndPassword(email: email, password: password);

      await _db.collection('staff').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'restaurant_id': restaurantId,
        'role': role,
        'created_at': FieldValue.serverTimestamp(),
      });

      await tempApp.delete();
      return true;
    } catch (e) {
      print('Staff Registration Error: $e');
      return false;
    }
  }

  // 5. Send Password Reset Email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      print('Reset Password Error: $e');
      return false;
    }
  }

  // 6. Logout Function
  Future<void> logout() async {
    await _auth.signOut();
  }
}
/*
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Login Function (Throws exception for specific errors)
  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      DocumentSnapshot userDoc = await _db
          .collection('staff')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        if (data.containsKey('role') && data.containsKey('restaurant_id')) {
          return data;
        } else {
          await logout();
          throw FirebaseAuthException(
            code: 'invalid-permissions',
            message: 'Corrupted staff record or missing permissions.',
          );
        }
      } else {
        await logout();
        throw FirebaseAuthException(
          code: 'no-record',
          message: 'No staff record found for this user.',
        );
      }
    } catch (e) {
      // Re-throw to handle it in the UI
      rethrow;
    }
  }

  // 2. Session Checker (Auto-Login Support)
  Future<Map<String, dynamic>?> getCurrentStaffData() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc = await _db
            .collection('staff')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          return userDoc.data() as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      print('Session Check Error: $e');
      return null;
    }
  }

  // 3. Restaurant Registration Function (For Admins)
  Future<Map<String, dynamic>?> registerRestaurant({
    required String restaurantName,
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      String baseName = restaurantName.trim().toLowerCase().replaceAll(
        RegExp(r'\s+'),
        '_',
      );
      String uniqueSuffix = userCredential.user!.uid
          .substring(0, 4)
          .toLowerCase();

      String restaurantId = '${baseName}_$uniqueSuffix';

      Map<String, dynamic> userData = {
        'uid': userCredential.user!.uid,
        'email': email,
        'restaurant_name': restaurantName,
        'restaurant_id': restaurantId,
        'role': 'admin',
        'created_at': FieldValue.serverTimestamp(),
      };

      await _db.collection('staff').doc(userCredential.user!.uid).set(userData);
      return userData;
    } catch (e) {
      rethrow; // Pass error to UI
    }
  }

  // 4. Create Staff Account (For Admins to add Waiter or Kitchen)
  Future<bool> createStaffAccount({
    required String email,
    required String password,
    required String restaurantId,
    required String role,
  }) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      DocumentSnapshot adminDoc = await _db
          .collection('staff')
          .doc(currentUser.uid)
          .get();
      if (!adminDoc.exists) return false;

      final adminData = adminDoc.data() as Map<String, dynamic>;
      if (adminData['role'] != 'admin' ||
          adminData['restaurant_id'] != restaurantId) {
        return false;
      }

      FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'TemporaryRegisterApp',
        options: Firebase.app().options,
      );

      UserCredential userCredential = await FirebaseAuth.instanceFor(
        app: tempApp,
      ).createUserWithEmailAndPassword(email: email, password: password);

      await _db.collection('staff').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'restaurant_id': restaurantId,
        'role': role,
        'created_at': FieldValue.serverTimestamp(),
      });

      await tempApp.delete();
      return true;
    } catch (e) {
      print('Staff Registration Error: $e');
      return false;
    }
  }

  // 5. Send Password Reset Email (NEW)
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      print('Reset Password Error: $e');
      return false;
    }
  }

  // 6. Logout Function
  Future<void> logout() async {
    await _auth.signOut();
  }
}
*/