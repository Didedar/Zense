import 'dart:io';

class AppConfig {
  static const String appName = 'Zense';
  static const String appVersion = '1.0.0';
  static const String defaultCurrency = 'KZT';

  static String get baseUrl {
    const env = String.fromEnvironment('API_BASE_URL');
    if (env.isNotEmpty) return env;

    // Авто-определение для эмуляторов
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api/v1'; // Android Emulator
    }
    // Если запускаете на реальном iPhone, нужен IP мака в локальной сети
    if (Platform.isIOS) {
      return 'http://192.168.0.106:8000/api/v1'; // IP вашего Mac
    }
    return 'http://127.0.0.1:8000/api/v1'; // Остальные (Web / Десктоп)
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
