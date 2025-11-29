# Stability Threshold Configuration Fix

## Problem
Auto-complete weighing was not firing even when the weight was within min/max range, especially when testing with percentage-based tolerance. The stability detection used a **hard-coded 50g (0.05kg) threshold** which could be too strict for testing scenarios.

## Solution
Implemented **configurable stability threshold** that allows users to adjust the maximum weight difference (in kg) to consider readings as "stable".

## Changes Made

### 1. Settings Service (`lib/services/settings_service.dart`)
**Added:**
- New field: `double _stabilityThreshold = 0.05` (default 50g)
- Getter: `stabilityThreshold`
- Update method: `updateStabilityThreshold(double threshold)` with range 0.01kg-1.0kg
- Persistence: Load/save from SharedPreferences

### 2. Weight Stability Monitor (`lib/services/weight_stability_monitor.dart`)
**Changed:**
- Removed hard-coded constant: `static const double _stabilityThreshold = 0.05`
- Added configurable field: `double _stabilityThreshold`
- Updated constructor to accept: `required double stabilityThreshold`
- Uses injected threshold value in `_checkStability()` method

### 3. Weighing Station Controller (`lib/screens/weighing_station/controllers/weighing_station_controller.dart`)
**Updated:**
- Pass `settings.stabilityThreshold` when creating WeightStabilityMonitor
- Enhanced debug log to show threshold value

### 4. Settings UI (`lib/screens/settings/settings_screen.dart`)
**Added:**
- New slider control under "Tự động hoàn tất" section
- Range: 0.01kg to 1.0kg (displayed as grams: 10g to 1000g)
- Label shows current value in grams for better readability

## Testing Scenarios

### Scenario 1: Strict Mode (Production)
- Set threshold to **0.05kg (50g)** - requires very stable readings
- Use for final production weighing

### Scenario 2: Normal Mode (Default)
- Set threshold to **0.1kg (100g)** - standard tolerance
- Good for most testing and regular operation

### Scenario 3: Lenient Mode (Testing)
- Set threshold to **0.2kg (200g)** or higher
- Use with "test %" setting mentioned by user
- Allows auto-complete to fire even with slight fluctuations

### Scenario 4: Very Lenient Mode (Debug)
- Set threshold to **0.5kg (500g)** or **1.0kg (1000g)**
- For initial testing or with unstable scales

## How It Works

### Stability Detection Flow:
1. User sets threshold in Settings → saved to SharedPreferences
2. WeighingStationController loads settings on init
3. Passes `stabilityThreshold` to WeightStabilityMonitor constructor
4. Monitor accumulates weight samples over stabilization delay period
5. Checks if `(maxWeight - minWeight) <= stabilityThreshold`
6. If stable AND weight in min/max range → triggers auto-complete

### Example Workflow:
```
Settings: threshold = 0.2kg (200g)
Current weight: 5.05 kg
Last 5 samples: [5.00, 5.04, 5.05, 5.03, 5.02]
Range: 5.00 - 5.05 = 0.05kg ✅ Within 0.2kg threshold
Result: ✅ STABLE → Auto-complete triggered
```

## Debug Information

### Console Logs Show:
```
📊 Khởi tạo theo dõi ổn định (Delay: 5s, Threshold: 0.2kg)
📊 Kiểm tra ổn định: diff=0.05 kg (ngưỡng=0.2kg), mẫu=50/50, ổn định=true
✅ Cân ổn định! (Chênh lệch: 0.05 kg, Giá trị: 5.05 kg)
✅ Cân ổn định (5.05 kg)! Đợi 2s...
```

## Files Modified
- ✅ `lib/services/settings_service.dart` - Added threshold setting
- ✅ `lib/services/weight_stability_monitor.dart` - Made threshold configurable
- ✅ `lib/screens/weighing_station/controllers/weighing_station_controller.dart` - Pass threshold
- ✅ `lib/screens/settings/settings_screen.dart` - Added UI slider

## User Instructions

### To Test Auto-Complete with Looser Tolerance:
1. Open **Settings** screen
2. Enable **"Bật tự động hoàn tất"** (Enable auto-complete)
3. Find slider: **"Độ chênh lệch tối đa (test)"**
4. Drag slider to desired tolerance (e.g., 200g for testing)
5. Go back to Weighing Station
6. Place item on scale - should now auto-complete more easily

### Recommended Settings:
- **Production**: 50g (0.05kg) - very accurate
- **Testing**: 100-200g (0.1-0.2kg) - normal
- **Debug**: 300-500g (0.3-0.5kg) - very lenient

## Technical Notes

- Threshold applies to all weight readings (not percentage-based)
- Works with both Bluetooth and simulated weight for testing
- Threshold change takes effect immediately (no restart needed)
- Default value (50g) preserved if user hasn't changed settings

## Benefits

✅ Auto-complete now works with user-configurable tolerance
✅ Can be adjusted for different scales (commercial vs lab-grade)
✅ Perfect for testing scenarios ("test %" use case)
✅ Settings persist between app sessions
✅ Real-time adjustment without app restart
