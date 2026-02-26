class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  const ApiException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  factory ApiException.fromResponse(int? statusCode, dynamic data) {
    String message = 'Произошла ошибка';
    Map<String, dynamic>? errors;

    if (data is Map<String, dynamic>) {
      message =
          data['detail']?.toString() ?? data['message']?.toString() ?? message;
      if (data['detail'] is List) {
        final details = data['detail'] as List;
        message = details
            .map((e) => (e is Map ? e['msg'] : null) ?? e.toString())
            .join(', ');
        errors = {'validation': details};
      }
    } else if (data is String) {
      message = data;
    }

    return ApiException(
        message: message, statusCode: statusCode, errors: errors);
  }

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
  bool get isValidationError => statusCode == 422;
  bool get isServerError => statusCode != null && statusCode! >= 500;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'Нет подключения к интернету']);

  @override
  String toString() => 'NetworkException: $message';
}

class AuthException implements Exception {
  final String message;
  const AuthException([this.message = 'Ошибка авторизации']);

  @override
  String toString() => 'AuthException: $message';
}
