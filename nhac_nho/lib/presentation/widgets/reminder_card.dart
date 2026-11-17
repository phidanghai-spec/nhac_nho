// Widget thẻ nhắc nhở tối giản, vùng chạm >= 48dp, tách rõ Xong / Bỏ qua cho mọi lứa tuổi.

import 'package:material_ui/material_ui.dart';

import '../../core/time_utils.dart';
import '../../domain/entities/completion_log.dart';
import '../../domain/entities/reminder.dart';
import '../theme/category_style.dart';

class ReminderCard extends StatelessWidget {
  const ReminderCard({
    super.key,
    required this.reminder,
    required this.status,
    required this.onMarkDone,
    required this.onMarkSkipped,
    required this.onToggleEnabled,
    required this.onEdit,
  });

  final Reminder reminder;
  final CompletionStatus? status;
  final VoidCallback onMarkDone;
  final VoidCallback onMarkSkipped;
  final VoidCallback onToggleEnabled;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highContrast = MediaQuery.highContrastOf(context);
    final visual = CategoryStyle.of(
      reminder.category,
      theme.brightness,
      highContrast: highContrast,
    );
    final isDone = status == CompletionStatus.done;
    final isSkipped = status == CompletionStatus.skipped;

    final timeLabel = reminder.repeat == RepeatType.interval &&
            reminder.endHour != null &&
            reminder.endMinute != null
        ? '${TimeUtils.format24h(reminder.hour, reminder.minute)}–'
            '${TimeUtils.format24h(reminder.endHour!, reminder.endMinute!)} '
            '(mỗi ${reminder.intervalMinutes ?? 90}p)'
        : TimeUtils.format24h(reminder.hour, reminder.minute);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDone
              ? visual.foregroundColor.withValues(alpha: 0.7)
              : theme.colorScheme.outlineVariant,
          width: isDone ? 1.5 : 1.0,
        ),
      ),
      child: Opacity(
        opacity: reminder.enabled ? 1.0 : 0.6,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: visual.containerColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                visual.icon,
                                size: 18,
                                color: visual.foregroundColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                visual.label,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: visual.foregroundColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          timeLabel,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (reminder.priority == 1)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Quan trọng (MIT)',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Semantics(
                    label: 'Chỉnh sửa nhắc ${reminder.title}',
                    button: true,
                    child: IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Chỉnh sửa',
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                    ),
                  ),
                  Semantics(
                    label: reminder.enabled
                        ? 'Tắt nhắc ${reminder.title}'
                        : 'Bật nhắc ${reminder.title}',
                    toggled: reminder.enabled,
                    child: Switch(
                      value: reminder.enabled,
                      onChanged: (_) => onToggleEnabled(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                reminder.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  decoration: isDone ? TextDecoration.lineThrough : null,
                ),
              ),
              if (reminder.note != null && reminder.note!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    reminder.note!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: onMarkSkipped,
                        icon: Icon(
                          isSkipped
                              ? Icons.skip_next
                              : Icons.skip_next_outlined,
                        ),
                        label: Text(isSkipped ? 'Đã bỏ qua' : 'Bỏ qua'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isSkipped
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: onMarkDone,
                        icon: Icon(
                          isDone
                              ? Icons.check_circle
                              : Icons.check_circle_outline,
                        ),
                        label: Text(isDone ? 'Đã xong' : 'Xong'),
                        style: FilledButton.styleFrom(
                          backgroundColor: isDone
                              ? visual.foregroundColor
                              : theme.colorScheme.primary,
                          foregroundColor: isDone
                              ? (theme.brightness == Brightness.dark
                                  ? Colors.black
                                  : Colors.white)
                              : theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
