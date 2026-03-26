# Team Shuffle Popup - Final Solution

## Problem
When swapping teams during an active match, the win/loss popup was not showing.

## Root Cause
The app was waiting for a `teamShuffleResult` socket event from the backend, but the backend was only emitting `scoreboardSwapped`.

## Solution
The app now handles the shuffle result directly from the `scoreboardSwapped` event when `isSwappingDuringMatch` is true.

## How It Works

### Flow Diagram
```
User swaps teams during match
  ↓
Client sends API request with match state
  ↓
API updates teams in database
  ↓
Backend emits 'scoreboardSwapped' to all players
  ↓
All 4 players receive 'scoreboardSwapped' event
  ↓
Client checks if isSwappingDuringMatch = true
  ↓
Client calculates team results (WIN/LOSE/DRAW)
  ↓
Client shows popup to user
  ↓
Client resets match after popup is closed
```

## Code Changes

### 1. Client Sends Match State in API Request

```dart
final body = {
  'scoreboardId': scoreboardId.value,
  'action': 'swap',
  'teams': updatedTeams,
  'isSwappingDuringMatch': isSwappingDuringMatch,
  'preShuffleWinner': preShuffleWinner.value,
  'preShuffleTeamAWins': preShuffleTeamAWins.value,
  'preShuffleTeamBWins': preShuffleTeamBWins.value,
};
```

### 2. Client Handles scoreboardSwapped Event

```dart
repository.onScoreboardSwapped((data) {
  // Check if swap happened during match
  if (data['isSwappingDuringMatch'] == true) {
    // Calculate results
    String teamAResult = calculateResult(...);
    String teamBResult = calculateResult(...);
    
    // Show popup
    showTeamsShuffleResultDialog(
      teamAResult: teamAResult,
      teamBResult: teamBResult,
    );
    
    // Reset match
    _restartMatchAfterShuffle();
  }
  
  // Update UI
  fetchScoreBoard(showLoader: false);
});
```

### 3. Backend Requirements (Optional Enhancement)

The backend can optionally calculate XP and include it in the response:

```javascript
socket.on('scoreboardSwapped', async (data) => {
  const { scoreboardId, teams, isSwappingDuringMatch, preShuffleWinner, preShuffleTeamAWins, preShuffleTeamBWins } = data;
  
  // Update teams
  await updateTeams(scoreboardId, teams);
  
  // If swapping during match, calculate XP
  if (isSwappingDuringMatch) {
    const xpEarned = calculateXP(preShuffleTeamAWins, preShuffleTeamBWins);
    const xpLost = calculateXP(preShuffleTeamAWins, preShuffleTeamBWins);
    
    // Update player XP in database
    await updatePlayerXP(...);
    
    // Include XP in the broadcast
    data.xpEarned = xpEarned;
    data.xpLost = xpLost;
    data.currentXP = xpEarned;
    data.xpChange = xpEarned;
  }
  
  // Broadcast to all players
  io.to(scoreboardId).emit('scoreboardSwapped', data);
});
```

## Testing Steps

### Test 1: Swap During Match
1. Start a match with 4 players
2. Click "Start Game"
3. Add a set with scores (e.g., Team A: 6, Team B: 4)
4. Click swap icon
5. Swap at least one player
6. Click checkmark to save

**Expected Result:**
- ✅ All 4 players see win/loss popup
- ✅ Popup shows correct result (WIN/LOSE/DRAW)
- ✅ Match resets after popup is closed
- ✅ Teams are updated

### Test 2: Swap Before Match
1. Add 4 players
2. Click swap icon (before starting game)
3. Swap players
4. Click checkmark to save

**Expected Result:**
- ✅ No popup shown
- ✅ Teams are updated
- ✅ Can start game normally

### Test 3: Multiple Swaps
1. Start match and add scores
2. Swap teams (popup shows)
3. Close popup
4. Start new game
5. Add scores
6. Swap teams again

**Expected Result:**
- ✅ Popup shows both times
- ✅ No duplicate popups
- ✅ Match resets each time

## Logs to Verify

When swapping during match, you should see:

```
🔄 SWAP INITIATED - isSwappingDuringMatch: true
📤 SENDING SWAP API BODY
✅ SWAP API CALL SUCCESSFUL
📡 scoreboardSwapped SOCKET EVENT EMITTED
⏳ Waiting for backend to process...
🔄 Team swap received: {data with isSwappingDuringMatch: true}
🎯 Swap during match detected - will show shuffle result
🏆 Calculated results - Team A: WIN, Team B: LOSE
🔔 SHUFFLE RESULT FROM SWAP
✅ Dialog closed, resetting match
```

## Key Features

### 1. No Backend Changes Required
The solution works with the current backend that only emits `scoreboardSwapped`.

### 2. All Players See Popup
The `scoreboardSwapped` event is broadcast to all players in the room, so everyone sees the popup.

### 3. No Duplicate Popups
The `isShowingShuffleResultDialog` flag prevents duplicate popups.

### 4. Proper Match Reset
After the popup is closed, the match state is reset for all players.

### 5. XP Support
If the backend includes XP values in the `scoreboardSwapped` event, they will be displayed in the popup.

## Troubleshooting

### Issue: Popup Not Showing

**Check logs for:**
```
🔄 SWAP INITIATED - isSwappingDuringMatch: false
```

**Solution:** Make sure you:
1. Started the game
2. Added at least one set
3. Added scores to the set

### Issue: Popup Shows Wrong Result

**Check logs for:**
```
🏆 Calculated results - Team A: WIN, Team B: LOSE
```

**Solution:** Verify the pre-shuffle winner and scores are correct.

### Issue: Match Not Resetting

**Check logs for:**
```
✅ Dialog closed, resetting match
```

**Solution:** Check for errors in `_restartMatchAfterShuffle()`.

## Summary

The solution:
- ✅ Shows popup when swapping during match
- ✅ Works for all 4 players simultaneously
- ✅ No duplicate popups
- ✅ Resets match properly
- ✅ Works with current backend
- ✅ Supports XP display (if backend provides it)
- ✅ Handles edge cases (swap before match, multiple swaps)

The key insight is that we don't need a separate `teamShuffleResult` event - we can handle everything from the `scoreboardSwapped` event by including the match state in the request.
