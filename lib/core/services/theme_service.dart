import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tema modunu temsil eden enum
enum AppThemeMode {
  light, // Açık tema
  dark, // Koyu tema
  system // Sistem teması
}

/// Tema servisinin state'i
class ThemeState {
  final AppThemeMode themeMode;
  
  ThemeState({required this.themeMode});
  
  /// Geçerli tema modu ayarlanır
  ThemeState copyWith({AppThemeMode? themeMode}) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

/// Tema değişimini yöneten servis sınıfı
class ThemeService extends StateNotifier<ThemeState> {
  static const String _themeKey = 'theme_mode';
  final SharedPreferences _prefs;
  
  ThemeService(this._prefs) 
      : super(ThemeState(
          themeMode: _getThemeModeFromString(
            _prefs.getString(_themeKey) ?? 'system',
          ),
        ));
  
  /// String'den ThemeMode döndürür
  static AppThemeMode _getThemeModeFromString(String themeModeString) {
    switch (themeModeString) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      case 'system':
      default:
        return AppThemeMode.system;
    }
  }
  
  /// ThemeMode'u String'e dönüştürür
  String _themeToString(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'light';
      case AppThemeMode.dark:
        return 'dark';
      case AppThemeMode.system:
        return 'system';
    }
  }
  
  /// Tema modunu değiştirir
  Future<void> setThemeMode(AppThemeMode mode) async {
    // SharedPreferences'e kaydet
    await _prefs.setString(_themeKey, _themeToString(mode));
    
    // State'i güncelle
    state = state.copyWith(themeMode: mode);
  }
  
  /// Geçerli tema modu
  AppThemeMode get themeMode => state.themeMode;
  
  /// Sistemin ayarlarına göre geçerli temanın karanlık mı yoksa aydınlık mı olduğunu belirler
  bool isDarkMode(BuildContext context) {
    if (state.themeMode == AppThemeMode.light) {
      return false;
    } else if (state.themeMode == AppThemeMode.dark) {
      return true;
    } else {
      // Sistem ayarlarına bak
      final brightness = MediaQuery.of(context).platformBrightness;
      return brightness == Brightness.dark;
    }
  }
  
  /// Tema modunu döngüsel olarak değiştirir
  Future<void> toggleTheme() async {
    AppThemeMode nextMode;
    
    switch (state.themeMode) {
      case AppThemeMode.light:
        nextMode = AppThemeMode.dark;
        break;
      case AppThemeMode.dark:
        nextMode = AppThemeMode.system;
        break;
      case AppThemeMode.system:
        nextMode = AppThemeMode.light;
        break;
    }
    
    await setThemeMode(nextMode);
  }
}

/// SharedPreferences provider'ı
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Should be overridden in ProviderScope.overrides');
});

/// Tema servis provider'ı
final themeServiceProvider = StateNotifierProvider<ThemeService, ThemeState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeService(prefs);
});

/// Tema modu provider'ı
final themeModeProvider = Provider<AppThemeMode>((ref) {
  return ref.watch(themeServiceProvider).themeMode;
});

/// Flutter ThemeMode dönüştürücü
final flutterThemeModeProvider = Provider<ThemeMode>((ref) {
  final appThemeMode = ref.watch(themeModeProvider);
  switch (appThemeMode) {
    case AppThemeMode.light:
      return ThemeMode.light;
    case AppThemeMode.dark:
      return ThemeMode.dark;
    case AppThemeMode.system:
      return ThemeMode.system;
  }
});

/// İfade edici tema modu string provider'ı
final themeModeStringProvider = Provider<String>((ref) {
  final themeMode = ref.watch(themeModeProvider);
  switch (themeMode) {
    case AppThemeMode.light:
      return 'Açık Tema';
    case AppThemeMode.dark:
      return 'Koyu Tema';
    case AppThemeMode.system:
      return 'Sistem Teması';
  }
}); 