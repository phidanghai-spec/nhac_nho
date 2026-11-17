# Nhắc Nhở — Công việc, Ăn uống, Giấc ngủ & Thói quen

Ứng dụng Flutter 100% Offline giúp quản lý lịch làm việc trong ngày, thói quen sinh hoạt (ăn uống, uống nước định kỳ theo chu kỳ, nghỉ giải lao, giấc ngủ) và phân tích thể trạng/dinh dưỡng cá nhân hóa.

## Tính năng chính
- **4 loại nhắc & phân biệt đa giác quan (WCAG AA):** Công việc (`task`), Ăn uống (`meal`), Uống nước & Nghỉ (`hydration`), Giấc ngủ (`sleep`) — mỗi loại có màu tương phản >= 4.5:1, icon riêng và nhãn tiếng Việt.
- **4 kiểu lặp thông báo cục bộ:** Một lần (`once`), Hằng ngày (`daily`), Theo thứ (`weekly`), và Theo chu kỳ phút (`interval` — ví dụ uống nước mỗi 90 phút, hỗ trợ cả khung giờ qua nửa đêm cho ca đêm). Hỗ trợ nút **Hoãn 10 phút** trên Android (slot 99).
- **4 Bộ lịch mẫu (Presets):** Dân văn phòng / Coder, Học sinh / Sinh viên, Người làm tự do (Freelancer), Người lớn tuổi / Chăm sóc sức khỏe.
- **Phân tích Thể trạng, Dinh dưỡng & Giấc ngủ (`BodyNutritionAnalyzer` & `SleepPlanner`):**
  - Tính BMI (chuẩn Châu Á), BMR (Mifflin-St Jeor), TDEE, lượng đạm/ngày, tỷ lệ đĩa ăn, lượng nước & chu kỳ uống nước.
  - Hỗ trợ chế độ ăn **Ăn đa dạng / Chay trứng sữa / Thuần chay**, **Tập Gym** (Pre/Post-workout, +600ml nước), **Ca làm việc** (Ban ngày / Ca đêm / Xoay ca neo theo giờ thức) và lưu ý sức khỏe (Đau dạ dày/Trào ngược, Đường huyết, Lớn tuổi/Tim mạch).
- **Thống kê thói quen:** Tính chuỗi ngày duy trì (Streak >= 80% thói quen) và biểu đồ tỷ lệ hoàn thành 7 ngày gần nhất.
- **Trợ năng đa lứa tuổi:** Material 3 (FlexColorScheme + Dynamic Color + High Contrast), font `Be Vietnam Pro`, body >= 16sp, vùng chạm >= 48x48dp, không tràn bố cục ở mức phóng to chữ 200% (`textScaler = 2.0`).

## Kiến trúc
4 tầng phụ thuộc một chiều: `presentation → application → domain ← data` (tầng `domain` là Dart thuần).

## Yêu cầu môi trường
- Flutter SDK `3.50.0+` (Dart `3.14.0+`)
- Java JDK 17 (`JAVA_HOME`)
- Android SDK với `compileSdk = 37`, `cmdline-tools`, `platform-tools` (`ANDROID_HOME`)

## Cách chạy ứng dụng
```bash
cd nhac_nho
flutter pub get
flutter run
```

## Cách chạy kiểm tra mã nguồn & test
```bash
cd nhac_nho
flutter analyze
flutter test
flutter build apk --debug
```

## Ảnh màn hình
Đã xuất 10 ảnh PNG cho 5 màn hình chính (Light & Dark) trong thư mục [docs/screenshots](docs/screenshots):
- **Hôm nay:** `01_home_light.png` / `01_home_dark.png`
- **Thêm/Sửa nhắc:** `02_reminder_form_light.png` / `02_reminder_form_dark.png`
- **Thể trạng, Dinh dưỡng & Giấc ngủ:** `03_sleep_nutrition_light.png` / `03_sleep_nutrition_dark.png`
- **Thống kê 7 ngày:** `04_stats_light.png` / `04_stats_dark.png`
- **Cài đặt & Quyền hệ thống:** `05_settings_light.png` / `05_settings_dark.png`

## Bảng ghi kết quả test trên máy thật (Mục 11.3)
| Máy / Hãng / Android | T1 | T2 | T3 | T4 | T5 | T6 | T7 | T8 | T9 | T10 | T11 | Ghi chú |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| *(Chưa test máy thật)* | | | | | | | | | | | | Cần cắm cáp USB (`adb devices`) và kiểm tra T1–T11 |

## Tuyên bố sức khỏe
Nội dung chỉ mang tính tham khảo chung về lối sống lành mạnh cho người khỏe mạnh, không thay thế tư vấn của bác sĩ hay chuyên gia dinh dưỡng; người có bệnh nền, đang dùng thuốc hoặc có vấn đề giấc ngủ nên hỏi ý kiến chuyên gia y tế.
