import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/network/dio_client.dart';
import 'core/providers/settings_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_provider.dart';
import 'features/offline/sync/sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SyncService.instance.start();
  runApp(
    const ProviderScope(
      child: WorkTrackrApp(),
    ),
  );
}

class WorkTrackrApp extends ConsumerWidget {
  const WorkTrackrApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    DioClient.onSessionExpired = () {
      ref.read(authProvider.notifier).logout();
    };

    final router = createRouter(ref);

    // Use when() with skipLoadingOnReload so a settings toggle never
    // causes a full loading state — it just keeps the previous value.
    final settings = ref.watch(settingsProvider).whenData((s) => s).valueOrNull;

    return MaterialApp.router(
      title: 'WorkTrackr',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: (settings?.isDarkMode ?? false)
          ? ThemeMode.dark
          : ThemeMode.light,
      locale: settings?.locale,
      supportedLocales: const [Locale('en'), Locale('fr')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
