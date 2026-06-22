import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/offline/queue/checkin_queue.dart';
import 'features/offline/sync/sync_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/network/dio_client.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await CheckinQueue.init();
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
    // Register session-expired callback so Dio interceptor can
    // trigger logout + redirect when token refresh fails.
    DioClient.onSessionExpired = () {
      ref.read(authProvider.notifier).logout();
    };

    final router = createRouter(ref);

    return MaterialApp.router(
      title: 'WorkTrackr',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}