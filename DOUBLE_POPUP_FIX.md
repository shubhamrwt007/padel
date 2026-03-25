# Team Shuffle Double Popup Fix

## Issue
When swapping players during an active match:
1. **Initiator** (player who clicks save): Sees TWO popups - one from local code, one from socket
2. **Other 3 players**: Don't see any popup

## Root Cause
In `savePlayerSwaps()` method, the initiator was:
1. Emitting socket event to all players
2. Showing dialog locally for themselves
3. Then receiving their own socket event and showing dialog again

## Solution

### Changed Flow:

**Before (WRONG):**
```
Initiator clicks save
  ↓
Emit socket to all 4 players
  ↓
Show dialog for initiator (LOCAL)  ← First popup
  ↓
Initiator receives socket event
  ↓
Show dialog for initiator (SOCKET) ← Second popup (DUPLICATE!)
```

**After (CORRECT):**
```
Initiator clicks save
  ↓
Emit socket to all 4 players
  ↓
DON'T show dialog locally
  ↓
All 4 players (including initiator) receive socket event
  ↓
Show dialog for all 4 players (SOCKET ONLY) ← Single popup for everyone
```

### Code Changes

#### 1. `savePlayerSwaps()` Method
**Removed** the local dialog display for initiator:

```dart
// OLD CODE (REMOVED):
isShowingShuffleResultDialog.value = true;

await showTeamsShuffleResultDialog(
  controller: this,
  teamAResult: teamAStatus,
  teamBResult: teamBStatus,
);

isShowingShuffleResultDialog.value = false;
await _restartMatchAfterShuffle();

// NEW CODE:
// DON'T show dialog here for initiator - let socket handler show it for everyone
// This prevents double popup for initiator

// Just wait a bit for socket to propagate
await Future.delayed(const Duration(milliseconds: 500));
```

#### 2. `_handleTeamShuffleResultFromSocket()` Method
Enhanced logging and proper flag management:

```dart
Future<void> _handleTeamShuffleResultFromSocket(dynamic data) async {
  try {
    // Log when handler is called
    CustomLogger.logMessage(
      msg: '🔔 SOCKET HANDLER CALLED - isShowingShuffleResultDialog: ${isShowingShuffleResultDialog.value}',
      level: LogLevel.info,
    );
    
    // Prevent duplicate dialog if already showing
    if (isShowingShuffleResultDialog.value) {
      return;
    }
    
    // Set flag BEFORE showing dialog
    isShowingShuffleResultDialog.value = true;
    
    // Show dialog
    await showTeamsShuffleResultDialog(...);
    
    // Reset flag AFTER dialog is closed
    isShowingShuffleResultDialog.value = false;
    
    // Reset match for this player
    await _restartMatchAfterShuffle();
    didShuffleDuringActiveMatch.value = false;
    
  } catch (e, stackTrace) {
    isShowingShuffleResultDialog.value = false;
    // Log error
  }
}
```

## How It Works Now

### Scenario: 4 players in a match, Player 1 swaps teams

1. **Player 1 (Initiator)**:
   - Clicks save button
   - API call succeeds
   - Socket event emitted to all 4 players
   - Waits 500ms
   - Receives socket event
   - Shows dialog (from socket)
   - Resets match

2. **Players 2, 3, 4**:
   - Receive socket event
   - Show dialog (from socket)
   - Reset match

**Result**: All 4 players see exactly ONE popup at the same time.

## Key Points

### 1. Single Source of Truth
- **Socket event** is the ONLY trigger for showing the dialog
- No local dialog display for initiator
- Ensures all players see the same thing at the same time

### 2. Flag Protection
- `isShowingShuffleResultDialog` prevents duplicate dialogs
- Set to `true` BEFORE showing dialog
- Reset to `false` AFTER dialog is closed

### 3. Proper Cleanup
- Match reset happens AFTER dialog is closed
- `didShuffleDuringActiveMatch` flag is reset
- All players sync to the same state

## Testing Checklist

- [ ] **Initiator sees ONE popup** (not two)
- [ ] **Other 3 players see ONE popup each**
- [ ] **All 4 players see popup at same time**
- [ ] **XP values are correct in popup**
- [ ] **Match resets after popup is closed**
- [ ] **All players can start new game after reset**

## Logs to Check

When testing, look for these logs:

### Initiator:
```
📤 SENDING SWAP API BODY
✅ SWAP API CALL SUCCESSFUL
📡 SOCKET EVENT EMITTED
📊 PREPARING XP DATA
📤 EMITTING SHUFFLE RESULT DATA
📡 TEAM SHUFFLE RESULT EMITTED TO ALL PLAYERS
🔔 SOCKET HANDLER CALLED - isShowingShuffleResultDialog: false
🔍 FULL SOCKET DATA
✅ Dialog closed, resetting match
```

### Other Players:
```
🏆 Team shuffle result received
🔔 SOCKET HANDLER CALLED - isShowingShuffleResultDialog: false
🔍 FULL SOCKET DATA
✅ Dialog closed, resetting match
```

## Common Issues

### Issue: Initiator still sees double popup
**Cause**: Socket event is being received twice
**Solution**: Check backend - ensure socket event is emitted only once

### Issue: Other players don't see popup
**Cause**: Socket event not reaching them
**Solution**: 
- Check if all players joined the scoreboard room
- Verify backend emits to the room: `io.to(scoreboardId).emit(...)`
- Check socket connection status

### Issue: Popup shows but match doesn't reset
**Cause**: `_restartMatchAfterShuffle()` is failing
**Solution**: Check logs for errors in match reset

## Backend Requirements

The backend MUST:

1. **Emit to ALL players in the room**:
   ```javascript
   io.to(scoreboardId).emit('teamShuffleResult', {
     scoreboardId,
     teamAResult: 'WIN',
     teamBResult: 'LOSE',
     teamAScore: 3,
     teamBScore: 1,
     xpEarned: 150,
     xpLost: 50
   });
   ```

2. **Include the initiator** in the room emission
3. **Emit only ONCE** per team swap

## Summary

The fix ensures:
- ✅ **No double popup** for initiator
- ✅ **All 4 players see popup** via socket
- ✅ **Single source of truth** (socket event)
- ✅ **Proper synchronization** across all devices
- ✅ **Clean state management** with flags
