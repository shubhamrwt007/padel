import '../../core/endpoitns.dart';
import '../../core/network/dio_client.dart';
import '../../data/response_models/app_version_model.dart';
import '../../handler/logger.dart';
import 'package:dio/dio.dart';

class AppVersionRepository {
  final DioClient dioClient = DioClient();
  // Future<AppVersionModel> checkAppVersion({required Map<String, dynamic> body}) async {
  //   try {
  //     CustomLogger.logMessage(msg: "APP VERSION BODY:-> $body", level: LogLevel.info);
  //     final response = await dioClient.post(
  //       AppEndpoints.appVersions,
  //       data: body,
  //       options: Options(headers: {'Authorization': ''}),
  //     );
  //
  //     if (response.statusCode == 200) {
  //       CustomLogger.logMessage(
  //         msg: "App version check successful: ${response.data}",
  //         level: LogLevel.info,
  //       );
  //       return AppVersionModel.fromJson(response.data);
  //     } else {
  //       throw Exception("App version check failed with status code: ${response.statusCode}");
  //     }
  //   } catch (e, st) {
  //     CustomLogger.logMessage(
  //       msg: "App version check failed with error: ${e.toString()}",
  //       level: LogLevel.error,
  //       st: st,
  //     );
  //     rethrow;
  //   }
  // }
}
