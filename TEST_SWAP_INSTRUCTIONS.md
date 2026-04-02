# Test Instructions - Swap During Match

## Setup
1. 4 devices/emulators ready
2. All 4 players join same match
3. Start match and play 2-3 sets
4. Make sure Team A wins (e.g., 2-1)

## Test Scenario

### Before Swap:
```
Team A: Player1, Player2 (2 sets won) ✅ WINNERS
Team B: Player3, Player4 (1 set won) ❌ LOSERS
```

### Action:
Player1 clicks swap icon and swaps teams

### Expected Console Logs:

#### Player1 (Initiator):
```
📊 PREPARE SHUFFLE SESSION - Winner: Team A, Team A: 2, Team B: 1, User in Team A: true, User in Team B: false
🏆 Match completed received: {isSwapDuringMatch: true, ...}
📊 PRE-SHUFFLE DATA FROM SOCKET:
   Winner: Team A
   Team A Wins: 2
   Team B Wins: 1
   User in Team A (before swap): true
   User in Team B (before swap): false
🔍 ========== GET MATCH RESULT ==========
🔍 preShuffleUserInTeamA: true
🔍 preShuffleUserInTeamB: false
🏆 Result: WIN (Team A won, user WAS in Team A: true)
```

#### Player2 (Team A):
```
🏆 Match completed received: {isSwapDuringMatch: true, ...}
📊 PRE-SHUFFLE DATA FROM SOCKET:
   Winner: Team A
   Team A Wins: 2
   Team B Wins: 1
   User in Team A (before swap): true
   User in Team B (before swap): false
🔍 ========== GET MATCH RESULT ==========
🔍 preShuffleUserInTeamA: true
🔍 preShuffleUserInTeamB: false
🏆 Result: WIN (Team A won, user WAS in Team A: true)
```

#### Player3 (Team B):
```
🏆 Match completed received: {isSwapDuringMatch: true, ...}
📊 PRE-SHUFFLE DATA FROM SOCKET:
   Winner: Team A
   Team A Wins: 2
   Team B Wins: 1
   User in Team A (before swap): false
   User in Team B (before swap): true
🔍 ========== GET MATCH RESULT ==========
🔍 preShuffleUserInTeamA: false
🔍 preShuffleUserInTeamB: true
🏆 Result: LOSS (Team A won, user WAS in Team A: false)
```

#### Player4 (Team B):
```
🏆 Match completed received: {isSwapDuringMatch: true, ...}
📊 PRE-SHUFFLE DATA FROM SOCKET:
   Winner: Team A
   Team A Wins: 2
   Team B Wins: 1
   User in Team A (before swap): false
   User in Team B (before swap): true
🔍 ========== GET MATCH RESULT ==========
🔍 preShuffleUserInTeamA: false
🔍 preShuffleUserInTeamB: true
🏆 Result: LOSS (Team A won, user WAS in Team A: false)
```

### Expected Popups:
- Player1: **WIN** with +XP ✅
- Player2: **WIN** with +XP ✅
- Player3: **LOSS** with -XP ❌
- Player4: **LOSS** with -XP ❌

## If Still Showing DRAW:

### Check 1: Backend Socket Event
Backend must emit:
```javascript
io.to(`scoreboard_${scoreboardId}`).emit('matchCompleted', {
  scoreboardId: "xxx",
  isSwapDuringMatch: true,
  preShuffleWinner: "Team A",  // Must be "Team A" or "Team B"
  preShuffleTeamAWins: 2,
  preShuffleTeamBWins: 1,
  xpEarned: 100,
  xpLost: 50
});
```

### Check 2: Console Values
Agar DRAW dikhe, check karo:
```
🔍 preShuffleWinner: "???"  <- Should be "Team A" or "Team B", NOT empty
🔍 preShuffleTeamAWins: ???  <- Should be actual score
🔍 preShuffleTeamBWins: ???  <- Should be actual score
🔍 preShuffleUserInTeamA: ???  <- Should be true/false
```

### Check 3: Backend Logs
Backend pe check karo ki socket emit ho raha hai:
```
📤 Emitting matchCompleted to scoreboard_xxx
📤 Data: {isSwapDuringMatch: true, preShuffleWinner: "Team A", ...}
```

## Common Issues:

1. **Backend not emitting socket** - Check backend logs
2. **preShuffleWinner is empty** - Backend must send "Team A" or "Team B"
3. **isSwapDuringMatch is false** - Backend must set it to true
4. **Players not in same socket room** - Check socket connection

## Quick Debug Command:

Run this in Flutter DevTools console for each player:
```dart
final controller = Get.find<ScoreBoardController>();
print('=== DEBUG INFO ===');
print('wasSwapDuringMatch: ${controller.wasSwapDuringMatch.value}');
print('preShuffleWinner: "${controller.preShuffleWinner.value}"');
print('preShuffleTeamAWins: ${controller.preShuffleTeamAWins.value}');
print('preShuffleTeamBWins: ${controller.preShuffleTeamBWins.value}');
print('preShuffleUserInTeamA: ${controller.preShuffleUserInTeamA.value}');
print('preShuffleUserInTeamB: ${controller.preShuffleUserInTeamB.value}');
print('isUserInTeamA: ${controller.isUserInTeamA}');
print('isUserInTeamB: ${controller.isUserInTeamB}');
```
