import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'services.dart';

class ApiBaseHelper {
  static final Dio _dio = Dio();

  static final PrettyDioLogger _prettyDioLogger = PrettyDioLogger(
    requestHeader: true,
    requestBody: true,
    responseBody: true,
    responseHeader: true,
    error: true,
    compact: true,
    maxWidth: 90,
  );

  static void setupDio() async {
    _dio.interceptors.add(_prettyDioLogger);
  }

  static final String baseUrl = "https://huggingface.co/";

  // get token from preferences

  static Future<Map<String, dynamic>> getHeaders() async {
    Map<String, dynamic> headers = {
      "Content-Type": "application/json",
    };

    return headers;
  }

  static Future<void> download(
    String endpoint,
    String savePath, {
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      await _dio.download(
        "$baseUrl$endpoint",
        savePath,
        onReceiveProgress: onReceiveProgress,
        options: Options(headers: await getHeaders()),
      );
    } on DioException catch (error) {
      // dio error (api reach the server but not performed successfully

      switch (error.type) {
        case DioExceptionType.connectionError:
          throw DioException(
            type: DioExceptionType.connectionError,
            requestOptions: RequestOptions(path: endpoint),
            error: error.toString(),
          );

        case DioExceptionType.badResponse:
          throw DioException(
            type: DioExceptionType.badResponse,
            requestOptions: RequestOptions(path: endpoint),
            error: error.toString(),
          );

        case DioExceptionType.connectionTimeout:
          throw DioException(
            type: DioExceptionType.connectionTimeout,
            requestOptions: RequestOptions(path: endpoint),
            error: error.toString(),
          );

        case DioExceptionType.receiveTimeout:
          throw DioException(
            type: DioExceptionType.receiveTimeout,
            requestOptions: RequestOptions(path: endpoint),
            error: error.toString(),
          );

        default:
          throw DioException(
            requestOptions: RequestOptions(path: endpoint),
            error: error.toString(),
          );
      }
    }
  }

  // You can also add additional methods or configurations as needed.
}
