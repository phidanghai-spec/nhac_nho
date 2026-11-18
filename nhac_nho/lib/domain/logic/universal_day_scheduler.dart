// Thuật toán Lập lịch Động theo Nhịp sống Cá nhân (Wake-Anchored Auto-Fit).

import '../entities/body_profile.dart';
import '../entities/nutrition_plan.dart';
import '../entities/reminder.dart';
import '../entities/user_settings.dart';
import '../entities/user_task_input.dart';
import 'adaptive_food_catalog.dart';
import 'body_nutrition_analyzer.dart';
import 'sleep_planner.dart';

class DayGap {
  const DayGap({
    required this.startOffsetMinutes,
    required this.endOffsetMinutes,
    required this.startTime,
    required this.endTime,
  });

  final int startOffsetMinutes;
  final int endOffsetMinutes;
  final ClockTime startTime;
  final ClockTime endTime;

  int get durationMinutes => endOffsetMinutes - startOffsetMinutes;
}

class ScheduledDayPlan {
  const ScheduledDayPlan({
    required this.reminders,
    required this.sleepPlan,
    required this.nutritionPlan,
    required this.freeGaps,
  });

  final List<Reminder> reminders;
  final SleepPlanResult sleepPlan;
  final NutritionPlan nutritionPlan;
  final List<DayGap> freeGaps;
}

class _BusyBlock {
  const _BusyBlock(this.start, this.end);
  final int start;
  final int end;

  bool overlaps(int otherStart, int otherEnd) {
    return start < otherEnd && otherStart < end;
  }
}

class UniversalDayScheduler {
  const UniversalDayScheduler._();

  static ScheduledDayPlan schedule({
    required List<UserTaskInput> tasks,
    required BodyProfile profile,
    required UserSettings settings,
    Map<MealSlot, int> mealVariantIndices = const {},
    String? createdAt,
  }) {
    final stamp = createdAt ?? '2026-11-18T00:00:00.000Z';
    final wake = ClockTime.parse(settings.wakeTime);

    final initialSleep = SleepPlanner.calculate(
      wakeTime: wake,
      sleepHours: settings.sleepHours,
      fallAsleepBufferMin: settings.fallAsleepBufferMin,
      dinnerCutoffHours: settings.dinnerCutoffHours,
      caffeineCutoffHours: settings.caffeineCutoffHours,
      windDownMin: settings.windDownMin,
    );

    final nutrition = BodyNutritionAnalyzer.analyze(
      profile,
      wakeTime: wake,
      bedtime: initialSleep.bedtime,
    );

    final sleep = SleepPlanner.calculate(
      wakeTime: wake,
      sleepHours: settings.sleepHours,
      fallAsleepBufferMin: settings.fallAsleepBufferMin,
      dinnerCutoffHours: nutrition.recommendedDinnerCutoffHours,
      caffeineCutoffHours: nutrition.recommendedCaffeineCutoffHours,
      windDownMin: settings.windDownMin,
    );

    final wakeMin = wake.toMinutes();
    final rawAwakeEnd = (sleep.bedtime.toMinutes() - wakeMin + 1440) % 1440;
    final awakeDuration = rawAwakeEnd == 0 ? 16 * 60 : rawAwakeEnd;

    final busy = <_BusyBlock>[];
    final generated = <Reminder>[];

    int toOffset(int hour, int minute) {
      return (hour * 60 + minute - wakeMin + 1440) % 1440;
    }

    // 1. Đặt các công việc cố định giờ trước tiên.
    final fixedTasks = tasks.where((t) => t.isFixed).toList();
    final flexibleTasks = tasks.where((t) => !t.isFixed).toList();

    for (final task in fixedTasks) {
      final offset = toOffset(task.fixedHour!, task.fixedMinute!);
      busy.add(_BusyBlock(offset, offset + task.estimatedMinutes));
      generated.add(
        Reminder(
          title: task.title,
          note: task.note ??
              'Lịch cố định (${task.estimatedMinutes}p · ${task.energyDemand.displayName}).',
          category: ReminderCategory.task,
          isRoutine: false,
          priority: task.energyDemand == TaskEnergyDemand.highFocus ? 1 : 2,
          hour: task.fixedHour!,
          minute: task.fixedMinute!,
          repeat: RepeatType.daily,
          createdAt: stamp,
        ),
      );

      // Chèn nghỉ ngắn & uống nước nếu việc cố định dài >= 60 phút
      if (task.estimatedMinutes >= 60) {
        final breakOffset = offset + task.estimatedMinutes;
        if (breakOffset + 10 <= awakeDuration - 30) {
          final breakTime = wake.addMinutes(breakOffset);
          busy.add(_BusyBlock(breakOffset, breakOffset + 10));
          generated.add(
            Reminder(
              title: 'Nghỉ mắt & Uống nước sau "${task.title}"',
              note: 'Thư giãn 5–10 phút và uống 150–200ml nước trước việc kế tiếp.',
              category: ReminderCategory.hydration,
              isRoutine: true,
              hour: breakTime.hour,
              minute: breakTime.minute,
              repeat: RepeatType.daily,
              createdAt: stamp,
            ),
          );
        }
      }
    }

    // 2. Xếp các bữa ăn & tránh xung đột với công việc cố định.
    for (final rec in nutrition.mealScheduleRecommendations) {
      if (rec.category == ReminderCategory.hydration) {
        final t = ClockTime(rec.hour, rec.minute);
        generated.add(
          Reminder(
            title: rec.title,
            note: rec.foodAdvice,
            category: rec.category,
            isRoutine: true,
            hour: t.hour,
            minute: t.minute,
            repeat: RepeatType.daily,
            createdAt: stamp,
          ),
        );
        continue;
      }

      var mealOffset = toOffset(rec.hour, rec.minute);
      const mealDuration = 30;
      mealOffset = _resolveConflictOffset(
        preferred: mealOffset,
        duration: mealDuration,
        busy: busy,
        maxOffset: awakeDuration - 45,
      );

      busy.add(_BusyBlock(mealOffset, mealOffset + mealDuration));
      final shiftedTime = wake.addMinutes(mealOffset);
      final slot = AdaptiveFoodCatalog.inferSlotFromTitle(rec.title);
      final variant = mealVariantIndices[slot] ?? 0;
      final suggestion = AdaptiveFoodCatalog.swapMealOption(
        slot: slot,
        profile: profile,
        variantIndex: variant,
      );

      generated.add(
        Reminder(
          title: rec.title,
          note: AdaptiveFoodCatalog.formatNote(suggestion),
          category: ReminderCategory.meal,
          isRoutine: true,
          hour: shiftedTime.hour,
          minute: shiftedTime.minute,
          repeat: RepeatType.daily,
          createdAt: stamp,
        ),
      );
    }

    // 3. Tự động xếp việc linh hoạt theo 3 vùng năng lượng sinh học cá nhân.
    // Đỉnh 1: wake + 90p .. wake + 300p (highFocus)
    // Vùng phục hồi & nhẹ: wake + 300p .. wake + 510p (lightChore)
    // Đỉnh 2: wake + 510p .. wake + 690p (mediumTask, physicalOrEvent)
    flexibleTasks.sort((a, b) {
      return _energyRank(a.energyDemand).compareTo(_energyRank(b.energyDemand));
    });

    for (final task in flexibleTasks) {
      final (prefStart, prefEnd) = switch (task.energyDemand) {
        TaskEnergyDemand.highFocus => (90, 300),
        TaskEnergyDemand.lightChore => (300, 540),
        TaskEnergyDemand.mediumTask => (180, 660),
        TaskEnergyDemand.physicalOrEvent => (480, awakeDuration - 90),
      };

      final placed = _findFirstFreeSlot(
            duration: task.estimatedMinutes,
            preferredStart: prefStart.clamp(15, awakeDuration - 60),
            preferredEnd: prefEnd.clamp(60, awakeDuration - 30),
            busy: busy,
          ) ??
          _findFirstFreeSlot(
            duration: task.estimatedMinutes,
            preferredStart: 15,
            preferredEnd: awakeDuration - 30,
            busy: busy,
          );

      final startOffset = placed ?? 90;
      busy.add(_BusyBlock(startOffset, startOffset + task.estimatedMinutes));
      final startTime = wake.addMinutes(startOffset);

      generated.add(
        Reminder(
          title: task.title,
          note: task.note ??
              'Tự động xếp vào khung tối ưu (${task.estimatedMinutes}p · ${task.energyDemand.displayName}).',
          category: ReminderCategory.task,
          isRoutine: false,
          priority: task.energyDemand == TaskEnergyDemand.highFocus ? 1 : 2,
          hour: startTime.hour,
          minute: startTime.minute,
          repeat: RepeatType.daily,
          createdAt: stamp,
        ),
      );

      if (task.estimatedMinutes >= 60) {
        final breakOffset = startOffset + task.estimatedMinutes;
        if (breakOffset + 10 <= awakeDuration - 30 &&
            !_hasConflict(breakOffset, breakOffset + 10, busy)) {
          final breakTime = wake.addMinutes(breakOffset);
          busy.add(_BusyBlock(breakOffset, breakOffset + 10));
          generated.add(
            Reminder(
              title: 'Nghỉ mắt & Uống nước sau "${task.title}"',
              note: 'Đứng dậy vươn vai 5–10 phút và uống 200ml nước.',
              category: ReminderCategory.hydration,
              isRoutine: true,
              hour: breakTime.hour,
              minute: breakTime.minute,
              repeat: RepeatType.daily,
              createdAt: stamp,
            ),
          );
        }
      }
    }

    // 4. Thêm chu kỳ uống nước tổng thể + các mốc giấc ngủ.
    generated.addAll([
      Reminder(
        title: 'Uống nước định kỳ (${nutrition.dailyWaterMl}ml/ngày)',
        note:
            'Uống ~220ml mỗi ${nutrition.waterIntervalMin} phút trong khung '
            '${ClockTime(nutrition.waterStartHour, nutrition.waterStartMinute).format24h()}–'
            '${ClockTime(nutrition.waterEndHour, nutrition.waterEndMinute).format24h()}.',
        category: ReminderCategory.hydration,
        isRoutine: true,
        hour: nutrition.waterStartHour,
        minute: nutrition.waterStartMinute,
        repeat: RepeatType.interval,
        intervalMinutes: nutrition.waterIntervalMin,
        endHour: nutrition.waterEndHour,
        endMinute: nutrition.waterEndMinute,
        createdAt: stamp,
      ),
      Reminder(
        title: 'Ngừng Caffeine',
        note:
            'Ngừng cà phê, trà đậm ${nutrition.recommendedCaffeineCutoffHours.toStringAsFixed(0)} giờ trước khi ngủ.',
        category: ReminderCategory.hydration,
        isRoutine: true,
        hour: sleep.caffeineCutoff.hour,
        minute: sleep.caffeineCutoff.minute,
        repeat: RepeatType.daily,
        createdAt: stamp,
      ),
      Reminder(
        title: 'Ngừng ăn tối & đồ ăn vặt',
        note:
            'Kết thúc ăn ${nutrition.recommendedDinnerCutoffHours.toStringAsFixed(1)} giờ trước ngủ để dạ dày nghỉ ngơi.',
        category: ReminderCategory.sleep,
        isRoutine: true,
        hour: sleep.dinnerStop.hour,
        minute: sleep.dinnerStop.minute,
        repeat: RepeatType.daily,
        createdAt: stamp,
      ),
      Reminder(
        title: 'Chuẩn bị đi ngủ',
        note: nutrition.sleepAdviceNote,
        category: ReminderCategory.sleep,
        isRoutine: true,
        hour: sleep.windDown.hour,
        minute: sleep.windDown.minute,
        repeat: RepeatType.daily,
        createdAt: stamp,
      ),
      Reminder(
        title: 'Đi ngủ đúng giờ',
        note:
            'Mục tiêu ngủ ${settings.sleepHours} giờ, thức dậy lúc ${wake.format24h()}.',
        category: ReminderCategory.sleep,
        isRoutine: true,
        hour: sleep.bedtime.hour,
        minute: sleep.bedtime.minute,
        repeat: RepeatType.daily,
        createdAt: stamp,
      ),
    ]);

    generated.sort((a, b) {
      final ao = toOffset(a.hour, a.minute);
      final bo = toOffset(b.hour, b.minute);
      final cmp = ao.compareTo(bo);
      if (cmp != 0) return cmp;
      return a.priority.compareTo(b.priority);
    });

    final freeGaps = _computeFreeGaps(
      wake: wake,
      awakeDuration: awakeDuration,
      busy: busy,
    );

    return ScheduledDayPlan(
      reminders: generated,
      sleepPlan: sleep,
      nutritionPlan: nutrition,
      freeGaps: freeGaps,
    );
  }

  static int _energyRank(TaskEnergyDemand demand) {
    return switch (demand) {
      TaskEnergyDemand.highFocus => 0,
      TaskEnergyDemand.mediumTask => 1,
      TaskEnergyDemand.lightChore => 2,
      TaskEnergyDemand.physicalOrEvent => 3,
    };
  }

  static bool _hasConflict(int start, int end, List<_BusyBlock> busy) {
    for (final b in busy) {
      if (b.overlaps(start, end)) return true;
    }
    return false;
  }

  static int _resolveConflictOffset({
    required int preferred,
    required int duration,
    required List<_BusyBlock> busy,
    required int maxOffset,
  }) {
    if (!_hasConflict(preferred, preferred + duration, busy)) {
      return preferred;
    }

    // Thử dịch lên sớm trước (tối đa 90 phút) hoặc lùi sau khi hết việc bận.
    for (var shift = 15; shift <= 120; shift += 15) {
      final earlier = preferred - shift;
      if (earlier >= 15 && !_hasConflict(earlier, earlier + duration, busy)) {
        return earlier;
      }
      final later = preferred + shift;
      if (later + duration <= maxOffset &&
          !_hasConflict(later, later + duration, busy)) {
        return later;
      }
    }
    return preferred;
  }

  static int? _findFirstFreeSlot({
    required int duration,
    required int preferredStart,
    required int preferredEnd,
    required List<_BusyBlock> busy,
  }) {
    for (var cursor = preferredStart;
        cursor + duration <= preferredEnd;
        cursor += 15) {
      if (!_hasConflict(cursor, cursor + duration, busy)) {
        return cursor;
      }
    }
    return null;
  }

  static List<DayGap> _computeFreeGaps({
    required ClockTime wake,
    required int awakeDuration,
    required List<_BusyBlock> busy,
  }) {
    if (busy.isEmpty) return const [];
    final sorted = [...busy]..sort((a, b) => a.start.compareTo(b.start));
    final gaps = <DayGap>[];
    var cursor = 0;

    for (final block in sorted) {
      if (block.start > cursor && block.start - cursor >= 30) {
        gaps.add(
          DayGap(
            startOffsetMinutes: cursor,
            endOffsetMinutes: block.start,
            startTime: wake.addMinutes(cursor),
            endTime: wake.addMinutes(block.start),
          ),
        );
      }
      if (block.end > cursor) {
        cursor = block.end;
      }
    }
    if (awakeDuration - cursor >= 30) {
      gaps.add(
        DayGap(
          startOffsetMinutes: cursor,
          endOffsetMinutes: awakeDuration,
          startTime: wake.addMinutes(cursor),
          endTime: wake.addMinutes(awakeDuration),
        ),
      );
    }
    return gaps;
  }
}
