// Màn hình Hôm nay: Chọn 7 ngày, Bento Tiến độ + Nước, Dòng thời gian 4 buổi & Trợ lý Lập lịch.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../application/providers.dart';
import '../../application/reminder_controller.dart';
import '../../domain/entities/body_profile.dart';
import '../../domain/entities/completion_log.dart';
import '../../domain/entities/preset_profile.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/user_settings.dart';
import '../../domain/logic/body_nutrition_analyzer.dart';
import '../../domain/logic/habit_stats_calculator.dart';
import '../../domain/logic/sleep_planner.dart';
import '../../domain/logic/work_meal_guide.dart';
import '../theme/category_style.dart';
import '../widgets/reminder_card.dart';
import 'smart_planner_sheet.dart';

enum _HomeFilter { all, tasks, routines }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  _HomeFilter _filter = _HomeFilter.all;
  final Map<int, int> _mealVariantCounters = {};

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(reminderControllerProvider);
    final selectedDate = ref.watch(selectedHomeDateProvider);
    final selectedDateKey = HabitStatsCalculator.formatDateKey(selectedDate);
    final logsForSelectedAsync =
        ref.watch(dateCompletionLogsProvider(selectedDateKey));
    final bodyProfile = ref.watch(bodyProfileProvider).value ?? const BodyProfile();
    final userSettings = ref.watch(userSettingsProvider).value ?? const UserSettings();
    final waterMl = ref.watch(waterIntakeMlProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hôm nay'),
        actions: [
          Semantics(
            label: 'Thêm nhắc nhở thủ công',
            button: true,
            child: IconButton(
              onPressed: () => context.push('/reminder/new'),
              icon: const Icon(LucideIcons.plus),
              tooltip: 'Thêm nhắc nhở',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
          ),
          Semantics(
            label: 'Thống kê nhanh',
            button: true,
            child: IconButton(
              onPressed: () => context.go('/stats'),
              icon: const Icon(LucideIcons.barChart3),
              tooltip: 'Thống kê thói quen',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => SmartPlannerSheet.show(context),
        icon: const Icon(LucideIcons.sparkles),
        label: const Text('Lập lịch thông minh'),
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Không tải được lịch nhắc: $err'),
          ),
        ),
        data: (state) {
          if (state.allReminders.isEmpty) {
            return _EmptyOnboardingView(
              onSelectPreset: (presetId) async {
                await ref
                    .read(reminderControllerProvider.notifier)
                    .applyPreset(presetId);
              },
              onOpenSmartPlanner: () => SmartPlannerSheet.show(context),
              onCreateManual: () => context.push('/reminder/new'),
            );
          }

          final now = DateTime.now();
          final todayOnly = DateTime(now.year, now.month, now.day);
          final isToday = selectedDate == todayOnly;

          final dayReminders = state.allReminders
              .where((r) => r.isScheduledForDate(selectedDate))
              .where((r) {
                if (_filter == _HomeFilter.tasks) return !r.isRoutine;
                if (_filter == _HomeFilter.routines) return r.isRoutine;
                return true;
              })
              .toList()
            ..sort((a, b) {
              final h = a.hour.compareTo(b.hour);
              if (h != 0) return h;
              final m = a.minute.compareTo(b.minute);
              if (m != 0) return m;
              return a.priority.compareTo(b.priority);
            });

          final logsMap = isToday
              ? state.todayLogs
              : (logsForSelectedAsync.value ?? const <int, CompletionStatus>{});

          final sleepPlan = SleepPlanner.calculate(
            wakeTime: ClockTime.parse(userSettings.wakeTime),
            sleepHours: userSettings.sleepHours,
            fallAsleepBufferMin: userSettings.fallAsleepBufferMin,
            windDownMin: userSettings.windDownMin,
            dinnerCutoffHours: userSettings.dinnerCutoffHours,
            caffeineCutoffHours: userSettings.caffeineCutoffHours,
          );
          final nutritionReport = BodyNutritionAnalyzer.analyze(
            bodyProfile,
            wakeTime: sleepPlan.wakeTime,
            bedtime: sleepPlan.bedtime,
          );

          final morning = <Reminder>[];
          final noon = <Reminder>[];
          final afternoon = <Reminder>[];
          final evening = <Reminder>[];

          for (final r in dayReminders) {
            final mins = r.hour * 60 + r.minute;
            if (mins >= 5 * 60 && mins < 11 * 60 + 30) {
              morning.add(r);
            } else if (mins >= 11 * 60 + 30 && mins < 14 * 60) {
              noon.add(r);
            } else if (mins >= 14 * 60 && mins < 18 * 60) {
              afternoon.add(r);
            } else {
              evening.add(r);
            }
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(reminderControllerProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 104),
              children: [
                _SevenDayBar(
                  today: todayOnly,
                  selectedDate: selectedDate,
                  onSelect: (d) =>
                      ref.read(selectedHomeDateProvider.notifier).selectDate(d),
                ),
                const SizedBox(height: 14),
                _BentoSummaryCard(
                  state: state,
                  waterMl: waterMl,
                  waterTargetMl: nutritionReport.dailyWaterMl,
                  onAddWater: () =>
                      ref.read(waterIntakeMlProvider.notifier).addWater(200),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Tất cả'),
                      selected: _filter == _HomeFilter.all,
                      onSelected: (_) =>
                          setState(() => _filter = _HomeFilter.all),
                    ),
                    ChoiceChip(
                      label: const Text('Công việc'),
                      selected: _filter == _HomeFilter.tasks,
                      onSelected: (_) =>
                          setState(() => _filter = _HomeFilter.tasks),
                    ),
                    ChoiceChip(
                      label: const Text('Thói quen'),
                      selected: _filter == _HomeFilter.routines,
                      onSelected: (_) =>
                          setState(() => _filter = _HomeFilter.routines),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (dayReminders.isEmpty)
                  const _SectionEmptyHint(
                    message:
                        'Không có mốc nhắc nào trong ngày này theo bộ lọc hiện tại.',
                  )
                else ...[
                  if (morning.isNotEmpty)
                    ..._buildPeriodTimeline(
                      context: context,
                      icon: LucideIcons.sunrise,
                      title: 'Buổi sáng (05:00 – 11:30)',
                      items: morning,
                      logsMap: logsMap,
                      selectedDate: selectedDate,
                      profile: bodyProfile,
                    ),
                  if (noon.isNotEmpty)
                    ..._buildPeriodTimeline(
                      context: context,
                      icon: LucideIcons.sun,
                      title: 'Buổi trưa (11:30 – 14:00)',
                      items: noon,
                      logsMap: logsMap,
                      selectedDate: selectedDate,
                      profile: bodyProfile,
                    ),
                  if (afternoon.isNotEmpty)
                    ..._buildPeriodTimeline(
                      context: context,
                      icon: LucideIcons.sunset,
                      title: 'Buổi chiều (14:00 – 18:00)',
                      items: afternoon,
                      logsMap: logsMap,
                      selectedDate: selectedDate,
                      profile: bodyProfile,
                    ),
                  if (evening.isNotEmpty)
                    ..._buildPeriodTimeline(
                      context: context,
                      icon: LucideIcons.moon,
                      title: 'Buổi tối (18:00 – 05:00)',
                      items: evening,
                      logsMap: logsMap,
                      selectedDate: selectedDate,
                      profile: bodyProfile,
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildPeriodTimeline({
    required BuildContext context,
    required IconData icon,
    required String title,
    required List<Reminder> items,
    required Map<int, CompletionStatus> logsMap,
    required DateTime selectedDate,
    required BodyProfile profile,
  }) {
    final controller = ref.read(reminderControllerProvider.notifier);
    final theme = Theme.of(context);
    final highContrast = MediaQuery.highContrastOf(context);

    return [
      _SectionHeader(
        icon: icon,
        title: title,
        count: items.length,
      ),
      const SizedBox(height: 10),
      ...items.asMap().entries.map((entry) {
        final index = entry.key;
        final reminder = entry.value;
        final id = reminder.id;
        final visual = CategoryStyle.of(
          reminder.category,
          theme.brightness,
          highContrast: highContrast,
        );
        final isLast = index == items.length - 1;

        final card = ReminderCard(
          reminder: reminder,
          status: id == null ? null : logsMap[id],
          onMarkDone: () {
            if (id != null) {
              controller.markStatusForDate(
                id,
                CompletionStatus.done,
                selectedDate,
              );
            }
          },
          onMarkSkipped: () {
            if (id != null) {
              controller.markStatusForDate(
                id,
                CompletionStatus.skipped,
                selectedDate,
              );
            }
          },
          onToggleEnabled: () => controller.toggleEnabled(reminder),
          onEdit: () => context.push('/reminder/edit', extra: reminder),
          onSwapMeal: reminder.category == ReminderCategory.meal
              ? () {
                  final key = id ?? reminder.hashCode;
                  final nextIdx = (_mealVariantCounters[key] ?? 0) + 1;
                  _mealVariantCounters[key] = nextIdx;
                  controller.swapMealReminderVariant(
                    reminder: reminder,
                    profile: profile,
                    nextVariantIndex: nextIdx,
                  );
                }
              : null,
        );

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 22,
                child: Column(
                  children: [
                    const SizedBox(height: 18),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: visual.foregroundColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: visual.containerColor,
                          width: 2.5,
                        ),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Expanded(child: card),
            ],
          ),
        )
            .animate(delay: Duration(milliseconds: (index * 25).clamp(0, 150)))
            .fadeIn(duration: 180.ms)
            .slideY(begin: 0.03, end: 0, duration: 180.ms);
      }),
      const SizedBox(height: 8),
    ];
  }
}

class _SevenDayBar extends StatelessWidget {
  const _SevenDayBar({
    required this.today,
    required this.selectedDate,
    required this.onSelect,
  });

  final DateTime today;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelect;

  static String _weekdayShort(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'T2';
      case DateTime.tuesday:
        return 'T3';
      case DateTime.wednesday:
        return 'T4';
      case DateTime.thursday:
        return 'T5';
      case DateTime.friday:
        return 'T6';
      case DateTime.saturday:
        return 'T7';
      case DateTime.sunday:
        return 'CN';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = List.generate(
      7,
      (i) => today.subtract(const Duration(days: 1)).add(Duration(days: i)),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: days.map((d) {
          final isSelected = d.year == selectedDate.year &&
              d.month == selectedDate.month &&
              d.day == selectedDate.day;
          final isToday =
              d.year == today.year && d.month == today.month && d.day == today.day;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onSelect(d),
              child: Container(
                constraints: const BoxConstraints(minWidth: 52, minHeight: 56),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isToday && !isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _weekdayShort(d.weekday),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${d.day}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BentoSummaryCard extends StatelessWidget {
  const _BentoSummaryCard({
    required this.state,
    required this.waterMl,
    required this.waterTargetMl,
    required this.onAddWater,
  });

  final ReminderState state;
  final int waterMl;
  final int waterTargetMl;
  final VoidCallback onAddWater;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (state.todayProgress * 100).round();
    final waterProgress =
        waterTargetMl > 0 ? (waterMl / waterTargetMl).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        Card(
          elevation: 0,
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 68,
                  height: 68,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          startDegreeOffset: -90,
                          sectionsSpace: 0,
                          centerSpaceRadius: 24,
                          sections: [
                            PieChartSectionData(
                              value: state.todayProgress > 0
                                  ? state.todayProgress * 100
                                  : 0.01,
                              color: theme.colorScheme.primary,
                              radius: 8,
                              showTitle: false,
                            ),
                            PieChartSectionData(
                              value: ((1 - state.todayProgress) * 100)
                                  .clamp(0.01, 100),
                              color: theme.colorScheme.surfaceContainerHighest,
                              radius: 8,
                              showTitle: false,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '$percent%',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tiến độ hôm nay: ${state.todayDoneCount}/${state.todayTotalEnabled} ($percent%)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Chip(
                        avatar: const Icon(LucideIcons.flame, size: 16),
                        label: Text('Chuỗi ${state.currentStreak} ngày'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.droplets,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nước hôm nay: $waterMl / $waterTargetMl ml',
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 160,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: waterProgress,
                              minHeight: 7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                FilledButton.tonalIcon(
                  onPressed: onAddWater,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('+200ml'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
  });

  final IconData icon;
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$title ($count)',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionEmptyHint extends StatelessWidget {
  const _SectionEmptyHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(message),
      ),
    );
  }
}

class _EmptyOnboardingView extends StatelessWidget {
  const _EmptyOnboardingView({
    required this.onSelectPreset,
    required this.onOpenSmartPlanner,
    required this.onCreateManual,
  });

  final Future<void> Function(PresetId presetId) onSelectPreset;
  final VoidCallback onOpenSmartPlanner;
  final VoidCallback onCreateManual;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final presets = WorkMealGuide.getAllPresets();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Text(
          'Chào mừng bạn đến với Nhắc Nhở',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Bạn có thể nhờ Trợ lý Lập lịch tự xếp việc theo giờ thức thực tế, hoặc chọn nhanh 1 Bộ lịch mẫu bên dưới:',
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 50,
          child: FilledButton.icon(
            onPressed: onOpenSmartPlanner,
            icon: const Icon(LucideIcons.sparkles),
            label: const Text('Mở Trợ lý Lập lịch thông minh'),
          ),
        ),
        const SizedBox(height: 16),
        ...presets.map(
          (preset) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preset.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(preset.description),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.tonal(
                      onPressed: () => onSelectPreset(preset.id),
                      child: Text('Áp dụng mẫu ${preset.name}'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: onCreateManual,
            icon: const Icon(LucideIcons.plus),
            label: const Text('Tự tạo nhắc nhở đầu tiên'),
          ),
        ),
      ],
    );
  }
}
