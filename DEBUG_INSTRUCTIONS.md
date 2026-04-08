# Debug Instructions for Slot Selection Issue

## What I Fixed:

1. **Added `userId` field to Slots model** - to track which user locked/booked the slot
2. **Enhanced logging** - to see exactly what's happening
3. **Increased delay** - from 2 to 5 seconds to ignore socket updates after locking
4. **Fixed deselection logic** - to keep slots selected if they belong to current user

## How to Debug:

### Step 1: Run the app and watch the logs

When you select multiple slots and tap "Book Now", look for these logs:

```
🔒 Calling createAndGetSlotHistory API with X slots
✅ All locked slots belong to current user (userId: XXX), allowing navigation
⏸️ Ignoring socket update - Xs remaining after lock
```

### Step 2: Check if userId is being received

Look for these logs to see if userId is coming from socket:

```
🔍 _deSelectAndCleanupConflictingSlots - Current User ID: XXX
🔍 Slot XX:XX (slotId): status=lock, userId=XXX
🔍 Checking slot XX:XX (slotId): status=lock, slotUserId=XXX, currentUserId=XXX
```

### Step 3: Verify the comparison

If you see:
- `✅ Slot XX:XX (slotId) is lock by current user (XXX) - keeping selection` ✅ GOOD
- `❌ Slot XX:XX (slotId) is lock by different user - will deselect` ❌ BAD

### Common Issues:

1. **userId is empty/null in socket response**
   - Check if backend is sending userId in the slot data
   - Log: `userId=null` or `userId=`

2. **currentUserId is empty**
   - Check if storage.read("userId") is returning correct value
   - Log: `currentUserId=`

3. **Socket update comes before delay expires**
   - Should see: `⏸️ Ignoring socket update - Xs remaining after lock`
   - If not, the 5-second delay might not be enough

4. **Different userId format**
   - Check if userId from socket matches userId from storage
   - They might have different formats (e.g., "123" vs 123)

## What to Share:

Please share the complete logs from when you:
1. Select multiple slots
2. Tap "Book Now"
3. See slots getting deselected

Look for all logs with these emojis: 🔒 🔍 ✅ ❌ ⏸️
