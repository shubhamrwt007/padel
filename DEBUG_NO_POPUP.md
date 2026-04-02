# Debug Guide: Popup Not Showing After Team Swap

## Step-by-Step Debugging

### Step 1: Check if swapPlayer Event is Emitted

**Expected Logs:**
```
📡 ========== EMITTING swapPlayer SOCKET EVENT ==========
📡 Socket Data: {scoreboardId: xxx, isSwappingDuringMatch: true, ...}
📤 SOCKET: swapPlayer emitted: {...}
✅ swapPlayer socket event emitted
```

**If NOT seeing these logs:**
- `savePlayerSwaps` method not being called
- Check if "Save" button is working
- Check if `hasPlayerSwaps.value` is true

---

### Step 2: Check if matchCompleted Event is Received

**Expected Logs:**
```
🏆 ========== MATCH COMPLETED EVENT RECEIVED ==========
🏆 Full data: {...}
🏆 Data type: _InternalLinkedHashMap<String, dynamic>
🔄 isSwapDuringMatch: true
🔍 Available keys: [scoreboardId, isSwapDuringMatch, xpChanges, ...]
```

**If NOT seeing these logs:**
- Backend is not emitting `matchCompleted` event
- Check backend logs
- Check if backend received `swapPlayer` event

---

### Step 3: Check XP Changes Array

**Expected Logs:**
```
💰 XP CHANGES ARRAY FOUND with 4 items
👤 Current User ID: 69b7be786be85c6111f852c2
💰 Player: 69b7be786be85c6111f852c2, XP: 120, Result: W
💰 Player: 69cce1e7d939cfffdf0a8093, XP: 120, Result: W
💰 Player: 696e5aa4c5a128b24b3dac75, XP: -60, Result: L
💰 Player: 69cce1f8d939cfffdf0aa738, XP: -60, Result: L
✅ FOUND CURRENT USER XP!
✅ Set xpEarned to: 120
```

**If seeing:**
```
⚠️ xpChanges array NOT FOUND in socket data
⚠️ Available keys: [...]
```
- Backend is not sending `xpChanges` array
- Check backend implementation

**If seeing:**
```
⚠️ CURRENT USER NOT FOUND IN XP CHANGES!
```
- Current user's ID doesn't match any player in xpChanges
- Check if `currentUserId` is correct
- Check if backend is sending correct player IDs

---

### Step 4: Check Dialog Trigger

**Expected Logs:**
```
🔄 Setting isCompleted to true
🔄 Setting wasSwapDuringMatch flag to true
📥 Fetching scoreboard...
🔔 Calling tryShowMatchSummaryDialog...
🔔 ========== tryShowMatchSummaryDialog CALLED ==========
🔔 isShowingMatchSummary: false
🔔 isCompleted: true
🔔 wasSwapDuringMatch: true
✅ Showing match summary dialog...
```

**If NOT seeing these logs:**
- Event handler not completing
- Check for errors in console

---

### Step 5: Check Dialog Display

**Expected Logs:**
```
🎭 ========== showMatchSummaryDialog CALLED ==========
🎭 _isOpeningMatchSummaryDialog: false
🔍 Getting match result...
🏆 SWAP DURING MATCH - Using XP changes to determine result
👤 Current User ID: 69b7be786be85c6111f852c2
✅ User WON - xpEarned: 120
🏆 Match result: _MatchResult.win
💬 Showing result dialog...
✅ Dialog shown successfully
🎭 ========== showMatchSummaryDialog COMPLETED ==========
```

**If seeing:**
```
⚠️ Dialog already opening, skipping
```
- Multiple calls happening too fast
- Should resolve automatically

**If seeing:**
```
⚠️ Dialog request too soon, skipping (XXXms)
```
- Multiple calls within 1500ms
- Should resolve automatically

---

## Common Issues & Solutions

### Issue 1: No Logs at All
**Problem:** Socket not connected or event not emitted

**Check:**
```
✅ SOCKET: Connected successfully!
🚪 Joined scoreboard: xxx
```

**Solution:**
- Restart app
- Check socket connection
- Check if `scoreboardId` is valid

---

### Issue 2: swapPlayer Emitted but matchCompleted Not Received
**Problem:** Backend not handling event

**Check Backend Logs:**
```
🔄 swapPlayer EVENT RECEIVED
🏆 SWAP DURING MATCH - Calculating XP...
📡 Emitting matchCompleted to room: scoreboard:xxx
```

**Solution:**
- Check backend implementation
- Verify backend is listening for `swapPlayer` event
- Verify backend is emitting to correct room

---

### Issue 3: matchCompleted Received but No xpChanges
**Problem:** Backend not sending xpChanges array

**Check Logs:**
```
⚠️ xpChanges array NOT FOUND in socket data
⚠️ Available keys: [scoreboardId, isSwapDuringMatch, ...]
```

**Solution:**
- Backend must send `xpChanges` array
- Share `BACKEND_SWAPPLAYER_SOCKET.md` with backend developer

---

### Issue 4: xpChanges Present but User Not Found
**Problem:** Player ID mismatch

**Check Logs:**
```
👤 Current User ID: 69b7be786be85c6111f852c2
💰 Player: DIFFERENT_ID, XP: 120, Result: W
⚠️ CURRENT USER NOT FOUND IN XP CHANGES!
```

**Solution:**
- Check if `currentUserId` is correct
- Check if backend is sending correct player IDs
- Player IDs must match exactly (case-sensitive)

---

### Issue 5: Dialog Not Showing Despite All Logs
**Problem:** UI issue or dialog already open

**Check:**
```
🔔 isShowingMatchSummary: true  ← Already showing
```

**Solution:**
- Close any open dialogs manually
- Restart app
- Check if `isShowingMatchSummary` is stuck at true

---

## Quick Test Commands

### 1. Check Socket Connection
```dart
print('Socket connected: ${repository._socket?.connected}');
print('Socket ID: ${repository._socket?.id}');
```

### 2. Check Current User ID
```dart
print('Current User ID: ${profileController.profileModel.value?.response?.sId}');
```

### 3. Check Controller State
```dart
print('isCompleted: ${controller.isCompleted.value}');
print('wasSwapDuringMatch: ${controller.wasSwapDuringMatch.value}');
print('xpEarned: ${controller.xpEarned.value}');
print('xpLost: ${controller.xpLost.value}');
```

### 4. Manually Trigger Dialog
```dart
controller.tryShowMatchSummaryDialog();
```

---

## Expected Complete Flow

```
1. User clicks Save after swapping teams
   📡 EMITTING swapPlayer SOCKET EVENT
   📤 SOCKET: swapPlayer emitted

2. Backend receives and processes
   [Backend] 🔄 swapPlayer EVENT RECEIVED
   [Backend] 🏆 Calculating XP...
   [Backend] 📡 Emitting matchCompleted

3. Frontend receives matchCompleted
   🏆 MATCH COMPLETED EVENT RECEIVED
   🔄 isSwapDuringMatch: true
   💰 XP CHANGES ARRAY FOUND with 4 items
   ✅ FOUND CURRENT USER XP!

4. Dialog is triggered
   🔔 tryShowMatchSummaryDialog CALLED
   🎭 showMatchSummaryDialog CALLED
   🏆 Match result: win/loss
   💬 Showing result dialog...
   ✅ Dialog shown successfully

5. User sees popup
   [UI] WIN/LOSS popup appears ✅
```

---

## What to Share

If popup still not showing, share these logs:

1. **Frontend logs** (from console)
2. **Backend logs** (if available)
3. **Which step is failing** (from above flow)

---

## Emergency Fix

If nothing works, try this:

```dart
// Add this in controller after swap
Future.delayed(Duration(seconds: 2), () {
  print('🚨 EMERGENCY: Manually triggering dialog');
  wasSwapDuringMatch.value = true;
  isCompleted.value = true;
  xpEarned.value = 100; // Dummy value for testing
  tryShowMatchSummaryDialog();
});
```

This will help identify if issue is with:
- Socket events (if manual trigger works)
- Dialog logic (if manual trigger also doesn't work)
