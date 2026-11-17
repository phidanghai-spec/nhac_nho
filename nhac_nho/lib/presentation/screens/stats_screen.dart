// Màn hình Thống kê hiển thị Streak và biểu đồ hoàn thành 7 ngày.

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(reminderControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê thói quen'),
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Lỗi tải thống kê: $err')),
        data: (state) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Card(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        size: 40,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Chuỗi duy trì hiện tại',
                              style: theme.textTheme.titleMedium,
                            ),
                            Text(
                              '${state.currentStreak} ngày liên tiếp',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tính khi hoàn thành ≥ 80% thói quen sinh hoạt mỗi ngày.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _SevenDayChartCard(
                title: 'Thói quen sinh hoạt (Ăn, Uống nước, Ngủ) · 7 ngày',
                rates: state.routineRates7Days,
                barColor: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              _SevenDayChartCard(
                title: 'Công việc trong ngày · 7 ngày',
                rates: state.taskRates7Days,
                barColor: theme.colorScheme.secondary,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SevenDayChartCard extends StatelessWidget {
  const _SevenDayChartCard({
    required this.title,
    required this.rates,
    required this.barColor,
  });

  final String title;
  final Map<String, double> rates;
  final Color barColor;

  String _shortDayLabel(String dateKey) {
    final dt = DateTime.tryParse(dateKey);
    if (dt == null) return dateKey;
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = rates.entries.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: entries.map((e) {
                final percent = (e.value * 100).round();
                final barHeight = (e.value.clamp(0.0, 1.0) * 100).toDouble();
                return Expanded(
                  child: Semantics(
                    label: 'Ngày ${_shortDayLabel(e.key)}: $percent phần trăm',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '$percent%',
                              maxLines: 1,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 104,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                height: barHeight < 6 ? 6 : barHeight,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: e.value > 0
                                      ? barColor
                                      : theme.colorScheme
                                          .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _shortDayLabel(e.key),
                              maxLines: 1,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
