# DEBUG GUIDE: Popup Not Showing When Swapping Teams

## Step-by-Step Debugging

### Step 1: Verify Match is Active

**Before swapping teams, check these conditions:**

1. ✅ Game is started (clicked "Start Game" button)
2. ✅ At least one set exists
3. ✅ Set has scores (not 0-0)

**Look for this log when you click save:**
```
🔄 SWAP INITIATED - isSwappingDuringMatch: true, isGameStarted: true, sets.length: 1
```

**If you see `isSwappingDuringMatch: false`:**
- ❌ Game not started OR no sets added
- **Solution**: Start game and add scores first

---

### Step 2: Check What's Being Sent to API

**Look for these logs:**
```
========== SENDING SWAP API ==========
   ScoreboardId: abc123
   Action: swap
   isSwappingDuringMatch: true
   preShuffleWinner: Team A
   preShuffleTeamAWins: 2
   preShuffleTeamBWins: 1
   Teams: [...]
========================================
```

**If `isSwappingDuringMatch: false`:**
- ❌ Match state not detected
- **Check**: Did you start the game and add scores?

**If `preShuffleWinner` is empty or null:**
- ❌ Winner not calculated
- **Check**: Are there scores in the sets?

---

### Step 3: Check API Response

**Look for:**
```
✅ SWAP API CALL SUCCESSFUL
📡 scoreboardSwapped SOCKET EVENT EMITTED
```

**If you see error:**
```
❌ SWAP API CALL FAILED: [error message]
```
- ❌ API request failed
- **Solution**: Check backend logs

---

### Step 4: Check Socket Event Reception

**Look for:**
```
🔄 ========== SCOREBOARD SWAPPED EVENT RECEIVED ==========
🔄 Full data: {scoreboardId: abc123, isSwappingDuringMatch: true, ...}
🔄 Data type: _Map<String, dynamic>
🔄 Data is not null
🔄 Data is a Map
🔄 Available keys: [scoreboardId, action, teams, isSwappingDuringMatch, ...]
🔄 isSwappingDuringMatch value: true
```

**If you DON'T see this:**
- ❌ Socket event not received
- **Possible causes**:
  1. Backend not emitting the event
  2. Socket disconnected
  3. Not joined to scoreboard room

---

### Step 5: Check isSwappingDuringMatch in Socket Data

**Look for:**
```
🔄 isSwappingDuringMatch value: true
🔄 isSwappingDuringMatch type: bool
```

**If you see:**
```
⚠️ isSwappingDuringMatch is FALSE or null - no popup will show
```

**This means:**
1. Backend received `isSwappingDuringMatch: false` from client
2. OR backend didn't include it in the socket emission
3. OR backend modified the value

**Solution:**
- Check Step 2 - was it sent as `true`?
- Check backend - is it passing through the value?

---

### Step 6: Check Result Calculation

**Look for:**
```
📊 Pre-shuffle data:
   Winner: Team A
   Team A Wins: 2
   Team B Wins: 1
🔍 Normalized winner: "teama"
✅ Team A is winner
🏆 Final results - Team A: WIN, Team B: LOSE
```

**If winner is empty:**
- ❌ Winner data not in socket event
- **Check**: Backend needs to pass through `preShuffleWinner`

---

### Step 7: Check Dialog Scheduling

**Look for:**
```
🔔 Scheduling dialog to show in 500ms...
🔔 Delay complete, calling _handleTeamShuffleResultFromSwap
```

**If you see scheduling but no "Delay complete":**
- ❌ App might have crashed or error occurred
- **Check**: Look for error logs

---

### Step 8: Check Dialog Display

**Look for:**
```
🔔 SHUFFLE RESULT FROM SWAP - isShowingShuffleResultDialog: false
Showing shuffle result - Team A: WIN (2), Team B: LOSE (1)
```

**If you see:**
```
Shuffle result dialog already showing, skipping duplicate
```
- ❌ Dialog flag stuck
- **Solution**: Restart the app

---

## Common Issues & Solutions

### Issue 1: "isSwappingDuringMatch: false" in Step 2

**Cause**: Match not active

**Solution**:
1. Click "Start Game" button
2. Add a set (click "+ Add Set")
3. Add scores to the set (e.g., Team A: 6, Team B: 4)
4. Then try swapping

---

### Issue 2: Socket Event Not Received (Step 4)

**Cause**: Backend not emitting or socket disconnected

**Solution**:
1. Check backend logs - is it receiving the API request?
2. Check backend - is it emitting `scoreboardSwapped`?
3. Restart the app to reconnect socket

**Backend should do:**
```javascript
// Receive API request
app.put('/scoreboard', async (req, res) => {
  const { scoreboardId, isSwappingDuringMatch, ... } = req.body;
  
  // Update database
  await updateScoreboard(...);
  
  // Emit socket event with ALL the data from request
  io.to(scoreboardId).emit('scoreboardSwapped', req.body);
  
  res.json({ success: true });
});
```

---

### Issue 3: "isSwappingDuringMatch is FALSE" in Socket Data (Step 5)

**Cause**: Backend not passing through the value

**Solution**: Backend must include `isSwappingDuringMatch` in socket emission

**Backend should emit:**
```javascript
io.to(scoreboardId).emit('scoreboardSwapped', {
  scoreboardId,
  action: 'swap',
  teams: updatedTeams,
  isSwappingDuringMatch: req.body.isSwappingDuringMatch,  // ← MUST INCLUDE
  preShuffleWinner: req.body.preShuffleWinner,            // ← MUST INCLUDE
  preShuffleTeamAWins: req.body.preShuffleTeamAWins,      // ← MUST INCLUDE
  preShuffleTeamBWins: req.body.preShuffleTeamBWins       // ← MUST INCLUDE
});
```

---

### Issue 4: Only Initiator Sees Logs, Other Players Don't

**Cause**: Backend using `socket.emit()` instead of `io.to().emit()`

**Solution**: Backend must broadcast to room

**Wrong:**
```javascript
socket.emit('scoreboardSwapped', data);  // ❌ Only sender
```

**Correct:**
```javascript
io.to(scoreboardId).emit('scoreboardSwapped', data);  // ✅ All players
```

---

## Complete Test Scenario

### Setup:
1. Open app on 4 devices (or 4 browser tabs)
2. All 4 join the same match
3. Device 1 will be the "initiator"

### Test Steps:

**On Device 1:**
1. Click "Start Game"
2. Click "+ Add Set"
3. Add scores: Team A = 6, Team B = 4
4. Click swap icon (⇄)
5. Swap at least one player
6. Click checkmark (✓)

**Expected Logs on Device 1:**
```
🔄 SWAP INITIATED - isSwappingDuringMatch: true
========== SENDING SWAP API ==========
   isSwappingDuringMatch: true
   preShuffleWinner: Team A
   preShuffleTeamAWins: 1
   preShuffleTeamBWins: 0
✅ SWAP API CALL SUCCESSFUL
📡 scoreboardSwapped SOCKET EVENT EMITTED
🔄 ========== SCOREBOARD SWAPPED EVENT RECEIVED ==========
🔄 isSwappingDuringMatch value: true
🎯 ========== SWAP DURING MATCH DETECTED ==========
🏆 Final results - Team A: WIN, Team B: LOSE
🔔 Scheduling dialog to show in 500ms...
🔔 Delay complete, calling _handleTeamShuffleResultFromSwap
🔔 SHUFFLE RESULT FROM SWAP
[POPUP SHOWS]
```

**Expected Logs on Devices 2, 3, 4:**
```
🔄 ========== SCOREBOARD SWAPPED EVENT RECEIVED ==========
🔄 isSwappingDuringMatch value: true
🎯 ========== SWAP DURING MATCH DETECTED ==========
🏆 Final results - Team A: WIN, Team B: LOSE
🔔 Scheduling dialog to show in 500ms...
🔔 Delay complete, calling _handleTeamShuffleResultFromSwap
🔔 SHUFFLE RESULT FROM SWAP
[POPUP SHOWS]
```

---

## Quick Checklist

Before reporting the issue, verify:

- [ ] Game is started (not just players added)
- [ ] At least one set exists
- [ ] Set has scores (not 0-0)
- [ ] You see "isSwappingDuringMatch: true" in Step 2 logs
- [ ] You see "SCOREBOARD SWAPPED EVENT RECEIVED" in Step 4 logs
- [ ] You see "isSwappingDuringMatch value: true" in Step 5 logs
- [ ] You see "SWAP DURING MATCH DETECTED" in Step 5 logs
- [ ] You see "Scheduling dialog" in Step 7 logs
- [ ] You see "Delay complete" in Step 7 logs
- [ ] You see "SHUFFLE RESULT FROM SWAP" in Step 8 logs

**If ANY of these are missing, that's where the issue is!**

---

## Share These Logs

If the issue persists, copy and share:

1. **All logs from Step 2** (what's being sent)
2. **All logs from Step 4** (what's being received)
3. **All logs from Step 5** (isSwappingDuringMatch check)

This will show exactly where the flow is breaking.
