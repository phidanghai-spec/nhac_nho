# Tài liệu phát triển app Lịch nhắc nhở: Công việc, Ăn uống, Giấc ngủ & Thói quen
Dành cho PhiDang · Công cụ viết code: Antigravity · Nền tảng: Flutter (Android trước, iOS sau) · Cập nhật 17/11/2026 (Phiên bản 2.1 - Đã hợp nhất BodyProfile, Gym, Ăn chay & Ca đêm)

**Cách dùng tài liệu:** Lưu file này vào repo thành `docs/DEV_GUIDE.md`. Các prompt ở mục 12 và 15.5 yêu cầu Antigravity đọc file đó, nên chỉ cần thực hiện theo thứ tự từng Phase.

---

## 1. Quyết định nền tảng

| Tiêu chí | Flutter | React Native | Web (PWA) |
| :--- | :--- | :--- | :--- |
| Thông báo hẹn giờ khi app đã đóng | Tốt (`flutter_local_notifications`) | Tốt (`Notifee`) | Kém, trình duyệt không đảm bảo |
| Tài liệu và ví dụ cho lịch nhắc lặp & chu kỳ | Nhiều, đã kiểm tra ở bước tìm tài liệu | Có | Hạn chế |
| Chạy trên điện thoại thật | Có | Có | Có nhưng hạn chế quyền |
| Hợp với Antigravity | Tốt, dự án có cấu trúc rõ | Tốt | Tốt |

**Chốt:** Flutter, tập trung Android trước vì test trên máy thật dễ hơn, iOS làm sau khi Android ổn. Dart có cú pháp gần C# nên đọc code do agent viết sẽ không khó.

**Lý do loại web:** App nhắc việc và ăn uống phải rung chuông khi điện thoại khóa màn hình và app đã tắt, điều mà trang web không làm đáng tin.

---

## 2. Phạm vi MVP (Nâng cấp từ mô hình HabitMaker + Loop Habit Tracker + WaterMe)

### Có trong MVP
- **4 loại nhắc & hoạt động:**
  1. `task` (Công việc cần làm trong ngày – Work Schedule).
  2. `meal` (Ăn uống & Thực phẩm gợi ý – Daily Routine).
  3. `hydration` (Chu kỳ sinh học: Uống nước định kỳ & Nghỉ giải lao giữa giờ làm – học từ `WaterMe`).
  4. `sleep` (Ngủ nghỉ & Chuẩn bị ngủ).
- **2 luồng quản lý rõ ràng trên màn hình Hôm nay (học từ `GavinBDev/HabitMaker` & `SubhamTyagi/ToDo`):**
  - **Lịch việc trong ngày (Work Schedule):** Danh sách công việc theo khung giờ Năng lượng cao / Vừa / Nhẹ, có mức ưu tiên (Quan trọng nhất - MIT, Bình thường).
  - **Thói quen sinh hoạt (Daily Routine):** Lịch lặp lại cố định cho ăn sáng/trưa/tối, uống nước, tập thể dục, ngủ nghỉ.
- **4 Kiểu lặp:** một lần (`once`), hằng ngày (`daily`), các thứ trong tuần (`weekly`), và **lặp theo chu kỳ phút trong khung giờ thức (`interval`)** (ví dụ: nhắc uống nước mỗi 90 phút từ 07:00 đến 20:00).
- **4 Bộ lịch mẫu (Profile Presets) dùng ngay cho mọi đối tượng:**
  1. *Lập trình viên / Dân văn phòng* (`office_coder`)
  2. *Học sinh / Sinh viên* (`student`)
  3. *Người làm tự do (Freelancer)* (`freelancer`)
  4. *Người lớn tuổi / Chăm sóc sức khỏe* (`senior_health`)
- **Thống kê trực quan Offline (học từ `iSoron/uhabits`):** Chuỗi ngày duy trì (Streak) và biểu đồ tỷ lệ hoàn thành 7 ngày gần nhất cho Việc làm, Ăn đúng giờ, Uống nước và Giấc ngủ.
- **Màn hình Thể trạng, Dinh dưỡng & Giấc ngủ:**
  - Nhập thể trạng (Tuổi, Giới tính, Chiều cao, Cân nặng, Vận động, Mục tiêu, Chế độ ăn Đa dạng/Ăn chay trứng sữa/Thuần chay, Ca làm việc Ban ngày/Ca đêm/Xoay ca, Tập Gym & giờ tập, Lưu ý sức khỏe: Bình thường/Đau dạ dày/Đường huyết/Lớn tuổi).
  - Tính BMI (chuẩn Châu Á), BMR, TDEE, lượng đạm/ngày, tỷ lệ đĩa ăn, tổng lượng nước & chu kỳ uống nước, giờ đi ngủ, ngừng ăn tối, ngừng caffeine, chuẩn bị ngủ và thực đơn gợi ý cá nhân hóa.
- **Thông báo cục bộ 100% Offline:** Không cần server, không cần tài khoản.
- **Màn hình Cài đặt:** Chọn Bộ lịch mẫu (Preset), chỉnh giờ mặc định, kiểm tra quyền thông báo, báo thức chính xác, tối ưu pin theo hãng máy.

### Ngoài MVP (làm sau)
- Đồng bộ đám mây, đăng nhập.
- Theo dõi giấc ngủ bằng cảm biến.
- Đếm calo chi tiết từng gam, nhận diện món ăn bằng AI.
- Push từ server (FCM).

---

## 3. Kiến trúc và cấu trúc thư mục (Cập nhật thêm BodyProfile & NutritionAnalyzer)

Chia 4 tầng, phụ thuộc một chiều: `presentation → application → domain ← data`. Tầng `domain` là Dart thuần, không import Flutter, để test đơn vị dễ.

```text
nhac_nho/
├─ docs/DEV_GUIDE.md
├─ lib/
│  ├─ main.dart
│  ├─ core/
│  │  ├─ constants.dart                  // tên channel, key cài đặt
│  │  └─ time_utils.dart                 // nextInstanceOf, intervalSlots, format giờ 24h
│  ├─ domain/
│  │  ├─ entities/reminder.dart
│  │  ├─ entities/user_settings.dart
│  │  ├─ entities/body_profile.dart      // MỚI: Chiều cao, cân nặng, tuổi, mục tiêu, bệnh lý, ăn chay, ca làm, gym
│  │  ├─ entities/nutrition_plan.dart    // MỚI: Kết quả BMI, TDEE, đạm, nước, khung giờ & thực đơn
│  │  ├─ entities/completion_log.dart
│  │  ├─ entities/preset_profile.dart    // cấu hình mẫu cho 4 nhóm đối tượng
│  │  ├─ repositories/reminder_repository.dart   // abstract
│  │  ├─ repositories/settings_repository.dart   // abstract
│  │  ├─ services/notification_scheduler.dart    // abstract
│  │  ├─ logic/sleep_planner.dart                // thuần Dart: tính giờ ngủ, ngừng ăn, ngừng cafe
│  │  ├─ logic/body_nutrition_analyzer.dart      // MỚI: Thuần Dart phân tích thể trạng -> lịch ăn & thực phẩm
│  │  ├─ logic/work_meal_guide.dart              // thuần Dart: gợi ý thực phẩm & phân bổ việc
│  │  └─ logic/habit_stats_calculator.dart       // thuần Dart: tính streak & tỷ lệ 7 ngày (uhabits)
│  ├─ data/
│  │  ├─ db/app_database.dart                    // sqflite
│  │  ├─ reminder_repository_impl.dart
│  │  ├─ settings_repository_impl.dart           // shared_preferences
│  │  └─ notification_scheduler_impl.dart        // flutter_local_notifications
│  ├─ application/
│  │  ├─ providers.dart                          // Riverpod
│  │  └─ reminder_controller.dart
│  └─ presentation/
│     ├─ router.dart                             // go_router
│     ├─ theme/
│     │  ├─ app_theme.dart                       // FlexColorScheme + Dynamic Color + High Contrast
│     │  └─ category_style.dart                  // Màu, Icon, Nhãn cho 4 loại nhắc
│     ├─ screens/
│     │  ├─ home_screen.dart                     // Tách 2 khu: Công việc & Thói quen + Thanh tiến độ
│     │  ├─ reminder_form_screen.dart
│     │  ├─ sleep_planner_screen.dart            // Phân tích Thể trạng - Dinh dưỡng & Giấc ngủ
│     │  ├─ stats_screen.dart                    // Biểu đồ chuỗi thói quen 7 ngày (học từ uhabits)
│     │  └─ settings_screen.dart                 // Chọn Preset mẫu, Giờ mặc định, Quyền hệ thống
│     └─ widgets/
└─ test/
   ├─ domain/sleep_planner_test.dart
   ├─ domain/body_nutrition_analyzer_test.dart   // MỚI: Test tính BMI, TDEE, nước, ăn chay, gym, ca đêm, bệnh lý
   ├─ domain/habit_stats_calculator_test.dart
   ├─ data/reminder_repository_test.dart
   └─ application/reminder_controller_test.dart
```

Mẫu thiết kế dùng: Repository (data), Strategy cho kiểu lặp (`once`/`daily`/`weekly`/`interval`), Factory cho Bộ lịch mẫu (`PresetProfile`), Dependency Injection qua Riverpod.

---

## 4. Package

Dùng bản mới nhất tương thích với Flutter đang cài (chạy `flutter pub add`, không ghim phiên bản cũ copy từ bài hướng dẫn). Khi API khác, làm theo README hiện tại của plugin.

| Package | Dùng để |
| :--- | :--- |
| `flutter_riverpod` | Quản lý state, DI |
| `go_router` | Điều hướng |
| `sqflite`, `path` | Lưu danh sách nhắc và lịch sử hoàn thành (SQLite) |
| `shared_preferences` | Lưu cài đặt người dùng, BodyProfile và Preset đã chọn |
| `flutter_local_notifications` | Lên lịch thông báo cục bộ |
| `timezone`, `flutter_timezone` | Tính giờ theo múi giờ máy |
| `permission_handler` | Xin quyền thông báo, tối ưu pin |
| `intl` | Định dạng ngày giờ tiếng Việt |
| `flex_color_scheme`, `dynamic_color` | Tạo theme Material 3 sáng/tối chuẩn đẹp, đồng bộ màu máy |
| `google_fonts` | Phông chữ hiển thị rõ dấu tiếng Việt cho mọi lứa tuổi |
| `flutter_animate` | Hiệu ứng chuyển động nhẹ nhàng |
| `mocktail` (dev) | Mock khi viết unit test |
| `sqflite_common_ffi` (dev) | Test database SQLite trực tiếp trên máy tính |

---

## 5. Mô hình dữ liệu

### `Reminder` (`reminders`)
| Trường | Kiểu | Ghi chú |
| :--- | :--- | :--- |
| `id` | `int` | Khóa chính, tự tăng |
| `title` | `text` | Tên nhắc (VD: "Bữa sáng giàu đạm", "Deep Work: Học code") |
| `note` | `text`, null | Ghi chú / Gợi ý thực phẩm hoặc cách thực hiện |
| `category` | `enum` | `task` (Công việc), `meal` (Ăn uống), `hydration` (Uống nước/Giải lao), `sleep` (Ngủ nghỉ) |
| `isRoutine` | `int` 0/1 | 1 = Thói quen cố định mỗi ngày (Routine), 0 = Việc làm cụ thể (Work Schedule) |
| `priority` | `int` | 1 = Quan trọng nhất (MIT), 2 = Bình thường, 3 = Nhẹ nhàng |
| `hour`, `minute` | `int` | Giờ bắt đầu (24h) |
| `repeat` | `enum` | `once`, `daily`, `weekly`, `interval` |
| `intervalMinutes` | `int`, null | Chu kỳ lặp bằng phút (VD: 90 hoặc 120 phút), dùng khi `repeat == interval` |
| `endHour`, `endMinute` | `int`, null | Giờ kết thúc chu kỳ trong ngày (VD: 20:00), dùng khi `repeat == interval` |
| `weekdaysMask` | `int` | Bit 0 = Thứ 2 … bit 6 = Chủ nhật; dùng khi `weekly` |
| `date` | `text`, null | `yyyy-MM-dd`, dùng khi `once` |
| `enabled` | `int` 0/1 | Bật/tắt |
| `createdAt` | `text` | ISO 8601 |

### `CompletionLog` (`completion_logs`)
- `id` (`int`), `reminderId` (`int`), `date` (`yyyy-MM-dd`), `status` (`done`, `skipped`), `completedAt` (`text` ISO 8601).

### `UserSettings` (`shared_preferences`)
- `selectedPreset`: `office_coder` (mặc định), `student`, `freelancer`, `senior_health`.
- `wakeTime` (mặc định `06:30`), `sleepHours` (mặc định `7.5`), `fallAsleepBufferMin` (mặc định `15`).
- `breakfastTime` (`07:00`), `lunchTime` (`12:00`), `afternoonSnackTime` (`16:00`), `dinnerTime` (`18:30`).
- `dinnerCutoffHours` (mặc định `3.0`), `caffeineCutoffHours` (mặc định `8.0`), `windDownMin` (mặc định `45`).
- `waterIntervalMin` (mặc định `120` phút).

### `BodyProfile` (Lưu trong `shared_preferences` qua `SettingsRepository`)
| Trường | Kiểu | Mặc định | Ghi chú |
| :--- | :--- | :--- | :--- |
| `age` | `int` | `25` | Tuổi (10–100) |
| `gender` | `enum` | `male` | `male`, `female` |
| `heightCm` | `double` | `168.0` | Chiều cao (cm) |
| `weightKg` | `double` | `62.0` | Cân nặng (kg) |
| `activityLevel` | `enum` | `sedentary` | `sedentary` (1.2), `light` (1.375), `moderate` (1.55), `active` (1.725) |
| `goal` | `enum` | `maintain` | `loseWeight`, `maintain`, `gainWeight` |
| `condition` | `enum` | `none` | `none`, `stomachReflux` (Đau dạ dày/Trào ngược), `bloodSugar` (Đường huyết), `seniorCardio` (Lớn tuổi/Tim mạch) |
| `dietType` | `enum` | `omnivore` | `omnivore` (Ăn đa dạng), `vegetarian` (Ăn chay trứng sữa), `vegan` (Thuần chay) |
| `workShift` | `enum` | `dayShift` | `dayShift` (Ban ngày), `nightShift` (Ca đêm), `rotatingShift` (Xoay ca) |
| `isGymGoer` | `bool` | `false` | Có tập gym/thể hình hay không |
| `workoutHour` | `int` | `17` | Giờ tập (24h) |
| `workoutMinute` | `int` | `0` | Phút tập |

### `NutritionPlan` (Kết quả phân tích từ `BodyNutritionAnalyzer.analyze(BodyProfile, wakeTime, bedtime)`)
- `bmi` (`double`), `bmiCategory` (`String`: Thiếu cân / Cân đối / Thừa cân / Béo phì).
- `bmr` (`int`), `tdee` (`int`), `targetCalories` (`int`: Calo khuyến nghị mỗi ngày).
- `dailyProteinGramsMin` (`int`), `dailyProteinGramsMax` (`int`).
- `plateRatioText` (`String`: Tỷ lệ đĩa ăn Rau - Đạm - Tinh bột phù hợp mục tiêu).
- `dailyWaterMl` (`int`: Tổng lượng nước ml/ngày), `waterIntervalMin` (`int`: Số phút giữa 2 lần nhắc uống nước).
- `waterStartHour` (`int`), `waterStartMinute` (`int`), `waterEndHour` (`int`), `waterEndMinute` (`int`) // Tự động xoay theo ca ngày hoặc ca đêm.
- `recommendedDinnerCutoffHours` (`double`: 3.0h cho người thường, 3.5h cho giảm cân/đường huyết, 4.0h cho đau dạ dày/trào ngược).
- `recommendedCaffeineCutoffHours` (`double`: 8.0h cho ca ngày, 7.0h cho ca đêm).
- `sleepAdviceNote` (`String`: ghi chú nhắc ngủ phù hợp, VD ca đêm hạn chế ánh nắng gắt & kéo rèm tối).
- `mealScheduleRecommendations` (`List<MealRecommendation>`): Gồm `hour`, `minute`, `title`, `foodAdvice` (nên ăn gì, hạn chế gì đã lọc theo `dietType`, `workShift`, `isGymGoer`, `goal`, `condition`) và các nhắc nhở bổ trợ (VD Pre/Post-workout, đi bộ sau ăn tối).

---

## 6. Logic nghiệp vụ, Dinh dưỡng & Phân chia công việc chuẩn khoa học

### 6.1 Khung giờ Ăn uống & Gợi ý thực phẩm tích hợp sẵn trong App (`work_meal_guide.dart`)
Mỗi lời nhắc ăn uống trong app không chỉ báo giờ mà còn kèm note gợi ý thực phẩm dễ áp dụng cho mọi gia đình Việt Nam:

| Bữa / Nhắc | Giờ mặc định | Loại | Nguyên tắc dinh dưỡng & Thực phẩm gợi ý (hiển thị trong note của nhắc) |
| :--- | :--- | :--- | :--- |
| Uống nước ấm sáng | `06:35` | `hydration` | Uống 200–300ml nước ấm ngay sau khi thức dậy để bù nước sau đêm dài và kích hoạt tiêu hóa. |
| Bữa sáng | `07:00` | `meal` | Tinh bột chậm + Đạm + Chất xơ: Trứng, yến mạch, bánh mì nguyên cám, khoai lang, hoặc bún/phở ít béo thêm rau. Hạn chế đồ ngọt tinh luyện để không buồn ngủ lúc 10h sáng. |
| Bữa trưa | `12:00` | `meal` | Quy tắc Đĩa ăn 2:1:1: 1/2 rau xanh/củ quả, 1/4 đạm nạc (cá, ức gà, đậu phụ, thịt nạc), 1/4 cơm/tinh bột vừa phải. Tránh ăn quá no tinh bột gây lờ đờ đầu giờ chiều. |
| Ngừng Caffeine | Tính từ giờ ngủ (6.3) | `hydration` | Ngừng cà phê, trà đậm, nước tăng lực 8 giờ trước khi ngủ (khoảng 14:30) để không làm giảm giấc ngủ sâu ban đêm. |
| Bữa phụ chiều | `16:00` | `meal` | Nạp nhẹ chống đói: 1 hũ sữa chua không đường, 1 nắm hạt (hạnh nhân, óc chó, hạt điều) hoặc trái cây ít ngọt (táo, ổi, chuối) giúp giữ tỉnh táo cuối chiều. |
| Bữa tối | `18:30` | `meal` | Nhẹ bụng, dễ tiêu: Ưu tiên cá, rau luộc/canh ấm, đậu phụ, ít cơm. Tránh đồ chiên rán nhiều dầu mỡ, đồ cay nóng hoặc ăn quá no. |
| Uống nước định kỳ | Mỗi 120 phút (`08:30–20:00`) | `hydration` | Uống 150–200ml nước mỗi lần nhắc (tổng ~1.8–2.2 lít/ngày). Ngừng uống nhiều nước sau 20:00 để tránh thức giấc đi tiểu đêm. |
| Ngừng ăn tối | Tính từ giờ ngủ (6.3) | `sleep` | Kết thúc bữa tối và đồ ăn vặt 3 giờ trước khi ngủ (19:45) để dạ dày được nghỉ ngơi, chống trào ngược. |
| Chuẩn bị đi ngủ | Tính từ giờ ngủ (6.3) | `sleep` | 45 phút trước giờ ngủ (22:00): Tắt máy tính/điện thoại, giảm ánh sáng xanh, giãn cơ nhẹ hoặc đọc sách giấy. |
| Đi ngủ | Tính từ giờ ngủ (6.3) | `sleep` | Lên giường đi ngủ (22:45) để đảm bảo đủ chu kỳ giấc ngủ 7.5 giờ. |

### 6.2 Khung giờ Công việc & Phân chia công việc cho mọi người (Time Blocking & Nhịp sinh học)

#### A. Nguyên tắc phân chia công việc trong ngày
- **Ca Sáng – Đỉnh tập trung (Deep Work: 08:00 – 11:30):**
  - Não bộ tỉnh táo nhất sau bữa sáng. Dành cho 1–2 Việc Quan Trọng Nhất (MIT - Priority 1): học lập trình, giải quyết việc khó, viết lách, học môn chính.
  - Áp dụng nhịp 50 phút tập trung – 10 phút nghỉ giải lao (đứng dậy vươn vai, nhìn xa 6 mét bảo vệ mắt).
- **Giờ Nghỉ Trưa – Phục hồi (11:30 – 13:30):**
  - Ăn trưa lúc 12:00, đi bộ nhẹ 10 phút, và Ngủ trưa ngắn (Power Nap 15–20 phút lúc 13:00) để khôi phục sự tỉnh táo mà không bị đau đầu.
- **Ca Chiều – Phối hợp & Hoàn tất (13:30 – 17:30):**
  - 13:30 – 15:30 (Vùng trũng sinh học): Xử lý Việc nhẹ / Hành chính (Shallow Work - Priority 2 & 3) như trả lời email, họp hành, dọn dẹp, việc lặp lại.
  - 15:30 – 17:00 (Đỉnh năng lượng thứ hai): Hoàn tất việc tồn đọng trong ngày.
  - 17:00 – 18:00: Vận động thể chất / Tập thể dục (đi bộ nhanh, chạy bộ, gym, thể thao) khi thân nhiệt đạt mức tối ưu.
- **Buổi Tối – Tổng kết & Thư giãn (19:30 – 22:00):**
  - 19:30 – 21:00: Học kỹ năng mới nhẹ nhàng / Đọc sách / Dành thời gian cho gia đình.
  - 21:00 – 21:15: Lên danh sách 3 việc cần làm cho ngày mai (Rule of 3) để giải phóng tâm trí trước khi ngủ.

#### B. 4 Bộ lịch mẫu (Presets) tích hợp sẵn trong `preset_profile.dart` & `work_meal_guide.dart`
Người dùng chọn 1 trong 4 bộ mẫu khi mở app lần đầu (hoặc đổi trong Cài đặt), app sẽ tự động tạo bộ nhắc nhở phù hợp:
1. **Lập trình viên / Dân văn phòng (`office_coder` - Mặc định):**
   Thức 06:30 · Ăn sáng 07:00 · Deep Work / Code ca sáng 08:30 · Nhắc nghỉ mắt & uống nước mỗi 90 phút · Ăn trưa 12:00 · Ngủ trưa 20p 13:00 · Việc chiều 14:00 · Bữa phụ 16:00 · Tập thể dục 17:15 · Ăn tối 18:30 · Học code/Đọc tài liệu tối 20:00 · Lên lịch ngày mai 21:15 · Chuẩn bị ngủ 22:00 · Ngủ 22:45.
2. **Học sinh / Sinh viên (`student`):**
   Thức 06:00 · Ăn sáng 06:30 · Ca học sáng 07:30 · Ăn trưa 11:45 · Ngủ trưa 12:45 · Tự học/Làm bài tập chiều 14:00 · Thể thao/Giải trí 17:00 · Ăn tối 18:30 · Ôn bài tối & Chuẩn bị sách vở 19:45 · Chuẩn bị ngủ 21:45 · Ngủ 22:30.
3. **Người làm tự do (`freelancer`):**
   Thức 07:00 · Ăn sáng 07:30 · 3 Việc quan trọng nhất (MIT) 09:00 · Ăn trưa 12:30 · Xử lý khách hàng & Việc nhẹ 14:30 · Vận động 17:30 · Ăn tối 19:00 · Tổng kết thu/chi & Lịch mai 21:00 · Ngủ 23:15.
4. **Người lớn tuổi / Chăm sóc sức khỏe (`senior_health`):**
   Thức 05:30 · Uống nước ấm & Vận động nhẹ 05:45 · Ăn sáng thanh đạm 06:30 · Nhắc uống thuốc/Đo huyết áp sáng (nếu có) 07:30 · Đọc báo/Chăm cây/Thư giãn 09:00 · Ăn trưa 11:30 · Nghỉ trưa 12:30 · Đi bộ chiều 16:30 · Ăn tối nhẹ 18:00 · Ngâm chân nước ấm/Thư giãn 20:30 · Đi ngủ 21:30.

### 6.3 `SleepPlanner` (hàm thuần, có test)
```text
bedtime        = wakeTime − sleepHours − fallAsleepBufferMin
dinnerStop     = bedtime − dinnerCutoffHours
caffeineCutoff = bedtime − caffeineCutoffHours
windDown       = bedtime − windDownMin
```
Ví dụ dùng làm test: Thức 06:30, ngủ 7.5 giờ, đệm 15 phút → đi ngủ 22:45, ngừng ăn 19:45 (cutoff 3 giờ), ngừng cà phê 14:45 (cutoff 8 giờ), chuẩn bị ngủ 22:00. Phải xử lý trường hợp vượt nửa đêm (cả khi giờ ngủ rơi vào ngày hôm trước như thức 06:30 ngủ 22:45, lẫn người làm ca đêm thức 16:00 ngủ 08:00 sáng hôm sau).

### 6.4 `HabitStatsCalculator` (học từ `iSoron/uhabits`, hàm thuần, có test)
- **Tính Chuỗi ngày liên tiếp (Current Streak):** số ngày liên tiếp tính đến hôm nay (hoặc hôm qua nếu hôm nay chưa hết ngày / chưa hoàn thành đủ) mà người dùng hoàn thành >= 80% các mục `isRoutine == 1`.
- **Tính Tỷ lệ hoàn thành 7 ngày gần nhất (`Map<String, double>`):** tỷ lệ `done / total` cho từng ngày để vẽ thanh tiến độ 7 ngày trên màn hình Thống kê.

### 6.5 Quy tắc xử lý trong `BodyNutritionAnalyzer` & Validation (Thuần Dart, có Unit Test)

1. **Tính chỉ số cơ bản:**
   - **BMI (Chuẩn Châu Á IDI & WPRO):** `bmi = weightKg / pow(heightCm / 100, 2)`
     - `< 18.5`: Thiếu cân | `18.5 – 22.9`: Cân đối | `23.0 – 24.9`: Thừa cân | `>= 25.0`: Béo phì.
   - **BMR (Mifflin-St Jeor):**
     - Nam: `10 * weightKg + 6.25 * heightCm - 5 * age + 5`
     - Nữ: `10 * weightKg + 6.25 * heightCm - 5 * age - 161`
   - **TDEE & Target Calories:**
     - `tdee = round(bmr * activityMultiplier)` (`sedentary` 1.2, `light` 1.375, `moderate` 1.55, `active` 1.725)
     - `targetCalories`: Giảm cân (`loseWeight`) = `max(1200, tdee - 400)`, Giữ cân (`maintain`) = `tdee`, Tăng cân (`gainWeight`) = `tdee + 350`.
   - **Đạm hằng ngày:**
     - Nếu `isGymGoer == true`: `dailyProteinGramsMin = round(1.6 * weightKg)`, `dailyProteinGramsMax = round(2.2 * weightKg)`.
     - Ngược lại: `dailyProteinGramsMin = round(1.0 * weightKg)`, `dailyProteinGramsMax = round(1.3 * weightKg)`.
   - **Nước uống & chu kỳ uống nước:**
     - `dailyWaterMl = round(weightKg * 35) + (activityLevel == moderate || activityLevel == active ? 400 : 0) + (isGymGoer ? 600 : 0)`
     - Giả sử mỗi lần uống `220ml` trong khung giờ thức `13 giờ` (`780 phút`):
       - `timesPerDay = clamp(dailyWaterMl / 220, 6, 12)`
       - `waterIntervalMin` làm tròn về bội số 15 phút (ví dụ 60, 75, 90, 105, 120), và nếu `isGymGoer` thì giảm khoảng 15 phút (không thấp hơn 45 phút).

2. **Xử lý Khung giờ theo Ca làm việc (`workShift`):**
   - **Nếu `workShift == dayShift`:**
     - Khung giờ uống nước: từ `wakeTime` (hoặc +5p) đến trước `bedtime` 2 giờ.
     - Các bữa chính mặc định: Sáng (`wakeTime + 30p`), Trưa (`12:00`), Phụ (`16:00`), Tối (`18:30`, hoặc điều chỉnh theo `goal`/`condition`).
   - **Nếu `workShift == nightShift` (hoặc `rotatingShift` với giờ thức dậy từ `13:00` đến `21:00`):**
     - Tính mọi bữa ăn neo theo `wakeTime` và `bedtime` (xử lý vượt qua mốc `24:00` sang ngày hôm sau):
       - Bữa 1 (Khởi đầu ca): `wakeTime + 45 phút`.
       - Bữa 2 (Giữa ca đêm): `wakeTime + 5 giờ 30 phút`.
       - Bữa phụ rạng sáng: `wakeTime + 9 giờ` (nhắc ăn rất nhẹ <200 kcal, tránh dầu mỡ từ 01:00–04:00).
       - Bữa 3 (Cuối ca trước ngủ): `bedtime - 2 giờ 30 phút`.
       - Ngừng Caffeine: `recommendedCaffeineCutoffHours = 7.0` (`bedtime - 7 giờ`).
       - Khung uống nước xoay theo `wakeTime` đến `bedtime - 1 giờ 30 phút`.
       - Ghi chú nhắc ngủ ban ngày: *"Đeo kính râm tránh nắng gắt khi tan ca, kéo rèm cản sáng tuyệt đối (Blackout) và giữ phòng mát"*.

3. **Xử lý Lịch tập Gym (`isGymGoer == true`):**
   - Tự động thêm nhắc `"Bữa phụ trước tập (Pre-workout)"` vào thời điểm `(workoutHour:workoutMinute - 75 phút)`.
   - Tự động thêm nhắc `"Bổ sung Đạm & Nước sau tập (Post-workout)"` vào thời điểm `(workoutHour:workoutMinute + 75 phút)`.

4. **Bộ lọc Thực phẩm theo Chế độ ăn (`dietType`):**
   - `omnivore`: Ức gà, cá hồi/cá thu, thịt thăn, trứng, tôm, đậu phụ, sữa chua.
   - `vegetarian`: Đậu phụ, nấm đùi gà/nấm hương, đậu lăng, đậu gà, trứng gà, sữa chua Hy Lạp, phô mai ít béo, các loại hạt.
   - `vegan`: Đậu phụ, tempeh, đậu gà, đậu lăng, đậu đen, nấm, sữa đậu nành/hạnh nhân không đường, bơ đậu phộng, hạt chia, hạt bí, hạt óc chó kết hợp ngũ cốc nguyên cám; kèm nhắc ăn cùng thực phẩm giàu Vitamin C (ớt chuông, bông cải xanh, cam, ổi) để tăng hấp thu sắt, hạn chế trà đậm ngay sau bữa.

5. **Quy tắc điều chỉnh theo Lưu ý sức khỏe & Mục tiêu (`goal` & `condition`):**
   - `condition == stomachReflux`: `recommendedDinnerCutoffHours = 4.0`; Bữa sáng cách giờ thức 30–45 phút (*"Ăn đồ ấm mềm, tránh chua cay và cà phê lúc bụng đói"*); tự động thêm bữa phụ nhẹ `10:00` và `15:30` (hoặc tương ứng theo ca) để trung hòa axit dạ dày.
   - `goal == loseWeight` hoặc `condition == bloodSugar`: `recommendedDinnerCutoffHours = 3.5`, bữa tối ca ngày không muộn hơn `18:30`; ghi chú *"Quy tắc ăn ngược: Rau xanh trước -> Đạm -> Tinh bột chậm sau cùng"*; tự động thêm nhắc *"Đi bộ nhẹ 10–15 phút sau ăn tối"* (+30p sau bữa tối).
   - `goal == gainWeight`: Tự động bật 2 bữa phụ giàu dinh dưỡng (`09:30` và `15:30` ở ca ngày, hoặc neo theo ca).
   - `condition == seniorCardio` hoặc `age >= 60`: Bữa tối ca ngày đẩy sớm về `17:30 – 18:00`, ghi chú *"Ăn nhạt, giảm muối/mỡ, ưu tiên thức ăn mềm dễ tiêu; hạn chế uống nhiều nước sau 19:30 để tránh tiểu đêm"*.

6. **Kiểm tra hợp lệ (Validation):**
   - `sleepHours` ngoài khoảng 7–9: vẫn cho nhập nhưng hiện cảnh báo nhẹ.
   - `dinnerTime` muộn hơn `dinnerStop`: hiện cảnh báo gợi ý ăn sớm hơn hoặc ăn thức ăn nhẹ dễ tiêu.
   - `title` không được rỗng; `weekly` phải chọn ít nhất 1 ngày; `once` phải có ngày không nằm trong quá khứ; `interval` phải có `intervalMinutes >= 30` và giờ kết thúc sau giờ bắt đầu.

---

## 7. Thông báo (kết hợp `uhabits` & `WaterMe`)

### 7.1 Quy tắc ID
`notificationId = reminderId * 100 + slot`:
- `slot = 0`: cho `once` và `daily`.
- `slot = 1..7`: cho từng thứ trong tuần (`weekly`, Thứ 2 = 1 .. Chủ nhật = 7).
- `slot = 10..29`: cho các mốc giờ trong ngày của kiểu lặp chu kỳ `interval` (tối đa 20 mốc từ `10` đến `29`, mỗi mốc dùng `matchDateTimeComponents: DateTimeComponents.time`).
- `slot = 99`: để dành cho nút Hoãn (Snooze 10 phút).

Nhờ quy tắc nhân 100 này, khi sửa hoặc xóa một nhắc có `reminderId`, chỉ cần hủy các ID từ `reminderId * 100` đến `reminderId * 100 + 99`.

### 7.2 Cách lên lịch
- `daily`: một thông báo với `matchDateTimeComponents: DateTimeComponents.time`.
- `weekly`: mỗi thứ được chọn một thông báo với `DateTimeComponents.dayOfWeekAndTime`.
- `interval`: Tính danh sách các mốc `(hour, minute)` từ giờ bắt đầu đến `endHour:endMinute` cộng dần `intervalMinutes` (hỗ trợ cả trường hợp khung giờ qua nửa đêm cho ca đêm), sau đó đặt thông báo lặp hằng ngày (`DateTimeComponents.time`) cho từng mốc vào `slot = 10 + index` (tối đa 20 slot).
- `once`: `zonedSchedule` thường, không lặp.

```dart
tz.TZDateTime nextInstanceOf(int hour, int minute) {
  final now = tz.TZDateTime.now(tz.local);
  var t = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
  if (!t.isAfter(now)) {
    t = tz.TZDateTime(tz.local, now.year, now.month, now.day + 1, hour, minute);
  }
  return t;
}
```
*Lưu ý: Tên tham số `flutter_local_notifications` và `flutter_timezone` có thể thay đổi theo phiên bản hiện hành, phải đối chiếu README / API thực tế của package đã cài.*

### 7.3 Khởi tạo
- `tz.initializeTimeZones()` rồi `tz.setLocalLocation(tz.getLocation(...))` từ `FlutterTimezone.getLocalTimezone()`.
- Tạo 4 notification channel: `task` (Công việc), `meal` (Ăn uống), `hydration` (Uống nước & Giải lao), `sleep` (Ngủ nghỉ).
- Xin quyền thông báo lúc chạy (Android 13+ và iOS), **không xin ngay khi mở app lần đầu** mà xin khi người dùng bấm chọn Bộ lịch mẫu hoặc tạo nhắc đầu tiên.

### 7.4 Cấu hình Android
- Quyền trong `AndroidManifest.xml`: `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `SCHEDULE_EXACT_ALARM` (nếu dùng alarm chính xác).
- Khai báo receiver khởi động lại để lịch sống sót sau reboot (theo README plugin, gồm `ScheduledNotificationReceiver` và `ScheduledNotificationBootReceiver`).
- Bật core library desugaring trong `android/app/build.gradle(.kts)`.
- Icon thông báo: tạo `ic_notification` trong `android/app/src/main/res/drawable`.

### 7.5 Alarm chính xác hay không chính xác
- Thử dùng `exactAllowWhileIdle`; nếu bị từ chối thì tự rơi về `inexactAllowWhileIdle` và hiện giải thích trong Cài đặt.

### 7.6 iOS
- Xin quyền lúc chạy; làm theo phần iOS setup trong README plugin (`AppDelegate`, `Info.plist`).

### 7.7 Khi nào phải lên lịch lại toàn bộ (`rescheduleAll`)
- Mở app, sau mỗi lần thêm/sửa/xóa/bật/tắt, khi đổi Bộ lịch mẫu (Preset), khi áp dụng lịch dinh dưỡng & giấc ngủ, khi đổi cài đặt giờ ngủ hoặc giờ ăn, khi múi giờ máy đổi, và sau khi khởi động lại máy.

### 7.8 Giới hạn hệ thống
- iOS chỉ giữ 64 thông báo sắp kích hoạt nhất; Samsung có giới hạn khoảng 500 alarm. Dùng cơ chế cửa sổ trượt giới hạn tối đa ~50 thông báo gần nhất khi cần.

---

## 8. Màn hình

| Màn hình | Nội dung chính |
| :--- | :--- |
| **Hôm nay (Home)** | Thanh tiến độ hoàn thành trong ngày + Chuỗi ngày (Streak). 2 phân khu rõ ràng: Công việc hôm nay (`Work Schedule`) và Thói quen sinh hoạt (`Daily Routine`: Ăn, Uống nước, Ngủ). Mỗi thẻ hiện giờ, nhãn loại, ghi chú thực phẩm/cách làm, nút lớn Xong / Bỏ qua chỉ 1 chạm. |
| **Thêm/Sửa nhắc** | Tên, loại (`task`/`meal`/`hydration`/`sleep`), tích chọn Thói quen cố định hay Việc trong ngày, mức ưu tiên, giờ, kiểu lặp (`once`/`daily`/`weekly`/`interval`), ghi chú, công tắc bật. |
| **Thể trạng, Dinh dưỡng & Giấc ngủ** | Phần 1: Form nhập Thể trạng (Tuổi, Giới tính, Chiều cao, Cân nặng, Vận động, Mục tiêu, Chế độ ăn Đa dạng/Chay trứng sữa/Thuần chay, Ca làm việc Ban ngày/Ca đêm/Xoay ca, Công tắc Tập Gym kèm Giờ tập, Lưu ý sức khỏe).<br>Phần 2: Thẻ kết quả phân tích (BMI chuẩn Châu Á, BMR/TDEE & Calo mục tiêu, Lượng đạm g/ngày, Tỷ lệ đĩa ăn, Tổng lượng nước & chu kỳ uống nước).<br>Phần 3: Lịch Giấc ngủ (Giờ đi ngủ, Ngừng ăn, Ngừng Caffeine, Chuẩn bị ngủ) & Khung giờ ăn cá nhân hóa kèm thực phẩm gợi ý.<br>Nút "Áp dụng Lịch Dinh dưỡng & Giấc ngủ": tạo/cập nhật các nhắc ăn, uống nước, ngủ vào DB và gọi `rescheduleAll`. |
| **Thống kê (Stats)** | Học từ `iSoron/uhabits`: Hiển thị chuỗi ngày duy trì (Streak) và biểu đồ cột/thanh 7 ngày gần nhất cho tỷ lệ hoàn thành Công việc và Sinh hoạt. |
| **Cài đặt** | Chọn Bộ lịch mẫu (4 Presets cho mọi lứa tuổi), chỉnh giờ ăn mặc định, chu kỳ uống nước, trạng thái quyền (thông báo, báo thức chính xác, tối ưu pin đèn xanh/đỏ), nút mở cài đặt hệ thống, liên kết `dontkillmyapp.com` theo hãng máy. |

Giao diện: Tiếng Việt, giờ 24h, Material 3, hỗ trợ chế độ tối, chữ đủ lớn (>= 16sp body) và hỗ trợ trợ năng.

---

## 9. App tham khảo
- `GavinBDev/HabitMaker` & `SubhamTyagi/ToDo`: tách `isRoutine` và `priority`.
- `iSoron/uhabits`: Streak & lịch sử `CompletionLog` 7 ngày.
- `D3vNe0/WaterMe` & `Crazy-Marvin/WaterReminder`: nhắc chu kỳ `interval`.
- `Astronaut Daily`: ràng buộc lịch sinh học vào 4 Bộ lịch mẫu (Presets).

---

## 10. Cơ sở khoa học & Tuyên bố sức khỏe
- Ngủ người lớn: 7–9 giờ (CDC/ATS), mặc định 7.5 giờ.
- Ngừng ăn tối trước giờ ngủ 2–4 giờ (mặc định 3 giờ).
- Ngừng caffeine tối thiểu 6–8 giờ trước khi ngủ (mặc định 8 giờ cho ca ngày, 7 giờ cho ca đêm).
- **Tuyên bố trong app (bắt buộc hiển thị ở màn Giấc ngủ/Dinh dưỡng và Cài đặt):**
  *"Nội dung chỉ mang tính tham khảo chung về lối sống lành mạnh cho người khỏe mạnh, không thay thế tư vấn của bác sĩ hay chuyên gia dinh dưỡng; người có bệnh nền, đang dùng thuốc hoặc có vấn đề giấc ngủ nên hỏi ý kiến chuyên gia y tế."*

---

## 11. Kế hoạch test trên điện thoại thật
- Xử lý hạn chế pin theo hãng máy (`dontkillmyapp.com`: Samsung, Xiaomi, Oppo, Vivo, Honor).
- Kịch bản T1–T11 và bảng ghi kết quả test trên máy thật.
- Màn Cài đặt kiểm tra `Permission.notification`, `Permission.ignoreBatteryOptimizations` và quyền báo thức chính xác (`scheduleExactAlarm`), hiện đèn xanh/đỏ, nút mở cài đặt hệ thống và liên kết `dontkillmyapp.com`.

---

## 12. Lộ trình từng Phase
- **Phase 0:** `chore: scaffold project` — Tạo project `nhac_nho`, cài packages, tạo cây thư mục, bật core library desugaring.
- **Phase 1:** `feat: data layer and extended body profile` — Entities, repositories, SQLite (`app_database.dart`), `SharedPreferences`, test `reminder_repository_test.dart`.
- **Phase 2:** `feat: domain logic with gym, vegan and night shift analyzer` — `SleepPlanner`, `BodyNutritionAnalyzer`, `WorkMealGuide`, `HabitStatsCalculator`, unit tests đầy đủ.
- **Phase 3:** `feat: notifications` — `NotificationScheduler`, `NotificationSchedulerImpl`, `AndroidManifest.xml`, `ic_notification`, `time_utils.dart`, unit tests.
- **Phase 4:** `feat: main ui with complete body nutrition planner` — `router.dart`, `providers.dart`, `reminder_controller.dart`, 4 màn hình chính + widget test form.
- **Phase 4B:** `feat: theme and accessibility` — `app_theme.dart` (FlexColorScheme + Be Vietnam Pro + Dynamic Color + High Contrast), `category_style.dart`, Semantics, `flutter_animate`, widget test `textScaler = 2.0` + dark mode.
- **Phase 5:** `feat: settings, presets and permissions` — `settings_screen.dart` hoàn chỉnh với 4 Presets, giờ mặc định, trạng thái quyền, xin quyền đúng thời điểm.
- **Phase 6:** `chore: polish` — Rà soát nghiệm thu, `README.md`, tuyên bố sức khỏe, nút Hoãn 10 phút (slot 99), `flutter analyze`, `flutter test`, `flutter build apk --debug`.
- **Phase 7:** `feat: universal smart scheduler, adaptive food matrix and visual timeline ui overhaul` — Mở rộng hệ thống lập lịch động theo giờ thức thực tế (`UniversalDayScheduler`, `UserTaskInput`), ma trận thực phẩm 4 chiều (`AdaptiveFoodCatalog`, `DailyFocusMode`), 7 bộ mẫu khởi tạo nhanh, trợ lý 3 bước (`SmartPlannerSheet`), giao diện Visual Timeline 4 buổi & Bento Grid (`fl_chart`, `lucide_icons_flutter`, `flutter_slidable`, theo dõi nước `+200ml`), đạt **67/67 tests** (bao gồm `textScaler = 2.0` ở Light/Dark/HighContrast).

---

## 16. Kiến trúc Phase 7: Universal Smart Planner & Bento UI
- **Lập lịch Động theo Nhịp sống Cá nhân (`UniversalDayScheduler` & `UserTaskInput`):**
  - Không áp đặt giờ hành chính cố định; tự neo lịch theo `wakeTime` và `sleepHours` thực tế từ `UserSettings` (hỗ trợ cả ca đêm / xoay ca).
  - Phân bổ công việc theo `TaskEnergyDemand` (`highFocus` vào đỉnh năng lượng sinh học, `mediumTask`, `lightChore`, `physicalOrEvent`), tự dịch bữa ăn nếu trùng lịch cố định và chèn nhắc nghỉ/uống nước cho việc kéo dài >= 60 phút.
- **Ma trận Thực phẩm 4 Chiều (`AdaptiveFoodCatalog`) & 7 Bộ mẫu khởi tạo nhanh (`PresetId`):**
  - Lọc thực đơn Việt theo 4 chiều: Thể trạng/Bệnh lý (`BodyProfile`), Chế độ ăn (`omnivore`, `vegetarian`, `vegan`), Nhu cầu ưu tiên trong ngày (`DailyFocusMode`: `brainFocus`, `staminaPhysical`, `leanAntiBloat`, `digestiveComfort`, `quickBudget`), và xoay vòng biến thể qua `swapMealOption(...)` / **Đổi món** trực tiếp trên thẻ.
  - Bổ sung từ 4 lên 7 bộ mẫu khởi tạo nhanh: `officeCoder`, `student`, `freelancer`, `modelAesthetic`, `homemakerParent`, `activeWorker`, `seniorHealth`.
- **Trợ lý 3 bước & Giao diện Visual Timeline / Bento Grid:**
  - `SmartPlannerSheet`: 3 bước (1. Chọn `DailyFocusMode` & mẫu nhanh -> 2. Nhập việc tự do / Smart Chips, thời lượng, mức năng lượng, giờ cố định/tự động -> 3. Xem trước dòng thời gian, đổi món & áp dụng giữ nguyên streak qua `replaceRoutineReminders`).
  - `HomeScreen`, `SleepPlannerScreen`, `StatsScreen`: Nâng cấp Visual Timeline 4 buổi (`Sáng`, `Trưa`, `Chiều`, `Tối`), thanh chọn 7 ngày, Bento Grid với `fl_chart` (Donut, PieChart, BarChart), theo dõi nước uống `+200ml` (`waterIntakeMlProvider`), thao tác vuốt `flutter_slidable`, biểu tượng `lucide_icons_flutter` và thẻ bo góc `20dp`.

---

## 13. Tiêu chí nghiệm thu
- `flutter analyze` không lỗi, `flutter test` xanh.
- `SleepPlanner`, `BodyNutritionAnalyzer` và `HabitStatsCalculator` đúng quy tắc mục 6 và có test.
- 4 Bộ lịch mẫu (Presets) hoạt động mượt, tạo đúng danh sách việc làm + ăn uống + uống nước + giấc ngủ.
- Tạo nhắc `daily`, `weekly`, `interval`, `once` đều lên lịch đúng; sửa/xóa/tắt nhắc không còn thông báo cũ.
- Nhắc còn hiệu lực sau reboot (receiver khai báo chuẩn).
- Màn Cài đặt phản ánh đúng trạng thái quyền.
- Có tuyên bố sức khỏe trong app.
- `README.md` có hướng dẫn chạy và test.

---

## 15. UI/UX & Trợ năng đa lứa tuổi
- **Theme (`app_theme.dart`):** FlexColorScheme Material 3 (sáng/tối), phông `Be Vietnam Pro` (`google_fonts`), hỗ trợ `dynamic_color`, tự đổi sang theme tương phản cao khi `MediaQuery.of(context).accessibilityFeatures.highContrast` bật.
- **Category Style (`category_style.dart`):** Độ tương phản chữ/màu >= 4.5:1 (WCAG AA):
  - `task`: Xanh dương đậm + `Icons.work_outline` + `"Công việc"`
  - `meal`: Cam ấm / Xanh lá đậm + `Icons.restaurant_outlined` + `"Ăn uống"`
  - `hydration`: Xanh ngọc đậm + `Icons.water_drop_outlined` + `"Uống nước & Nghỉ"`
  - `sleep`: Tím chàm + `Icons.bedtime_outlined` + `"Giấc ngủ"`
- **Trợ năng:** Body >= 16sp, vùng chạm tối thiểu 48x48 dp, nhãn `Semantics` tiếng Việt cho nút icon, không tràn khi `textScaler = 2.0`, hiệu ứng `flutter_animate` nhẹ nhàng không chớp nháy.

```

Mẫu thiết kế dùng: Repository (data), Strategy cho kiểu lặp (`once`/`daily`/`weekly`/`interval`), Factory cho Bộ lịch mẫu (`PresetProfile`), Dependency Injection qua Riverpod.

---

## 4. Package

Dùng bản mới nhất tương thích với Flutter đang cài (chạy `flutter pub add`, không ghim phiên bản cũ copy từ bài hướng dẫn). Khi API khác, làm theo README hiện tại của plugin.

| Package | Dùng để |
| :--- | :--- |
| `flutter_riverpod` | Quản lý state, DI |
| `go_router` | Điều hướng |
| `sqflite`, `path` | Lưu danh sách nhắc và lịch sử hoàn thành (SQLite) |
| `shared_preferences` | Lưu cài đặt người dùng, BodyProfile và Preset đã chọn |
| `flutter_local_notifications` | Lên lịch thông báo cục bộ |
| `timezone`, `flutter_timezone` | Tính giờ theo múi giờ máy |
| `permission_handler` | Xin quyền thông báo, tối ưu pin |
| `intl` | Định dạng ngày giờ tiếng Việt |
| `flex_color_scheme`, `dynamic_color` | Tạo theme Material 3 sáng/tối chuẩn đẹp, đồng bộ màu máy |
| `google_fonts` | Phông chữ hiển thị rõ dấu tiếng Việt cho mọi lứa tuổi |
| `flutter_animate` | Hiệu ứng chuyển động nhẹ nhàng |
| `mocktail` (dev) | Mock khi viết unit test |
| `sqflite_common_ffi` (dev) | Test database SQLite trực tiếp trên máy tính |

---

## 5. Mô hình dữ liệu

### `Reminder` (`reminders`)
| Trường | Kiểu | Ghi chú |
| :--- | :--- | :--- |
| `id` | `int` | Khóa chính, tự tăng |
| `title` | `text` | Tên nhắc (VD: "Bữa sáng giàu đạm", "Deep Work: Học code") |
| `note` | `text`, null | Ghi chú / Gợi ý thực phẩm hoặc cách thực hiện |
| `category` | `enum` | `task` (Công việc), `meal` (Ăn uống), `hydration` (Uống nước/Giải lao), `sleep` (Ngủ nghỉ) |
| `isRoutine` | `int` 0/1 | 1 = Thói quen cố định mỗi ngày (Routine), 0 = Việc làm cụ thể (Work Schedule) |
| `priority` | `int` | 1 = Quan trọng nhất (MIT), 2 = Bình thường, 3 = Nhẹ nhàng |
| `hour`, `minute` | `int` | Giờ bắt đầu (24h) |
| `repeat` | `enum` | `once`, `daily`, `weekly`, `interval` |
| `intervalMinutes` | `int`, null | Chu kỳ lặp bằng phút (VD: 90 hoặc 120 phút), dùng khi `repeat == interval` |
| `endHour`, `endMinute` | `int`, null | Giờ kết thúc chu kỳ trong ngày (VD: 20:00), dùng khi `repeat == interval` |
| `weekdaysMask` | `int` | Bit 0 = Thứ 2 … bit 6 = Chủ nhật; dùng khi `weekly` |
| `date` | `text`, null | `yyyy-MM-dd`, dùng khi `once` |
| `enabled` | `int` 0/1 | Bật/tắt |
| `createdAt` | `text` | ISO 8601 |

### `CompletionLog` (`completion_logs`)
- `id` (`int`), `reminderId` (`int`), `date` (`yyyy-MM-dd`), `status` (`done`, `skipped`), `completedAt` (`text` ISO 8601).

### `UserSettings` (`shared_preferences`)
- `selectedPreset`: `office_coder` (mặc định), `student`, `freelancer`, `senior_health`.
- `wakeTime` (mặc định `06:30`), `sleepHours` (mặc định `7.5`), `fallAsleepBufferMin` (mặc định `15`).
- `breakfastTime` (`07:00`), `lunchTime` (`12:00`), `afternoonSnackTime` (`16:00`), `dinnerTime` (`18:30`).
- `dinnerCutoffHours` (mặc định `3.0`), `caffeineCutoffHours` (mặc định `8.0`), `windDownMin` (mặc định `45`).
- `waterIntervalMin` (mặc định `120` phút).

### `BodyProfile` (Lưu trong `shared_preferences` qua `SettingsRepository`)
| Trường | Kiểu | Mặc định | Ghi chú |
| :--- | :--- | :--- | :--- |
| `age` | `int` | `25` | Tuổi (10–100) |
| `gender` | `enum` | `male` | `male`, `female` |
| `heightCm` | `double` | `168.0` | Chiều cao (cm) |
| `weightKg` | `double` | `62.0` | Cân nặng (kg) |
| `activityLevel` | `enum` | `sedentary` | `sedentary` (1.2), `light` (1.375), `moderate` (1.55), `active` (1.725) |
| `goal` | `enum` | `maintain` | `loseWeight`, `maintain`, `gainWeight` |
| `condition` | `enum` | `none` | `none`, `stomachReflux` (Đau dạ dày/Trào ngược), `bloodSugar` (Đường huyết), `seniorCardio` (Lớn tuổi/Tim mạch) |
| `dietType` | `enum` | `omnivore` | `omnivore` (Ăn đa dạng), `vegetarian` (Ăn chay trứng sữa), `vegan` (Thuần chay) |
| `workShift` | `enum` | `dayShift` | `dayShift` (Ban ngày), `nightShift` (Ca đêm), `rotatingShift` (Xoay ca) |
| `isGymGoer` | `bool` | `false` | Có tập gym/thể hình hay không |
| `workoutHour` | `int` | `17` | Giờ tập (24h) |
| `workoutMinute` | `int` | `0` | Phút tập |

### `NutritionPlan` (Kết quả phân tích từ `BodyNutritionAnalyzer.analyze(BodyProfile, wakeTime, bedtime)`)
- `bmi` (`double`), `bmiCategory` (`String`: Thiếu cân / Cân đối / Thừa cân / Béo phì).
- `bmr` (`int`), `tdee` (`int`), `targetCalories` (`int`: Calo khuyến nghị mỗi ngày).
- `dailyProteinGramsMin` (`int`), `dailyProteinGramsMax` (`int`).
- `plateRatioText` (`String`: Tỷ lệ đĩa ăn Rau - Đạm - Tinh bột phù hợp mục tiêu).
- `dailyWaterMl` (`int`: Tổng lượng nước ml/ngày), `waterIntervalMin` (`int`: Số phút giữa 2 lần nhắc uống nước).
- `waterStartHour` (`int`), `waterStartMinute` (`int`), `waterEndHour` (`int`), `waterEndMinute` (`int`) // Tự động xoay theo ca ngày hoặc ca đêm.
- `recommendedDinnerCutoffHours` (`double`: 3.0h cho người thường, 3.5h cho giảm cân/đường huyết, 4.0h cho đau dạ dày/trào ngược).
- `recommendedCaffeineCutoffHours` (`double`: 8.0h cho ca ngày, 7.0h cho ca đêm).
- `sleepAdviceNote` (`String`: ghi chú nhắc ngủ phù hợp, VD ca đêm hạn chế ánh nắng gắt & kéo rèm tối).
- `mealScheduleRecommendations` (`List<MealRecommendation>`): Gồm `hour`, `minute`, `title`, `foodAdvice` (nên ăn gì, hạn chế gì đã lọc theo `dietType`, `workShift`, `isGymGoer`, `goal`, `condition`) và các nhắc nhở bổ trợ (VD Pre/Post-workout, đi bộ sau ăn tối).

---

## 6. Logic nghiệp vụ, Dinh dưỡng & Phân chia công việc chuẩn khoa học

### 6.1 Khung giờ Ăn uống & Gợi ý thực phẩm tích hợp sẵn trong App (`work_meal_guide.dart`)
Mỗi lời nhắc ăn uống trong app không chỉ báo giờ mà còn kèm note gợi ý thực phẩm dễ áp dụng cho mọi gia đình Việt Nam:

| Bữa / Nhắc | Giờ mặc định | Loại | Nguyên tắc dinh dưỡng & Thực phẩm gợi ý (hiển thị trong note của nhắc) |
| :--- | :--- | :--- | :--- |
| Uống nước ấm sáng | `06:35` | `hydration` | Uống 200–300ml nước ấm ngay sau khi thức dậy để bù nước sau đêm dài và kích hoạt tiêu hóa. |
| Bữa sáng | `07:00` | `meal` | Tinh bột chậm + Đạm + Chất xơ: Trứng, yến mạch, bánh mì nguyên cám, khoai lang, hoặc bún/phở ít béo thêm rau. Hạn chế đồ ngọt tinh luyện để không buồn ngủ lúc 10h sáng. |
| Bữa trưa | `12:00` | `meal` | Quy tắc Đĩa ăn 2:1:1: 1/2 rau xanh/củ quả, 1/4 đạm nạc (cá, ức gà, đậu phụ, thịt nạc), 1/4 cơm/tinh bột vừa phải. Tránh ăn quá no tinh bột gây lờ đờ đầu giờ chiều. |
| Ngừng Caffeine | Tính từ giờ ngủ (6.3) | `hydration` | Ngừng cà phê, trà đậm, nước tăng lực 8 giờ trước khi ngủ (khoảng 14:30) để không làm giảm giấc ngủ sâu ban đêm. |
| Bữa phụ chiều | `16:00` | `meal` | Nạp nhẹ chống đói: 1 hũ sữa chua không đường, 1 nắm hạt (hạnh nhân, óc chó, hạt điều) hoặc trái cây ít ngọt (táo, ổi, chuối) giúp giữ tỉnh táo cuối chiều. |
| Bữa tối | `18:30` | `meal` | Nhẹ bụng, dễ tiêu: Ưu tiên cá, rau luộc/canh ấm, đậu phụ, ít cơm. Tránh đồ chiên rán nhiều dầu mỡ, đồ cay nóng hoặc ăn quá no. |
| Uống nước định kỳ | Mỗi 120 phút (`08:30–20:00`) | `hydration` | Uống 150–200ml nước mỗi lần nhắc (tổng ~1.8–2.2 lít/ngày). Ngừng uống nhiều nước sau 20:00 để tránh thức giấc đi tiểu đêm. |
| Ngừng ăn tối | Tính từ giờ ngủ (6.3) | `sleep` | Kết thúc bữa tối và đồ ăn vặt 3 giờ trước khi ngủ (19:45) để dạ dày được nghỉ ngơi, chống trào ngược. |
| Chuẩn bị đi ngủ | Tính từ giờ ngủ (6.3) | `sleep` | 45 phút trước giờ ngủ (22:00): Tắt máy tính/điện thoại, giảm ánh sáng xanh, giãn cơ nhẹ hoặc đọc sách giấy. |
| Đi ngủ | Tính từ giờ ngủ (6.3) | `sleep` | Lên giường đi ngủ (22:45) để đảm bảo đủ chu kỳ giấc ngủ 7.5 giờ. |

### 6.2 Khung giờ Công việc & Phân chia công việc cho mọi người (Time Blocking & Nhịp sinh học)

#### A. Nguyên tắc phân chia công việc trong ngày
- **Ca Sáng – Đỉnh tập trung (Deep Work: 08:00 – 11:30):**
  - Não bộ tỉnh táo nhất sau bữa sáng. Dành cho 1–2 Việc Quan Trọng Nhất (MIT - Priority 1): học lập trình, giải quyết việc khó, viết lách, học môn chính.
  - Áp dụng nhịp 50 phút tập trung – 10 phút nghỉ giải lao (đứng dậy vươn vai, nhìn xa 6 mét bảo vệ mắt).
- **Giờ Nghỉ Trưa – Phục hồi (11:30 – 13:30):**
  - Ăn trưa lúc 12:00, đi bộ nhẹ 10 phút, và Ngủ trưa ngắn (Power Nap 15–20 phút lúc 13:00) để khôi phục sự tỉnh táo mà không bị đau đầu.
- **Ca Chiều – Phối hợp & Hoàn tất (13:30 – 17:30):**
  - 13:30 – 15:30 (Vùng trũng sinh học): Xử lý Việc nhẹ / Hành chính (Shallow Work - Priority 2 & 3) như trả lời email, họp hành, dọn dẹp, việc lặp lại.
  - 15:30 – 17:00 (Đỉnh năng lượng thứ hai): Hoàn tất việc tồn đọng trong ngày.
  - 17:00 – 18:00: Vận động thể chất / Tập thể dục (đi bộ nhanh, chạy bộ, gym, thể thao) khi thân nhiệt đạt mức tối ưu.
- **Buổi Tối – Tổng kết & Thư giãn (19:30 – 22:00):**
  - 19:30 – 21:00: Học kỹ năng mới nhẹ nhàng / Đọc sách / Dành thời gian cho gia đình.
  - 21:00 – 21:15: Lên danh sách 3 việc cần làm cho ngày mai (Rule of 3) để giải phóng tâm trí trước khi ngủ.

#### B. 4 Bộ lịch mẫu (Presets) tích hợp sẵn trong `preset_profile.dart` & `work_meal_guide.dart`
Người dùng chọn 1 trong 4 bộ mẫu khi mở app lần đầu (hoặc đổi trong Cài đặt), app sẽ tự động tạo bộ nhắc nhở phù hợp:
1. **Lập trình viên / Dân văn phòng (`office_coder` - Mặc định):**
   Thức 06:30 · Ăn sáng 07:00 · Deep Work / Code ca sáng 08:30 · Nhắc nghỉ mắt & uống nước mỗi 90 phút · Ăn trưa 12:00 · Ngủ trưa 20p 13:00 · Việc chiều 14:00 · Bữa phụ 16:00 · Tập thể dục 17:15 · Ăn tối 18:30 · Học code/Đọc tài liệu tối 20:00 · Lên lịch ngày mai 21:15 · Chuẩn bị ngủ 22:00 · Ngủ 22:45.
2. **Học sinh / Sinh viên (`student`):**
   Thức 06:00 · Ăn sáng 06:30 · Ca học sáng 07:30 · Ăn trưa 11:45 · Ngủ trưa 12:45 · Tự học/Làm bài tập chiều 14:00 · Thể thao/Giải trí 17:00 · Ăn tối 18:30 · Ôn bài tối & Chuẩn bị sách vở 19:45 · Chuẩn bị ngủ 21:45 · Ngủ 22:30.
3. **Người làm tự do (`freelancer`):**
   Thức 07:00 · Ăn sáng 07:30 · 3 Việc quan trọng nhất (MIT) 09:00 · Ăn trưa 12:30 · Xử lý khách hàng & Việc nhẹ 14:30 · Vận động 17:30 · Ăn tối 19:00 · Tổng kết thu/chi & Lịch mai 21:00 · Ngủ 23:15.
4. **Người lớn tuổi / Chăm sóc sức khỏe (`senior_health`):**
   Thức 05:30 · Uống nước ấm & Vận động nhẹ 05:45 · Ăn sáng thanh đạm 06:30 · Nhắc uống thuốc/Đo huyết áp sáng (nếu có) 07:30 · Đọc báo/Chăm cây/Thư giãn 09:00 · Ăn trưa 11:30 · Nghỉ trưa 12:30 · Đi bộ chiều 16:30 · Ăn tối nhẹ 18:00 · Ngâm chân nước ấm/Thư giãn 20:30 · Đi ngủ 21:30.

### 6.3 `SleepPlanner` (hàm thuần, có test)
```text
bedtime        = wakeTime − sleepHours − fallAsleepBufferMin
dinnerStop     = bedtime − dinnerCutoffHours
caffeineCutoff = bedtime − caffeineCutoffHours
windDown       = bedtime − windDownMin
```
Ví dụ dùng làm test: Thức 06:30, ngủ 7.5 giờ, đệm 15 phút → đi ngủ 22:45, ngừng ăn 19:45 (cutoff 3 giờ), ngừng cà phê 14:45 (cutoff 8 giờ), chuẩn bị ngủ 22:00. Phải xử lý trường hợp vượt nửa đêm (cả khi giờ ngủ rơi vào ngày hôm trước như thức 06:30 ngủ 22:45, lẫn người làm ca đêm thức 16:00 ngủ 08:00 sáng hôm sau).

### 6.4 `HabitStatsCalculator` (học từ `iSoron/uhabits`, hàm thuần, có test)
- **Tính Chuỗi ngày liên tiếp (Current Streak):** số ngày liên tiếp tính đến hôm nay (hoặc hôm qua nếu hôm nay chưa hết ngày / chưa hoàn thành đủ) mà người dùng hoàn thành >= 80% các mục `isRoutine == 1`.
- **Tính Tỷ lệ hoàn thành 7 ngày gần nhất (`Map<String, double>`):** tỷ lệ `done / total` cho từng ngày để vẽ thanh tiến độ 7 ngày trên màn hình Thống kê.

### 6.5 Quy tắc xử lý trong `BodyNutritionAnalyzer` & Validation (Thuần Dart, có Unit Test)

1. **Tính chỉ số cơ bản:**
   - **BMI (Chuẩn Châu Á IDI & WPRO):** `bmi = weightKg / pow(heightCm / 100, 2)`
     - `< 18.5`: Thiếu cân | `18.5 – 22.9`: Cân đối | `23.0 – 24.9`: Thừa cân | `>= 25.0`: Béo phì.
   - **BMR (Mifflin-St Jeor):**
     - Nam: `10 * weightKg + 6.25 * heightCm - 5 * age + 5`
     - Nữ: `10 * weightKg + 6.25 * heightCm - 5 * age - 161`
   - **TDEE & Target Calories:**
     - `tdee = round(bmr * activityMultiplier)` (`sedentary` 1.2, `light` 1.375, `moderate` 1.55, `active` 1.725)
     - `targetCalories`: Giảm cân (`loseWeight`) = `max(1200, tdee - 400)`, Giữ cân (`maintain`) = `tdee`, Tăng cân (`gainWeight`) = `tdee + 350`.
   - **Đạm hằng ngày:**
     - Nếu `isGymGoer == true`: `dailyProteinGramsMin = round(1.6 * weightKg)`, `dailyProteinGramsMax = round(2.2 * weightKg)`.
     - Ngược lại: `dailyProteinGramsMin = round(1.0 * weightKg)`, `dailyProteinGramsMax = round(1.3 * weightKg)`.
   - **Nước uống & chu kỳ uống nước:**
     - `dailyWaterMl = round(weightKg * 35) + (activityLevel == moderate || activityLevel == active ? 400 : 0) + (isGymGoer ? 600 : 0)`
     - Giả sử mỗi lần uống `220ml` trong khung giờ thức `13 giờ` (`780 phút`):
       - `timesPerDay = clamp(dailyWaterMl / 220, 6, 12)`
       - `waterIntervalMin` làm tròn về bội số 15 phút (ví dụ 60, 75, 90, 105, 120), và nếu `isGymGoer` thì giảm khoảng 15 phút (không thấp hơn 45 phút).

2. **Xử lý Khung giờ theo Ca làm việc (`workShift`):**
   - **Nếu `workShift == dayShift`:**
     - Khung giờ uống nước: từ `wakeTime` (hoặc +5p) đến trước `bedtime` 2 giờ.
     - Các bữa chính mặc định: Sáng (`wakeTime + 30p`), Trưa (`12:00`), Phụ (`16:00`), Tối (`18:30`, hoặc điều chỉnh theo `goal`/`condition`).
   - **Nếu `workShift == nightShift` (hoặc `rotatingShift` với giờ thức dậy từ `13:00` đến `21:00`):**
     - Tính mọi bữa ăn neo theo `wakeTime` và `bedtime` (xử lý vượt qua mốc `24:00` sang ngày hôm sau):
       - Bữa 1 (Khởi đầu ca): `wakeTime + 45 phút`.
       - Bữa 2 (Giữa ca đêm): `wakeTime + 5 giờ 30 phút`.
       - Bữa phụ rạng sáng: `wakeTime + 9 giờ` (nhắc ăn rất nhẹ <200 kcal, tránh dầu mỡ từ 01:00–04:00).
       - Bữa 3 (Cuối ca trước ngủ): `bedtime - 2 giờ 30 phút`.
       - Ngừng Caffeine: `recommendedCaffeineCutoffHours = 7.0` (`bedtime - 7 giờ`).
       - Khung uống nước xoay theo `wakeTime` đến `bedtime - 1 giờ 30 phút`.
       - Ghi chú nhắc ngủ ban ngày: *"Đeo kính râm tránh nắng gắt khi tan ca, kéo rèm cản sáng tuyệt đối (Blackout) và giữ phòng mát"*.

3. **Xử lý Lịch tập Gym (`isGymGoer == true`):**
   - Tự động thêm nhắc `"Bữa phụ trước tập (Pre-workout)"` vào thời điểm `(workoutHour:workoutMinute - 75 phút)`.
   - Tự động thêm nhắc `"Bổ sung Đạm & Nước sau tập (Post-workout)"` vào thời điểm `(workoutHour:workoutMinute + 75 phút)`.

4. **Bộ lọc Thực phẩm theo Chế độ ăn (`dietType`):**
   - `omnivore`: Ức gà, cá hồi/cá thu, thịt thăn, trứng, tôm, đậu phụ, sữa chua.
   - `vegetarian`: Đậu phụ, nấm đùi gà/nấm hương, đậu lăng, đậu gà, trứng gà, sữa chua Hy Lạp, phô mai ít béo, các loại hạt.
   - `vegan`: Đậu phụ, tempeh, đậu gà, đậu lăng, đậu đen, nấm, sữa đậu nành/hạnh nhân không đường, bơ đậu phộng, hạt chia, hạt bí, hạt óc chó kết hợp ngũ cốc nguyên cám; kèm nhắc ăn cùng thực phẩm giàu Vitamin C (ớt chuông, bông cải xanh, cam, ổi) để tăng hấp thu sắt, hạn chế trà đậm ngay sau bữa.

5. **Quy tắc điều chỉnh theo Lưu ý sức khỏe & Mục tiêu (`goal` & `condition`):**
   - `condition == stomachReflux`: `recommendedDinnerCutoffHours = 4.0`; Bữa sáng cách giờ thức 30–45 phút (*"Ăn đồ ấm mềm, tránh chua cay và cà phê lúc bụng đói"*); tự động thêm bữa phụ nhẹ `10:00` và `15:30` (hoặc tương ứng theo ca) để trung hòa axit dạ dày.
   - `goal == loseWeight` hoặc `condition == bloodSugar`: `recommendedDinnerCutoffHours = 3.5`, bữa tối ca ngày không muộn hơn `18:30`; ghi chú *"Quy tắc ăn ngược: Rau xanh trước -> Đạm -> Tinh bột chậm sau cùng"*; tự động thêm nhắc *"Đi bộ nhẹ 10–15 phút sau ăn tối"* (+30p sau bữa tối).
   - `goal == gainWeight`: Tự động bật 2 bữa phụ giàu dinh dưỡng (`09:30` và `15:30` ở ca ngày, hoặc neo theo ca).
   - `condition == seniorCardio` hoặc `age >= 60`: Bữa tối ca ngày đẩy sớm về `17:30 – 18:00`, ghi chú *"Ăn nhạt, giảm muối/mỡ, ưu tiên thức ăn mềm dễ tiêu; hạn chế uống nhiều nước sau 19:30 để tránh tiểu đêm"*.

6. **Kiểm tra hợp lệ (Validation):**
   - `sleepHours` ngoài khoảng 7–9: vẫn cho nhập nhưng hiện cảnh báo nhẹ.
   - `dinnerTime` muộn hơn `dinnerStop`: hiện cảnh báo gợi ý ăn sớm hơn hoặc ăn thức ăn nhẹ dễ tiêu.
   - `title` không được rỗng; `weekly` phải chọn ít nhất 1 ngày; `once` phải có ngày không nằm trong quá khứ; `interval` phải có `intervalMinutes >= 30` và giờ kết thúc sau giờ bắt đầu.

---

## 7. Thông báo (kết hợp `uhabits` & `WaterMe`)

### 7.1 Quy tắc ID
`notificationId = reminderId * 100 + slot`:
- `slot = 0`: cho `once` và `daily`.
- `slot = 1..7`: cho từng thứ trong tuần (`weekly`, Thứ 2 = 1 .. Chủ nhật = 7).
- `slot = 10..29`: cho các mốc giờ trong ngày của kiểu lặp chu kỳ `interval` (tối đa 20 mốc từ `10` đến `29`, mỗi mốc dùng `matchDateTimeComponents: DateTimeComponents.time`).
- `slot = 99`: để dành cho nút Hoãn (Snooze 10 phút).

Nhờ quy tắc nhân 100 này, khi sửa hoặc xóa một nhắc có `reminderId`, chỉ cần hủy các ID từ `reminderId * 100` đến `reminderId * 100 + 99`.

### 7.2 Cách lên lịch
- `daily`: một thông báo với `matchDateTimeComponents: DateTimeComponents.time`.
- `weekly`: mỗi thứ được chọn một thông báo với `DateTimeComponents.dayOfWeekAndTime`.
- `interval`: Tính danh sách các mốc `(hour, minute)` từ giờ bắt đầu đến `endHour:endMinute` cộng dần `intervalMinutes` (hỗ trợ cả trường hợp khung giờ qua nửa đêm cho ca đêm), sau đó đặt thông báo lặp hằng ngày (`DateTimeComponents.time`) cho từng mốc vào `slot = 10 + index` (tối đa 20 slot).
- `once`: `zonedSchedule` thường, không lặp.

```dart
tz.TZDateTime nextInstanceOf(int hour, int minute) {
  final now = tz.TZDateTime.now(tz.local);
  var t = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
  if (!t.isAfter(now)) {
    t = tz.TZDateTime(tz.local, now.year, now.month, now.day + 1, hour, minute);
  }
  return t;
}
```
*Lưu ý: Tên tham số `flutter_local_notifications` và `flutter_timezone` có thể thay đổi theo phiên bản hiện hành, phải đối chiếu README / API thực tế của package đã cài.*

### 7.3 Khởi tạo
- `tz.initializeTimeZones()` rồi `tz.setLocalLocation(tz.getLocation(...))` từ `FlutterTimezone.getLocalTimezone()`.
- Tạo 4 notification channel: `task` (Công việc), `meal` (Ăn uống), `hydration` (Uống nước & Giải lao), `sleep` (Ngủ nghỉ).
- Xin quyền thông báo lúc chạy (Android 13+ và iOS), **không xin ngay khi mở app lần đầu** mà xin khi người dùng bấm chọn Bộ lịch mẫu hoặc tạo nhắc đầu tiên.

### 7.4 Cấu hình Android
- Quyền trong `AndroidManifest.xml`: `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `SCHEDULE_EXACT_ALARM` (nếu dùng alarm chính xác).
- Khai báo receiver khởi động lại để lịch sống sót sau reboot (theo README plugin, gồm `ScheduledNotificationReceiver` và `ScheduledNotificationBootReceiver`).
- Bật core library desugaring trong `android/app/build.gradle(.kts)`.
- Icon thông báo: tạo `ic_notification` trong `android/app/src/main/res/drawable`.

### 7.5 Alarm chính xác hay không chính xác
- Thử dùng `exactAllowWhileIdle`; nếu bị từ chối thì tự rơi về `inexactAllowWhileIdle` và hiện giải thích trong Cài đặt.

### 7.6 iOS
- Xin quyền lúc chạy; làm theo phần iOS setup trong README plugin (`AppDelegate`, `Info.plist`).

### 7.7 Khi nào phải lên lịch lại toàn bộ (`rescheduleAll`)
- Mở app, sau mỗi lần thêm/sửa/xóa/bật/tắt, khi đổi Bộ lịch mẫu (Preset), khi áp dụng lịch dinh dưỡng & giấc ngủ, khi đổi cài đặt giờ ngủ hoặc giờ ăn, khi múi giờ máy đổi, và sau khi khởi động lại máy.

### 7.8 Giới hạn hệ thống
- iOS chỉ giữ 64 thông báo sắp kích hoạt nhất; Samsung có giới hạn khoảng 500 alarm. Dùng cơ chế cửa sổ trượt giới hạn tối đa ~50 thông báo gần nhất khi cần.

---

## 8. Màn hình

| Màn hình | Nội dung chính |
| :--- | :--- |
| **Hôm nay (Home)** | Thanh tiến độ hoàn thành trong ngày + Chuỗi ngày (Streak). 2 phân khu rõ ràng: Công việc hôm nay (`Work Schedule`) và Thói quen sinh hoạt (`Daily Routine`: Ăn, Uống nước, Ngủ). Mỗi thẻ hiện giờ, nhãn loại, ghi chú thực phẩm/cách làm, nút lớn Xong / Bỏ qua chỉ 1 chạm. |
| **Thêm/Sửa nhắc** | Tên, loại (`task`/`meal`/`hydration`/`sleep`), tích chọn Thói quen cố định hay Việc trong ngày, mức ưu tiên, giờ, kiểu lặp (`once`/`daily`/`weekly`/`interval`), ghi chú, công tắc bật. |
| **Thể trạng, Dinh dưỡng & Giấc ngủ** | Phần 1: Form nhập Thể trạng (Tuổi, Giới tính, Chiều cao, Cân nặng, Vận động, Mục tiêu, Chế độ ăn Đa dạng/Chay trứng sữa/Thuần chay, Ca làm việc Ban ngày/Ca đêm/Xoay ca, Công tắc Tập Gym kèm Giờ tập, Lưu ý sức khỏe).<br>Phần 2: Thẻ kết quả phân tích (BMI chuẩn Châu Á, BMR/TDEE & Calo mục tiêu, Lượng đạm g/ngày, Tỷ lệ đĩa ăn, Tổng lượng nước & chu kỳ uống nước).<br>Phần 3: Lịch Giấc ngủ (Giờ đi ngủ, Ngừng ăn, Ngừng Caffeine, Chuẩn bị ngủ) & Khung giờ ăn cá nhân hóa kèm thực phẩm gợi ý.<br>Nút "Áp dụng Lịch Dinh dưỡng & Giấc ngủ": tạo/cập nhật các nhắc ăn, uống nước, ngủ vào DB và gọi `rescheduleAll`. |
| **Thống kê (Stats)** | Học từ `iSoron/uhabits`: Hiển thị chuỗi ngày duy trì (Streak) và biểu đồ cột/thanh 7 ngày gần nhất cho tỷ lệ hoàn thành Công việc và Sinh hoạt. |
| **Cài đặt** | Chọn Bộ lịch mẫu (4 Presets cho mọi lứa tuổi), chỉnh giờ ăn mặc định, chu kỳ uống nước, trạng thái quyền (thông báo, báo thức chính xác, tối ưu pin đèn xanh/đỏ), nút mở cài đặt hệ thống, liên kết `dontkillmyapp.com` theo hãng máy. |

Giao diện: Tiếng Việt, giờ 24h, Material 3, hỗ trợ chế độ tối, chữ đủ lớn (>= 16sp body) và hỗ trợ trợ năng.

---

## 9. App tham khảo
- `GavinBDev/HabitMaker` & `SubhamTyagi/ToDo`: tách `isRoutine` và `priority`.
- `iSoron/uhabits`: Streak & lịch sử `CompletionLog` 7 ngày.
- `D3vNe0/WaterMe` & `Crazy-Marvin/WaterReminder`: nhắc chu kỳ `interval`.
- `Astronaut Daily`: ràng buộc lịch sinh học vào 4 Bộ lịch mẫu (Presets).

---

## 10. Cơ sở khoa học & Tuyên bố sức khỏe
- Ngủ người lớn: 7–9 giờ (CDC/ATS), mặc định 7.5 giờ.
- Ngừng ăn tối trước giờ ngủ 2–4 giờ (mặc định 3 giờ).
- Ngừng caffeine tối thiểu 6–8 giờ trước khi ngủ (mặc định 8 giờ cho ca ngày, 7 giờ cho ca đêm).
- **Tuyên bố trong app (bắt buộc hiển thị ở màn Giấc ngủ/Dinh dưỡng và Cài đặt):**
  *"Nội dung chỉ mang tính tham khảo chung về lối sống lành mạnh cho người khỏe mạnh, không thay thế tư vấn của bác sĩ hay chuyên gia dinh dưỡng; người có bệnh nền, đang dùng thuốc hoặc có vấn đề giấc ngủ nên hỏi ý kiến chuyên gia y tế."*

---

## 11. Kế hoạch test trên điện thoại thật
- Xử lý hạn chế pin theo hãng máy (`dontkillmyapp.com`: Samsung, Xiaomi, Oppo, Vivo, Honor).
- Kịch bản T1–T11 và bảng ghi kết quả test trên máy thật.
- Màn Cài đặt kiểm tra `Permission.notification`, `Permission.ignoreBatteryOptimizations` và quyền báo thức chính xác (`scheduleExactAlarm`), hiện đèn xanh/đỏ, nút mở cài đặt hệ thống và liên kết `dontkillmyapp.com`.

---

## 12. Lộ trình từng Phase
- **Phase 0:** `chore: scaffold project` — Tạo project `nhac_nho`, cài packages, tạo cây thư mục, bật core library desugaring.
- **Phase 1:** `feat: data layer and extended body profile` — Entities, repositories, SQLite (`app_database.dart`), `SharedPreferences`, test `reminder_repository_test.dart`.
- **Phase 2:** `feat: domain logic with gym, vegan and night shift analyzer` — `SleepPlanner`, `BodyNutritionAnalyzer`, `WorkMealGuide`, `HabitStatsCalculator`, unit tests đầy đủ.
- **Phase 3:** `feat: notifications` — `NotificationScheduler`, `NotificationSchedulerImpl`, `AndroidManifest.xml`, `ic_notification`, `time_utils.dart`, unit tests.
- **Phase 4:** `feat: main ui with complete body nutrition planner` — `router.dart`, `providers.dart`, `reminder_controller.dart`, 4 màn hình chính + widget test form.
- **Phase 4B:** `feat: theme and accessibility` — `app_theme.dart` (FlexColorScheme + Be Vietnam Pro + Dynamic Color + High Contrast), `category_style.dart`, Semantics, `flutter_animate`, widget test `textScaler = 2.0` + dark mode.
- **Phase 5:** `feat: settings, presets and permissions` — `settings_screen.dart` hoàn chỉnh với 4 Presets, giờ mặc định, trạng thái quyền, xin quyền đúng thời điểm.
- **Phase 6:** `chore: polish` — Rà soát nghiệm thu, `README.md`, tuyên bố sức khỏe, nút Hoãn 10 phút (slot 99), `flutter analyze`, `flutter test`, `flutter build apk --debug`.
- **Phase 7:** `feat: universal smart scheduler, adaptive food matrix and visual timeline ui overhaul` — Mở rộng hệ thống lập lịch động theo giờ thức thực tế (`UniversalDayScheduler`, `UserTaskInput`), ma trận thực phẩm 4 chiều (`AdaptiveFoodCatalog`, `DailyFocusMode`), 7 bộ mẫu khởi tạo nhanh, trợ lý 3 bước (`SmartPlannerSheet`), giao diện Visual Timeline 4 buổi & Bento Grid (`fl_chart`, `lucide_icons_flutter`, `flutter_slidable`, theo dõi nước `+200ml`), đạt **67/67 tests** (bao gồm `textScaler = 2.0` ở Light/Dark/HighContrast).

---

## 16. Kiến trúc Phase 7: Universal Smart Planner & Bento UI
- **Lập lịch Động theo Nhịp sống Cá nhân (`UniversalDayScheduler` & `UserTaskInput`):**
  - Không áp đặt giờ hành chính cố định; tự neo lịch theo `wakeTime` và `sleepHours` thực tế từ `UserSettings` (hỗ trợ cả ca đêm / xoay ca).
  - Phân bổ công việc theo `TaskEnergyDemand` (`highFocus` vào đỉnh năng lượng sinh học, `mediumTask`, `lightChore`, `physicalOrEvent`), tự dịch bữa ăn nếu trùng lịch cố định và chèn nhắc nghỉ/uống nước cho việc kéo dài >= 60 phút.
- **Ma trận Thực phẩm 4 Chiều (`AdaptiveFoodCatalog`) & 7 Bộ mẫu khởi tạo nhanh (`PresetId`):**
  - Lọc thực đơn Việt theo 4 chiều: Thể trạng/Bệnh lý (`BodyProfile`), Chế độ ăn (`omnivore`, `vegetarian`, `vegan`), Nhu cầu ưu tiên trong ngày (`DailyFocusMode`: `brainFocus`, `staminaPhysical`, `leanAntiBloat`, `digestiveComfort`, `quickBudget`), và xoay vòng biến thể qua `swapMealOption(...)` / **Đổi món** trực tiếp trên thẻ.
  - Bổ sung từ 4 lên 7 bộ mẫu khởi tạo nhanh: `officeCoder`, `student`, `freelancer`, `modelAesthetic`, `homemakerParent`, `activeWorker`, `seniorHealth`.
- **Trợ lý 3 bước & Giao diện Visual Timeline / Bento Grid:**
  - `SmartPlannerSheet`: 3 bước (1. Chọn `DailyFocusMode` & mẫu nhanh -> 2. Nhập việc tự do / Smart Chips, thời lượng, mức năng lượng, giờ cố định/tự động -> 3. Xem trước dòng thời gian, đổi món & áp dụng giữ nguyên streak qua `replaceRoutineReminders`).
  - `HomeScreen`, `SleepPlannerScreen`, `StatsScreen`: Nâng cấp Visual Timeline 4 buổi (`Sáng`, `Trưa`, `Chiều`, `Tối`), thanh chọn 7 ngày, Bento Grid với `fl_chart` (Donut, PieChart, BarChart), theo dõi nước uống `+200ml` (`waterIntakeMlProvider`), thao tác vuốt `flutter_slidable`, biểu tượng `lucide_icons_flutter` và thẻ bo góc `20dp`.

---

## 13. Tiêu chí nghiệm thu
- `flutter analyze` không lỗi, `flutter test` xanh.
- `SleepPlanner`, `BodyNutritionAnalyzer` và `HabitStatsCalculator` đúng quy tắc mục 6 và có test.
- 4 Bộ lịch mẫu (Presets) hoạt động mượt, tạo đúng danh sách việc làm + ăn uống + uống nước + giấc ngủ.
- Tạo nhắc `daily`, `weekly`, `interval`, `once` đều lên lịch đúng; sửa/xóa/tắt nhắc không còn thông báo cũ.
- Nhắc còn hiệu lực sau reboot (receiver khai báo chuẩn).
- Màn Cài đặt phản ánh đúng trạng thái quyền.
- Có tuyên bố sức khỏe trong app.
- `README.md` có hướng dẫn chạy và test.

---

## 15. UI/UX & Trợ năng đa lứa tuổi
- **Theme (`app_theme.dart`):** FlexColorScheme Material 3 (sáng/tối), phông `Be Vietnam Pro` (`google_fonts`), hỗ trợ `dynamic_color`, tự đổi sang theme tương phản cao khi `MediaQuery.of(context).accessibilityFeatures.highContrast` bật.
- **Category Style (`category_style.dart`):** Độ tương phản chữ/màu >= 4.5:1 (WCAG AA):
  - `task`: Xanh dương đậm + `Icons.work_outline` + `"Công việc"`
  - `meal`: Cam ấm / Xanh lá đậm + `Icons.restaurant_outlined` + `"Ăn uống"`
  - `hydration`: Xanh ngọc đậm + `Icons.water_drop_outlined` + `"Uống nước & Nghỉ"`
  - `sleep`: Tím chàm + `Icons.bedtime_outlined` + `"Giấc ngủ"`
- **Trợ năng:** Body >= 16sp, vùng chạm tối thiểu 48x48 dp, nhãn `Semantics` tiếng Việt cho nút icon, không tràn khi `textScaler = 2.0`, hiệu ứng `flutter_animate` nhẹ nhàng không chớp nháy.