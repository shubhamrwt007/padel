import 'package:flutter/material.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/utils/share_payment_helper.dart';

/// Drop this widget anywhere you want a share button
/// 
/// Example:
///   SharePaymentButton(matchId: match.sId ?? '')
///   SharePaymentButton(matchId: match.sId ?? '', matchName: 'Evening Match', amount: '₹500')
class SharePaymentButton extends StatelessWidget {
  final String matchId;
  final String? matchName;
  final String? amount;
  final bool iconOnly;

  const SharePaymentButton({
    super.key,
    required this.matchId,
    this.matchName,
    this.amount,
    this.iconOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    if (iconOnly) {
      return IconButton(
        icon: const Icon(Icons.share, color: AppColors.primaryColor),
        tooltip: 'Share Payment',
        onPressed: _share,
      );
    }
    return ElevatedButton.icon(
      icon: const Icon(Icons.share, size: 18),
      label: const Text('Share Payment'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: _share,
    );
  }

  void _share() {
    SharePaymentHelper.share(
      matchId: matchId,
      matchName: matchName,
      amount: amount,
    );
  }
}
