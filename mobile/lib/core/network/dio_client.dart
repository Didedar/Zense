import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../errors/exceptions.dart';
import '../storage/secure_storage.dart';

class DioClient {
  late final Dio _dio;
  final SecureStorage _secureStorage;
  VoidCallback? onUnauthenticated;
  bool _isRefreshing = false;
  Future<bool>? _refreshTokenFuture;

  DioClient(this._secureStorage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        contentType: 'application/json',
        responseType: ResponseType.json,
      ),
    );

    _dio.interceptors.addAll([
      _authInterceptor(),
      if (kDebugMode) _loggingInterceptor(),
    ]);
  }

  Dio get dio => _dio;

  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _secureStorage.getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          if (_isRefreshing) {
            try {
              if (_refreshTokenFuture != null) {
                final success = await _refreshTokenFuture!;
                if (success) {
                  return _retryRequest(error.requestOptions, handler);
                }
              }
            } catch (_) {}
            return handler.next(error);
          }

          _isRefreshing = true;
          final completer = Completer<bool>();
          _refreshTokenFuture = completer.future;

          try {
            final refreshed = await _tryRefreshToken();
            if (!completer.isCompleted) completer.complete(refreshed);

            if (refreshed) {
              _isRefreshing = false;
              _refreshTokenFuture = null;
              return _retryRequest(error.requestOptions, handler);
            }
          } catch (e) {
            if (!completer.isCompleted) completer.complete(false);
          }

          _isRefreshing = false;
          _refreshTokenFuture = null;
          await _secureStorage.clearTokens();
          onUnauthenticated?.call();
        }
        handler.next(error);
      },
    );
  }

  Future<void> _retryRequest(
      RequestOptions requestOptions, ErrorInterceptorHandler handler) async {
    try {
      final token = await _secureStorage.getAccessToken();
      requestOptions.headers['Authorization'] = 'Bearer $token';
      final response = await _dio.fetch<dynamic>(requestOptions);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    } catch (e) {
      handler.next(DioException(requestOptions: requestOptions, error: e));
    }
  }

  Future<bool> _tryRefreshToken() async {
    final refreshToken = await _secureStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final freshDio = Dio(BaseOptions(
        baseUrl: AppConfig.baseUrl,
        contentType: 'application/json',
      ));
      final response = await freshDio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      if (response.statusCode == 200) {
        final data = response.data;
        await _secureStorage.saveTokens(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
        );
        return true;
      }
    } catch (_) {
      // Refresh failed
    }
    return false;
  }

  LogInterceptor _loggingInterceptor() {
    return LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (msg) => debugPrint('[API] $msg'),
    );
  }

  // Convenience methods
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get<T>(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.post<T>(path,
          data: data, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
  }) async {
    try {
      return await _dio.patch<T>(path, data: data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response<T>> delete<T>(String path) async {
    try {
      return await _dio.delete<T>(path);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException('Время ожидания истекло');
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.badResponse:
        return ApiException.fromResponse(
          e.response?.statusCode,
          e.response?.data,
        );
      default:
        return const NetworkException('Неизвестная ошибка сети');
    }
  }
}
