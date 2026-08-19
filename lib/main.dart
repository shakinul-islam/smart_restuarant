import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/menu_screen.dart';
import 'services/cart_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => CartProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Menu & POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[50],
      ),

      // ================= WEB ROUTING LOGIC =================
      onGenerateRoute: (settings) {
        final Uri uri = Uri.parse(settings.name ?? '');

        // ১. যদি লিংকে '/menu' থাকে, তবে কাস্টমারকে সরাসরি মেনুতে পাঠাবে
        if (uri.path == '/menu') {
          final String? restId = uri.queryParameters['restId'];
          final String? tableStr = uri.queryParameters['table'];

          if (restId != null && tableStr != null) {
            return MaterialPageRoute(
              builder: (context) => MenuScreen(
                restaurantId: restId,
                tableNumber: int.tryParse(tableStr) ?? 1,
              ),
            );
          }
        }

        // ২. অন্যথায় ডিফল্ট ওয়েলকাম স্ক্রিনে পাঠাবে
        return MaterialPageRoute(builder: (context) => const WelcomeScreen());
      },
    );
  }
}

// ================= WELCOME SCREEN (For incorrect link or Staff Login) =================
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.qr_code_scanner,
              size: 100,
              color: Colors.deepOrange,
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome to our Digital Menu!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Please scan the QR code on your table to order.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),

            // স্টাফদের প্যানেলে যাওয়ার লগইন বাটন
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              icon: const Icon(Icons.lock_person, color: Colors.grey),
              label: const Text(
                'Staff Login',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
