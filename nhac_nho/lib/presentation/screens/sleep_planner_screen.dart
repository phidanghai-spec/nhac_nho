// Màn hình Thể trạng, Dinh dưỡng & Giấc ngủ.

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/constants.dart';
import '../../core/time_utils.dart';
import '../../domain/entities/body_profile.dart';
import '../../domain/entities/user_settings.dart';
import '../../domain/logic/body_nutrition_analyzer.dart';
import '../../domain/logic/sleep_planner.dart';

class SleepPlannerScreen extends ConsumerStatefulWidget {
  const SleepPlannerScreen({super.key});

  @override
  ConsumerState<SleepPlannerScreen> createState() => _SleepPlannerScreenState();
}

class _SleepPlannerScreenState extends ConsumerState<SleepPlannerScreen> {
  final _ageCtrl = TextEditingController(text: '25');
  final _heightCtrl = TextEditingController(text: '168');
  final _weightCtrl = TextEditingController(text: '62');

  bool _initializedFromRepo = false;
  UserSettings _settings = const UserSettings();
  BodyProfile _profile = const BodyProfile();
  bool _applying = false;

  @override
  void dispose() {
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  void _syncInitial(UserSettings settings, BodyProfile profile) {
    if (_initializedFromRepo) return;
    _initializedFromRepo = true;
    _settings = settings;
    _profile = profile;
    _ageCtrl.text = profile.age.toString();
    _heightCtrl.text = profile.heightCm.toStringAsFixed(0);
    _weightCtrl.text = profile.weightKg.toStringAsFixed(1);
  }

  BodyProfile get _currentProfile {
    final age = (int.tryParse(_ageCtrl.text.trim()) ?? _profile.age).clamp(10, 100);
    final height =
        (double.tryParse(_heightCtrl.text.trim()) ?? _profile.heightCm).clamp(100.0, 230.0);
    final weight =
        (double.tryParse(_weightCtrl.text.trim()) ?? _profile.weightKg).clamp(30.0, 200.0);
    return _profile.copyWith(age: age, heightCm: height, weightKg: weight);
  }

  Future<void> _pickWakeTime() async {
    final wake = ClockTime.parse(_settings.wakeTime);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: wake.hour, minute: wake.minute),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked == null) return;
    setState(() {
      _settings = _settings.copyWith(
        wakeTime: TimeUtils.format24h(picked.hour, picked.minute),
      );
    });
  }

  Future<void> _pickWorkoutTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _profile.workoutHour,
        minute: _profile.workoutMinute,
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked == null) return;
    setState(() {
      _profile = _profile.copyWith(
        workoutHour: picked.hour,
        workoutMinute: picked.minute,
      );
    });
  }

  Future<void> _applyPlan(
    double dinnerCutoffHours,
    double caffeineCutoffHours,
    int waterIntervalMin,
  ) async {
    setState(() => _applying = true);
    try {
      final updatedSettings = _settings.copyWith(
        dinnerCutoffHours: dinnerCutoffHours,
        caffeineCutoffHours: caffeineCutoffHours,
        waterIntervalMin: waterIntervalMin,
      );
      final updatedProfile = _currentProfile;
      await ref
          .read(reminderControllerProvider.notifier)
          .applyNutritionAndSleepPlan(
            settings: updatedSettings,
            profile: updatedProfile,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Đã cập nhật lịch ăn uống, uống nước và giấc ngủ vào danh sách nhắc!',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(userSettingsProvider);
    final profileAsync = ref.watch(bodyProfileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thể trạng, Dinh dưỡng & Giấc ngủ'),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi tải cài đặt: $e')),
        data: (repoSettings) {
          return profileAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Lỗi tải thể trạng: $e')),
            data: (repoProfile) {
              _syncInitial(repoSettings, repoProfile);

              final profile = _currentProfile;
              final wake = ClockTime.parse(_settings.wakeTime);
              final initialSleep = SleepPlanner.calculate(
                wakeTime: wake,
                sleepHours: _settings.sleepHours,
                fallAsleepBufferMin: _settings.fallAsleepBufferMin,
                dinnerCutoffHours: _settings.dinnerCutoffHours,
                caffeineCutoffHours: _settings.caffeineCutoffHours,
                windDownMin: _settings.windDownMin,
              );
              final plan = BodyNutritionAnalyzer.analyze(
                profile,
                wakeTime: wake,
                bedtime: initialSleep.bedtime,
              );
              final sleepPlan = SleepPlanner.calculate(
                wakeTime: wake,
                sleepHours: _settings.sleepHours,
                fallAsleepBufferMin: _settings.fallAsleepBufferMin,
                dinnerCutoffHours: plan.recommendedDinnerCutoffHours,
                caffeineCutoffHours: plan.recommendedCaffeineCutoffHours,
                windDownMin: _settings.windDownMin,
                dinnerTime: ClockTime.parse(_settings.dinnerTime),
              );

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  Text(
                    '1. Thông tin Thể trạng & Lịch sinh hoạt',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Giờ thức dậy (24h)'),
                            trailing: FilledButton.tonal(
                              onPressed: _pickWakeTime,
                              child: Text(_settings.wakeTime),
                            ),
                          ),
                          Text(
                            'Thời lượng ngủ: ${_settings.sleepHours.toStringAsFixed(1)} giờ',
                            style: theme.textTheme.titleMedium,
                          ),
                          Slider(
                            value: _settings.sleepHours,
                            min: 5.0,
                            max: 10.0,
                            divisions: 10,
                            label: '${_settings.sleepHours.toStringAsFixed(1)}h',
                            onChanged: (v) => setState(
                              () => _settings = _settings.copyWith(sleepHours: v),
                            ),
                          ),
                          if (sleepPlan.sleepDurationWarning != null)
                            _WarningBanner(message: sleepPlan.sleepDurationWarning!),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _ageCtrl,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setState(() {}),
                                  decoration: const InputDecoration(
                                    labelText: 'Tuổi',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _heightCtrl,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setState(() {}),
                                  decoration: const InputDecoration(
                                    labelText: 'Cao (cm)',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _weightCtrl,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setState(() {}),
                                  decoration: const InputDecoration(
                                    labelText: 'Nặng (kg)',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _EnumChips<Gender>(
                            title: 'Giới tính',
                            values: Gender.values,
                            selected: _profile.gender,
                            labelBuilder: (g) =>
                                g == Gender.male ? 'Nam' : 'Nữ',
                            onSelected: (g) => setState(
                              () => _profile = _profile.copyWith(gender: g),
                            ),
                          ),
                          _EnumChips<ActivityLevel>(
                            title: 'Mức độ vận động',
                            values: ActivityLevel.values,
                            selected: _profile.activityLevel,
                            labelBuilder: (a) => switch (a) {
                              ActivityLevel.sedentary => 'Ít vận động',
                              ActivityLevel.light => 'Nhẹ',
                              ActivityLevel.moderate => 'Vừa',
                              ActivityLevel.active => 'Năng động',
                            },
                            onSelected: (a) => setState(
                              () => _profile = _profile.copyWith(activityLevel: a),
                            ),
                          ),
                          _EnumChips<FitnessGoal>(
                            title: 'Mục tiêu',
                            values: FitnessGoal.values,
                            selected: _profile.goal,
                            labelBuilder: (g) => switch (g) {
                              FitnessGoal.loseWeight => 'Giảm cân',
                              FitnessGoal.maintain => 'Giữ cân',
                              FitnessGoal.gainWeight => 'Tăng cân',
                            },
                            onSelected: (g) => setState(
                              () => _profile = _profile.copyWith(goal: g),
                            ),
                          ),
                          _EnumChips<DietType>(
                            title: 'Chế độ ăn',
                            values: DietType.values,
                            selected: _profile.dietType,
                            labelBuilder: (d) => switch (d) {
                              DietType.omnivore => 'Ăn đa dạng',
                              DietType.vegetarian => 'Chay trứng sữa',
                              DietType.vegan => 'Thuần chay',
                            },
                            onSelected: (d) => setState(
                              () => _profile = _profile.copyWith(dietType: d),
                            ),
                          ),
                          _EnumChips<WorkShift>(
                            title: 'Ca làm việc',
                            values: WorkShift.values,
                            selected: _profile.workShift,
                            labelBuilder: (w) => switch (w) {
                              WorkShift.dayShift => 'Ban ngày',
                              WorkShift.nightShift => 'Ca đêm',
                              WorkShift.rotatingShift => 'Xoay ca',
                            },
                            onSelected: (w) => setState(
                              () => _profile = _profile.copyWith(workShift: w),
                            ),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Tập Gym / Thể hình'),
                            subtitle: const Text(
                              'Tự động tăng đạm, thêm 600ml nước và bữa Trước/Sau tập',
                            ),
                            value: _profile.isGymGoer,
                            onChanged: (v) => setState(
                              () => _profile = _profile.copyWith(isGymGoer: v),
                            ),
                          ),
                          if (_profile.isGymGoer)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Giờ tập Gym (24h)'),
                              trailing: FilledButton.tonal(
                                onPressed: _pickWorkoutTime,
                                child: Text(
                                  TimeUtils.format24h(
                                    _profile.workoutHour,
                                    _profile.workoutMinute,
                                  ),
                                ),
                              ),
                            ),
                          _EnumChips<HealthCondition>(
                            title: 'Lưu ý sức khỏe',
                            values: HealthCondition.values,
                            selected: _profile.condition,
                            labelBuilder: (c) => switch (c) {
                              HealthCondition.none => 'Bình thường',
                              HealthCondition.stomachReflux =>
                                'Đau dạ dày / Trào ngược',
                              HealthCondition.bloodSugar => 'Đường huyết',
                              HealthCondition.seniorCardio =>
                                'Lớn tuổi / Tim mạch',
                            },
                            onSelected: (c) => setState(
                              () => _profile = _profile.copyWith(condition: c),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '2. Kết quả Phân tích Thể trạng',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Card(
                    color: theme.colorScheme.secondaryContainer
                        .withValues(alpha: 0.45),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _MetricRow(
                            label: 'Chỉ số BMI (Chuẩn Châu Á)',
                            value: '${plan.bmi} · ${plan.bmiCategory}',
                          ),
                          _MetricRow(
                            label: 'BMR / TDEE',
                            value: '${plan.bmr} / ${plan.tdee} kcal',
                          ),
                          _MetricRow(
                            label: 'Calo mục tiêu mỗi ngày',
                            value: '${plan.targetCalories} kcal/ngày',
                          ),
                          _MetricRow(
                            label: 'Đạm khuyến nghị',
                            value:
                                '${plan.dailyProteinGramsMin}–${plan.dailyProteinGramsMax} g/ngày',
                          ),
                          _MetricRow(
                            label: 'Nước cần uống & chu kỳ',
                            value:
                                '${plan.dailyWaterMl} ml/ngày (mỗi ${plan.waterIntervalMin}p, '
                                '${TimeUtils.format24h(plan.waterStartHour, plan.waterStartMinute)}–'
                                '${TimeUtils.format24h(plan.waterEndHour, plan.waterEndMinute)})',
                          ),
                          const Divider(height: 20),
                          Text(
                            'Tỷ lệ đĩa ăn: ${plan.plateRatioText}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '3. Lịch Giấc ngủ & Khung giờ ăn cá nhân hóa',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _MetricRow(
                            label: 'Đi ngủ',
                            value: sleepPlan.bedtime.format24h(),
                          ),
                          _MetricRow(
                            label: 'Chuẩn bị ngủ',
                            value: sleepPlan.windDown.format24h(),
                          ),
                          _MetricRow(
                            label: 'Ngừng ăn tối',
                            value: sleepPlan.dinnerStop.format24h(),
                          ),
                          _MetricRow(
                            label: 'Ngừng Caffeine',
                            value: sleepPlan.caffeineCutoff.format24h(),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            plan.sleepAdviceNote,
                            style: theme.textTheme.bodySmall,
                          ),
                          if (sleepPlan.dinnerTooLateWarning != null) ...[
                            const SizedBox(height: 8),
                            _WarningBanner(
                              message: sleepPlan.dinnerTooLateWarning!,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...plan.mealScheduleRecommendations.map(
                    (meal) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          child: Text(
                            TimeUtils.format24h(meal.hour, meal.minute),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(
                          meal.title,
                          style: theme.textTheme.titleMedium,
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(meal.foodAdvice),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: _applying
                          ? null
                          : () => _applyPlan(
                                plan.recommendedDinnerCutoffHours,
                                plan.recommendedCaffeineCutoffHours,
                                plan.waterIntervalMin,
                              ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(
                        _applying
                            ? 'Đang áp dụng...'
                            : 'Áp dụng Lịch Dinh dưỡng & Giấc ngủ',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _DisclaimerCard(),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _EnumChips<T> extends StatelessWidget {
  const _EnumChips({
    required this.title,
    required this.values,
    required this.selected,
    required this.labelBuilder,
    required this.onSelected,
  });

  final String title;
  final List<T> values;
  final T selected;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values
                .map(
                  (v) => ChoiceChip(
                    label: Text(labelBuilder(v)),
                    selected: v == selected,
                    onSelected: (_) => onSelected(v),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 2,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onTertiaryContainer,
        ),
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        HealthDisclaimer.text,
        style: theme.textTheme.bodySmall,
      ),
    );
  }
}
