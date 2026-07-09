import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/routes/routes_name.dart';
import 'package:padel_mobile/core/endpoitns.dart';
import 'package:padel_mobile/handler/logger.dart';
import 'package:padel_mobile/repositories/share_payment_repository.dart';
import 'package:padel_mobile/configs/components/app_toast.dart';

class SharePaymentController extends GetxController {
  final _repo = SharePaymentRepository();

  final isLoading = true.obs;
  final errorMessage = ''.obs;
  final paymentData = Rx<Map<String, dynamic>?>(null);

  String paymentId = '';

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    // Support both deep link styles
    paymentId = args?['paymentId'] ?? args?['matchId'] ?? '';
    if (paymentId.isEmpty) {
      errorMessage.value = 'Invalid link. Payment ID is missing.';
      isLoading.value = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final data = await _repo.resolveSharePayment(paymentId);
      if (data == null) {
        errorMessage.value = 'Could not load payment details. Please try again.';
        return;
      }
      final success = data['success'] == true;
      if (!success) {
        final status = data['data']?['paymentStatus'] ?? '';
        errorMessage.value = status == 'cancelled'
            ? 'This payment link has been cancelled.'
            : data['message'] ?? 'Payment is no longer available.';
        return;
      }
      paymentData.value = data;
    } catch (e) {
      CustomLogger.logMessage(msg: '❌ SharePayment load error: $e', level: LogLevel.error);
      errorMessage.value = 'Something went wrong. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  void retry() => _load();

  Map<String, dynamic>? get _data => paymentData.value?['data'] as Map<String, dynamic>?;

  /// Prepend base URL if the link is a relative path
  String _resolveUrl(String link) {
    if (link.isEmpty) return '';
    if (link.startsWith('http://') || link.startsWith('https://')) return link;
    // Relative path — strip leading /api/ since AppEndpoints.base already ends with /api/
    final base = AppEndpoints.socketUrl;
    return '$base$link';
  }

  String get paymentMode => _data?['paymentMode'] as String? ?? '';
  bool get isWalletPayment => paymentMode.toLowerCase() == 'wallet';

  /// The resolved accept-wallet endpoint (used for wallet payments)
  String get walletAcceptUrl {
    final endpoint = _data?['acceptEndpoint'] as String? ??
        _data?['walletAcceptUrl'] as String? ?? '';
    if (endpoint.isEmpty) return '';
    if (endpoint.startsWith('http://') || endpoint.startsWith('https://')) return endpoint;
    // acceptEndpoint starts with /api/customer/... — prepend just the host
    final host = AppEndpoints.socketUrl; // e.g. http://192.168.0.126:5070
    return '$host$endpoint';
  }

  /// For Razorpay / split payments: the external payment link
  String get razorpayLink {
    final link = _data?['razorpayPaymentLink'] as String? ??
        _data?['paymentLink'] as String? ?? '';
    return _resolveUrl(link);
  }

  Map<String, dynamic>? get matchInfo =>
      _data?['match'] as Map<String, dynamic>?;

  double get paymentAmount => (_data?['paymentAmount'] ?? 0).toDouble();
  double get razorpayAmountDue => (_data?['razorpayAmountDue'] ?? 0).toDouble();
  double get walletContribution => (_data?['walletContributionAmount'] ?? 0).toDouble();
  String get paymentStatus => _data?['paymentStatus'] ?? '';

  /// Called when user taps Pay for a wallet payment
  Future<void> acceptWalletPayment() async {
    final url = walletAcceptUrl;
    if (url.isEmpty) {
      AppToast.error('Wallet payment URL not available.');
      return;
    }
    isLoading.value = true;
    try {
      await _repo.acceptWalletPayment(url);
      AppToast.success('Payment successful!');
      Get.offAllNamed(RoutesName.bottomNav);
    } catch (e) {
      CustomLogger.logMessage(msg: '❌ Wallet payment error: $e', level: LogLevel.error);
      AppToast.error('Payment failed. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }
}

// ─── WebView Payment Screen ──────────────────────────────────────────────────

class RazorpayWebViewScreen extends StatefulWidget {
  final String url;
  const RazorpayWebViewScreen({super.key, required this.url});

  @override
  State<RazorpayWebViewScreen> createState() => _RazorpayWebViewScreenState();
}

class _RazorpayWebViewScreenState extends State<RazorpayWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _isLoading = true),
        onPageFinished: (_) => setState(() => _isLoading = false),
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.blackColor),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Complete Payment',
          style: TextStyle(color: AppColors.blackColor, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.primaryColor)),
        ],
      ),
    );
  }
}

// ─── Share Payment Screen ─────────────────────────────────────────────────────

class SharePaymentScreen extends StatelessWidget {
  const SharePaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SharePaymentController());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.blackColor),
          onPressed: () => Get.offAllNamed(RoutesName.bottomNav),
        ),
        title: const Text(
          'Payment Request',
          style: TextStyle(color: AppColors.blackColor, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor),
          );
        }

        if (controller.errorMessage.value.isNotEmpty) {
          final isCancelled = controller.errorMessage.value.contains('cancelled');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isCancelled ? Icons.cancel_outlined : Icons.error_outline,
                    size: 64,
                    color: isCancelled ? Colors.orange : Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    controller.errorMessage.value,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, color: AppColors.darkGrey),
                  ),
                  const SizedBox(height: 24),
                  if (!isCancelled)
                    ElevatedButton(
                      onPressed: controller.retry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Retry', style: TextStyle(color: Colors.white)),
                    ),
                  OutlinedButton(
                    onPressed: () => Get.offAllNamed(RoutesName.bottomNav),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Go to Home', style: TextStyle(color: AppColors.primaryColor)),
                  ),
                ],
              ),
            ),
          );
        }

        final match = controller.matchInfo;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.sports_tennis, size: 48, color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      'You have a payment request!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Match details
              if (match != null) ...[
                const Text('Match Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _infoCard([
                  if (match['clubName'] != null) _row('Club', match['clubName']),
                  if (match['courtName'] != null) _row('Court', match['courtName']),
                  if (match['bookingDate'] != null) _row('Date', match['bookingDate']),
                  if (match['bookingTime'] != null) _row('Time', match['bookingTime']),
                  if (match['skillLevel'] != null) _row('Skill', match['skillLevel']),
                  if (match['gender'] != null) _row('Gender', match['gender']),
                ]),
                const SizedBox(height: 20),
              ],

              // Payment breakdown
              const Text('Payment Breakdown',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _infoCard([
                _row('Total Amount', '₹${controller.paymentAmount.toStringAsFixed(2)}'),
                _row('Wallet Used', '₹${controller.walletContribution.toStringAsFixed(2)}'),
                _row('Amount Due', '₹${controller.razorpayAmountDue.toStringAsFixed(2)}',
                    valueStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.primaryColor)),
              ]),
              const SizedBox(height: 28),

              // Pay Now button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isWalletPayment
                      ? controller.acceptWalletPayment
                      : (controller.razorpayLink.isNotEmpty
                          ? () => Get.to(() => RazorpayWebViewScreen(url: controller.razorpayLink))
                          : null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    controller.isWalletPayment
                        ? 'Pay ₹${controller.paymentAmount.toStringAsFixed(2)} from Wallet'
                        : 'Pay ₹${controller.razorpayAmountDue.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Get.offAllNamed(RoutesName.bottomNav),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.primaryColor),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Go to Home',
                      style: TextStyle(
                          color: AppColors.primaryColor, fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _infoCard(List<Widget> rows) {
    final nonEmpty = rows.where((w) => w is! SizedBox).toList();
    if (nonEmpty.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightBlueColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.textFieldBorderColor),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1) const Divider(height: 16),
          ]
        ],
      ),
    );
  }

  Widget _row(String label, String value, {TextStyle? valueStyle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.darkGrey, fontSize: 14)),
        Text(value,
            style: valueStyle ??
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }
}
