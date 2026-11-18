// Unit test cho AdaptiveFoodCatalog (Ma trận thực phẩm 4 chiều & đổi món).

import 'package:flutter_test/flutter_test.dart';
import 'package:nhac_nho/domain/entities/body_profile.dart';
import 'package:nhac_nho/domain/logic/adaptive_food_catalog.dart';

void main() {
  group('AdaptiveFoodCatalog', () {
    test('đổi món khác nhau qua variantIndex và xoay vòng mượt', () {
      const profile = BodyProfile(
        dietType: DietType.omnivore,
        dailyFocusMode: DailyFocusMode.brainFocus,
      );

      final v0 = AdaptiveFoodCatalog.swapMealOption(
        slot: MealSlot.breakfast,
        profile: profile,
        variantIndex: 0,
      );
      final v1 = AdaptiveFoodCatalog.swapMealOption(
        slot: MealSlot.breakfast,
        profile: profile,
        variantIndex: 1,
      );
      final vWrap = AdaptiveFoodCatalog.swapMealOption(
        slot: MealSlot.breakfast,
        profile: profile,
        variantIndex: v0.totalVariants,
      );

      expect(v0.foodItems, isNotEmpty);
      expect(v1.foodItems, isNot(equals(v0.foodItems)));
      expect(vWrap.foodItems, equals(v0.foodItems));
    });

    test('chế độ leanAntiBloat ưu tiên món ít muối, chống tích nước', () {
      const profile = BodyProfile(
        dietType: DietType.omnivore,
        dailyFocusMode: DailyFocusMode.leanAntiBloat,
      );

      final lunch = AdaptiveFoodCatalog.swapMealOption(
        slot: MealSlot.lunch,
        profile: profile,
      );

      expect(lunch.advice.toLowerCase(), contains('dầu mỡ'));
      expect(lunch.foodItems.join(' '), contains('Ức gà'));
    });

    test('thuần chay (vegan) luôn dùng thực phẩm thực vật và nhắc Vitamin C ở bữa chính', () {
      const profile = BodyProfile(
        dietType: DietType.vegan,
        dailyFocusMode: DailyFocusMode.brainFocus,
      );

      final lunch = AdaptiveFoodCatalog.swapMealOption(
        slot: MealSlot.lunch,
        profile: profile,
      );
      final joined = '${lunch.foodItems.join(' ')} ${lunch.advice}'.toLowerCase();

      expect(joined, contains('vitamin c'));
      expect(joined, isNot(RegExp(r'(^|\s)gà(\s|$)')));
      expect(joined, isNot(RegExp(r'(^|\s)cá(\s|$)')));
      expect(joined, isNot(RegExp(r'(^|\s)trứng(\s|$)')));
    });

    test('formatNote và parseFoodItemsFromNote bảo toàn danh sách chip món ăn', () {
      const profile = BodyProfile();
      final s = AdaptiveFoodCatalog.swapMealOption(
        slot: MealSlot.breakfast,
        profile: profile,
      );
      final note = AdaptiveFoodCatalog.formatNote(s);
      final parsed = AdaptiveFoodCatalog.parseFoodItemsFromNote(note);

      expect(parsed, equals(s.foodItems));
      expect(AdaptiveFoodCatalog.extractAdviceFromNote(note), equals(s.advice));
    });
  });
}
