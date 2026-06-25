import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PaymentPopupDialog extends StatelessWidget {
  final String paymentId;
  final VoidCallback onSubmit;

  const PaymentPopupDialog({
    super.key,
    required this.paymentId,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.payment,
              size: 64,
              color: Color(0xFF1E40AF),
            ),
            const SizedBox(height: 16),
            Text(
              "Payment Request",
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "You have a pending payment for this match. Would you like to proceed with the payment?",
              textAlign: TextAlign.center,
              style: Get.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onSubmit();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E40AF),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Submit",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static void show(BuildContext context, String paymentLink) {
    final paymentId = _extractPaymentId(paymentLink);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentPopupDialog(
        paymentId: paymentId,
        onSubmit: () => _handlePayment(paymentId),
      ),
    );
  }

  static String _extractPaymentId(String paymentLink) {
    final uri = Uri.parse(paymentLink);
    final segments = uri.pathSegments;
    final index = segments.indexOf('pay-share-payment');
    if (index != -1 && index + 1 < segments.length) {
      return segments[index + 1];
    }
    return '';
  }

  static Future<void> _handlePayment(String paymentId) async {
    // TODO: Replace with your actual API service
    // Example: await ApiService().acceptWalletPayment(paymentId);
    
    try {
      Get.snackbar(
        "Processing",
        "Payment is being processed...",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue.shade100,
      );
      
      // Your API call here
      // final response = await http.post(
      //   Uri.parse('/api/customer/court/openmatch/pay-share-payment/$paymentId/accept-wallet'),
      // );
      
      Get.snackbar(
        "Success",
        "Payment completed successfully",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Payment failed: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
    }
  }
}
