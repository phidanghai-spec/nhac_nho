// Widget thẻ nhắc nhở hiện đại (bo góc 20dp, Food Chips, Đổi món, Slidable + nút chạm >= 48dp).

import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/time_utils.dart';
import '../../domain/entities/completion_log.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/logic/adaptive_food_catalog.dart';
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
    this.onSwapMeal,
  });

  final Reminder reminder;
  final CompletionStatus? status;
  final VoidCallback onMarkDone;
  final VoidCallback onMarkSkipped;
  final VoidCallback onToggleEnabled;
  final VoidCallback onEdit;
  final VoidCallback? onSwapMeal;

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

    final foodItems = AdaptiveFoodCatalog.parseFoodItemsFromNote(reminder.note);
    final advice = AdaptiveFoodCatalog.extractAdviceFromNote(reminder.note);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        key: ValueKey(
          'slidable_${reminder.id ?? reminder.title}_${reminder.hour}_${reminder.minute}',
        ),
        startActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.28,
          children: [
            SlidableAction(
              onPressed: (_) => onMarkDone(),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              icon: LucideIcons.check,
              label: 'Xong',
              borderRadius: BorderRadius.circular(20),
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.28,
          children: [
            SlidableAction(
              onPressed: (_) => onMarkSkipped(),
              backgroundColor: theme.colorScheme.errorContainer,
              foregroundColor: theme.colorScheme.onErrorContainer,
              icon: LucideIcons.skipForward,
              label: 'Bỏ qua',
              borderRadius: BorderRadius.circular(20),
            ),
          ],
        ),
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDone
                  ? visual.foregroundColor.withValues(alpha: 0.75)
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
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    visual.icon,
                                    size: 16,
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
                                  borderRadius: BorderRadius.circular(8),
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
                          icon: const Icon(LucideIcons.pencil, size: 20),
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          reminder.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            decoration: isDone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      if (reminder.category == ReminderCategory.meal &&
                          onSwapMeal != null)
                        TextButton.icon(
                          onPressed: onSwapMeal,
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
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
                                color: theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                item,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  if (advice.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        advice,
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
                                  ? LucideIcons.skipForward
                                  : LucideIcons.fastForward,
                              size: 18,
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: onMarkDone,
                            icon: Icon(
                              isDone
                                  ? LucideIcons.circleCheck
                                  : LucideIcons.check,
                              size: 18,
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
        ),
      ),
    );
  }
}
