import 'package:dio/dio.dart';
import 'package:get/get.dart' as getx;
import 'package:padel_mobile/core/endpoitns.dart';
import 'package:padel_mobile/core/network/dio_client.dart';
import 'package:padel_mobile/handler/logger.dart';

class SharePaymentRepository {
  final DioClient _dioClient = getx.Get.find<DioClient>();

  /// GET /api/customer/court/openmatch/pay-share-payment/{matchId}/resolve
  Future<Map<String, dynamic>?> resolveSharePayment(String matchId) async {
    try {
      final response = await _dioClient.get(
        AppEndpoints.sharePaymentResolve(matchId),
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data is Map<String, dynamic>
            ? response.data
            : {'data': response.data};
      }
      return null;
    } on DioException catch (e) {
      // Return the error response body so the UI can show the correct message
      final data = e.response?.data;
      if (data is Map<String, dynamic>) return data;
      return null;
    } catch (e) {

      CustomLogger.logMessage(msg: '❌ resolveSharePayment: $e', level: LogLevel.error);
      return null;
    }
  }

  /// Generate shareable deep link for a match
  static String generateShareLink(String matchId) {
    return 'https://swootapp.com/sharePayment?matchId=$matchId';
  }

  /// POST to the wallet accept URL (full URL already resolved by controller)
  Future<void> acceptWalletPayment(String fullUrl) async {
    try {
      final response = await _dioClient.post(fullUrl);
      if (response.statusCode != 200) {
        throw Exception('Wallet payment failed: ${response.statusCode}');
      }
    } catch (e) {
      CustomLogger.logMessage(msg: '❌ acceptWalletPayment: $e', level: LogLevel.error);
      rethrow;
    }
  }
}
