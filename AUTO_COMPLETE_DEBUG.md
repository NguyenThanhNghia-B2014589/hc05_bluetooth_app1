// File để debug tự động hoàn tất

// Vấn đề gặp phải:
// 1. autoCompleteEnabled mặc định là FALSE
// 2. Phải bật từ Settings trước
// 3. Sau đó quay lại Weighing Screen

// Cách kiểm tra:
// 1. Mở Settings
// 2. Tìm phần "Tự động hoàn tất"
// 3. Bật Toggle "Bật tự động hoàn tất" ✅
// 4. Chọn thời gian ổn định (5 giây - mặc định)
// 5. Quay lại Trạm Cân
// 6. Scan mã
// 7. Đặt hàng lên cân
// 8. Chờ ~5-7 giây → nên tự động hoàn tất

// Nhật ký sửa lỗi:
// ✅ Fix 1: Thay đổi currentWeight từ _records[0].qtys → bluetoothService.currentWeight.value
// ✅ Fix 2: Thêm reset monitor khi scan mã mới
// ✅ Fix 3: Đổi logic từ "check 1 lần" sang "check định kỳ (500ms)"
// ✅ Fix 4: Thêm _wasStable flag để tránh gọi callback nhiều lần

// Log debug cần xem:
// 📊 Khởi tạo theo dõi ổn định (Delay: 5s)
// 📊 Kiểm tra ổn định: diff=X kg, ổn định=true
// ✅ Cân ổn định!
// ✅ Cân đã ổn định! Sẽ hoàn tất sau 2s...
