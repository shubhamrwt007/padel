# Debug Steps for Swap During Match Issue

## Step 1: Check Console Logs

Jab swap karo, console mein yeh logs dikhne chahiye:

### Initiator Player (Jo swap kar raha hai):
```
📊 PREPARE SHUFFLE SESSION - Winner: Team A, Team A: 2, Team B: 1, User in Team A: true, User in Team B: false
========== SENDING SWAP API ==========
✅ SWAP API CALL SUCCESSFUL
🏆 Match completed received: {isSwapDuringMatch: true, ...}
📊 PRE-SHUFFLE DATA FROM SOCKET:
   Winner: Team A
   Team A Wins: 2
   Team B Wins: 1
   User in Team A (before swap): true
   User in Team B (before swap): false
🔍 ========== GET MATCH RESULT ==========
🔍 preShuffleUserInTeamA: true
🏆 Result: WIN
```

### Other 3 Players:
```
🏆 Match completed received: {isSwapDuringMatch: true, ...}
📊 PRE-SHUFFLE DATA FROM SOCKET:
   Winner: Team A
   Team A Wins: 2
   Team B Wins: 1
   User in Team A (before swap): true/false
   User in Team B (before swap): false/true
🔍 ========== GET MATCH RESULT ==========
🔍 preShuffleUserInTeamA: true/false
🏆 Result: WIN/LOSS
```

## Step 2: Check Backend Socket Emission

Backend ko yeh emit karna chahiye:
```javascript
io.to(`scoreboard_${scoreboardId}`).emit('matchCompleted', {
  scoreboardId: "xxx",
  isSwapDuringMatch: true,
  preShuffleWinner: "Team A",
  preShuffleTeamAWins: 2,
  preShuffleTeamBWins: 1,
  xpEarned: 100,
  xpLost: 50
});
```

## Step 3: Agar Logs Nahi Dikhe

1. Check if backend is emitting the event
2. Check if all players are connected to socket
3. Check if scoreboardId is correct
4. Check if players are in the same room

## Step 4: Agar DRAW Dikhe

Check these values in console:
- `preShuffleWinner` - Should be "Team A" or "Team B", NOT empty
- `preShuffleUserInTeamA` - Should be true/false based on player's team
- `preShuffleTeamAWins` and `preShuffleTeamBWins` - Should NOT be equal

## Step 5: Manual Test

Run this in console to check values:
```dart
print('Winner: ${controller.preShuffleWinner.value}');
print('Team A Wins: ${controller.preShuffleTeamAWins.value}');
print('Team B Wins: ${controller.preShuffleTeamBWins.value}');
print('User in Team A: ${controller.preShuffleUserInTeamA.value}');
print('User in Team B: ${controller.preShuffleUserInTeamB.value}');
```
