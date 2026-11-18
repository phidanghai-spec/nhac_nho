// Bottom Sheet hiển thị Danh sách Nguyên liệu Đi chợ trích xuất từ các bữa ăn trong ngày.

import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/entities/reminder.dart';
import '../../domain/logic/shopping_list_extractor.dart';

class ShoppingListSheet extends StatefulWidget {
  const ShoppingListSheet({super.key, required this.reminders});

  final List<Reminder> reminders;

  static Future<void> show(BuildContext context, List<Reminder> reminders) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ShoppingListSheet(reminders: reminders),
    );
  }

  @override
  State<ShoppingListSheet> createState() => _ShoppingListSheetState();
}

class _ShoppingListSheetState extends State<ShoppingListSheet> {
  final Set<String> _checked = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = ShoppingListExtractor.extractFromReminders(widget.reminders);
    final grouped = ShoppingListExtractor.groupItems(items);

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: [
                  Icon(LucideIcons.shoppingBasket, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đi chợ / Nguyên liệu hôm nay',
                          style: theme.textTheme.titleLarge,
                        ),
                        Text(
                          'Đã chuẩn bị ${_checked.length}/${items.length} món',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Chưa có bữa ăn nào đang bật hoặc có thẻ món ăn để trích xuất nguyên liệu.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      children: [
                        for (final group in ShoppingGroup.values)
                          if (grouped[group]?.isNotEmpty ?? false) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
                              child: Text(
                                group.label,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            for (final item in grouped[group]!)
                              CheckboxListTile(
                                value: _checked.contains(item.name),
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _checked.add(item.name);
                                    } else {
                                      _checked.remove(item.name);
                                    }
                                  });
                                },
                                controlAffinity: ListTileControlAffinity.leading,
                                title: Text(
                                  item.name,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    decoration: _checked.contains(item.name)
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                subtitle: Text(
                                  item.mealSources.join(' • '),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                          ],
                      ],
                    ),
            ),
            const Divider(height: 1),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: items.isEmpty
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final text = ShoppingListExtractor.formatForClipboard(items);
                            await Clipboard.setData(ClipboardData(text: text));
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Đã sao chép danh sách đi chợ!'),
                                ),
                              );
                            }
                          },
                    icon: const Icon(LucideIcons.copy),
                    label: const Text('Sao chép danh sách'),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
