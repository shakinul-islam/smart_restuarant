import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Login Function (For both Admin & Waiter)
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

        // --- Security Check 1: Ensure Role and Restaurant ID exist ---
        if (data.containsKey('role') && data.containsKey('restaurant_id')) {
          return data;
        } else {
          await logout(); // Invalid data structure, force logout
          print(
            'Security Alert: Corrupted staff record or missing permissions.',
          );
          return null;
        }
      } else {
        await logout(); // User authenticated but no staff record found
        print('Security Alert: No staff record found for this user.');
        return null;
      }
    } catch (e) {
      print('Login Error: $e');
      return null;
    }
  }

  // 2. Session Checker (Auto-Login Support)
  // অ্যাপ ওপেন করার সময় ইউজার আগে থেকেই লগ-ইন করা আছে কি না, তা চেক করার জন্য
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

      // Generating a unique Restaurant ID (Multi-tenant Architecture)
      String restaurantId = '${baseName}_$uniqueSuffix';

      Map<String, dynamic> userData = {
        'uid': userCredential.user!.uid,
        'email': email,
        'restaurant_name': restaurantName,
        'restaurant_id': restaurantId,
        'role': 'admin', // Strict Role Assignment
        'created_at': FieldValue.serverTimestamp(),
      };

      await _db.collection('staff').doc(userCredential.user!.uid).set(userData);
      return userData;
    } catch (e) {
      print('Registration Error: $e');
      return null;
    }
  }

  // 4. Create Waiter Account (For Admins to add staff)
  Future<bool> createWaiterAccount({
    required String email,
    required String password,
    required String restaurantId,
  }) async {
    try {
      // --- Security Check 2: Unauthorized Waiter Creation Prevention ---
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Verify that the current user is actually an 'admin' of THIS specific restaurant
      DocumentSnapshot adminDoc = await _db
          .collection('staff')
          .doc(currentUser.uid)
          .get();
      if (!adminDoc.exists) return false;

      final adminData = adminDoc.data() as Map<String, dynamic>;
      if (adminData['role'] != 'admin' ||
          adminData['restaurant_id'] != restaurantId) {
        print(
          'Security Alert: Unauthorized attempt to create a waiter account!',
        );
        return false;
      }

      // Create a temporary secondary Firebase App to prevent Admin logout
      FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'TemporaryRegisterApp',
        options: Firebase.app().options,
      );

      // Use the temporary app to create the waiter user
      UserCredential userCredential = await FirebaseAuth.instanceFor(
        app: tempApp,
      ).createUserWithEmailAndPassword(email: email, password: password);

      // Save waiter data to Firestore 'staff' collection
      await _db.collection('staff').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'restaurant_id': restaurantId, // Tied strictly to Admin's Restaurant ID
        'role': 'waiter', // Strictly assigned as Waiter
        'created_at': FieldValue.serverTimestamp(),
      });

      // Delete the temporary app instance so it doesn't cause conflicts
      await tempApp.delete();

      return true; // Successfully created
    } catch (e) {
      print('Waiter Registration Error: $e');
      return false;
    }
  }

  // 5. Logout Function
  Future<void> logout() async {
    await _auth.signOut();
  }
}
