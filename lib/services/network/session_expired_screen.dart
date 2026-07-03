import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../configs/routes/routes_name.dart';

class SessionExpiredPage extends StatelessWidget {
  const SessionExpiredPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Session expired icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.access_time_filled,
                  size: 60,
                  color: Colors.red,
                ),
              ),

              const SizedBox(height: 32),

              // Title
              const Text(
                'Session Expired',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Subtitle
              const Text(
                'Your session has expired for security reasons. Please log in again to continue.',
                style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Login button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    _handleLoginRedirect();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Login Again',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Contact support button (optional)
              TextButton(
                onPressed: () {
                  _showContactSupport(context);
                },
                child: const Text(
                  'Need Help? Contact Support',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLoginRedirect() async {
    final storage = GetStorage();
    final pendingPaymentId = storage.read<String>('pendingPaymentId');
    await storage.erase();
    if (pendingPaymentId != null && pendingPaymentId.isNotEmpty) {
      await storage.write('pendingPaymentId', pendingPaymentId);
    }
    Get.offAllNamed(RoutesName.login);
  }

  void _showContactSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Contact Support'),
          content: const Text(
            'If you continue to experience issues, please contact our support team at support@yourapp.com',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
