# XP Socket Data Debugging Guide

## Issue
XP values are showing fallback values (+100/-100) instead of dynamic values from socket data.

## What Was Fixed

### 1. Added Comprehensive Logging
- **Repository Level**: Added detailed logging in socket event handlers to see exact data received
- **Controller Level**: Added logging to track XP extraction and updates
- **Dialog Level**: Shows XP based on controller values

### 2. Multiple Key Support
The code now checks for XP in multiple possible keys:
- `xpEarned` (primary)
- `currentXP` (alternative)
- `xpChange` (alternative)

### 3. Type Safety
Added proper type checking to ensure data is a Map before accessing keys.

## How to Debug

### Step 1: Check Console Logs
When you swap players and the dialog appears, look for these logs:

```
🏆 SOCKET: teamShuffleResult received: {data}
🏆 SOCKET DATA KEYS: [list of keys]
🏆 XP DATA - xpEarned: value, currentXP: value, xpChange: value
🏆 XP DATA - xpLost: value
```

### Step 2: Check Controller Logs
Look for these logs in the controller:

```
🔍 FULL SOCKET DATA: {entire data object}
🔍 EXTRACTED XP - Earned: X, Lost: Y
🔍 AVAILABLE KEYS: [list of all keys in data]
✅ XP Earned updated to: X
✅ XP Lost updated to: Y
```

### Step 3: Check Emitted Data
When the initiator saves player swaps, look for:

```
📊 PREPARING XP DATA - Earned: X, Lost: Y
📤 EMITTING SHUFFLE RESULT DATA: {full data object}
📤 SOCKET: teamShuffleResult emitted: {data}
```

## Expected Socket Data Structure

The backend should send data in this format:

```json
{
  "scoreboardId": "abc123",
  "teamAResult": "WIN",
  "teamBResult": "LOSE",
  "teamAScore": 3,
  "teamBScore": 1,
  "xpEarned": 150,
  "xpLost": 50,
  "currentXP": 150,
  "xpChange": 150
}
```

## Common Issues & Solutions

### Issue 1: XP Values are 0
**Symptom**: Logs show `xpEarned: 0, xpLost: 0`

**Possible Causes**:
1. Backend is not calculating XP
2. Backend is not including XP in socket emission
3. XP is stored under a different key name

**Solution**:
- Check backend logs to see if XP is calculated
- Check what keys the backend is sending in the socket event
- Add the key name to the controller's key checking logic

### Issue 2: Socket Data is Empty
**Symptom**: Logs show `FULL SOCKET DATA: null` or `{}`

**Possible Causes**:
1. Socket event is not being emitted by backend
2. Socket connection is not established
3. Wrong event name

**Solution**:
- Check backend socket emission code
- Verify socket connection status
- Ensure event name matches: `teamShuffleResult`

### Issue 3: XP Shows +100/-100 (Fallback)
**Symptom**: Dialog shows fallback values instead of dynamic values

**Possible Causes**:
1. `controller.xpEarned.value` is 0
2. `controller.xpLost.value` is 0
3. XP values are not being updated from socket

**Solution**:
- Check if socket handler is being called
- Check if XP extraction logic is working
- Verify controller values are being updated

## Testing Checklist

Run through this checklist to verify the fix:

1. **Start a match with 4 players**
   - [ ] All players added
   - [ ] Match started
   - [ ] Scores added

2. **Swap players during active match**
   - [ ] Enter shuffle mode
   - [ ] Swap at least 2 players
   - [ ] Click save/checkmark

3. **Check logs for initiator (player who saved)**
   - [ ] See "PREPARING XP DATA" log
   - [ ] See "EMITTING SHUFFLE RESULT DATA" log
   - [ ] XP values are NOT 0

4. **Check logs for all 4 players**
   - [ ] All see "teamShuffleResult received" log
   - [ ] All see "FULL SOCKET DATA" log
   - [ ] All see "EXTRACTED XP" log
   - [ ] All see "XP Earned/Lost updated" log

5. **Check dialog display**
   - [ ] Winners see "+{actual_value} XP" (not +100)
   - [ ] Losers see "-{actual_value} XP" (not -100)
   - [ ] XP badge is color-coded correctly

## Backend Requirements

For this to work, the backend MUST:

1. **Calculate XP when match completes or teams shuffle**
   ```javascript
   const xpEarned = calculateXP(winner);
   const xpLost = calculateXP(loser);
   ```

2. **Include XP in socket emission**
   ```javascript
   io.to(scoreboardId).emit('teamShuffleResult', {
     scoreboardId,
     teamAResult: 'WIN',
     teamBResult: 'LOSE',
     teamAScore: 3,
     teamBScore: 1,
     xpEarned: 150,
     xpLost: 50,
     currentXP: 150,  // Alternative key
     xpChange: 150    // Alternative key
   });
   ```

3. **Emit to ALL players in the scoreboard room**
   ```javascript
   io.to(scoreboardId).emit('teamShuffleResult', data);
   ```

## Next Steps

1. **Run the app and swap players**
2. **Check the console logs** for the patterns above
3. **Share the logs** if XP is still showing +100/-100
4. **Verify backend** is sending XP data in socket events

The logs will tell us exactly what data is being received and where the issue is.
