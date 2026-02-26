import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const _onboardingCompletedKey = 'onboarding_completed';
  static const _firstLaunchKey = 'first_launch';

  final SharedPreferences _prefs;

  LocalStorage(this._prefs);

  bool get isOnboardingCompleted =>
      _prefs.getBool(_onboardingCompletedKey) ?? false;
  Future<void> setOnboardingCompleted(bool value) =>
      _prefs.setBool(_onboardingCompletedKey, value);

  bool get isFirstLaunch => _prefs.getBool(_firstLaunchKey) ?? true;
  Future<void> setFirstLaunch(bool value) =>
      _prefs.setBool(_firstLaunchKey, value);
}
