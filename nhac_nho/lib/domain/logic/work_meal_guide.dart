// Logic thuần Dart cung cấp 4 bộ lịch mẫu (Presets) và tích hợp lịch sinh hoạt cá nhân hóa.

import '../entities/body_profile.dart';
import '../entities/preset_profile.dart';
import '../entities/reminder.dart';
import '../entities/user_settings.dart';
import 'body_nutrition_analyzer.dart';
import 'sleep_planner.dart';

class WorkMealGuide {
  const WorkMealGuide._();

  static List<PresetProfile> getAllPresets({String? createdAt}) {
    final stamp = createdAt ?? '2026-11-17T06:00:00.000Z';
    return [
      officeCoderPreset(createdAt: stamp),
      studentPreset(createdAt: stamp),
      freelancerPreset(createdAt: stamp),
      seniorHealthPreset(createdAt: stamp),
    ];
  }

  static PresetProfile getPreset(PresetId id, {String? createdAt}) {
    final stamp = createdAt ?? '2026-11-17T06:00:00.000Z';
    return switch (id) {
      PresetId.officeCoder => officeCoderPreset(createdAt: stamp),
      PresetId.student => studentPreset(createdAt: stamp),
      PresetId.freelancer => freelancerPreset(createdAt: stamp),
      PresetId.seniorHealth => seniorHealthPreset(createdAt: stamp),
    };
  }

  static PresetProfile officeCoderPreset({required String createdAt}) {
    const settings = UserSettings(
      selectedPreset: 'office_coder',
      wakeTime: '06:30',
      sleepHours: 7.5,
      fallAsleepBufferMin: 15,
      breakfastTime: '07:00',
      lunchTime: '12:00',
      afternoonSnackTime: '16:00',
      dinnerTime: '18:30',
      dinnerCutoffHours: 3.0,
      caffeineCutoffHours: 8.0,
      windDownMin: 45,
      waterIntervalMin: 90,
    );

    return PresetProfile(
      id: PresetId.officeCoder,
      name: PresetId.officeCoder.displayName,
      description:
          'Deep Work buổi sáng 08:30, nghỉ mắt & uống nước mỗi 90 phút, Power Nap 20 phút, Rule of 3 buổi tối.',
      defaultSettings: settings,
      reminders: [
        _r(
          title: 'Uống nước ấm sau khi thức dậy',
          note:
              'Uống 200–300ml nước ấm ngay sau khi thức để bù nước và kích hoạt tiêu hóa.',
          category: ReminderCategory.hydration,
          isRoutine: true,
          hour: 6,
          minute: 35,
          createdAt: createdAt,
        ),
        _r(
          title: 'Bữa sáng giàu đạm & tinh bột chậm',
          note:
              'Trứng, yến mạch, bánh mì nguyên cám, khoai lang hoặc phở ít béo thêm rau; hạn chế đồ ngọt tinh luyện.',
          category: ReminderCategory.meal,
          isRoutine: true,
          hour: 7,
          minute: 0,
          createdAt: createdAt,
        ),
        _r(
          title: 'Deep Work: Code / Việc trọng tâm (MIT)',
          note:
              'Đỉnh tập trung buổi sáng (50p làm – 10p nghỉ): giải quyết 1–2 việc khó và quan trọng nhất.',
          category: ReminderCategory.task,
          isRoutine: false,
          priority: 1,
          hour: 8,
          minute: 30,
          createdAt: createdAt,
        ),
        _r(
          title: 'Nghỉ mắt 20-20-20 & Uống nước',
          note:
              'Uống 150–200ml nước, đứng dậy vươn vai và nhìn xa 6 mét để bảo vệ mắt.',
          category: ReminderCategory.hydration,
          isRoutine: true,
          hour: 8,
          minute: 30,
          repeat: RepeatType.interval,
          intervalMinutes: 90,
          endHour: 20,
          endMinute: 0,
          createdAt: createdAt,
        ),
        _r(
          title: 'Bữa trưa chuẩn đĩa ăn 2:1:1',
          note:
              '1/2 rau xanh củ quả, 1/4 đạm nạc (cá, ức gà, đậu phụ), 1/4 tinh bột vừa phải để tránh lờ đờ.',
          category: ReminderCategory.meal,
          isRoutine: true,
          hour: 12,
          minute: 0,
          createdAt: createdAt,
        ),
        _r(
          title: 'Ngủ trưa ngắn (Power Nap 20 phút)',
          note:
              'Chợp mắt 15–20 phút để khôi phục sự tỉnh táo mà không bị đau đầu.',
          category: ReminderCategory.sleep,
          isRoutine: true,
          hour: 13,
          minute: 0,
          createdAt: createdAt,
        ),
        _r(
          title: 'Shallow Work: Email, họp & việc nhẹ',
          note:
              'Xử lý email, trao đổi nhóm, rà soát công việc tồn đọng trong ngày.',
          category: ReminderCategory.task,
          isRoutine: false,
          priority: 2,
          hour: 14,
          minute: 0,
          createdAt: createdAt,
        ),
        _r(
          title: 'Ngừng Caffeine (Cà phê / Trà đậm)',
          note:
              'Ngừng caffeine 8 giờ trước khi ngủ để không làm giảm giấc ngủ sâu ban đêm.',
          category: ReminderCategory.hydration,
          isRoutine: true,
          hour: 14,
          minute: 45,
          createdAt: createdAt,
        ),
        _r(
          title: 'Bữa phụ chiều tỉnh táo',
          note:
              '1 hũ sữa chua không đường, 1 nắm hạt (hạnh nhân, óc chó) hoặc táo/ổi.',
          category: ReminderCategory.meal,
          isRoutine: true,
          hour: 16,
          minute: 0,
          createdAt: createdAt,
        ),
        _r(
          title: 'Tập thể dục / Vận động thể chất',
          note:
              'Đi bộ nhanh, chạy bộ, gym hoặc giãn cơ 30–45 phút khi thân nhiệt đạt tối ưu.',
          category: ReminderCategory.task,
          isRoutine: true,
          priority: 2,
          hour: 17,
          minute: 15,
          createdAt: createdAt,
        ),
        _r(
          title: 'Bữa tối nhẹ bụng, dễ tiêu',
          note:
              'Ưu tiên cá, rau luộc/canh ấm, đậu phụ, ít cơm; tránh đồ chiên rán nhiều dầu mỡ.',
          category: ReminderCategory.meal,
          isRoutine: true,
          hour: 18,
          minute: 30,
          createdAt: createdAt,
        ),
        _r(
          title: 'Ngừng ăn tối & đồ ăn vặt',
          note:
              'Kết thúc ăn 3 giờ trước khi ngủ để dạ dày nghỉ ngơi, chống trào ngược.',
          category: ReminderCategory.sleep,
          isRoutine: true,
          hour: 19,
          minute: 45,
          createdAt: createdAt,
        ),
        _r(
          title: 'Học code / Đọc tài liệu buổi tối',
          note: 'Học kỹ năng mới nhẹ nhàng hoặc đọc sách chuyên môn.',
          category: ReminderCategory.task,
          isRoutine: false,
          priority: 3,
          hour: 20,
          minute: 0,
          createdAt: createdAt,
        ),
        _r(
          title: 'Lên 3 việc quan trọng cho ngày mai (Rule of 3)',
          note:
              'Viết ra tối đa 3 việc ưu tiên cho ngày mai để giải phóng tâm trí trước khi ngủ.',
          category: ReminderCategory.task,
          isRoutine: true,
          priority: 2,
          hour: 21,
          minute: 15,
          createdAt: createdAt,
        ),
        _r(
          title: 'Chuẩn bị đi ngủ (Giảm ánh sáng xanh)',
          note:
              '45 phút trước ngủ: Tắt máy tính/điện thoại, giãn cơ nhẹ hoặc đọc sách giấy.',
          category: ReminderCategory.sleep,
          isRoutine: true,
          hour: 22,
          minute: 0,
          createdAt: createdAt,
        ),
        _r(
          title: 'Đi ngủ đúng giờ',
          note: 'Lên giường đi ngủ lúc 22:45 để đủ chu kỳ giấc ngủ 7.5 giờ.',
          category: ReminderCategory.sleep,
          isRoutine: true,
          hour: 22,
          minute: 45,
          createdAt: createdAt,
        ),
      ],
    );
  }

  static PresetProfile studentPreset({required String createdAt}) {
    const settings = UserSettings(
      selectedPreset: 'student',
      wakeTime: '06:00',
      sleepHours: 8.0,
      fallAsleepBufferMin: 15,
      breakfastTime: '06:30',
      lunchTime: '11:45',
      afternoonSnackTime: '15:30',
      dinnerTime: '18:30',
      dinnerCutoffHours: 3.0,
      caffeineCutoffHours: 8.0,
      windDownMin: 45,
      waterIntervalMin: 120,
    );

    return PresetProfile(
      id: PresetId.student,
      name: PresetId.student.displayName,
      description:
          'Thức 06:00, học ca sáng 07:30, tự học chiều 14:00, ôn bài tối 19:45 và ngủ đủ 8 giờ lúc 22:30.',
      defaultSettings: settings,
      reminders: [
        _r(
          title: 'Uống nước ấm & Đón nắng sáng',
          note: 'Uống 250ml nước ấm giúp tỉnh táo nhanh trước khi ăn sáng.',
          category: ReminderCategory.hydration,
          isRoutine: true,
          hour: 6,
          minute: 5,
          createdAt: createdAt,
        ),
        _r(
          title: 'Bữa sáng đủ năng lượng đi học',
          note:
              'Trứng, bánh mì nguyên cám, xôi/khoai lang kèm sữa hoặc bún ít béo thêm rau.',
          category: ReminderCategory.meal,
          isRoutine: true,
          hour: 6,
          minute: 30,
          createdAt: createdAt,
        ),
        _r(
          title: 'Ca học sáng / Môn chính (MIT)',
          note:
              'Tập trung cao độ môn học chính; nghỉ ngắn 5–10 phút giữa các tiết.',
          category: ReminderCategory.task,
          isRoutine: false,
          priority: 1,
          hour: 7,
          minute: 30,
          createdAt: createdAt,
        ),
        _r(
          title: 'Uống nước định kỳ mỗi 120 phút',
          note: 'Uống 180–200ml nước để não bộ tập trung tốt khi học.',
          category: ReminderCategory.hydration,
          isRoutine: true,
          hour: 8,
          minute: 0,
          repeat: RepeatType.interval,
          intervalMinutes: 120,
          endHour: 20,
          endMinute: 0,
          createdAt: createdAt,
        ),
        _r(
          title: 'Bữa trưa cân bằng dinh dưỡng',
          note: '1/2 rau củ, 1/4 đạm (thịt, cá, trứng, đậu phụ), 1/4 cơm vừa phải.',
          category: ReminderCategory.meal,
          isRoutine: true,
          hour: 11,
          minute: 45,
          createdAt: createdAt,
        ),
        _r(
          title: 'Ngủ trưa phục hồi 20 phút',
          note: 'Chợp mắt ngắn giúp tiếp thu bài buổi chiều hiệu quả hơn.',
          category: ReminderCategory.sleep,
          isRoutine: true,
          hour: 12,
          minute: 45,
          createdAt: createdAt,
        ),
        _r(
          title: 'Tự học / Làm bài tập buổi chiều',
          note: 'Làm bài tập về nhà và thực hành các môn theo kế hoạch.',
          category: ReminderCategory.task,
          isRoutine: false,
          priority: 1,
          hour: 14,
          minute: 0,
          createdAt: createdAt,
        ),
        _r(
          title: 'Bữa phụ chiều chống đói',
          note: 'Sữa chua, trái cây ít ngọt hoặc một nắm hạt.',
          category: ReminderCategory.meal,
          isRoutine: true,
          hour: 15,
          minute: 30,
          createdAt: createdAt,
        ),
        _r(
          title: 'Thể thao / Giải trí vận động',
          note: 'Chạy bộ, cầu lông, đá bóng hoặc đạp xe 30–45 phút.',
          category: ReminderCategory.task,
          isRoutine: true,
          priority: 2,
          hour: 17,
          minute: 0,
          createdAt: createdAt,
        ),
        _r(
          title: 'Bữa tối cùng gia đình',
          note: 'Ăn vừa đủ, ưu tiên rau xanh, canh ấm và đạm dễ tiêu.',
          category: ReminderCategory.meal,
          isRoutine: true,
          hour: 18,
          minute: 30,
          createdAt: createdAt,
        ),
        _r(
          title: 'Ôn bài tối & Chuẩn bị sách vở ngày mai',
          note: 'Tổng hợp lại kiến thức trong ngày và soạn sẵn cặp/đồ dùng.',
          category: ReminderCategory.task,
          isRoutine: true,
          priority: 2,
          hour: 19,
          minute: 45,
          createdAt: createdAt,
        ),
        _r(
          title: 'Chuẩn bị đi ngủ',
          note: 'Rời điện thoại 45 phút trước giờ ngủ để ngủ sâu giấc.',
          category: ReminderCategory.sleep,
          isRoutine: true,
          hour: 21,
          minute: 45,
          createdAt: createdAt,
        ),
        _r(
          title: 'Đi ngủ đúng giờ',
          note: 'Ngủ lúc 22:30 để đảm bảo đủ 8 giờ phục hồi trí nhớ.',
          category: ReminderCategory.sleep,
          isRoutine: true,
          hour: 22,
          minute: 30,
          createdAt: createdAt,
        ),
      ],
    );
  }

  static PresetProfile freelancerPreset({required String createdAt}) {
    const settings = UserSettings(
      selectedPreset: 'freelancer',
      wakeTime: '07:00',
      sleepHours: 7.5,
      fallAsleepBufferMin: 15,
      breakfastTime: '07:30',
      lunchTime: '12:30',
      afternoonSnackTime: '16:00',
      dinnerTime: '19:00',
      dinnerCutoffHours: 3.0,
      caffeineCutoffHours: 8.0,
      windDownMin: 45,
      waterIntervalMin: 105,
    );

    return PresetProfile(
      id: PresetId.freelancer,
      name: PresetId.freelancer.displayName,
      description:
          'Khởi động linh hoạt 07:00, 3 việc quan trọng nhất (MIT) lúc 09:00, xử lý khách hàng buổi chiều và ngủ 23:15.',
      defaultSettings: settings,
      reminders: [
        _r(
          title: 'Uống nước ấm khởi động ngày mới',
          note: 'Uống 250ml nước ấm ngay sau khi thức giấc lúc 07:00.',
          category: ReminderCategory.hydration,
          isRoutine: true,
          hour: 7,
          minute: 5,
          createdAt: createdAt,
        ),
        _r(
          title: 'Bữa sáng giữ ổn định đường huyết',
          note: 'Yến mạch, trứng, bơ, bánh mì nguyên cám; tránh bỏ bữa sáng.',
          category: ReminderCategory.meal,
          isRoutine: true,
          hour: 7,
          minute: 30,
          createdAt: createdAt,
        ),
        _r(
          title: '3 Việc quan trọng nhất (MIT Deep Work)',
          note:
              'Tắt thông báo mạng xã hội, hoàn thành các hạng mục tạo giá trị cao nhất.',
          category: ReminderCategory.task,
          isRoutine: false,
          priority: 1,
          hour: 9,
          minute: 0,
          createdAt: createdAt,
        ),
        _r(
          title: 'Uống nước & Giãn cơ giữa giờ',
          note: 'Uống 180–200ml nước và đứng lên vận động nhẹ 3 phút.',
          category: ReminderCategory.hydration,
          isRoutine: true,
          hour: 9,
          minute: 0,
          repeat: RepeatType.interval,
          intervalMinutes: 105,
          endHour: 20,
          endMinute: 30,
          createdAt: createdAt,
        ),
        _r(
          title: 'Bữa trưa cân bằng dinh dưỡng',
          note: '1/2 rau xanh, 1/4 đạm nạc, 1/4 tinh bột chậm.',
          category: ReminderCategory.meal,
          isRoutine: true,
          hour: 12,
          minute: 30,
          createdAt: createdAt,
        ),
        _r(
          title: 'Xử lý khách hàng & Việc nhẹ (Shallow Work)',
          note: 'Trả lời tin nhắn, họp online, gửi báo giá/tiến độ.',
          category: ReminderCategory.task,
          isRoutine: false,
          priority: 2,
          hour: 14,
          minute: 30,
          createdAt: createdAt,
        ),
        _r(
          title: 'Ngừng Caffeine',
          note: 'Ngừng cà phê và trà đậm trước 15:15 để không khó ngủ.',
          category: ReminderCategory.hydration,
          isRoutine: true,
          hour: 15,
          minute: 15,
          createdAt: createdAt,
        ),
        _r(
          title: 'Vận động giải tỏa căng thẳng',
          note: 'Tập thể dục, đi bộ hoặc gym 40 phút để tách biệt giờ làm và giờ nghỉ.',
          category: ReminderCategory.task,
          isRoutine: true,
          priority: 2,
          hour: 17,
          minute: 30,
          createdAt: createdAt,
        ),
        _r(
          title: 'Bữa tối nhẹ nhàng',
          note: 'Ăn đủ rau, đạm dễ tiêu, hạn chế ăn muộn khi chạy deadline.',
          category: ReminderCategory.meal,
          isRoutine: true,
          hour: 19,
          minute: 0,
          createdAt: createdAt,
        ),
        _r(
          title: 'Tổng kết thu/chi & Lịch ngày mai',
          note: 'Ghi chú tiến độ công việc, thu chi và chốt 3 việc cho ngày mai.',
          category: ReminderCategory.task,
          isRoutine: true,
          priority: 3,
          hour: 21,
          minute: 0,
          createdAt: createdAt,
        ),
        _r(
          title: 'Chuẩn bị đi ngủ',
          note: 'Ngừng làm việc và rời màn hình trước ngủ 45 phút.',
          category: ReminderCategory.sleep,
          isRoutine: true,
          hour: 22,
          minute: 30,
          createdAt: createdAt,
        ),
        _r(
          title: 'Đi ngủ đúng giờ',
          note: 'Ngủ lúc 23:15 để duy trì sức khỏe bền bỉ.',
          category: ReminderCategory.sleep,
          isRoutine: true,
          hour: 23,
          minute: 15,
          createdAt: createdAt,
        ),
      ],
    );
  }

  static PresetProfile seniorHealthPreset({required String createdAt}) {
    const settings = UserSettings(
      selectedPreset: 'senior_health',
      wakeTime: '05:30',
      sleepHours: 7.5,
      fallAsleepBufferMin: 15,
      breakfastTime: '06:30',
      lunchTime: '11:30',
      afternoonSnackTime: '15:30',
      dinnerTime: '18:00',
      dinnerCutoffHours: 3.5,
      caffeineCutoffHours: 8.0,
      windDownMin: 45,
      waterIntervalMin: 120,
    );

    return PresetProfile(
      id: PresetId.seniorHealth,
      name: PresetId.seniorHealth.displayName,
      description:
          'Nhịp sinh hoạt điều độ: thức 05:30, ăn nhẹ dễ tiêu, đo huyết áp/uống thuốc sáng, đi bộ chiều và ngủ sớm 21:30.',
      defaultSettings: settings,
      reminders: [
        _r(
          title: 'Uống nước ấm & Vận động khớp nhẹ nhàng',
          note: 'Uống 200ml nước ấm, xoay khớp cổ tay, cổ chân và hít thở sâu.',
          category: ReminderCategory.hydration,
          isRoutine: true,
          hour: 5,
          minute: 45,
          createdAt: createdAt,
        ),
        _r(
          title: 'Bữa sáng thanh đạm, ấm bụng',
          note:
              'Cháo yến mạch, phở/bún nước trong ít béo, trứng luộc hoặc khoai lang mềm.',
          category: ReminderCategory.meal,
          isRoutine: true,
          hour: 6,
          minute: 30,
          createdAt: createdAt,
        ),
        _r(
          title: 'Nhắc đo huyết áp / Uống thuốc sáng (nếu có)',
          note: 'Kiểm tra sức khỏe buổi sáng và uống thuốc theo hướng dẫn bác sĩ.',
          category: ReminderCategory.task,
          isRoutine: true,
          priority: 1,
          hour: 7,
          minute: 30,
          createdAt: createdAt,
        ),
        _r(
          title: 'Uống nước đều trong ngày (Ngừng sau 19:30)',
          note:
              'Uống từng ngụm nhỏ 150ml; hạn chế uống nhiều nước buổi tối để tránh tiểu đêm.',
          category: ReminderCategory.hydration,
          isRoutine: true,
          hour: 8,
          minute: 0,
          repeat: RepeatType.interval,
          intervalMinutes: 120,
          endHour: 19,
          endMinute: 30,
          createdAt: createdAt,
        ),
        _r(
          title: 'Đọc báo / Chăm cây / Thư giãn buổi sáng',
          note: 'Hoạt động nhẹ giúp tinh thần vui vẻ, minh mẫn.',
          category: ReminderCategory.task,
          isRoutine: true,
          priority: 3,
          hour: 9,
          minute: 0,
          createdAt: createdAt,
        ),
        _r(
          title: 'Bữa trưa mềm, dễ tiêu & ít muối',
          note: 'Ưu tiên cá, đậu phụ, rau củ luộc mềm, canh ấm; giảm đồ mặn và mỡ.',
          category: ReminderCategory.meal,
          isRoutine: true,
          hour: 11,
          minute: 30,
          createdAt: createdAt,
        ),
        _r(
          title: 'Nghỉ trưa thư giãn 20–30 phút',
          note: 'Nằm nghỉ nhẹ nhàng giúp ổn định tim mạch buổi chiều.',
          category: ReminderCategory.sleep,
          isRoutine: true,
          hour: 12,
          minute: 30,
          createdAt: createdAt,
        ),
        _r(
          title: 'Đi bộ chiều nhẹ nhàng',
          note: 'Đi bộ 20–30 phút nơi thoáng mát, hít thở đều.',
          category: ReminderCategory.task,
          isRoutine: true,
          priority: 2,
          hour: 16,
          minute: 30,
          createdAt: createdAt,
        ),
        _r(
          title: 'Bữa tối sớm, thanh đạm',
          note: 'Ăn nhẹ, ít dầu mỡ, kết thúc sớm trước giờ ngủ ít nhất 3 giờ.',
          category: ReminderCategory.meal,
          isRoutine: true,
          hour: 18,
          minute: 0,
          createdAt: createdAt,
        ),
        _r(
          title: 'Ngâm chân nước ấm & Thư giãn trước ngủ',
          note: 'Ngâm chân nước ấm 10–15 phút giúp lưu thông máu và dễ ngủ.',
          category: ReminderCategory.sleep,
          isRoutine: true,
          hour: 20,
          minute: 30,
          createdAt: createdAt,
        ),
        _r(
          title: 'Đi ngủ đúng giờ',
          note: 'Lên giường đi ngủ lúc 21:30 trong phòng yên tĩnh.',
          category: ReminderCategory.sleep,
          isRoutine: true,
          hour: 21,
          minute: 30,
          createdAt: createdAt,
        ),
      ],
    );
  }

  /// Sinh danh sách nhắc cá nhân hóa (Ăn, Uống nước, Ngủ) từ [UserSettings] & [BodyProfile].
  static List<Reminder> buildPersonalizedRoutineReminders({
    required UserSettings settings,
    required BodyProfile profile,
    String? createdAt,
  }) {
    final stamp = createdAt ?? DateTime.now().toIso8601String();
    final wake = ClockTime.parse(settings.wakeTime);

    final initialSleep = SleepPlanner.calculate(
      wakeTime: wake,
      sleepHours: settings.sleepHours,
      fallAsleepBufferMin: settings.fallAsleepBufferMin,
      dinnerCutoffHours: settings.dinnerCutoffHours,
      caffeineCutoffHours: settings.caffeineCutoffHours,
      windDownMin: settings.windDownMin,
    );

    final plan = BodyNutritionAnalyzer.analyze(
      profile,
      wakeTime: wake,
      bedtime: initialSleep.bedtime,
    );

    final sleep = SleepPlanner.calculate(
      wakeTime: wake,
      sleepHours: settings.sleepHours,
      fallAsleepBufferMin: settings.fallAsleepBufferMin,
      dinnerCutoffHours: plan.recommendedDinnerCutoffHours,
      caffeineCutoffHours: plan.recommendedCaffeineCutoffHours,
      windDownMin: settings.windDownMin,
    );

    final list = <Reminder>[];

    for (final meal in plan.mealScheduleRecommendations) {
      list.add(
        _r(
          title: meal.title,
          note: meal.foodAdvice,
          category: meal.category,
          isRoutine: true,
          hour: meal.hour,
          minute: meal.minute,
          createdAt: stamp,
        ),
      );
    }

    list.add(
      _r(
        title: 'Uống nước định kỳ (${plan.dailyWaterMl}ml/ngày)',
        note:
            'Uống ~220ml mỗi ${plan.waterIntervalMin} phút trong khung '
            '${ClockTime(plan.waterStartHour, plan.waterStartMinute).format24h()}–'
            '${ClockTime(plan.waterEndHour, plan.waterEndMinute).format24h()}.',
        category: ReminderCategory.hydration,
        isRoutine: true,
        hour: plan.waterStartHour,
        minute: plan.waterStartMinute,
        repeat: RepeatType.interval,
        intervalMinutes: plan.waterIntervalMin,
        endHour: plan.waterEndHour,
        endMinute: plan.waterEndMinute,
        createdAt: stamp,
      ),
    );

    list.addAll([
      _r(
        title: 'Ngừng Caffeine',
        note:
            'Ngừng cà phê, trà đậm và nước tăng lực ${plan.recommendedCaffeineCutoffHours.toStringAsFixed(0)} giờ trước khi ngủ.',
        category: ReminderCategory.hydration,
        isRoutine: true,
        hour: sleep.caffeineCutoff.hour,
        minute: sleep.caffeineCutoff.minute,
        createdAt: stamp,
      ),
      _r(
        title: 'Ngừng ăn tối & đồ ăn vặt',
        note:
            'Kết thúc ăn ${plan.recommendedDinnerCutoffHours.toStringAsFixed(1)} giờ trước ngủ để dạ dày nghỉ ngơi.',
        category: ReminderCategory.sleep,
        isRoutine: true,
        hour: sleep.dinnerStop.hour,
        minute: sleep.dinnerStop.minute,
        createdAt: stamp,
      ),
      _r(
        title: 'Chuẩn bị đi ngủ',
        note: plan.sleepAdviceNote,
        category: ReminderCategory.sleep,
        isRoutine: true,
        hour: sleep.windDown.hour,
        minute: sleep.windDown.minute,
        createdAt: stamp,
      ),
      _r(
        title: 'Đi ngủ đúng giờ',
        note:
            'Mục tiêu ngủ ${settings.sleepHours} giờ, dậy lúc ${wake.format24h()}.',
        category: ReminderCategory.sleep,
        isRoutine: true,
        hour: sleep.bedtime.hour,
        minute: sleep.bedtime.minute,
        createdAt: stamp,
      ),
    ]);

    return list;
  }

  static Reminder _r({
    required String title,
    required String note,
    required ReminderCategory category,
    required bool isRoutine,
    int priority = 2,
    required int hour,
    required int minute,
    RepeatType repeat = RepeatType.daily,
    int? intervalMinutes,
    int? endHour,
    int? endMinute,
    required String createdAt,
  }) {
    return Reminder(
      title: title,
      note: note,
      category: category,
      isRoutine: isRoutine,
      priority: priority,
      hour: hour,
      minute: minute,
      repeat: repeat,
      intervalMinutes: intervalMinutes,
      endHour: endHour,
      endMinute: endMinute,
      enabled: true,
      createdAt: createdAt,
    );
  }
}
