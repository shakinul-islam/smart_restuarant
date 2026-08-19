import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRGeneratorScreen extends StatefulWidget {
  final String restaurantId;

  const QRGeneratorScreen({super.key, required this.restaurantId});

  @override
  State<QRGeneratorScreen> createState() => _QRGeneratorScreenState();
}

class _QRGeneratorScreenState extends State<QRGeneratorScreen> {
  final TextEditingController _tableController = TextEditingController();

  // ================= NEW: BASE URL FOR WEB APP =================
  // GitHub এ হোস্ট করার পর আপনার লিংকটি এখানে দেবেন। আপাতত লোকাল টেস্টিং এর জন্য একটি ডেমো লিংক রাখা হলো।
  final String baseUrl = 'https://shakinul.github.io/foodapp';

  String? _qrData;
  int _tableNumber = 1;

  void _generateQR() {
    if (_tableController.text.trim().isEmpty) return;

    setState(() {
      _tableNumber = int.parse(_tableController.text.trim());
      // ডাইনামিক লিংক তৈরি করা হচ্ছে
      _qrData =
          '$baseUrl/#/menu?restId=${widget.restaurantId}&table=$_tableNumber';
    });

    // কি-বোর্ড হাইড করা
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    _tableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Generate Table QR',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.qr_code_scanner_rounded,
                size: 80,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 20),
              const Text(
                'Enter Table Number',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Customers will scan this QR to view the menu and place orders.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),

              // Input Box
              Container(
                constraints: const BoxConstraints(maxWidth: 300),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _tableController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. 5',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Generate Button
              SizedBox(
                width: 300,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _generateQR,
                  icon: const Icon(Icons.qr_code, color: Colors.white),
                  label: const Text(
                    'Generate QR Code',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // QR Code Output
              if (_qrData != null) ...[
                const Divider(),
                const SizedBox(height: 20),
                const Text(
                  'Scan to order from:',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Table $_tableNumber',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: _qrData!,
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Colors.deepPurple,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Print and place this on the table',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
