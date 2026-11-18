// Màn hình thêm và chỉnh sửa nhắc nhở với đầy đủ 4 loại và 4 kiểu lặp.

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers.dart';
import '../../core/time_utils.dart';
import '../../domain/entities/reminder.dart';
import '../theme/category_style.dart';

class ReminderFormScreen extends ConsumerStatefulWidget {
  const ReminderFormScreen({super.key, this.initialReminder});

  final Reminder? initialReminder;

  @override
  ConsumerState<ReminderFormScreen> createState() => _ReminderFormScreenState();
}

class _ReminderFormScreenState extends ConsumerState<ReminderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  late final TextEditingController _intervalController;

  late ReminderCategory _category;
  late bool _isRoutine;
  late int _priority;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late RepeatType _repeat;
  late int _weekdaysMask;
  late DateTime _onceDate;
  late bool _enabled;
  String? _customError;

  static const _weekdayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  bool get _isEditing => widget.initialReminder != null;

  @override
  void initState() {
    super.initState();
    final r = widget.initialReminder;
    _titleController = TextEditingController(text: r?.title ?? '');
    _noteController = TextEditingController(text: r?.note ?? '');
    _intervalController = TextEditingController(
      text: (r?.intervalMinutes ?? 90).toString(),
    );
    _category = r?.category ?? ReminderCategory.task;
    _isRoutine = r?.isRoutine ?? false;
    _priority = r?.priority ?? 2;
    _startTime = TimeOfDay(hour: r?.hour ?? 8, minute: r?.minute ?? 0);
    _endTime = TimeOfDay(hour: r?.endHour ?? 20, minute: r?.endMinute ?? 0);
    _repeat = r?.repeat ?? RepeatType.daily;
    _weekdaysMask = r?.weekdaysMask ?? 0;
    _onceDate = _parseInitialDate(r?.date) ?? DateTime.now();
    _enabled = r?.enabled ?? true;
  }

  DateTime? _parseInitialDate(String? date) {
    if (date == null) return null;
    return DateTime.tryParse(date);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    final yyyy = d.year.toString().padLeft(4, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
      _customError = null;
    });
  }

  Future<void> _pickOnceDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _onceDate.isBefore(today) ? today : _onceDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365 * 2)),
    );
    if (picked == null) return;
    setState(() {
      _onceDate = picked;
      _customError = null;
    });
  }

  String? validateExtraRules() {
    if (_repeat == RepeatType.weekly && _weekdaysMask == 0) {
      return 'Vui lòng chọn ít nhất 1 ngày trong tuần.';
    }
    if (_repeat == RepeatType.once) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final selected = DateTime(_onceDate.year, _onceDate.month, _onceDate.day);
      if (selected.isBefore(today)) {
        return 'Ngày nhắc một lần không được nằm trong quá khứ.';
      }
    }
    if (_repeat == RepeatType.interval) {
      final interval = int.tryParse(_intervalController.text.trim());
      if (interval == null || interval < 30) {
        return 'Chu kỳ lặp phải từ 30 phút trở lên.';
      }
      final startTotal = _startTime.hour * 60 + _startTime.minute;
      final endTotal = _endTime.hour * 60 + _endTime.minute;
      if (endTotal <= startTotal) {
        return 'Giờ kết thúc phải sau giờ bắt đầu.';
      }
    }
    return null;
  }

  Future<void> _save() async {
    final formValid = _formKey.currentState?.validate() ?? false;
    final extraError = validateExtraRules();
    setState(() => _customError = extraError);
    if (!formValid || extraError != null) return;

    final intervalMin = _repeat == RepeatType.interval
        ? int.parse(_intervalController.text.trim())
        : null;

    final reminder = Reminder(
      id: widget.initialReminder?.id,
      title: _titleController.text.trim(),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      category: _category,
      isRoutine: _isRoutine,
      priority: _priority,
      hour: _startTime.hour,
      minute: _startTime.minute,
      repeat: _repeat,
      intervalMinutes: intervalMin,
      endHour: _repeat == RepeatType.interval ? _endTime.hour : null,
      endMinute: _repeat == RepeatType.interval ? _endTime.minute : null,
      weekdaysMask: _repeat == RepeatType.weekly ? _weekdaysMask : 0,
      date: _repeat == RepeatType.once ? _formatDate(_onceDate) : null,
      enabled: _enabled,
      createdAt:
          widget.initialReminder?.createdAt ?? DateTime.now().toIso8601String(),
    );

    final controller = ref.read(reminderControllerProvider.notifier);
    if (_isEditing) {
      await controller.updateReminder(reminder);
    } else {
      await controller.addReminder(reminder);
    }
    if (mounted) {
      final count = ref
              .read(reminderControllerProvider)
              .value
              ?.allReminders
              .where((r) => r.enabled)
              .length ??
          0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã lên lịch hẹn giờ cho $count lời nhắc nhở!'),
        ),
      );
      context.pop();
    }
  }

  Future<void> _delete() async {
    final id = widget.initialReminder?.id;
    if (id == null) return;
    await ref.read(reminderControllerProvider.notifier).deleteReminder(id);
    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highContrast =
        MediaQuery.highContrastOf(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa nhắc nhở' : 'Thêm nhắc nhở'),
        actions: [
          if (_isEditing)
            Semantics(
              label: 'Xóa nhắc nhở này',
              button: true,
              child: IconButton(
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Xóa',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tên nhắc nhở *',
                hintText: 'VD: Deep Work, Bữa sáng, Uống nước',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Tên nhắc không được để trống.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Loại hoạt động',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ReminderCategory.values.map((cat) {
                final visual = CategoryStyle.of(
                  cat,
                  theme.brightness,
                  highContrast: highContrast,
                );
                return ChoiceChip(
                  avatar: Icon(visual.icon, size: 18, color: visual.foregroundColor),
                  label: Text(visual.label),
                  selected: _category == cat,
                  onSelected: (_) {
                    setState(() {
                      _category = cat;
                      _isRoutine = cat != ReminderCategory.task;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Thói quen cố định mỗi ngày (Routine)'),
              subtitle: const Text(
                'Bật nếu là sinh hoạt lặp (Ăn, Uống nước, Ngủ); tắt nếu là việc cụ thể trong ngày.',
              ),
              value: _isRoutine,
              onChanged: (v) => setState(() => _isRoutine = v),
            ),
            const SizedBox(height: 12),
            Text(
              'Mức ưu tiên',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('1 · Quan trọng nhất (MIT)'),
                  selected: _priority == 1,
                  onSelected: (_) => setState(() => _priority = 1),
                ),
                ChoiceChip(
                  label: const Text('2 · Bình thường'),
                  selected: _priority == 2,
                  onSelected: (_) => setState(() => _priority = 2),
                ),
                ChoiceChip(
                  label: const Text('3 · Nhẹ nhàng'),
                  selected: _priority == 3,
                  onSelected: (_) => setState(() => _priority = 3),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Giờ bắt đầu (24h)'),
              trailing: FilledButton.tonal(
                onPressed: () => _pickTime(isStart: true),
                child: Text(
                  TimeUtils.format24h(_startTime.hour, _startTime.minute),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kiểu lặp',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Một lần'),
                  selected: _repeat == RepeatType.once,
                  onSelected: (_) => setState(() {
                    _repeat = RepeatType.once;
                    _customError = null;
                  }),
                ),
                ChoiceChip(
                  label: const Text('Hằng ngày'),
                  selected: _repeat == RepeatType.daily,
                  onSelected: (_) => setState(() {
                    _repeat = RepeatType.daily;
                    _customError = null;
                  }),
                ),
                ChoiceChip(
                  label: const Text('Theo thứ'),
                  selected: _repeat == RepeatType.weekly,
                  onSelected: (_) => setState(() {
                    _repeat = RepeatType.weekly;
                    _customError = null;
                  }),
                ),
                ChoiceChip(
                  label: const Text('Chu kỳ phút'),
                  selected: _repeat == RepeatType.interval,
                  onSelected: (_) => setState(() {
                    _repeat = RepeatType.interval;
                    _customError = null;
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_repeat == RepeatType.once)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ngày thực hiện'),
                trailing: FilledButton.tonal(
                  onPressed: _pickOnceDate,
                  child: Text(_formatDate(_onceDate)),
                ),
              ),
            if (_repeat == RepeatType.weekly)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(7, (bit) {
                  final selected = (_weekdaysMask & (1 << bit)) != 0;
                  return FilterChip(
                    label: Text(_weekdayLabels[bit]),
                    selected: selected,
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _weekdaysMask |= (1 << bit);
                        } else {
                          _weekdaysMask &= ~(1 << bit);
                        }
                        _customError = null;
                      });
                    },
                  );
                }),
              ),
            if (_repeat == RepeatType.interval) ...[
              TextFormField(
                controller: _intervalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Chu kỳ lặp (phút, tối thiểu 30)',
                  hintText: 'VD: 90 hoặc 120',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Giờ kết thúc trong ngày (24h)'),
                trailing: FilledButton.tonal(
                  onPressed: () => _pickTime(isStart: false),
                  child: Text(
                    TimeUtils.format24h(_endTime.hour, _endTime.minute),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Ghi chú / Gợi ý thực phẩm hoặc cách làm',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Bật thông báo nhắc này'),
              value: _enabled,
              onChanged: (v) => setState(() => _enabled = v),
            ),
            if (_customError != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _customError!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(_isEditing ? 'Lưu thay đổi' : 'Lưu nhắc nhở'),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
