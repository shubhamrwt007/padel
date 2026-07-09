import 'package:flutter/material.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/utils/share_payment_helper.dart';

class SharePaymentButton extends StatelessWidget {
  final String matchId;
  final String? matchName;
  final String? courtName;
  final String? amount;
  final String? currency;
  final ButtonStyle? style;

  const SharePaymentButton({
    super.key,
    required this.matchId,
    this.matchName,
    this.courtName,
    this.amount,
    this.currency,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.share),
      label: const Text('Share Payment'),
      style: style,
      onPressed: () {
        final displayAmount = (currency != null && amount != null)
            ? '$currency $amount'
            : amount;
        SharePaymentHelper.share(
          matchId: matchId,
          matchName: matchName,
          amount: displayAmount,
        );
      },
    );
  }
}

class SharePaymentIconButton extends StatelessWidget {
  final String matchId;
  final String? matchName;
  final String? amount;

  const SharePaymentIconButton({
    super.key,
    required this.matchId,
    this.matchName,
    this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.share),
      tooltip: 'Share Payment',
      onPressed: () => SharePaymentHelper.share(
        matchId: matchId,
        matchName: matchName,
        amount: amount,
      ),
    );
  }
}

class SharePaymentCard extends StatelessWidget {
  final String matchId;
  final String matchName;
  final String courtName;
  final String amount;
  final String currency;

  const SharePaymentCard({
    super.key,
    required this.matchId,
    required this.matchName,
    required this.courtName,
    required this.amount,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.payment, color: AppColors.primaryColor),
                const SizedBox(width: 12),
                const Text(
                  'Share Payment Request',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _row('Match', matchName),
            _row('Court', courtName),
            _row('Amount', '$currency $amount'),
            const SizedBox(height: 16),
            const Text(
              'Share this payment link with other players.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Share'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => SharePaymentHelper.share(
                  matchId: matchId,
                  matchName: matchName,
                  amount: '$currency $amount',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
