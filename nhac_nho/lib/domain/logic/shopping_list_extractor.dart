// Logic thuần Dart trích xuất và phân nhóm nguyên liệu đi chợ từ các bữa ăn trong ngày.

import '../entities/reminder.dart';
import 'adaptive_food_catalog.dart';

enum ShoppingGroup {
  protein('Đạm & Món chính'),
  carbs('Tinh bột & Ngũ cốc'),
  veggies('Rau củ & Trái cây'),
  drinksAndOther('Đồ uống & Khác');

  const ShoppingGroup(this.label);
  final String label;
}

class ShoppingItem {
  const ShoppingItem({
    required this.name,
    required this.group,
    required this.mealSources,
  });

  final String name;
  final ShoppingGroup group;
  final List<String> mealSources;
}

class ShoppingListExtractor {
  const ShoppingListExtractor._();

  static List<ShoppingItem> extractFromReminders(List<Reminder> reminders) {
    final map = <String, _MutableItem>{};

    for (final r in reminders) {
      if (r.category != ReminderCategory.meal || !r.enabled) continue;
      final items = AdaptiveFoodCatalog.parseFoodItemsFromNote(r.note);
      for (final raw in items) {
        final cleaned = raw.trim();
        if (cleaned.isEmpty) continue;
        final key = _dedupKey(cleaned);
        if (key.isEmpty) continue;

        final existing = map[key];
        if (existing != null) {
          if (!existing.sources.contains(r.title)) {
            existing.sources.add(r.title);
          }
        } else {
          map[key] = _MutableItem(
            name: cleaned,
            group: _classifyGroup(cleaned),
            sources: [r.title],
          );
        }
      }
    }

    final result = map.values
        .map(
          (e) => ShoppingItem(
            name: e.name,
            group: e.group,
            mealSources: List.unmodifiable(e.sources),
          ),
        )
        .toList();

    result.sort((a, b) {
      final gCmp = a.group.index.compareTo(b.group.index);
      if (gCmp != 0) return gCmp;
      return a.name.compareTo(b.name);
    });
    return result;
  }

  static Map<ShoppingGroup, List<ShoppingItem>> groupItems(
    List<ShoppingItem> items,
  ) {
    final grouped = <ShoppingGroup, List<ShoppingItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.group, () => []).add(item);
    }
    return grouped;
  }

  static String formatForClipboard(List<ShoppingItem> items) {
    if (items.isEmpty) return 'Chưa có nguyên liệu nào cho hôm nay.';
    final grouped = groupItems(items);
    final buffer = StringBuffer('Danh sách đi chợ hôm nay:\n');
    for (final group in ShoppingGroup.values) {
      final list = grouped[group];
      if (list == null || list.isEmpty) continue;
      buffer.writeln('\n${group.label}:');
      for (final item in list) {
        buffer.writeln('- [ ] ${item.name}');
      }
    }
    return buffer.toString().trim();
  }

  static String _dedupKey(String raw) {
    // Bỏ emoji/ký tự đầu không phải chữ cái hoặc số để khử trùng lặp chính xác.
    final lower = raw.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    return lower.replaceAll(RegExp(r'^[^\p{L}\p{N}]+', unicode: true), '').trim();
  }

  static ShoppingGroup _classifyGroup(String raw) {
    final lower = raw.toLowerCase();
    const veggieKeywords = [
      'rau',
      'cải',
      'bông cải',
      'xà lách',
      'cà chua',
      'dưa',
      'bí',
      'mướp',
      'chuối',
      'cam',
      'ổi',
      'táo',
      'bơ',
      'trái cây',
      'hoa quả',
      'salad',
      'nấm',
    ];
    for (final kw in veggieKeywords) {
      if (lower.contains(kw)) return ShoppingGroup.veggies;
    }

    const carbKeywords = [
      'cơm',
      'gạo',
      'bún',
      'phở',
      'miến',
      'mì',
      'yến mạch',
      'bánh mì',
      'khoai',
      'ngô',
      'cháo',
      'ngũ cốc',
    ];
    for (final kw in carbKeywords) {
      if (lower.contains(kw)) return ShoppingGroup.carbs;
    }

    const drinkKeywords = [
      'nước',
      'trà',
      'sinh tố',
      'sữa hạt',
      'điện giải',
      'chanh',
      'gừng',
    ];
    for (final kw in drinkKeywords) {
      if (lower.contains(kw)) return ShoppingGroup.drinksAndOther;
    }

    const proteinKeywords = [
      'gà',
      'cá',
      'thịt',
      'bò',
      'heo',
      'tôm',
      'trứng',
      'đậu',
      'sữa chua',
      'sữa',
      'phô mai',
      'hạt',
      'đạm',
      'whey',
    ];
    for (final kw in proteinKeywords) {
      if (lower.contains(kw)) return ShoppingGroup.protein;
    }

    return ShoppingGroup.drinksAndOther;
  }
}

class _MutableItem {
  _MutableItem({
    required this.name,
    required this.group,
    required this.sources,
  });

  final String name;
  final ShoppingGroup group;
  final List<String> sources;
}
