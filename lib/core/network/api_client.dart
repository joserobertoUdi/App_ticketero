import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

class ApiClient {
  late final Dio _dio;
  String? _authToken;
  String? _refreshToken;
  Future<void> Function()? _onRefreshFailed;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.requestTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 && _refreshToken != null) {
          try {
            final refreshResponse = await Dio(BaseOptions(
              baseUrl: ApiConstants.baseUrl,
              connectTimeout: ApiConstants.connectTimeout,
              receiveTimeout: ApiConstants.requestTimeout,
            )).post(
              ApiConstants.refreshEndpoint,
              data: {
                'refreshToken': _refreshToken,
              },
              options: Options(headers: {
                'Content-Type': 'application/json',
              }),
            );

            if (refreshResponse.statusCode == 200) {
              final data = refreshResponse.data as Map<String, dynamic>;
              _authToken = data['token'] as String?;
              _refreshToken = data['refreshToken'] as String?;

              error.requestOptions.headers['Authorization'] = 'Bearer $_authToken';
              final retryResponse = await _dio.fetch(error.requestOptions);
              return handler.resolve(retryResponse);
            }
          } catch (_) {}
          _onRefreshFailed?.call();
        }
        handler.next(error);
      },
    ));
  }

  void setToken(String? token, {String? refreshToken, Future<void> Function()? onRefreshFailed}) {
    _authToken = token;
    if (refreshToken != null) _refreshToken = refreshToken;
    if (onRefreshFailed != null) _onRefreshFailed = onRefreshFailed;
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParams, ResponseType? responseType}) async {
    return _dio.get(path, queryParameters: queryParams, options: responseType != null ? Options(responseType: responseType) : null);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return _dio.put(path, data: data);
  }

  Future<Response> delete(String path) async {
    return _dio.delete(path);
  }

  Future<Response> uploadFile(
      String path, String filePath, String fieldName) async {
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(filePath),
    });
    return _dio.post(path, data: formData);
  }
}
