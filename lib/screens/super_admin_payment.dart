import 'package:flutter/material.dart';
import '../services/database_service.dart';

class SuperAdminPaymentScreen extends StatefulWidget {
  final String restaurantId;
  const SuperAdminPaymentScreen({super.key, required this.restaurantId});

  @override
  State<SuperAdminPaymentScreen> createState() =>
      _SuperAdminPaymentScreenState();
}

class _SuperAdminPaymentScreenState extends State<SuperAdminPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _senderCtrl = TextEditingController();
  final TextEditingController _trxCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  bool _isSubmitting = false;

  void _showMessage(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.blue[50],
      prefixIcon: Icon(icon, color: Colors.blueAccent),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
      ),
    );
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    bool success = await _dbService.submitDeveloperPayment(
      restaurantId: widget.restaurantId,
      senderNumber: _senderCtrl.text.trim(),
      trxId: _trxCtrl.text.trim(),
      amount: _amountCtrl.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (success) {
      _showMessage(
        'Payment details submitted successfully! Verification pending.',
        Colors.green,
      );
      Navigator.pop(context);
    } else {
      _showMessage('Failed to submit payment details.', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Developer Payment',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(24),
            physics: const BouncingScrollPhysics(),
            children: [
              // ================= DEVELOPER PROFILE CARD =================
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.developer_mode,
                        size: 50,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Md Shakinul Islam',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Software Developer & System Maintainer',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Divider(height: 32, thickness: 1),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.pink.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.pink.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: Colors.pink,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Send bKash to: ',
                            style: TextStyle(
                              color: Colors.pink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '01775199186',
                            style: TextStyle(
                              color: Colors.pink,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please "Send Money" to the number above and fill out the form below to confirm your subscription payment.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ================= PAYMENT SUBMISSION FORM =================
              const Text(
                'Submit Transaction Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _amountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: _buildInputDecoration(
                          'Amount Paid (৳)',
                          Icons.attach_money,
                        ),
                        validator: (v) =>
                            v!.isEmpty ? 'Enter paid amount' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _senderCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: _buildInputDecoration(
                          'Sender bKash Number',
                          Icons.phone_android,
                        ),
                        validator: (v) =>
                            v!.isEmpty ? 'Enter sender number' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _trxCtrl,
                        decoration: _buildInputDecoration(
                          'Transaction ID (TrxID)',
                          Icons.tag,
                        ),
                        validator: (v) => v!.isEmpty ? 'Enter TrxID' : null,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isSubmitting ? null : _submitPayment,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Submit Payment',
                                  style: TextStyle(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
