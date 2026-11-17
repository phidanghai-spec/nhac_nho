// Màn hình Hôm nay: thanh tiến độ ngày, khu vực Công việc và Thói quen sinh hoạt.

import 'package:material_ui/material_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../application/providers.dart';
import '../../application/reminder_controller.dart';
import '../../domain/entities/completion_log.dart';
import '../../domain/entities/preset_profile.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/logic/work_meal_guide.dart';
import '../widgets/reminder_card.dart';

enum _HomeFilter { all, tasks, routines }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  _HomeFilter _filter = _HomeFilter.all;

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(reminderControllerProvider);
    final theme = Theme.of(context);
    final todayFormatted = DateFormat('EEEE, dd/MM/yyyy', 'vi').format(
      DateTime.now(),
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hôm nay'),
            Text(
              todayFormatted,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/reminder/new'),
        icon: const Icon(Icons.add),
        label: const Text('Thêm nhắc'),
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
              onCreateManual: () => context.push('/reminder/new'),
            );
          }

          final showTasks =
              _filter == _HomeFilter.all || _filter == _HomeFilter.tasks;
          final showRoutines =
              _filter == _HomeFilter.all || _filter == _HomeFilter.routines;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(reminderControllerProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              children: [
                _DailyProgressBanner(state: state),
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
                if (showTasks) ...[
                  _SectionHeader(
                    icon: Icons.work_outline,
                    title: 'Công việc trong ngày',
                    count: state.todayTasks.length,
                  ),
                  const SizedBox(height: 8),
                  if (state.todayTasks.isEmpty)
                    const _SectionEmptyHint(
                      message:
                          'Chưa có công việc nào hôm nay. Bấm "Thêm nhắc" để thêm việc quan trọng.',
                    )
                  else
                    ..._buildAnimatedCards(state.todayTasks, state),
                  const SizedBox(height: 16),
                ],
                if (showRoutines) ...[
                  _SectionHeader(
                    icon: Icons.restaurant_outlined,
                    title: 'Thói quen sinh hoạt (Ăn, Uống nước, Ngủ)',
                    count: state.todayRoutines.length,
                  ),
                  const SizedBox(height: 8),
                  if (state.todayRoutines.isEmpty)
                    const _SectionEmptyHint(
                      message:
                          'Chưa có thói quen sinh hoạt. Vào "Ngủ & Ăn" hoặc "Cài đặt" để áp dụng lịch mẫu.',
                    )
                  else
                    ..._buildAnimatedCards(state.todayRoutines, state),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildAnimatedCards(
    List<Reminder> items,
    ReminderState state,
  ) {
    final controller = ref.read(reminderControllerProvider.notifier);
    return items.asMap().entries.map((entry) {
      final index = entry.key;
      final reminder = entry.value;
      final id = reminder.id;
      final card = ReminderCard(
        reminder: reminder,
        status: id == null ? null : state.todayLogs[id],
        onMarkDone: () {
          if (id != null) {
            controller.markStatus(id, CompletionStatus.done);
          }
        },
        onMarkSkipped: () {
          if (id != null) {
            controller.markStatus(id, CompletionStatus.skipped);
          }
        },
        onToggleEnabled: () => controller.toggleEnabled(reminder),
        onEdit: () => context.push('/reminder/edit', extra: reminder),
      );
      return card
          .animate(delay: Duration(milliseconds: (index * 30).clamp(0, 180)))
          .fadeIn(duration: 200.ms)
          .slideY(begin: 0.04, end: 0, duration: 200.ms);
    }).toList();
  }
}

class _DailyProgressBanner extends StatelessWidget {
  const _DailyProgressBanner({required this.state});

  final ReminderState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (state.todayProgress * 100).round();

    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Tiến độ hôm nay: ${state.todayDoneCount}/${state.todayTotalEnabled} ($percent%)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Chip(
                  avatar: const Icon(Icons.local_fire_department, size: 18),
                  label: Text('Chuỗi ${state.currentStreak} ngày'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: state.todayProgress,
                minHeight: 10,
              ),
            ),
          ],
        ),
      ),
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
        Icon(icon, size: 22, color: theme.colorScheme.primary),
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
    required this.onCreateManual,
  });

  final Future<void> Function(PresetId presetId) onSelectPreset;
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
          'Chọn nhanh một Bộ lịch mẫu phù hợp để khởi tạo ngay lịch làm việc, ăn uống, uống nước và giấc ngủ chuẩn khoa học:',
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
                    child: FilledButton(
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
            icon: const Icon(Icons.add),
            label: const Text('Tự tạo nhắc nhở đầu tiên'),
          ),
        ),
      ],
    );
  }
}
