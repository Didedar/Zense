import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../storage/secure_storage.dart';
import '../storage/local_storage.dart';
import '../network/dio_client.dart';

// Secure Storage
final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});

// Shared Preferences (initialized in main.dart)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main.dart');
});

// Local Storage
final localStorageProvider = Provider<LocalStorage>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalStorage(prefs);
});

final dioClientProvider = Provider<DioClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return DioClient(secureStorage);
});
