# 🤖 Chức Năng Tự Động Hoàn Tất Cân - Hướng Dẫn Sử Dụng

## 📋 Tổng Quan
Tính năng tự động hoàn tất cân cho phép ứng dụng tự động hoàn tất quy trình cân khi cân bị ổn định trong một khoảng thời gian xác định. Điều này giúp tăng tốc độ và hiệu suất làm việc.

---

## ⚙️ Cài Đặt Có Sẵn

Tất cả các cài đặt được lưu trữ trong **Settings Screen** và tự động lưu vào SharedPreferences.

### 1. **Bật/Tắt Tự Động Hoàn Tất**
- **Vị trí:** Settings → Tự động hoàn tất → "Bật tự động hoàn tất"
- **Mặc định:** `Tắt` (false)
- **Hiệu ứng:** Khi bật, các tùy chọn khác sẽ hiển thị

### 2. **Thời Gian Chờ Cân Ổn Định** ⏱️
- **Vị trí:** Settings → Tự động hoàn tất → "Thời gian chờ cân ổn định"
- **Lựa chọn:** 3 giây, **5 giây** (mặc định), 10 giây
- **Mô tả:** Thời gian hệ thống chờ cho đến khi cân không thay đổi nhiều hơn ±20g

### 3. **Thời Gian Hoàn Tất Sau Ổn Định**
- **Vị trí:** Settings → Tự động hoàn tất → "Thời gian hoàn tất (sau ổn định)"
- **Phạm vi:** 1 - 5 giây
- **Mặc định:** `2 giây`
- **Mô tả:** Độ trễ trước khi thực hiện hành động hoàn tất (sau khi cân ổn định)

### 4. **Phát Tiếng Bíp Khi Thành Công**
- **Vị trí:** Settings → Âm thanh → "Phát tiếng bíp khi cân thành công"
- **Mặc định:** `Bật` (true)
- **Hiệu ứng:** Rung điện thoại (heavy impact) khi cân hoàn tất thành công

---

## 🔄 Quy Trình Hoạt Động

### Khi Bật Tự Động Hoàn Tất:

1. **Khởi Tạo Monitoring** (`initWeightMonitoring`)
   - Gọi từ `WeighingStationScreen.initState()`
   - Tạo `WeightStabilityMonitor` với cài đặt từ `SettingsService`

2. **Thu Thập Mẫu Cân** (`addWeightSample`)
   - Mỗi khi trọng lượng từ Bluetooth cập nhật (ValueListenableBuilder)
   - Thêm vào danh sách theo dõi trong `WeightStabilityMonitor`

3. **Phát Hiện Ổn Định** (`_checkStability`)
   - So sánh chênh lệch min/max trong danh sách
   - Ngưỡng ổn định: **±20g (0.02 kg)**
   - Khi ổn định → gọi callback

4. **Lên Lịch Hoàn Tất** (`_onWeightStable`)
   - Đặt timer với độ trễ từ cài đặt
   - Chạy `completeCurrentWeighing()` sau độ trễ

5. **Phát Âm Thanh** (nếu bật)
   - Gọi `AudioService.playSuccessBeep()`
   - Rung điện thoại (HeavyImpact)

6. **Reset & Chờ Scan Tiếp Theo**
   - Đặt lại `_stabilityMonitor` cho mã mới

---

## 📁 Tệp Được Thêm/Sửa Đổi

### Tệp Mới Tạo:
1. **`lib/services/weight_stability_monitor.dart`**
   - `WeightStabilityMonitor` class
   - Phương thức: `addWeight()`, `_checkStability()`, `reset()`, `dispose()`

2. **`lib/services/audio_service.dart`**
   - `AudioService` class (Singleton)
   - Phương thức: `playSuccessBeep()`, `playDoubleBeep()`, `playErrorVibration()`

3. **`AUTO_COMPLETE_FEATURE.md`** (tệp này)

### Tệp Được Sửa Đổi:
1. **`lib/services/settings_service.dart`**
   - Thêm: `_autoCompleteEnabled`, `_stabilizationDelay`, `_autoCompleteDelay`, `_beepOnSuccess`
   - Thêm: Phương thức `updateAutoCompleteEnabled()`, `updateStabilizationDelay()`, v.v.

2. **`lib/screens/settings/settings_screen.dart`**
   - Thêm UI: Toggle switch, dropdown, slider
   - Helper widgets: `_buildSectionHeader()`, `_buildToggleSetting()`, `_buildSliderSetting()`

3. **`lib/screens/weighing_station/controllers/weighing_station_controller.dart`**
   - Thêm import: `weight_stability_monitor`, `audio_service`, `settings_service`
   - Thêm biến: `_stabilityMonitor`, `_autoCompleteTimer`, `_isAutoCompletePending`
   - Thêm phương thức: `initWeightMonitoring()`, `addWeightSample()`, `_onWeightStable()`, `cancelAutoComplete()`, `dispose()`

4. **`lib/screens/weighing_station/weighing_station_screen.dart`**
   - Sửa `initState()`: Gọi `_controller.initWeightMonitoring(context)`
   - Sửa `ValueListenableBuilder`: Gọi `_controller.addWeightSample(currentWeight)`

---

## 🎯 Ví Dụ Sử Dụng

### Kịch Bản: Cân Nhập với Tự Động Hoàn Tất

1. **Bước 1:** Mở Settings → Bật "Tự động hoàn tất" ✅
2. **Bước 2:** Chọn "Thời gian ổn định: 5 giây"
3. **Bước 3:** Chọn "Thời gian hoàn tất: 2 giây"
4. **Bước 4:** Bật "Phát tiếng bíp"
5. **Bước 5:** Quay lại Trạm Cân
6. **Bước 6:** Scan mã (ví dụ: `ITEM001`)
7. **Bước 7:** Đặt hàng lên cân, chờ cân ổn định (~5s)
8. **Bước 8:** 2 giây sau, tự động hoàn tất + rung điện thoại 📱
9. **Bước 9:** Có thể scan mã tiếp theo

---

## ⚠️ Lưu Ý Quan Trọng

### Điều Kiện Hoàn Tất Tự Động:
- ✅ Phải scan mã trước (không rỗng)
- ✅ Trọng lượng phải nằm trong phạm vi (min/max)
- ✅ Cân phải ổn định ở phạm vi ±20g
- ✅ Online hoặc Offline đều hoạt động

### Không Hoàn Tất Nếu:
- ❌ Tính năng tắt
- ❌ Chưa scan mã
- ❌ Trọng lượng ngoài phạm vi
- ❌ Mã đã cân trước đó (kiểm tra tránh lặp)

### Hủy Tự Động Hoàn Tất:
- Rời khỏi Trạm Cân → `cancelAutoComplete()` được gọi
- Timer và monitor được hủy
- An toàn không có memory leak

---

## 🔧 Tuỳ Chỉnh

### Thay Đổi Ngưỡng Ổn Định (±20g):
**File:** `lib/services/weight_stability_monitor.dart`
```dart
static const double _stabilityThreshold = 0.02; // 0.02 kg = 20g
// Thay thành 0.05 cho 50g, 0.10 cho 100g, v.v.
```

### Thay Đổi Ngôn Ngữ UI:
Tìm tất cả chuỗi trong `settings_screen.dart` và `weighing_station_screen.dart`

### Thêm Âm Thanh Thực Tế:
Hiện tại sử dụng `HapticFeedback`. Để phát âm thanh thực tế, bổ sung:
- Dependency: `audioplayers` hoặc `just_audio`
- Thêm asset (.wav/.mp3)
- Cập nhật `AudioService.playSuccessBeep()`

---

## 🐛 Debug & Troubleshooting

### Log Debug:
Bật `kDebugMode` (Flutter) để xem console:
- `✅ Cân ổn định!`
- `📊 Khởi tạo theo dõi ổn định...`
- `🔔 Phát tiếng bíp thành công!`

### Nếu Không Tự Động Hoàn Tất:
1. Kiểm tra Settings: Bật "Tự động hoàn tất"?
2. Kiểm tra: Scan mã chưa?
3. Kiểm tra: Cân ở trong phạm vi?
4. Kiểm tra: Cân có ổn định?
5. Xem log console để tìm lỗi

---

## 📝 Changelog

### v1.0 (18/11/2025)
- ✅ Thêm chức năng tự động hoàn tất
- ✅ Thêm cài đặt ổn định & độ trễ
- ✅ Thêm phát âm thanh (rung)
- ✅ Hỗ trợ Online/Offline
- ✅ Tài liệu hoàn chỉnh

---

**Tác Giả:** GitHub Copilot  
**Ngày:** 18/11/2025  
**Trạng Thái:** ✅ Hoàn Thành
