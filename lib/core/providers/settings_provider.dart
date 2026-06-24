import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/settings_repository.dart';

// ── State ─────────────────────────────────────────────────────────────────

class AppSettings {
  final bool isDarkMode;
  final Locale locale;

  const AppSettings({
    required this.isDarkMode,
    required this.locale,
  });

  AppSettings copyWith({bool? isDarkMode, Locale? locale}) => AppSettings(
        isDarkMode: isDarkMode ?? this.isDarkMode,
        locale: locale ?? this.locale,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  static const _supportedLocales = ['en', 'fr'];

  @override
  Future<AppSettings> build() async {
    final repo = SettingsRepository.instance;
    final darkRaw  = await repo.read(SettingsRepository.keyDarkMode);
    final localeRaw = await repo.read(SettingsRepository.keyLocale);

    final isDark = darkRaw == '1';
    final localeCode = (localeRaw != null && _supportedLocales.contains(localeRaw))
        ? localeRaw
        : 'en';

    return AppSettings(
      isDarkMode: isDark,
      locale: Locale(localeCode),
    );
  }

  Future<void> setDarkMode(bool value) async {
    await SettingsRepository.instance.write(
      SettingsRepository.keyDarkMode,
      value ? '1' : '0',
    );
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWith(isDarkMode: value));
    }
  }

  Future<void> setLocale(Locale locale) async {
    await SettingsRepository.instance.write(
      SettingsRepository.keyLocale,
      locale.languageCode,
    );
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWith(locale: locale));
    }
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
