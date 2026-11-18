// Màn hình Thống kê hiển thị Bento Streak và biểu đồ fl_chart 7 ngày.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

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
          final routineAvg = state.routineRates7Days.isEmpty
              ? 0
              : ((state.routineRates7Days.values.reduce((a, b) => a + b) /
                          state.routineRates7Days.length) *
                      100)
                  .round();
          final taskAvg = state.taskRates7Days.isEmpty
              ? 0
              : ((state.taskRates7Days.values.reduce((a, b) => a + b) /
                          state.taskRates7Days.length) *
                      100)
                  .round();
          final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.35;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Card(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.flame,
                        size: 38,
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
              const SizedBox(height: 12),
              if (largeText) ...[
                _AvgBentoTile(
                  icon: LucideIcons.heartPulse,
                  label: 'TB Thói quen (7 ngày)',
                  value: '$routineAvg%',
                ),
                const SizedBox(height: 10),
                _AvgBentoTile(
                  icon: LucideIcons.briefcase,
                  label: 'TB Công việc (7 ngày)',
                  value: '$taskAvg%',
                ),
              ] else
                Row(
                  children: [
                    Expanded(
                      child: _AvgBentoTile(
                        icon: LucideIcons.heartPulse,
                        label: 'TB Thói quen (7 ngày)',
                        value: '$routineAvg%',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _AvgBentoTile(
                        icon: LucideIcons.briefcase,
                        label: 'TB Công việc (7 ngày)',
                        value: '$taskAvg%',
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
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

class _AvgBentoTile extends StatelessWidget {
  const _AvgBentoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(label, style: theme.textTheme.labelMedium),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = rates.entries.toList();
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final reservedBottom = textScale > 1.35 ? 36.0 : 28.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            if (entries.isEmpty)
              const Text('Chưa có dữ liệu 7 ngày.')
            else
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    maxY: 100,
                    minY: 0,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 25,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    extraLinesData: ExtraLinesData(
                      horizontalLines: [
                        HorizontalLine(
                          y: 80,
                          color: theme.colorScheme.tertiary.withValues(alpha: 0.7),
                          strokeWidth: 1.5,
                          dashArray: [6, 4],
                        ),
                      ],
                    ),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${rod.toY.round()}%',
                            TextStyle(
                              color: theme.colorScheme.onInverseSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: textScale > 1.35 ? 48 : 36,
                          interval: 50,
                          getTitlesWidget: (value, meta) => Text(
                            '${value.toInt()}%',
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: reservedBottom,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= entries.length) {
                              return const SizedBox.shrink();
                            }
                            final key = entries[idx].key;
                            final shortDate =
                                key.length >= 10 ? key.substring(8, 10) : key;
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                shortDate,
                                style: theme.textTheme.labelSmall,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: List.generate(entries.length, (i) {
                      final pct = (entries[i].value * 100).clamp(0, 100).toDouble();
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: pct,
                            width: 18,
                            color: barColor,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: 100,
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
