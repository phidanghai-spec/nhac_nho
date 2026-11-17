// Điểm khởi chạy ứng dụng Nhắc Nhở.

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'application/providers.dart';
import 'data/notification_scheduler_impl.dart';
import 'presentation/router.dart';
import 'presentation/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi');

  final prefs = await SharedPreferences.getInstance();
  final scheduler = NotificationSchedulerImpl();
  await scheduler.init();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        notificationSchedulerProvider.overrideWithValue(scheduler),
      ],
      child: const NhacNhoApp(),
    ),
  );
}

class NhacNhoApp extends ConsumerStatefulWidget {
  const NhacNhoApp({super.key});

  @override
  ConsumerState<NhacNhoApp> createState() => _NhacNhoAppState();
}

class _NhacNhoAppState extends ConsumerState<NhacNhoApp>
    with WidgetsBindingObserver {
  late final _router = createAppRouter();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() async {
      await ref.read(reminderControllerProvider.future);
      await ref.read(reminderControllerProvider.notifier).rescheduleAll();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(reminderControllerProvider.notifier).rescheduleAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final highContrast = MediaQuery.highContrastOf(context);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp.router(
          title: 'Nhắc Nhở',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: AppTheme.light(
            dynamicScheme: lightDynamic,
            highContrast: highContrast,
          ),
          darkTheme: AppTheme.dark(
            dynamicScheme: darkDynamic,
            highContrast: highContrast,
          ),
          routerConfig: _router,
        );
      },
    );
  }
}
