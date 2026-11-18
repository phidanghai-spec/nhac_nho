// Bảng trợ lý 3 bước: Chọn nhu cầu -> Nhập việc cần làm -> Xem trước dòng thời gian & Đổi món.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../application/providers.dart';
import '../../core/time_utils.dart';
import '../../domain/entities/body_profile.dart';
import '../../domain/entities/preset_profile.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/user_settings.dart';
import '../../domain/entities/user_task_input.dart';
import '../../domain/logic/adaptive_food_catalog.dart';
import '../../domain/logic/universal_day_scheduler.dart';
import '../../domain/logic/work_meal_guide.dart';
import '../theme/category_style.dart';

class SmartPlannerSheet extends ConsumerStatefulWidget {
  const SmartPlannerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const SmartPlannerSheet(),
    );
  }

  @override
  ConsumerState<SmartPlannerSheet> createState() => _SmartPlannerSheetState();
}

class _SmartPlannerSheetState extends ConsumerState<SmartPlannerSheet> {
  int _step = 0;
  late DailyFocusMode _focusMode;
  PresetId? _selectedQuickPreset;
  final List<UserTaskInput> _tasks = [];
  final Map<MealSlot, int> _mealVariants = {};
  bool _replaceExistingTasks = false;
  bool _saving = false;

  final _titleController = TextEditingController();
  int _draftMinutes = 60;
  TaskEnergyDemand _draftDemand = TaskEnergyDemand.highFocus;
  bool _isFixedTime = false;
  TimeOfDay _fixedTime = const TimeOfDay(hour: 9, minute: 0);

  static const _smartChips = <({String label, int mins, TaskEnergyDemand demand})>[
    (label: 'Tập trung xử lý việc chính', mins: 90, demand: TaskEnergyDemand.highFocus),
    (label: 'Học bài / Ôn thi', mins: 60, demand: TaskEnergyDemand.highFocus),
    (label: 'Họp nhóm / Trao đổi', mins: 45, demand: TaskEnergyDemand.mediumTask),
    (label: 'Đi chợ & Nấu ăn', mins: 45, demand: TaskEnergyDemand.lightChore),
    (label: 'Tập thể dục / Đi bộ', mins: 45, demand: TaskEnergyDemand.physicalOrEvent),
    (label: 'Uống thuốc / Kiểm tra sức khỏe', mins: 15, demand: TaskEnergyDemand.lightChore),
  ];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(bodyProfileProvider).value ?? const BodyProfile();
    _focusMode = profile.dailyFocusMode;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _addDraftTask({
    String? overrideTitle,
    int? overrideMins,
    TaskEnergyDemand? overrideDemand,
  }) {
    final title = (overrideTitle ?? _titleController.text).trim();
    if (title.isEmpty) return;
    setState(() {
      _tasks.add(
        UserTaskInput(
          id: 't_${DateTime.now().microsecondsSinceEpoch}_${_tasks.length}',
          title: title,
          estimatedMinutes: overrideMins ?? _draftMinutes,
          energyDemand: overrideDemand ?? _draftDemand,
          fixedHour: overrideTitle == null && _isFixedTime ? _fixedTime.hour : null,
          fixedMinute: overrideTitle == null && _isFixedTime ? _fixedTime.minute : null,
        ),
      );
      if (overrideTitle == null) {
        _titleController.clear();
        _isFixedTime = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(userSettingsProvider).value ?? const UserSettings();
    final baseProfile = ref.watch(bodyProfileProvider).value ?? const BodyProfile();
    final activeProfile = baseProfile.copyWith(dailyFocusMode: _focusMode);
    final effectiveSettings = _selectedQuickPreset != null
        ? WorkMealGuide.getPreset(_selectedQuickPreset!).defaultSettings.copyWith(
              wakeTime: settings.wakeTime,
              sleepHours: settings.sleepHours,
            )
        : settings;

    final plan = UniversalDayScheduler.schedule(
      tasks: _tasks,
      profile: activeProfile,
      settings: effectiveSettings,
      mealVariantIndices: _mealVariants,
    );

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.55,
        maxChildSize: 0.96,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.sparkles,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Lập lịch & Thực đơn thông minh',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _StepIndicator(
                      currentStep: _step,
                      onSelectStep: (idx) => setState(() => _step = idx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    if (_step == 0) _buildStep1(context),
                    if (_step == 1) _buildStep2(context),
                    if (_step == 2) _buildStep3(context, plan, activeProfile),
                  ],
                ),
              ),
              const Divider(height: 1),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Row(
                    children: [
                      if (_step > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () => setState(() => _step -= 1),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 50),
                            ),
                            child: const Text('Quay lại'),
                          ),
                        ),
                      if (_step > 0) const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: _saving
                              ? null
                              : () async {
                                  if (_step < 2) {
                                    setState(() => _step += 1);
                                    return;
                                  }
                                  await _applyPlan(
                                    plan: plan,
                                    settings: effectiveSettings,
                                    profile: activeProfile,
                                  );
                                },
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 50),
                          ),
                          icon: Icon(
                            _step < 2 ? LucideIcons.arrowRight : LucideIcons.check,
                          ),
                          label: Text(
                            _step < 2
                                ? 'Tiếp tục'
                                : (_saving ? 'Đang áp dụng...' : 'Áp dụng lịch trình'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStep1(BuildContext context) {
    final modes = <(DailyFocusMode, String, String, IconData)>[
      (
        DailyFocusMode.brainFocus,
        'Tỉnh táo trí não',
        'Ít đường, giàu Omega-3 & Choline, chống buồn ngủ sau ăn.',
        LucideIcons.brain,
      ),
      (
        DailyFocusMode.staminaPhysical,
        'Bền sức / Vận động',
        'Tăng tinh bột phức, đạm phục hồi cơ và bù điện giải.',
        LucideIcons.dumbbell,
      ),
      (
        DailyFocusMode.leanAntiBloat,
        'Nhẹ bụng / Giữ dáng',
        'Ít muối chống tích nước, giàu xơ & đạm nạc trước lên hình.',
        LucideIcons.sparkles,
      ),
      (
        DailyFocusMode.digestiveComfort,
        'Êm bụng / Dễ tiêu',
        'Món ấm, mềm, ít dầu mỡ và ít gia vị chua cay.',
        LucideIcons.heartPulse,
      ),
      (
        DailyFocusMode.quickBudget,
        'Nhanh gọn / Tiết kiệm',
        'Món quen thuộc, dễ mua hoặc nấu trong 10–15 phút.',
        LucideIcons.clock,
      ),
    ];

    final presets = WorkMealGuide.getAllPresets();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '1. Hôm nay bạn ưu tiên trạng thái nào?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'Thực đơn và nhịp nghỉ sẽ tự động thích ứng theo lựa chọn này.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        for (final (mode, title, subtitle, icon) in modes) ...[
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            color: _focusMode == mode
                ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.45)
                : null,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => setState(() => _focusMode = mode),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(icon, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Icon(
                      _focusMode == mode
                          ? LucideIcons.circleCheck
                          : LucideIcons.circle,
                      color: _focusMode == mode
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        Text(
          'Gợi ý khởi tạo nhanh (tuỳ chọn)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presets.map((p) {
            final selected = _selectedQuickPreset == p.id;
            return ChoiceChip(
              label: Text(p.name),
              selected: selected,
              onSelected: (on) {
                setState(() {
                  _selectedQuickPreset = on ? p.id : null;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStep2(BuildContext context) {
    final rolloverTasks =
        ref.watch(yesterdayIncompleteTasksProvider).value ?? const <Reminder>[];
    final addedTitles = _tasks.map((t) => t.title.toLowerCase()).toSet();
    final pendingRollover = rolloverTasks
        .where((r) => !addedTitles.contains(r.title.toLowerCase()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pendingRollover.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .tertiaryContainer
                  .withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.rotateCw,
                      size: 18,
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Việc chưa xong hôm qua (${pendingRollover.length})',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Chạm 1 lần để dời sang lịch thông minh hôm nay:',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: pendingRollover.map((r) {
                    return ActionChip(
                      avatar: const Icon(LucideIcons.plus, size: 16),
                      label: Text(r.title),
                      onPressed: () => _addDraftTask(
                        overrideTitle: r.title,
                        overrideMins: 60,
                        overrideDemand: r.priority == 1
                            ? TaskEnergyDemand.highFocus
                            : TaskEnergyDemand.mediumTask,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
        Text(
          '2. Ghi các việc cần làm trong ngày',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'App tự xếp giờ tối ưu theo nhịp sinh học và tự dịch bữa ăn nếu trùng lịch cố định.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _smartChips.map((chip) {
            return ActionChip(
              avatar: const Icon(LucideIcons.plus, size: 16),
              label: Text('${chip.label} (${chip.mins}p)'),
              onPressed: () => _addDraftTask(
                overrideTitle: chip.label,
                overrideMins: chip.mins,
                overrideDemand: chip.demand,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Tên công việc tự do',
                    hintText: 'Ví dụ: Hoàn thiện báo cáo, Đón con, Chụp lookbook...',
                  ),
                ),
                const SizedBox(height: 12),
                Text('Thời lượng dự kiến', style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [30, 45, 60, 90, 120].map((m) {
                    return ChoiceChip(
                      label: Text('${m}p'),
                      selected: _draftMinutes == m,
                      onSelected: (_) => setState(() => _draftMinutes = m),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Text('Mức tiêu hao năng lượng', style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    (TaskEnergyDemand.highFocus, 'Tập trung cao'),
                    (TaskEnergyDemand.mediumTask, 'Việc vừa'),
                    (TaskEnergyDemand.lightChore, 'Việc nhẹ'),
                    (TaskEnergyDemand.physicalOrEvent, 'Vận động / Ra ngoài'),
                  ].map((item) {
                    return ChoiceChip(
                      label: Text(item.$2),
                      selected: _draftDemand == item.$1,
                      onSelected: (_) => setState(() => _draftDemand = item.$1),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Giờ cố định (không tự dời)'),
                  subtitle: Text(
                    _isFixedTime
                        ? 'Cố định lúc ${_fixedTime.hour.toString().padLeft(2, '0')}:${_fixedTime.minute.toString().padLeft(2, '0')}'
                        : 'Để App tự xếp giờ tối ưu',
                  ),
                  value: _isFixedTime,
                  onChanged: (v) async {
                    if (v) {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _fixedTime,
                      );
                      if (picked != null && mounted) {
                        setState(() {
                          _isFixedTime = true;
                          _fixedTime = picked;
                        });
                      }
                    } else {
                      setState(() => _isFixedTime = false);
                    }
                  },
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: () => _addDraftTask(),
                    icon: const Icon(LucideIcons.plus),
                    label: const Text('Thêm vào danh sách hôm nay'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (_tasks.isNotEmpty) ...[
          Text(
            'Đã thêm (${_tasks.length} việc)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < _tasks.length; i++)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(_tasks[i].title),
                subtitle: Text(
                  '${_tasks[i].estimatedMinutes} phút • '
                  '${_tasks[i].isFixed ? "Cố định ${_tasks[i].fixedHour!.toString().padLeft(2, '0')}:${_tasks[i].fixedMinute!.toString().padLeft(2, '0')}" : "Tự động xếp giờ"}',
                ),
                trailing: IconButton(
                  tooltip: 'Xoá công việc',
                  icon: const Icon(LucideIcons.trash2),
                  onPressed: () => setState(() => _tasks.removeAt(i)),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildStep3(
    BuildContext context,
    ScheduledDayPlan plan,
    BodyProfile profile,
  ) {
    final brightness = Theme.of(context).brightness;
    final highContrast = MediaQuery.highContrastOf(context);
    final items = plan.reminders;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '3. Xem trước lịch trình & Thực đơn',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Gợi ý ăn uống dựa trên mục tiêu và chế độ của bạn. Bấm "Đổi món" nếu muốn thay thực đơn khác.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Thay thế các công việc cũ chưa xong'),
          subtitle: const Text('Tắt nếu bạn chỉ muốn thêm việc mới vào lịch hiện tại.'),
          value: _replaceExistingTasks,
          onChanged: (v) => setState(() => _replaceExistingTasks = v),
        ),
        const SizedBox(height: 8),
        for (final r in items) ...[
          _PreviewTimelineCard(
            reminder: r,
            visual: CategoryStyle.of(r.category, brightness, highContrast: highContrast),
            onSwapMeal: r.category == ReminderCategory.meal
                ? () {
                    final slot = AdaptiveFoodCatalog.inferSlotFromTitle(r.title);
                    setState(() {
                      _mealVariants[slot] = (_mealVariants[slot] ?? 0) + 1;
                    });
                  }
                : null,
          ),
        ],
      ],
    );
  }

  Future<void> _applyPlan({
    required ScheduledDayPlan plan,
    required UserSettings settings,
    required BodyProfile profile,
  }) async {
    setState(() => _saving = true);
    try {
      await ref.read(reminderControllerProvider.notifier).applyUniversalDayPlan(
            plan: plan,
            settings: settings,
            profile: profile,
            replaceExistingTasks: _replaceExistingTasks,
          );
      if (mounted) {
        Navigator.of(context).pop();
        final totalEnabled = ref
                .read(reminderControllerProvider)
                .value
                ?.allReminders
                .where((r) => r.enabled)
                .length ??
            plan.reminders.length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã lên lịch hẹn giờ cho $totalEnabled lời nhắc nhở!',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.currentStep,
    required this.onSelectStep,
  });

  final int currentStep;
  final ValueChanged<int> onSelectStep;

  @override
  Widget build(BuildContext context) {
    const labels = ['1. Nhu cầu', '2. Việc cần làm', '3. Xem trước'];
    return Row(
      children: List.generate(labels.length, (i) {
        final active = i == currentStep;
        final done = i < currentStep;
        final scheme = Theme.of(context).colorScheme;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < labels.length - 1 ? 8 : 0),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onSelectStep(i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                decoration: BoxDecoration(
                  color: active
                      ? scheme.primaryContainer
                      : (done
                          ? scheme.secondaryContainer.withValues(alpha: 0.6)
                          : scheme.surfaceContainerHighest),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: active ? scheme.onPrimaryContainer : scheme.onSurface,
                      ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _PreviewTimelineCard extends StatelessWidget {
  const _PreviewTimelineCard({
    required this.reminder,
    required this.visual,
    this.onSwapMeal,
  });

  final Reminder reminder;
  final CategoryVisual visual;
  final VoidCallback? onSwapMeal;

  @override
  Widget build(BuildContext context) {
    final foodItems = AdaptiveFoodCatalog.parseFoodItemsFromNote(reminder.note);
    final advice = AdaptiveFoodCatalog.extractAdviceFromNote(reminder.note);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: visual.containerColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(visual.icon, size: 15, color: visual.foregroundColor),
                      const SizedBox(width: 6),
                      Text(
                        TimeUtils.format24h(reminder.hour, reminder.minute),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: visual.foregroundColor,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    reminder.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (onSwapMeal != null)
                  TextButton.icon(
                    onPressed: onSwapMeal,
                    icon: const Icon(LucideIcons.refreshCw, size: 16),
                    label: const Text('Đổi món'),
                  ),
              ],
            ),
            if (foodItems.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: foodItems
                    .map(
                      (item) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          item,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            if (advice.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(advice, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
