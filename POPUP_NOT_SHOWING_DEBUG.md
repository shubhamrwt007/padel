# Troubleshooting: Popup Not Showing When Swapping Teams

## Issue
After fixing the double popup, now the popup is not showing at all when swapping teams during a match.

## What to Check

### 1. Check Console Logs

When you swap teams during a match, look for these logs in order:

#### On Initiator Device:
```
🔄 SWAP INITIATED - isSwappingDuringMatch: true, isGameStarted: true, sets.length: X
📊 PRE-SHUFFLE STATE - Winner: Team A, Team A: 2, Team B: 1
📤 SENDING SWAP API BODY
✅ SWAP API CALL SUCCESSFUL
📡 SOCKET EVENT EMITTED
🎯 SWAPPING DURING MATCH - Preparing shuffle result
🏆 TEAM RESULTS - Team A: WIN, Team B: LOSE
📊 PREPARING XP DATA - Earned: X, Lost: Y
📤 EMITTING SHUFFLE RESULT DATA: {full data}
📡 TEAM SHUFFLE RESULT EMITTED TO ALL PLAYERS
⏳ Waiting for socket to propagate...
✅ Socket propagation complete
```

Then after 1 second:
```
🏆 Team shuffle result received: {data}
🔔 SOCKET HANDLER CALLED - isShowingShuffleResultDialog: false
🔍 FULL SOCKET DATA: {data}
```

#### On Other Players' Devices:
```
🏆 Team shuffle result received: {data}
🔔 SOCKET HANDLER CALLED - isShowingShuffleResultDialog: false
🔍 FULL SOCKET DATA: {data}
```

### 2. Check If Socket Event Is Being Emitted

Look for this log:
```
📤 SOCKET: teamShuffleResult emitted: {data}
```

If you see:
```
❌ SOCKET: Cannot emit teamShuffleResult - socket not connected
```

**Problem**: Socket is not connected
**Solution**: Check socket connection in `onInit()`

### 3. Check If Socket Event Is Being Received

Look for this log on ALL 4 devices:
```
🏆 SOCKET: teamShuffleResult received: {data}
```

If you DON'T see this:
- **Problem**: Socket event not reaching devices
- **Solution**: Check backend socket emission

### 4. Check If Handler Is Being Called

Look for this log:
```
🔔 SOCKET HANDLER CALLED - isShowingShuffleResultDialog: false
```

If you DON'T see this:
- **Problem**: Socket listener not registered or callback not firing
- **Solution**: Check `onTeamShuffleResult()` registration in `onInit()`

### 5. Check Match State

Look for this log:
```
🔄 SWAP INITIATED - isSwappingDuringMatch: true, isGameStarted: true, sets.length: X
```

If you see:
```
⚠️ NOT swapping during match - no shuffle result dialog
```

**Problem**: The match is not considered "active"
**Possible causes**:
- `isGameStarted.value` is `false`
- `sets.length` is `0`

**Solution**: Make sure you've started the game and added at least one set with scores

## Common Scenarios

### Scenario 1: "isSwappingDuringMatch: false"

**Logs:**
```
🔄 SWAP INITIATED - isSwappingDuringMatch: false, isGameStarted: false, sets.length: 0
⚠️ NOT swapping during match - no shuffle result dialog
```

**Cause**: Game hasn't started or no sets added
**Solution**: 
1. Click "Start Game" button
2. Add at least one set
3. Add scores to the set
4. Then try swapping teams

### Scenario 2: Socket Event Not Received

**Logs on initiator:**
```
📡 TEAM SHUFFLE RESULT EMITTED TO ALL PLAYERS
⏳ Waiting for socket to propagate...
✅ Socket propagation complete
```

**But NO logs on other devices**

**Cause**: Backend not emitting to all players
**Solution**: Check backend code - ensure it emits to the room:
```javascript
io.to(scoreboardId).emit('teamShuffleResult', data);
```

### Scenario 3: Socket Not Connected

**Logs:**
```
❌ SOCKET: Cannot emit teamShuffleResult - socket not connected
```

**Cause**: Socket connection lost or never established
**Solution**:
1. Check if `joinScoreboard()` was called in `onInit()`
2. Check socket connection status
3. Restart the app

### Scenario 4: Handler Called But No Dialog

**Logs:**
```
🔔 SOCKET HANDLER CALLED - isShowingShuffleResultDialog: false
🔍 FULL SOCKET DATA: {data}
```

**But dialog doesn't appear**

**Cause**: Error in `showTeamsShuffleResultDialog()`
**Solution**: Check for errors in the dialog code or Get.dialog() call

## Step-by-Step Testing

### Test 1: Verify Match Is Active
1. Start a match with 4 players
2. Click "Start Game"
3. Add a set
4. Add scores (e.g., Team A: 6, Team B: 4)
5. Check logs - should see: `isGameStarted: true, sets.length: 1`

### Test 2: Verify Socket Connection
1. Open the app
2. Navigate to scoreboard
3. Check logs for: `🔵 SCOREBOARD ID: xxx`
4. Check logs for: `🚪 Joined scoreboard: xxx`
5. Check logs for: `🎯 Socket listener registered for teamShuffleResult`

### Test 3: Verify Swap Detection
1. Click swap button (swap icon)
2. Swap at least one player
3. Click checkmark to save
4. Check logs for: `🔄 SWAP INITIATED - isSwappingDuringMatch: true`

### Test 4: Verify Socket Emission
1. After saving swap
2. Check logs for: `📡 TEAM SHUFFLE RESULT EMITTED TO ALL PLAYERS`
3. If you see `❌ Cannot emit`, socket is not connected

### Test 5: Verify Socket Reception
1. Check ALL 4 devices
2. Each should show: `🏆 Team shuffle result received`
3. If only initiator sees it, backend issue
4. If nobody sees it, socket emission failed

### Test 6: Verify Handler Execution
1. After receiving socket event
2. Check logs for: `🔔 SOCKET HANDLER CALLED`
3. Check logs for: `🔍 FULL SOCKET DATA`
4. If you don't see these, handler not registered

## Quick Fix Checklist

- [ ] Match is started (`isGameStarted: true`)
- [ ] At least one set exists (`sets.length > 0`)
- [ ] Socket is connected (no "Cannot emit" errors)
- [ ] Socket event is emitted (see "EMITTED TO ALL PLAYERS")
- [ ] Socket event is received on all devices (see "received" on all 4)
- [ ] Handler is called (see "SOCKET HANDLER CALLED")
- [ ] No errors in handler execution

## Backend Requirements

The backend MUST:

1. **Listen for the emit from client**:
   ```javascript
   socket.on('teamShuffleResult', (data) => {
     console.log('Received teamShuffleResult:', data);
     // Broadcast to all players in the room
     io.to(data.scoreboardId).emit('teamShuffleResult', data);
   });
   ```

2. **Broadcast to ALL players** including the sender:
   ```javascript
   io.to(scoreboardId).emit('teamShuffleResult', data);
   ```

3. **NOT use `socket.broadcast.emit()`** (this excludes the sender)

## If Still Not Working

1. **Check if backend is receiving the emit**:
   - Add console.log in backend socket handler
   - Verify data is received

2. **Check if backend is broadcasting**:
   - Add console.log before io.to().emit()
   - Verify it's emitting to the room

3. **Check room membership**:
   - Verify all 4 players joined the room
   - Check socket.rooms on backend

4. **Share the logs**:
   - Copy all logs from initiator device
   - Copy logs from one other player device
   - Share for debugging

## Expected Flow

```
1. User swaps teams during match
   ↓
2. isSwappingDuringMatch = true ✓
   ↓
3. API call succeeds ✓
   ↓
4. Socket emits teamShuffleResult ✓
   ↓
5. Backend receives emit ✓
   ↓
6. Backend broadcasts to room ✓
   ↓
7. All 4 devices receive event ✓
   ↓
8. Handler called on all devices ✓
   ↓
9. Dialog shows on all devices ✓
```

If any step fails, the popup won't show. Use the logs to identify which step is failing.
