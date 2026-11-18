// Kho thực phẩm Việt Nam 4 chiều (Thể trạng/Bệnh lý + Chế độ ăn + Nhịp ngày + Bữa ăn).

import '../entities/body_profile.dart';

enum MealSlot {
  breakfast('Bữa sáng'),
  lunch('Bữa trưa'),
  snack('Bữa phụ'),
  dinner('Bữa tối'),
  preWorkout('Trước tập'),
  postWorkout('Sau tập');

  const MealSlot(this.displayName);
  final String displayName;
}

class MealSuggestion {
  const MealSuggestion({
    required this.slot,
    required this.foodItems,
    required this.advice,
    required this.variantIndex,
    required this.totalVariants,
  });

  final MealSlot slot;
  final List<String> foodItems;
  final String advice;
  final int variantIndex;
  final int totalVariants;
}

class _MealVariant {
  const _MealVariant(this.items, this.advice);
  final List<String> items;
  final String advice;
}

class AdaptiveFoodCatalog {
  const AdaptiveFoodCatalog._();

  static const String _itemsPrefix = 'Món gợi ý: ';

  static MealSuggestion swapMealOption({
    required MealSlot slot,
    required BodyProfile profile,
    DailyFocusMode? focusMode,
    int variantIndex = 0,
  }) {
    final effectiveFocus = _resolveEffectiveFocus(
      profile: profile,
      requested: focusMode ?? profile.dailyFocusMode,
    );

    final pool = _selectPool(
      slot: slot,
      dietType: profile.dietType,
      focusMode: effectiveFocus,
      goal: profile.goal,
      condition: profile.condition,
    );

    final normalizedIndex =
        ((variantIndex % pool.length) + pool.length) % pool.length;
    final chosen = pool[normalizedIndex];
    final extraAdvice = _buildConditionSuffix(profile, slot);

    return MealSuggestion(
      slot: slot,
      foodItems: chosen.items,
      advice: extraAdvice.isEmpty
          ? chosen.advice
          : '${chosen.advice} $extraAdvice',
      variantIndex: normalizedIndex,
      totalVariants: pool.length,
    );
  }

  static String formatNote(MealSuggestion suggestion) {
    final chipsLine = '$_itemsPrefix${suggestion.foodItems.join(' · ')}';
    return '$chipsLine\n${suggestion.advice}';
  }

  static List<String> parseFoodItemsFromNote(String? note) {
    if (note == null || note.isEmpty) return const [];
    final lines = note.split('\n');
    for (final line in lines) {
      if (line.startsWith(_itemsPrefix)) {
        return line
            .substring(_itemsPrefix.length)
            .split(' · ')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }
    return const [];
  }

  static String extractAdviceFromNote(String? note) {
    if (note == null || note.isEmpty) return '';
    final lines = note.split('\n');
    final rest = lines.where((l) => !l.startsWith(_itemsPrefix)).toList();
    return rest.join('\n').trim();
  }

  static MealSlot inferSlotFromTitle(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('pre-workout') || lower.contains('trước tập')) {
      return MealSlot.preWorkout;
    }
    if (lower.contains('post-workout') || lower.contains('sau tập')) {
      return MealSlot.postWorkout;
    }
    if (lower.contains('sáng') || lower.contains('bữa 1')) {
      return MealSlot.breakfast;
    }
    if (lower.contains('trưa') || lower.contains('bữa 2')) {
      return MealSlot.lunch;
    }
    if (lower.contains('tối') || lower.contains('bữa 3')) {
      return MealSlot.dinner;
    }
    return MealSlot.snack;
  }

  static DailyFocusMode _resolveEffectiveFocus({
    required BodyProfile profile,
    required DailyFocusMode requested,
  }) {
    if (profile.condition == HealthCondition.stomachReflux ||
        profile.condition == HealthCondition.seniorCardio ||
        profile.age >= 60) {
      if (requested == DailyFocusMode.leanAntiBloat ||
          requested == DailyFocusMode.brainFocus) {
        return requested;
      }
      return DailyFocusMode.digestiveComfort;
    }
    return requested;
  }

  static String _buildConditionSuffix(BodyProfile profile, MealSlot slot) {
    final parts = <String>[];
    if ((profile.goal == FitnessGoal.loseWeight ||
            profile.condition == HealthCondition.bloodSugar) &&
        (slot == MealSlot.lunch || slot == MealSlot.dinner)) {
      parts.add('Ưu tiên ăn rau trước rồi mới đến đạm và tinh bột.');
    }
    if (profile.dietType == DietType.vegan &&
        (slot == MealSlot.lunch || slot == MealSlot.dinner)) {
      parts.add('Kèm rau quả giàu Vitamin C (ớt chuông, ổi, cam) để hấp thu sắt.');
    }
    if (profile.condition == HealthCondition.stomachReflux) {
      parts.add('Ăn chậm, nhai kỹ, tránh đồ chua cay hoặc quá lạnh.');
    }
    return parts.join(' ');
  }

  static List<_MealVariant> _selectPool({
    required MealSlot slot,
    required DietType dietType,
    required DailyFocusMode focusMode,
    required FitnessGoal goal,
    required HealthCondition condition,
  }) {
    if (slot == MealSlot.preWorkout) {
      return switch (dietType) {
        DietType.omnivore => const [
          _MealVariant(
            ['🍌 1 Chuối chín', '🍠 1 Khoai lang nhỏ', '🥚 1 Trứng luộc'],
            'Nạp tinh bột vừa phải trước tập 60–90p giúp giữ sức bền.',
          ),
          _MealVariant(
            ['🥣 Yến mạch ấm', '🥛 Sữa tươi ít đường', '🍓 Quả mọng'],
            'Giải phóng năng lượng đều suốt buổi tập không gây nặng bụng.',
          ),
        ],
        DietType.vegetarian => const [
          _MealVariant(
            ['🍌 1 Chuối', '🍞 Bánh mì nguyên cám', '🥚 1 Trứng ốp la'],
            'Nạp năng lượng nhẹ trước tập 60–90p.',
          ),
          _MealVariant(
            ['🥣 Yến mạch', '🥛 Sữa chua Hy Lạp', '🍯 1 thìa mật ong'],
            'Nhẹ bụng, dễ tiêu hóa trước khi vận động.',
          ),
        ],
        DietType.vegan => const [
          _MealVariant(
            ['🍌 1 Chuối', '🥜 1 thìa bơ đậu phộng', '🍞 Bánh mì nguyên cám'],
            'Năng lượng thực vật ổn định đường huyết trước buổi tập.',
          ),
          _MealVariant(
            ['🍠 Khoai lang luộc', '🥛 Sữa đậu nành không đường'],
            'Tinh bột chậm + đạm thực vật nhẹ bụng trước tập.',
          ),
        ],
      };
    }

    if (slot == MealSlot.postWorkout) {
      return switch (dietType) {
        DietType.omnivore => const [
          _MealVariant(
            ['🍗 150g Ức gà áp chảo', '🍚 Cơm gạo lứt', '🥦 Bông cải xanh'],
            'Bù đạm phục hồi cơ và bù 300ml nước điện giải sau tập.',
          ),
          _MealVariant(
            ['🐟 Cá hồi áp chảo', '🥔 Khoai tây nghiền', '🥗 Salad rau xanh'],
            'Giàu đạm chất lượng cao và Omega-3 giảm đau mỏi cơ.',
          ),
        ],
        DietType.vegetarian => const [
          _MealVariant(
            ['🥚 2 Trứng gà', '🥛 Sữa chua Hy Lạp', '🍌 Chuối & yến mạch'],
            'Đạm hoàn chỉnh giúp phục hồi sợi cơ nhanh sau tập.',
          ),
          _MealVariant(
            ['🧈 Đậu phụ áp chảo', '🍄 Nấm đùi gà', '🍚 Cơm gạo lứt'],
            'Kết hợp đạm thực vật và tinh bột phục hồi glycogen.',
          ),
        ],
        DietType.vegan => const [
          _MealVariant(
            ['🧈 Đậu phụ / Tempeh', '🫘 Đậu gà trộn salad', '🍚 Cơm gạo lứt'],
            'Đủ 9 axit amin thiết yếu để tổng hợp cơ bắp sau tập.',
          ),
          _MealVariant(
            ['🥛 Sữa đậu nành giàu đạm', '🌾 Yến mạch', '🥜 Hạt bí & chia'],
            'Hấp thu nhanh, bù nước và đạm thực vật sau tập.',
          ),
        ],
      };
    }

    if (slot == MealSlot.snack) {
      return switch (dietType) {
        DietType.omnivore || DietType.vegetarian => switch (focusMode) {
          DailyFocusMode.leanAntiBloat => const [
            _MealVariant(
              ['🥒 Dưa leo & cần tây', '🥚 2 Lòng trắng trứng', '🫐 Quả mọng'],
              'Ít natri, chống tích nước và giữ bụng phẳng nhẹ.',
            ),
            _MealVariant(
              ['🥛 Sữa chua Hy Lạp', '🍓 Dâu tây / Táo xanh'],
              'Giàu lợi khuẩn tiêu hóa, ít đường, không gây đầy hơi.',
            ),
          ],
          DailyFocusMode.quickBudget => const [
            _MealVariant(
              ['🍌 1 Quả chuối', '🥜 1 nắm lạc rang'],
              'Rẻ, tiện lợi, nạp năng lượng nhanh trong 2 phút.',
            ),
            _MealVariant(
              ['🥛 1 Hộp sữa chua không đường', '🍏 1 Quả ổi'],
              'Mua dễ ở mọi cửa hàng, giàu vitamin C.',
            ),
          ],
          _ => const [
            _MealVariant(
              ['🥛 Sữa chua không đường', '🌰 1 nắm hạnh nhân / óc chó'],
              'Chống đói cuối buổi mà không làm tăng đường huyết đột ngột.',
            ),
            _MealVariant(
              ['🍏 1 Quả táo / ổi', '🥚 1 Trứng luộc'],
              'Cân bằng chất xơ và đạm nhẹ giữ tỉnh táo.',
            ),
          ],
        },
        DietType.vegan => const [
          _MealVariant(
            ['🥛 Sữa đậu nành không đường', '🌰 1 nắm hạt óc chó / điều'],
            'Bổ sung Omega-3 thực vật và đạm nhẹ.',
          ),
          _MealVariant(
            ['🍏 1 Quả ổi / táo', '🥜 1 thìa bơ đậu phộng'],
            'Nhanh gọn, giàu chất xơ và năng lượng sạch.',
          ),
        ],
      };
    }

    // Breakfast, Lunch, Dinner across DietType & FocusMode
    if (dietType == DietType.vegan) {
      return switch (slot) {
        MealSlot.breakfast => const [
          _MealVariant(
            ['🥣 Yến mạch nấu', '🥛 Sữa đậu nành', '🍌 Chuối & hạt chia'],
            'Bữa sáng thuần chay no lâu, giàu chất xơ hòa tan.',
          ),
          _MealVariant(
            ['🍞 Bánh mì nguyên cám', '🥜 Bơ đậu phộng', '🥑 Bơ lát'],
            'Tinh bột chậm kết hợp chất béo tốt cho trí não.',
          ),
          _MealVariant(
            ['🍲 Cháo đậu xanh yến mạch', '🍄 Nấm hương băm'],
            'Ấm bụng, êm dịu dạ dày và dễ tiêu hóa buổi sáng.',
          ),
        ],
        MealSlot.lunch => const [
          _MealVariant(
            ['🧈 Đậu phụ sốt cà', '🍚 Cơm gạo lứt', '🥦 Bông cải luộc'],
            'Đạm đậu nành + ngũ cốc nguyên cám đủ axit amin.',
          ),
          _MealVariant(
            ['🫘 Súp đậu lăng / đậu gà', '🍠 Khoai lang', '🫑 Salad ớt chuông'],
            'Chỉ số GI thấp, tỉnh táo cả buổi chiều.',
          ),
          _MealVariant(
            ['🍄 Nấm đùi gà kho tiêu', '🍚 Cơm mềm', '🥬 Canh rau ngót'],
            'Cơm nhà thuần chay tiết kiệm, dễ làm.',
          ),
        ],
        _ => const [
          _MealVariant(
            ['🧈 Đậu phụ non hấp', '🥬 Rau cải luộc', '🥣 Canh rong biển'],
            'Nhẹ bụng buổi tối, chống đầy hơi và dễ ngủ.',
          ),
          _MealVariant(
            ['🍲 Súp bí đỏ đậu đỏ', '🍄 Nấm hương', '🥗 Dưa leo'],
            'Ấm mềm dễ tiêu, ít muối giữ dáng.',
          ),
          _MealVariant(
            ['🫘 Đậu đen hầm rau củ', '🍚 1/2 chén cơm gạo lứt'],
            'No êm đến sáng mà không nặng dạ dày.',
          ),
        ],
      };
    }

    if (dietType == DietType.vegetarian) {
      return switch (slot) {
        MealSlot.breakfast => const [
          _MealVariant(
            ['🥚 2 Trứng luộc', '🍞 Bánh mì nguyên cám', '🍅 Cà chua'],
            'Nhanh gọn 5 phút, đạm chuẩn giữ tỉnh táo buổi sáng.',
          ),
          _MealVariant(
            ['🥣 Yến mạch', '🥛 Sữa chua Hy Lạp', '🌰 Hạt điều'],
            'Giàu lợi khuẩn và tinh bột chậm chống buồn ngủ.',
          ),
          _MealVariant(
            ['🍲 Cháo yến mạch trứng non', '🥬 Hành ngò ấm'],
            'Êm dịu dạ dày, dễ tiêu vào buổi sáng sớm.',
          ),
        ],
        MealSlot.lunch => const [
          _MealVariant(
            ['🧈 Đậu phụ hấp nấm', '🥚 Trứng hấp', '🥦 Rau xanh luộc'],
            'Cân bằng đạm thực vật + trứng, ít buồn ngủ chiều.',
          ),
          _MealVariant(
            ['🍝 Mì ngũ cốc', '🧀 Phô mai ít béo', '🫑 Ớt chuông & nấm'],
            'Đổi vị gọn nhẹ nhưng vẫn đủ năng lượng làm việc.',
          ),
          _MealVariant(
            ['🫘 Đậu lăng hầm cà rốt', '🍚 Cơm gạo lứt', '🥬 Canh rau'],
            'Bền sức và ổn định đường huyết suốt ca chiều.',
          ),
        ],
        _ => const [
          _MealVariant(
            ['🧈 Đậu phụ non sốt nấm', '🥬 Canh bí đao', '🥒 Dưa leo'],
            'Thanh đạm, nhẹ bụng, không gây tích nước buổi tối.',
          ),
          _MealVariant(
            ['🥚 Trứng chưng nhẹ', '🥦 Bông cải hấp', '🍠 1/2 Khoai lang'],
            'Dễ tiêu trước khi ngủ 3 giờ.',
          ),
          _MealVariant(
            ['🍲 Cháo nấm hạt sen', '🥛 Sữa ấm ít béo'],
            'Thư giãn hệ tiêu hóa và hỗ trợ ngủ sâu.',
          ),
        ],
      };
    }

    // Omnivore variants tailored by FocusMode
    if (focusMode == DailyFocusMode.leanAntiBloat) {
      return switch (slot) {
        MealSlot.breakfast => const [
          _MealVariant(
            ['🥚 3 Lòng trắng + 1 Trứng', '🥒 Dưa leo', '🫐 Quả mọng'],
            'Giàu đạm, ít muối, giảm giữ nước giúp gương mặt gọn nét.',
          ),
          _MealVariant(
            ['🥣 Yến mạch nước ấm', '🥛 Sữa chua không đường', '🍏 Táo xanh'],
            'Giàu chất xơ hòa tan giúp nhẹ bụng trước giờ lên hình/sự kiện.',
          ),
        ],
        MealSlot.lunch => const [
          _MealVariant(
            ['🍗 150g Ức gà hấp gừng', '🥗 Măng tây / Rau luộc', '🍠 1/2 Khoai'],
            'Sạch, không dầu mỡ, hạn chế đồ sinh khí gây chướng bụng.',
          ),
          _MealVariant(
            ['🐟 Cá diêu hồng / Cá hồi hấp', '🥒 Dưa leo & cần tây', '🍚 Ít cơm'],
            'Đạm dễ tiêu kèm rau giàu kali giúp thải muối dư thừa.',
          ),
        ],
        _ => const [
          _MealVariant(
            ['🐟 Cá hấp gừng', '🥬 Rau cải luộc nhạt', '🥣 Canh bí đao'],
            'Nhạt muối, nhẹ bụng buổi tối để sáng hôm sau không phù nề.',
          ),
          _MealVariant(
            ['🦐 Tôm hấp sả', '🥦 Bông cải hấp', '🥗 Salad trộn chanh'],
            'Ít calo nhưng vẫn đủ đạm giữ cơ.',
          ),
        ],
      };
    }

    if (focusMode == DailyFocusMode.digestiveComfort) {
      return switch (slot) {
        MealSlot.breakfast => const [
          _MealVariant(
            ['🍲 Cháo yến mạch thịt băm', '🥚 1 Trứng mềm'],
            'Món ấm mềm trung hòa axit dạ dày, ăn trong 30–45p sau khi thức.',
          ),
          _MealVariant(
            ['🍜 Bún / Phở nước trong ít béo', '🥬 Rau trụng mềm'],
            'Ấm bụng, dễ nuốt, phù hợp cả người lớn tuổi và dạ dày nhạy cảm.',
          ),
        ],
        MealSlot.lunch => const [
          _MealVariant(
            ['🐟 Cá kho nhạt / hấp', '🥬 Rau củ luộc mềm', '🍚 Cơm mềm'],
            'Giảm dầu mỡ và gia vị cay nóng, dễ tiêu hóa.',
          ),
          _MealVariant(
            ['🥩 Thịt nạc băm hấp', '🥣 Canh bí đỏ mềm', '🍚 Cơm vừa'],
            'Bổ dưỡng, ít muối và thân thiện tim mạch.',
          ),
        ],
        _ => const [
          _MealVariant(
            ['🍲 Súp gà rau củ ấm', '🧈 Đậu phụ non'],
            'Dễ tiêu hóa ban đêm, hạn chế trào ngược.',
          ),
          _MealVariant(
            ['🐟 Cháo cá hồi đậu xanh', '🥬 Rau cải băm nhỏ'],
            'Nhẹ nhàng trước giờ ngủ, tránh đầy bụng.',
          ),
        ],
      };
    }

    if (focusMode == DailyFocusMode.staminaPhysical) {
      return switch (slot) {
        MealSlot.breakfast => const [
          _MealVariant(
            ['🍜 Phở bò tái nạm ít mỡ', '🥚 1 Trứng chần', '🥬 Thêm rau'],
            'Đủ tinh bột phức và đạm cho người vận động / đi đường nhiều.',
          ),
          _MealVariant(
            ['🍚 Cơm tấm thịt nạc / ức gà', '🥚 Trứng ốp', '🥒 Dưa leo'],
            'Bền sức 4–5 tiếng lao động hoặc di chuyển liên tục.',
          ),
        ],
        MealSlot.lunch => const [
          _MealVariant(
            ['🍗 Đùi gà bỏ da / Thịt nạc', '🍚 1.5 chén cơm', '🥬 Canh rau'],
            'Nạp đủ năng lượng phục hồi cho ca chiều cường độ cao.',
          ),
          _MealVariant(
            ['🐟 Cá thu sốt cà', '🍚 Cơm gạo lứt/trắng', '🥦 Rau xào ít dầu'],
            'Cân bằng đạm, tinh bột và khoáng chất.',
          ),
        ],
        _ => const [
          _MealVariant(
            ['🥩 Thịt nạc / Cá áp chảo', '🍠 Khoai lang / Cơm', '🥬 Canh ấm'],
            'Phục hồi cơ bắp và năng lượng sau ngày dài vận động.',
          ),
          _MealVariant(
            ['🦐 Tôm thịt rim nhạt', '🍚 1 chén cơm', '🥬 Rau muống luộc'],
            'Dễ ăn kiểu cơm nhà, đủ chất.',
          ),
        ],
      };
    }

    if (focusMode == DailyFocusMode.quickBudget) {
      return switch (slot) {
        MealSlot.breakfast => const [
          _MealVariant(
            ['🥚 2 Trứng ốp la', '🥖 1 Bánh mì', '🥒 Dưa leo'],
            'Nhanh gọn dưới 5 phút, chi phí tiết kiệm vẫn đủ đạm.',
          ),
          _MealVariant(
            ['🍠 1 Củ khoai lang', '🥛 1 Hộp sữa tươi không đường'],
            'Mua tiện lợi ngay trên đường đi học/đi làm.',
          ),
        ],
        MealSlot.lunch => const [
          _MealVariant(
            ['🍗 Cơm ức gà / Thịt luộc', '🥬 Rau luộc', '🥣 Canh'],
            'Dễ chọn ở bất kỳ quán cơm văn phòng / cơm bình dân nào.',
          ),
          _MealVariant(
            ['🥚 Trứng cuộn / Đậu thịt', '🍚 Cơm trắng', '🥒 Cà chua dưa leo'],
            'Đơn giản, rẻ và dễ chuẩn bị hộp mang đi.',
          ),
        ],
        _ => const [
          _MealVariant(
            ['🐟 Cá nục / Cá basa kho nhạt', '🥬 Rau luộc', '🍚 Ít cơm'],
            'Cơm nhà tiết kiệm, đủ Omega-3.',
          ),
          _MealVariant(
            ['🥚 Canh cà chua trứng', '🧈 Đậu phụ luộc', '🍚 Cơm vừa'],
            'Nấu xong trong 10 phút, nhẹ bụng buổi tối.',
          ),
        ],
      };
    }

    // Default: brainFocus
    return switch (slot) {
      MealSlot.breakfast => const [
        _MealVariant(
          ['🥚 2 Trứng luộc', '🍠 Khoai lang', '🥗 Rau xanh'],
          'Giàu Choline bổ não và tinh bột chậm giữ tập trung suốt sáng.',
        ),
        _MealVariant(
          ['🥣 Yến mạch', '🥛 Sữa chua không đường', '🌰 Hạt óc chó'],
          'Chỉ số GI thấp, tránh tụt năng lượng lúc 10h sáng.',
        ),
        _MealVariant(
          ['🍞 Bánh mì nguyên cám', '🥑 Bơ', '🥚 Trứng ốp'],
          'Chất béo tốt giúp trí não tỉnh táo làm việc sâu.',
        ),
      ],
      MealSlot.lunch => const [
        _MealVariant(
          ['🐟 Cá hồi / Cá thu', '🥦 1/2 Đĩa rau xanh', '🍚 1/4 Cơm gạo lứt'],
          'Quy tắc 2:1:1 giàu Omega-3 giúp không buồn ngủ đầu giờ chiều.',
        ),
        _MealVariant(
          ['🍗 150g Ức gà áp chảo', '🥗 Salad rau củ', '🍠 1/2 Khoai lang'],
          'Đạm nạc + tinh bột chậm giữ đường huyết ổn định.',
        ),
        _MealVariant(
          ['🦐 Tôm xào bông cải', '🧈 Đậu phụ', '🍚 Cơm gạo lứt'],
          'Nhẹ nhàng, tỉnh táo cho ca làm việc chiều.',
        ),
      ],
      _ => const [
        _MealVariant(
          ['🐟 Cá hấp gừng', '🥬 Rau luộc', '🥣 Canh ấm'],
          'Nhẹ bụng, giàu tryptophan hỗ trợ giấc ngủ sâu.',
        ),
        _MealVariant(
          ['🍗 Ức gà / Thịt nạc luộc', '🥦 Bông cải xanh', '🍚 Ít cơm'],
          'Kết thúc ăn trước ngủ 3 giờ để dạ dày được nghỉ ngơi.',
        ),
        _MealVariant(
          ['🥚 Trứng hấp nấm', '🥬 Canh rau ngót', '🥒 Dưa leo'],
          'Dễ tiêu hóa, ít tinh bột ban đêm.',
        ),
      ],
    };
  }
}
