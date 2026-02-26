import '../../../../core/network/dio_client.dart';
import '../models/auth_models.dart';

class AuthApiService {
  final DioClient _client;
  AuthApiService(this._client);

  Future<TokenPair> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final response = await _client.post('/auth/register', data: {
      'email': email,
      'password': password,
      'display_name': displayName,
    });
    return TokenPair.fromJson(response.data);
  }

  Future<TokenPair> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return TokenPair.fromJson(response.data);
  }

  Future<UserRead> getMe() async {
    final response = await _client.get('/auth/me');
    return UserRead.fromJson(response.data);
  }
}
