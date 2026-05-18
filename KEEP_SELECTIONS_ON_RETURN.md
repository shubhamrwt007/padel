# Keep Selections When Returning from Payment

## New Feature

When user returns from payment page to book session page, the selected slots are now **kept selected** if they are still available (not booked by someone else).

## How It Works

### Flow:

1. **User selects multiple slots** across multiple courts ✅
2. **User taps "Book Now"** ✅
3. **Slots are locked** with user's userId ✅
4. **User navigates to payment page** ✅
5. **User cancels/completes payment and returns** 🔙
6. **System unlocks the slots** 🔓
7. **System refreshes slot data** 🔄
8. **System validates each selection** 🔍
   - ✅ **Available** → Keep selected
   - ✅ **Locked by current user** → Keep selected
   - ❌ **Booked by others** → Remove from selection
9. **User sees their selections preserved** (if still available) ✅

## Code Changes

### 1. Modified `cleanupOnBack()` Method

**File:** `book_session_controller.dart`

```dart
Future<void> cleanupOnBack() async {
  // Reset navigation flag
  isNavigatingToPayment.value = false;
  
  // Unlock slots via API
  await repository.deleteSlotHistory(data: {"slots": _lockedSlotsData});
  _lockedSlotsData.clear();
  
  // Refresh slots to get updated status WITHOUT clearing selections
  await getAvailableCourtsById(
    locationID.value,
    categoryId.value,
    sId.value,
    argument.id!,
    showUnavailable: true,
    preserveSelections: true,  // NEW: Keep selections during refresh
  );
  
  // After refresh, validate and keep only available slots
  _validateAndKeepAvailableSelections();
}
```

### 2. Added `preserveSelections` Parameter

**File:** `book_session_controller.dart`

```dart
Future<void> getAvailableCourtsById(
  String locationId,
  String categoryId,
  String sID,
  String clubId,
  {
    bool showUnavailable = false,
    bool preserveSelections = false,  // NEW parameter
  }
) async {
  // ... fetch and update slots
}
```

### 3. New Method: `_validateAndKeepAvailableSelections()`

**File:** `book_session_controller.dart`

This method checks each selected slot and decides whether to keep or remove it:

```dart
void _validateAndKeepAvailableSelections() {
  // Build map of current slot statuses
  final Map<String, Slots> currentSlotMap = {};
  for (final court in slots.value?.data ?? []) {
    for (final slot in court.slots ?? []) {
      currentSlotMap[slot.sId!] = slot;
    }
  }
  
  final keysToRemove = <String>[];
  final currentUserId = storage.read("userId") ?? "";
  
  multiDateSelections.forEach((key, selection) {
    final slot = selection['slot'] as Slots;
    final currentSlot = currentSlotMap[slot.sId];
    
    // Slot not found - remove
    if (currentSlot == null) {
      keysToRemove.add(key);
      return;
    }
    
    final status = currentSlot.status?.toLowerCase() ?? '';
    final slotUserId = currentSlot.userId ?? '';
    
    // Keep if available
    if (status == 'available') {
      log('✅ Keeping - slot is available');
      return;
    }
    
    // Keep if locked by current user
    if (status == 'lock' && slotUserId == currentUserId) {
      log('✅ Keeping - locked by current user');
      return;
    }
    
    // For 30-min slots, check specific half
    if (supports30Min && isLeftHalf != null) {
      final leftBooked = isLeftHalfBooked(currentSlot);
      final rightBooked = isRightHalfBooked(currentSlot);
      
      if ((isLeftHalf && !leftBooked) || (!isLeftHalf && !rightBooked)) {
        log('✅ Keeping - half slot is available');
        return;
      }
    }
    
    // Otherwise remove
    log('❌ Removing - slot is no longer available');
    keysToRemove.add(key);
  });
  
  // Remove unavailable slots
  for (final key in keysToRemove) {
    multiDateSelections.remove(key);
    // Also clean up selectedSlots and selectedSlotsWithCourtInfo
  }
  
  _recalculateTotalAmount();
  
  if (keysToRemove.length > 0) {
    AppToast.info('${keysToRemove.length} slot(s) were booked by others');
  }
}
```

### 4. Updated `_checkAndUnlockSlots()` in UI

**File:** `book_session.dart`

```dart
Future<void> _checkAndUnlockSlots() async {
  if (controller.hasCalledSlotHistoryAPI.value) {
    // Call cleanup which handles everything:
    // - Unlock slots
    // - Refresh data
    // - Validate selections
    await controller.cleanupOnBack();
    controller.hasCalledSlotHistoryAPI.value = false;
    
    // No need to refresh again - cleanupOnBack already does it
  }
}
```

## Validation Logic

The `_validateAndKeepAvailableSelections()` method checks each selected slot:

### Keep Selection If:
- ✅ Slot status is `available`
- ✅ Slot status is `lock` AND `userId` matches current user
- ✅ For 30-min slots: The specific half (left/right) is not booked

### Remove Selection If:
- ❌ Slot not found in refreshed data
- ❌ Slot status is `booked`
- ❌ Slot status is `lock` by a different user
- ❌ For 30-min slots: The specific half is booked
- ❌ Slot has maintenance/weather/unavailable status

## User Experience

### Scenario 1: All Slots Still Available
```
User selects: Slot A, Slot B, Slot C
User goes to payment → Returns
Status: All available
Result: ✅ All 3 slots remain selected
Message: No toast (all kept)
```

### Scenario 2: Some Slots Booked by Others
```
User selects: Slot A, Slot B, Slot C
User goes to payment → Returns
Status: A=available, B=booked, C=available
Result: ✅ Slot A and C remain selected, Slot B removed
Message: "1 slot(s) were booked by others and removed from your selection"
```

### Scenario 3: All Slots Booked by Others
```
User selects: Slot A, Slot B, Slot C
User goes to payment → Returns
Status: All booked by others
Result: ❌ All slots removed
Message: "3 slot(s) were booked by others and removed from your selection"
```

### Scenario 4: 30-Min Slots (Mixed)
```
User selects: Slot A (left half), Slot A (right half), Slot B (left half)
User goes to payment → Returns
Status: A-left=available, A-right=booked, B-left=available
Result: ✅ A-left and B-left remain selected, A-right removed
Message: "1 slot(s) were booked by others and removed from your selection"
```

## Testing Checklist

Test these scenarios:

### Test 1: All Slots Available
- [ ] Select 3 slots across 2 courts
- [ ] Tap "Book Now"
- [ ] Cancel payment and return
- [ ] Verify all 3 slots remain selected ✅
- [ ] Verify no error toast

### Test 2: One Slot Booked
- [ ] Select 3 slots
- [ ] Tap "Book Now"
- [ ] Have another user book 1 of those slots
- [ ] Cancel payment and return
- [ ] Verify 2 slots remain selected ✅
- [ ] Verify 1 slot is removed ❌
- [ ] Verify toast: "1 slot(s) were booked by others..."

### Test 3: All Slots Booked
- [ ] Select 2 slots
- [ ] Tap "Book Now"
- [ ] Have another user book both slots
- [ ] Cancel payment and return
- [ ] Verify all slots are removed ❌
- [ ] Verify toast: "2 slot(s) were booked by others..."

### Test 4: 30-Min Slots
- [ ] Select both halves of a slot (if supported)
- [ ] Tap "Book Now"
- [ ] Have another user book one half
- [ ] Cancel payment and return
- [ ] Verify available half remains selected ✅
- [ ] Verify booked half is removed ❌

## Expected Logs

When returning from payment, you should see:

```
🔍 _checkAndUnlockSlots called
🔓 Unlocking slots after returning to BookSession
🧹 cleanupOnBack() called
🔓 Unlocking X slot(s) via deleteSlotHistory API
✅ Successfully unlocked slots
🔄 Refreshing slots to check availability
🔍 Validating X selected slots
✅ Slot 10:00 AM (slotId) is available - keeping selection
✅ Slot 11:00 AM (slotId) is available - keeping selection
❌ Slot 12:00 PM (slotId) status is booked - removing
🗑️ Removing 1 unavailable slots from selection
✅ Slots unlocked and selections validated
```

## Benefits

1. **Better UX**: Users don't lose their selections when returning from payment
2. **Smart Validation**: Only removes slots that are actually unavailable
3. **Transparent**: Shows toast message when slots are removed
4. **Handles Edge Cases**: Works with 30-min slots, multiple courts, etc.
5. **Safe**: Always validates against latest data from server

## Important Notes

- Selections are validated AFTER unlocking slots and refreshing data
- Socket updates are still blocked during navigation (via `isNavigatingToPayment` flag)
- Only slots that are truly unavailable are removed
- User is notified via toast when slots are removed
- Total amount is recalculated after validation
