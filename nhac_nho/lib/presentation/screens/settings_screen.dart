// Màn hình Cài đặt chọn Preset mẫu, giờ mặc định và kiểm tra quyền hệ thống.

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../application/providers.dart';
import '../../core/constants.dart';
import '../../core/time_utils.dart';
import '../../domain/entities/preset_profile.dart';
import '../../domain/entities/user_settings.dart';
import '../../domain/logic/sleep_planner.dart';
import '../../domain/logic/work_meal_guide.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  bool _notifGranted = false;
  bool _exactAlarmGranted = false;
  bool _batteryIgnored = false;
  bool _loadingPerms = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermissions();
    }
  }

  Future<void> _refreshPermissions() async {
    bool notif = false;
    bool exact = false;
    bool battery = false;
    try {
      notif = (await Permission.notification.status).isGranted;
    } catch (_) {}
    try {
      exact =
          await ref.read(notificationSchedulerProvider).canScheduleExactAlarms();
    } catch (_) {}
    try {
      battery = (await Permission.ignoreBatteryOptimizations.status).isGranted;
    } catch (_) {}

    if (mounted) {
      setState(() {
        _notifGranted = notif;
        _exactAlarmGranted = exact;
        _batteryIgnored = battery;
        _loadingPerms = false;
      });
    }
  }

  Future<void> _requestNotificationPerm() async {
    try {
      await ref.read(notificationSchedulerProvider).requestPermissions();
    } catch (_) {}
    await _refreshPermissions();
  }

  Future<void> _requestBatteryIgnore() async {
    try {
      await Permission.ignoreBatteryOptimizations.request();
    } catch (_) {}
    await _refreshPermissions();
  }

  Future<void> _openSystemSettings() async {
    try {
      await openAppSettings();
    } catch (_) {}
  }

  Future<void> _editMealTime(
    UserSettings settings,
    String title,
    String currentHhmm,
    UserSettings Function(String newHhmm) updater,
  ) async {
    final t = ClockTime.parse(currentHhmm);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: t.hour, minute: t.minute),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked == null) return;
    final formatted = TimeUtils.format24h(picked.hour, picked.minute);
    await ref.read(userSettingsProvider.notifier).save(updater(formatted));
  }

  Future<void> _applyPreset(PresetId id) async {
    await ref.read(reminderControllerProvider.notifier).applyPreset(id);
    await _refreshPermissions();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã áp dụng bộ lịch "${id.displayName}"')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(userSettingsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);
    final presets = WorkMealGuide.getAllPresets();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt & Quyền hệ thống'),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi cài đặt: $e')),
        data: (settings) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Text(
                'Bộ lịch mẫu (Presets)',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              const Text(
                'Chọn nhanh 1 trong 4 bộ lịch khoa học theo nhóm đối tượng (tự động cập nhật lịch mẫu và xin quyền thông báo nếu chưa cấp):',
              ),
              const SizedBox(height: 10),
              ...presets.map((preset) {
                final selected = settings.selectedPreset == preset.id.id;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                preset.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (selected)
                              Chip(
                                label: const Text('Đang dùng'),
                                backgroundColor:
                                    theme.colorScheme.primaryContainer,
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(preset.description),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 48,
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => _applyPreset(preset.id),
                            child: Text(
                              selected
                                  ? 'Áp dụng lại mẫu này'
                                  : 'Chọn mẫu ${preset.name}',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              Text(
                'Giờ ăn mặc định & Chu kỳ uống nước',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Bữa sáng'),
                      trailing: Text(
                        settings.breakfastTime,
                        style: theme.textTheme.titleMedium,
                      ),
                      onTap: () => _editMealTime(
                        settings,
                        'Bữa sáng',
                        settings.breakfastTime,
                        (v) => settings.copyWith(breakfastTime: v),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Bữa trưa'),
                      trailing: Text(
                        settings.lunchTime,
                        style: theme.textTheme.titleMedium,
                      ),
                      onTap: () => _editMealTime(
                        settings,
                        'Bữa trưa',
                        settings.lunchTime,
                        (v) => settings.copyWith(lunchTime: v),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Bữa phụ chiều'),
                      trailing: Text(
                        settings.afternoonSnackTime,
                        style: theme.textTheme.titleMedium,
                      ),
                      onTap: () => _editMealTime(
                        settings,
                        'Bữa phụ chiều',
                        settings.afternoonSnackTime,
                        (v) => settings.copyWith(afternoonSnackTime: v),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Bữa tối'),
                      trailing: Text(
                        settings.dinnerTime,
                        style: theme.textTheme.titleMedium,
                      ),
                      onTap: () => _editMealTime(
                        settings,
                        'Bữa tối',
                        settings.dinnerTime,
                        (v) => settings.copyWith(dinnerTime: v),
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chu kỳ nhắc uống nước: ${settings.waterIntervalMin} phút',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [60, 75, 90, 105, 120]
                                .map(
                                  (m) => ChoiceChip(
                                    label: Text('$m phút'),
                                    selected: settings.waterIntervalMin == m,
                                    onSelected: (_) async {
                                      await ref
                                          .read(userSettingsProvider.notifier)
                                          .save(
                                            settings.copyWith(
                                              waterIntervalMin: m,
                                            ),
                                          );
                                      await ref
                                          .read(reminderControllerProvider
                                              .notifier)
                                          .rescheduleAll();
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Giao diện',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Theo hệ thống'),
                    selected: themeMode == ThemeMode.system,
                    onSelected: (_) => ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(ThemeMode.system),
                  ),
                  ChoiceChip(
                    label: const Text('Chế độ sáng'),
                    selected: themeMode == ThemeMode.light,
                    onSelected: (_) => ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(ThemeMode.light),
                  ),
                  ChoiceChip(
                    label: const Text('Chế độ tối'),
                    selected: themeMode == ThemeMode.dark,
                    onSelected: (_) => ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(ThemeMode.dark),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Trạng thái Quyền & Tối ưu pin',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_loadingPerms)
                        const LinearProgressIndicator()
                      else ...[
                        _PermissionStatusRow(
                          title: 'Quyền thông báo',
                          granted: _notifGranted,
                          detail: _notifGranted
                              ? 'Đang bật — app có thể hiển thị nhắc nhở.'
                              : 'Chưa bật — bấm "Xin quyền" hoặc mở Cài đặt hệ thống.',
                          onAction: _requestNotificationPerm,
                          actionLabel: 'Xin quyền',
                        ),
                        const Divider(height: 20),
                        _PermissionStatusRow(
                          title: 'Báo thức chính xác (Exact Alarm)',
                          granted: _exactAlarmGranted,
                          detail: _exactAlarmGranted
                              ? 'Đã cấp — thông báo reo đúng từng phút.'
                              : 'Chưa cấp — app tự chuyển sang chế độ gần đúng (có thể lệch vài phút). '
                                  'Có thể bật trong Cài đặt → Ứng dụng → Truy cập đặc biệt → Báo thức và lời nhắc.',
                          onAction: _openSystemSettings,
                          actionLabel: 'Mở Cài đặt',
                        ),
                        const Divider(height: 20),
                        _PermissionStatusRow(
                          title: 'Tối ưu pin (Không hạn chế nền)',
                          granted: _batteryIgnored,
                          detail: _batteryIgnored
                              ? 'Đã tắt tối ưu pin — lịch chạy bền bỉ hơn khi tắt app.'
                              : 'Máy đang giới hạn pin nền — nên chọn "Không hạn chế" (Unrestricted).',
                          onAction: _requestBatteryIgnore,
                          actionLabel: 'Tắt giới hạn',
                        ),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _openSystemSettings,
                          icon: const Icon(Icons.settings_applications_outlined),
                          label: const Text('Mở Cài đặt ứng dụng hệ thống'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hướng dẫn giữ thông báo ổn định theo hãng máy',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '• Samsung: Cài đặt → Pin → Giới hạn sử dụng nền → Không đưa app vào Sleeping/Deep Sleeping.\n'
                        '• Xiaomi / HyperOS: Bật Tự khởi chạy (Autostart) và chọn Tiết kiệm pin = Không hạn chế.\n'
                        '• Oppo / Vivo: Cho phép chạy nền và khóa app trong trình đa nhiệm.',
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(
                              const ClipboardData(
                                text: 'https://dontkillmyapp.com',
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Đã sao chép liên kết https://dontkillmyapp.com',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.link),
                          label: const Text('Sao chép dontkillmyapp.com'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  HealthDisclaimer.text,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PermissionStatusRow extends StatelessWidget {
  const _PermissionStatusRow({
    required this.title,
    required this.granted,
    required this.detail,
    required this.onAction,
    required this.actionLabel,
  });

  final String title;
  final bool granted;
  final String detail;
  final VoidCallback onAction;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor =
        granted ? const Color(0xFF15803D) : const Color(0xFFB91C1C);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              granted ? Icons.check_circle : Icons.cancel,
              size: 18,
              color: statusColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium,
              ),
            ),
            Text(
              granted ? 'Đạt' : 'Cần bật',
              style: theme.textTheme.labelLarge?.copyWith(color: statusColor),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(detail, style: theme.textTheme.bodySmall),
        if (!granted) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: FilledButton.tonal(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ),
        ],
      ],
    );
  }
}
