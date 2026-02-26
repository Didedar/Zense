import '../../../../core/network/dio_client.dart';
import '../models/profile_models.dart';

class ProfileApiService {
  final DioClient _client;
  ProfileApiService(this._client);

  Future<ProfileRead> getProfile() async {
    final response = await _client.get('/profile');
    return ProfileRead.fromJson(response.data);
  }

  Future<ProfileRead> updateProfile(Map<String, dynamic> data) async {
    final response = await _client.patch('/profile', data: data);
    return ProfileRead.fromJson(response.data);
  }
}
