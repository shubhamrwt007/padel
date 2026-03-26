import '../../core/endpoitns.dart';
import '../../core/network/dio_client.dart';

class SupportRepository {
  final DioClient dioClient = DioClient();

  Future<Map<String, dynamic>> sendSupportRequest(Map<String, dynamic> body) async {
    final response = await dioClient.post(AppEndpoints.support, data: body);
    return response.data;
  }
}
