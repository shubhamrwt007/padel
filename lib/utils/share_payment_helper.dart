import 'package:padel_mobile/repositories/share_payment_repository.dart';
import 'package:share_plus/share_plus.dart';

class SharePaymentHelper {
  /// Generates: https://swootapp.com/sharePayment?matchId=XXX
  static String generateLink(String matchId) {
    return SharePaymentRepository.generateShareLink(matchId);
  }

  /// Opens system share sheet with the payment link
  static Future<void> share({
    required String matchId,
    String? matchName,
    String? amount,
  }) async {
    final link = generateLink(matchId);
    final buffer = StringBuffer();
    buffer.writeln('🎾 Swoot - Payment Request');
    if (matchName != null && matchName.isNotEmpty) {
      buffer.writeln('Match: $matchName');
    }
    if (amount != null && amount.isNotEmpty) {
      buffer.writeln('Amount: $amount');
    }
    buffer.writeln('');
    buffer.writeln('Tap to pay your share:');
    buffer.write(link);

    await Share.share(buffer.toString(), subject: 'Swoot Payment Request');
  }
}
