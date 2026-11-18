import 'package:flutter_test/flutter_test.dart';
import 'package:nhac_nho/domain/entities/reminder.dart';
import 'package:nhac_nho/domain/logic/adaptive_food_catalog.dart';
import 'package:nhac_nho/domain/logic/shopping_list_extractor.dart';

void main() {
  group('ShoppingListExtractor', () {
    test('trích xuất nguyên liệu từ bữa ăn đang bật và khử trùng lặp', () {
      final reminders = [
        Reminder(
          id: 1,
          title: 'Bữa sáng',
          note: AdaptiveFoodCatalog.formatNote(
            const MealSuggestion(
              slot: MealSlot.breakfast,
              foodItems: ['🥚 Trứng luộc', '🌾 Yến mạch', '🍌 Chuối'],
              advice: 'Ăn chậm.',
              variantIndex: 0,
              totalVariants: 1,
            ),
          ),
          category: ReminderCategory.meal,
          isRoutine: true,
          hour: 7,
          minute: 0,
          repeat: RepeatType.daily,
          enabled: true,
          createdAt: '2026-11-18T00:00:00Z',
        ),
        Reminder(
          id: 2,
          title: 'Bữa trưa',
          note: AdaptiveFoodCatalog.formatNote(
            const MealSuggestion(
              slot: MealSlot.lunch,
              foodItems: ['🍗 Ức gà áp chảo', '🍚 Cơm gạo lứt', '🥦 Bông cải xanh'],
              advice: 'Đủ đạm.',
              variantIndex: 0,
              totalVariants: 1,
            ),
          ),
          category: ReminderCategory.meal,
          isRoutine: true,
          hour: 12,
          minute: 0,
          repeat: RepeatType.daily,
          enabled: true,
          createdAt: '2026-11-18T00:00:00Z',
        ),
        Reminder(
          id: 3,
          title: 'Bữa phụ',
          note: AdaptiveFoodCatalog.formatNote(
            const MealSuggestion(
              slot: MealSlot.snack,
              foodItems: ['🍌 chuối', '🥛 Sữa chua Hy Lạp'],
              advice: 'Nhẹ bụng.',
              variantIndex: 0,
              totalVariants: 1,
            ),
          ),
          category: ReminderCategory.meal,
          isRoutine: true,
          hour: 16,
          minute: 0,
          repeat: RepeatType.daily,
          enabled: true,
          createdAt: '2026-11-18T00:00:00Z',
        ),
        Reminder(
          id: 4,
          title: 'Bữa tối đã tắt',
          note: AdaptiveFoodCatalog.formatNote(
            const MealSuggestion(
              slot: MealSlot.dinner,
              foodItems: ['🐟 Cá hồi', '🥗 Salad'],
              advice: 'Không dùng.',
              variantIndex: 0,
              totalVariants: 1,
            ),
          ),
          category: ReminderCategory.meal,
          isRoutine: true,
          hour: 19,
          minute: 0,
          repeat: RepeatType.daily,
          enabled: false,
          createdAt: '2026-11-18T00:00:00Z',
        ),
        const Reminder(
          id: 5,
          title: 'Họp team',
          note: '☕ Chuẩn bị slide | 📋 Báo cáo',
          category: ReminderCategory.task,
          isRoutine: false,
          hour: 9,
          minute: 0,
          repeat: RepeatType.daily,
          enabled: true,
          createdAt: '2026-11-18T00:00:00Z',
        ),
      ];

      final items = ShoppingListExtractor.extractFromReminders(reminders);
      final names = items.map((e) => e.name.toLowerCase()).toList();

      // Khử trùng lặp Chuối (xuất hiện ở Bữa sáng & Bữa phụ)
      expect(names.where((n) => n.contains('chuối')).length, 1);
      // Bỏ qua Bữa tối đã tắt và Công việc không phải bữa ăn
      expect(names.any((n) => n.contains('cá hồi')), isFalse);
      expect(names.any((n) => n.contains('báo cáo')), isFalse);
      // Tổng 7 món duy nhất: Trứng, Yến mạch, Chuối, Ức gà, Cơm gạo lứt, Bông cải xanh, Sữa chua Hy Lạp
      expect(items.length, 7);

      final formatted = ShoppingListExtractor.formatForClipboard(items);
      expect(formatted, contains('Danh sách đi chợ hôm nay:'));
      expect(formatted, contains('Đạm & Món chính:'));
      expect(formatted, contains('Rau củ & Trái cây:'));
    });
  });
}
