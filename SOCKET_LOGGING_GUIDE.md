# Socket Data Logging Guide - Team Swap

## What Was Added

Comprehensive logging has been added to the `onScoreboardSwapped` socket listener in `score_board_controller.dart`.

## Where to Find Logs

When a user swaps teams, check your console/logcat for these logs:

### 1. Basic Data Structure
```
🔄 ========== SCOREBOARD SWAPPED EVENT RECEIVED ==========
🔄 Full data: {entire data object}
🔄 Data type: _InternalLinkedHashMap<String, dynamic>
🔄 Data is not null
🔄 Data is a Map
🔄 Available keys: [key1, key2, key3, ...]
```

### 2. Detailed Key-Value Pairs
```
🔍 KEY: "scoreboardId" => VALUE: 69cce0add939cfffdf0a0150 (String)
🔍 KEY: "isSwappingDuringMatch" => VALUE: true (bool)
🔍 KEY: "swapXpChanges" => VALUE: [{...}, {...}] (List)
🔍 KEY: "teams" => VALUE: [{...}, {...}] (List)
```

### 3. XP Changes Data (CRITICAL)
```
💰 SWAP XP CHANGES FOUND: [{playerId: xxx, xpChange: 182.42, result: W}, ...]
💰 swapXpChanges is a List with 4 items
💰 Player 0: {playerId: 69b7be786be85c6111f852c2, xpChange: 182.42, result: W}
💰 Player 1: {playerId: 69cce1e7d939cfffdf0a8093, xpChange: 219.02, result: W}
💰 Player 2: {playerId: 696e5aa4c5a128b24b3dac75, xpChange: -126.62, result: L}
💰 Player 3: {playerId: 69cce1f8d939cfffdf0aa738, xpChange: -85.56, result: L}
```

### 4. Alternative Key Names
```
💰 PLAYER XP CHANGES FOUND: [...]  // If backend uses 'playerXpChanges' instead
```

### 5. Missing Data Warning
```
⚠️ swapXpChanges NOT FOUND in socket data
```

## What to Check

### ✅ Expected Data Structure

Backend should send:
```json
{
  "scoreboardId": "69cce0add939cfffdf0a0150",
  "isSwappingDuringMatch": true,
  "swapXpChanges": [
    {
      "playerId": "69b7be786be85c6111f852c2",
      "xpChange": 182.42,
      "result": "W"
    },
    {
      "playerId": "69cce1e7d939cfffdf0a8093",
      "xpChange": 219.02,
      "result": "W"
    },
    {
      "playerId": "696e5aa4c5a128b24b3dac75",
      "xpChange": -126.62,
      "result": "L"
    },
    {
      "playerId": "69cce1f8d939cfffdf0aa738",
      "xpChange": -85.56,
      "result": "L"
    }
  ],
  "teams": [...],
  "preShuffleWinner": "Team A",
  "preShuffleTeamAWins": 2,
  "preShuffleTeamBWins": 1
}
```

### ❌ Common Issues to Look For

1. **Missing swapXpChanges**
   - Log will show: `⚠️ swapXpChanges NOT FOUND in socket data`
   - Solution: Backend needs to add this field

2. **Wrong Key Name**
   - Backend might use `playerXpChanges` instead of `swapXpChanges`
   - Check logs for: `💰 PLAYER XP CHANGES FOUND`

3. **Empty Array**
   - Log will show: `💰 swapXpChanges is a List with 0 items`
   - Solution: Backend needs to calculate XP for all 4 players

4. **Wrong Data Type**
   - Check the type in logs: `(${value.runtimeType})`
   - Should be: `List<dynamic>` or `List`

## Testing Steps

1. **Start a match** with 4 players
2. **Play some sets** (e.g., Team A wins 2-1)
3. **Swap teams** during the match
4. **Check console logs** immediately after swap
5. **Look for** the 🔄 and 💰 emoji logs

## What Backend Needs to Send

Based on your data structure, backend should emit:

```javascript
io.to(`scoreboard_${scoreboardId}`).emit('scoreboardSwapped', {
  scoreboardId: scoreboardId,
  isSwappingDuringMatch: true,
  swapXpChanges: [
    {
      playerId: '69b7be786be85c6111f852c2',
      xpChange: 182.42,
      result: 'W'
    },
    {
      playerId: '69cce1e7d939cfffdf0a8093',
      xpChange: 219.02,
      result: 'W'
    },
    {
      playerId: '696e5aa4c5a128b24b3dac75',
      xpChange: -126.62,
      result: 'L'
    },
    {
      playerId: '69cce1f8d939cfffdf0aa738',
      xpChange: -85.56,
      result: 'L'
    }
  ],
  teams: [...],
  preShuffleWinner: 'Team A',
  preShuffleTeamAWins: 2,
  preShuffleTeamBWins: 1
});
```

## Next Steps After Logging

Once you see the logs:

1. **If swapXpChanges is present** → Share the log output with frontend team to implement popup logic
2. **If swapXpChanges is missing** → Share the log output with backend team to add this field
3. **If data structure is different** → Update the key names in frontend code accordingly

## Log Filtering

To filter logs in your IDE/terminal:
- Android Studio: Filter by "🔄" or "💰" or "SWAP XP"
- VS Code: Search for "SCOREBOARD SWAPPED EVENT"
- Terminal: `adb logcat | grep "SWAP XP"`

## Example Complete Log Output

```
🔄 ========== SCOREBOARD SWAPPED EVENT RECEIVED ==========
🔄 Full data: {scoreboardId: 69cce0add939cfffdf0a0150, isSwappingDuringMatch: true, swapXpChanges: [...], teams: [...]}
🔄 Data type: _InternalLinkedHashMap<String, dynamic>
🔄 COMPLETE SOCKET DATA: {scoreboardId: 69cce0add939cfffdf0a0150, ...}
🔄 Data is not null
🔄 Data is a Map
🔄 Available keys: [scoreboardId, isSwappingDuringMatch, swapXpChanges, teams, preShuffleWinner, preShuffleTeamAWins, preShuffleTeamBWins]
🔍 KEY: "scoreboardId" => VALUE: 69cce0add939cfffdf0a0150 (String)
🔍 KEY: "isSwappingDuringMatch" => VALUE: true (bool)
🔍 KEY: "swapXpChanges" => VALUE: [{playerId: 69b7be786be85c6111f852c2, xpChange: 182.42, result: W}, ...] (List<dynamic>)
🔍 KEY: "teams" => VALUE: [{name: Team A, players: [...]}, {name: Team B, players: [...]}] (List<dynamic>)
🔍 KEY: "preShuffleWinner" => VALUE: Team A (String)
🔍 KEY: "preShuffleTeamAWins" => VALUE: 2 (int)
🔍 KEY: "preShuffleTeamBWins" => VALUE: 1 (int)
💰 SWAP XP CHANGES FOUND: [{playerId: 69b7be786be85c6111f852c2, xpChange: 182.42, result: W}, ...]
💰 swapXpChanges is a List with 4 items
💰 Player 0: {playerId: 69b7be786be85c6111f852c2, xpChange: 182.42, result: W}
💰 Player 1: {playerId: 69cce1e7d939cfffdf0a8093, xpChange: 219.02, result: W}
💰 Player 2: {playerId: 696e5aa4c5a128b24b3dac75, xpChange: -126.62, result: L}
💰 Player 3: {playerId: 69cce1f8d939cfffdf0aa738, xpChange: -85.56, result: L}
🔄 isSwappingDuringMatch value: true
🔄 isSwappingDuringMatch type: bool
```

This is the IDEAL log output you should see! ✅
