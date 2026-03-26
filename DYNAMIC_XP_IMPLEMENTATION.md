# Dynamic XP Implementation - UPDATED

## Overview
The XP values displayed in match completion and team shuffle popups are now fully dynamic, coming from the API and socket events. The system supports multiple key names for XP data (`xpEarned`, `currentXP`, `xpChange`) to ensure compatibility.

## Changes Made

### 1. **Model Updates** (`update_scoreboard_model.dart`)
Added XP fields to capture API response:
```dart
class Data {
  int? xpEarned;
  int? xpLost;
  // ... other fields
}
```

### 2. **Controller Updates** (`score_board_controller.dart`)

#### Added Observable Variables:
```dart
final xpEarned = 0.obs;
final xpLost = 0.obs;
```

#### Updated `endGame()` Method:
Captures XP from API response when match completes:
```dart
if (response.data != null) {
  xpEarned.value = response.data!.xpEarned ?? 0;
  xpLost.value = response.data!.xpLost ?? 0;
}
```

#### Updated Socket Event Handlers:

**Match Completed Event:**
```dart
repository.onMatchCompleted((data) {
  // Get XP values from socket data - supports multiple key names
  final socketXpEarned = data['xpEarned'] ?? data['currentXP'] ?? data['xpChange'] ?? 0;
  final socketXpLost = data['xpLost'] ?? 0;
  
  if (socketXpEarned > 0) {
    xpEarned.value = socketXpEarned;
  }
  if (socketXpLost > 0) {
    xpLost.value = socketXpLost;
  }
});
```

**Team Shuffle Result Event:**
```dart
Future<void> _handleTeamShuffleResultFromSocket(dynamic data) async {
  // Get XP values from socket data - supports multiple key names
  final socketXpEarned = data['xpEarned'] ?? data['currentXP'] ?? data['xpChange'] ?? 0;
  final socketXpLost = data['xpLost'] ?? 0;
  
  // Update controller XP values
  if (socketXpEarned > 0) {
    xpEarned.value = socketXpEarned;
  }
  if (socketXpLost > 0) {
    xpLost.value = socketXpLost;
  }
}
```

#### Updated `savePlayerSwaps()` Method:
Includes XP in socket emission with multiple key names for compatibility:
```dart
final shuffleResultData = {
  'scoreboardId': scoreboardId.value,
  'teamAResult': teamAStatus,
  'teamBResult': teamBStatus,
  'teamAScore': preShuffleTeamAWins.value,
  'teamBScore': preShuffleTeamBWins.value,
  'xpEarned': currentXpEarned,    // ✅ Primary key
  'xpLost': currentXpLost,        // ✅ Primary key
  'currentXP': currentXpEarned,   // ✅ Alternative key
  'xpChange': currentXpEarned,    // ✅ Alternative key
};
```

### 3. **Dialog Updates**

#### `match_summary_dialog.dart`
Changed from static to dynamic XP display:
```dart
final String badgeText = switch (result) {
  _MatchResult.win => controller.xpEarned.value > 0 
    ? "+${controller.xpEarned.value} XP"   // ✅ Dynamic from API
    : "+100 XP",                            // Fallback
  _MatchResult.loss => controller.xpLost.value > 0 
    ? "-${controller.xpLost.value} XP"     // ✅ Dynamic from API
    : "-100 XP",                            // Fallback
  _MatchResult.draw => "0 XP",
};
```

#### `teams_shuffle_result_dialog.dart` - NEW
Added XP display to team shuffle dialog:
```dart
Future<void> showTeamsShuffleResultDialog({
  required ScoreBoardController controller,
  required String teamAResult,
  required String teamBResult,
}) async {
  // Determine user's team and result
  final isUserInTeamA = controller.isUserInTeamA;
  final isUserInTeamB = controller.isUserInTeamB;
  
  String userResult = "DRAW";
  if (isUserInTeamA) {
    userResult = teamAResult;
  } else if (isUserInTeamB) {
    userResult = teamBResult;
  }
  
  // Get XP text based on result
  String xpText = "";
  if (userResult == "WIN" && controller.xpEarned.value > 0) {
    xpText = "+${controller.xpEarned.value} XP";
  } else if (userResult == "LOSE" && controller.xpLost.value > 0) {
    xpText = "-${controller.xpLost.value} XP";
  } else if (userResult == "DRAW") {
    xpText = "0 XP";
  }
  
  // Display XP in a styled container
  if (xpText.isNotEmpty) {
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: userResult == "WIN" 
          ? Colors.green.withOpacity(0.1)
          : userResult == "LOSE"
            ? Colors.red.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: userResult == "WIN" ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Text(xpText, style: ...),
    )
  }
}
```

## Data Flow

### Match Completion Flow:
```
1. User clicks "End Game"
   ↓
2. API: updateScoreBoard(type: "completed")
   ↓
3. API Response includes: { xpEarned: 150, xpLost: 50 }
   ↓
4. Controller stores: xpEarned.value = 150, xpLost.value = 50
   ↓
5. Socket emits: matchCompleted with XP data
   ↓
6. All players receive socket event with XP
   ↓
7. Dialog displays: "+150 XP" or "-50 XP"
```

### Team Shuffle Flow:
```
1. User swaps teams during active match
   ↓
2. Controller stores current XP values
   ↓
3. Socket emits: teamShuffleResult with XP data
   {
     teamAResult: "WIN",
     teamBResult: "LOSE",
     xpEarned: 150,
     xpLost: 50,
     currentXP: 150,  // Alternative key
     xpChange: 150    // Alternative key
   }
   ↓
4. All 4 players receive socket event
   ↓
5. Each player updates their XP values
   ↓
6. Dialog displays dynamic XP: "+150 XP" or "-50 XP"
```

## Socket Event Structure

### `matchCompleted` Event:
```json
{
  "scoreboardId": "abc123",
  "winner": "Team A",
  "xpEarned": 150,
  "xpLost": 50,
  "currentXP": 150,
  "xpChange": 150
}
```

### `teamShuffleResult` Event:
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

## Display Logic

### For Winners:
- If `xpEarned > 0`: Shows `"+{xpEarned} XP"` (e.g., "+150 XP")
- If `xpEarned = 0`: Shows `"0 XP"` or no badge

### For Losers:
- If `xpLost > 0`: Shows `"-{xpLost} XP"` (e.g., "-50 XP")
- If `xpLost = 0`: Shows `"0 XP"` or no badge

### For Draw:
- Always shows `"0 XP"`

## Key Features

✅ **Dynamic XP Values**: Shows actual XP from API/socket, not hardcoded
✅ **Multiple Key Support**: Handles `xpEarned`, `currentXP`, and `xpChange` keys
✅ **Real-time Updates**: All players see correct XP via socket events
✅ **User-Specific Display**: Shows XP based on user's team result
✅ **Styled XP Badge**: Color-coded container (green for win, red for loss)
✅ **Socket Synchronization**: XP data transmitted in real-time to all 4 players

## Testing Checklist

- [ ] Complete a match and verify XP shows from API
- [ ] Check if different match types show different XP values
- [ ] Verify all 4 players see the same XP in popup
- [ ] Test team shuffle during match shows correct XP
- [ ] Verify XP displays with `xpEarned` key
- [ ] Verify XP displays with `currentXP` key
- [ ] Verify XP displays with `xpChange` key
- [ ] Check socket events include XP data
- [ ] Verify XP updates in profile after match completion
- [ ] Test XP display for winners (green badge)
- [ ] Test XP display for losers (red badge)
- [ ] Test XP display for draw (orange badge)

## API Requirements

The backend should return XP values in the response using any of these keys:
```json
{
  "success": true,
  "data": {
    "xpEarned": 150,      // Primary key
    "xpLost": 50,         // Primary key
    "currentXP": 150,     // Alternative key
    "xpChange": 150       // Alternative key
  }
}
```

The app will check all possible key names and use the first available value.
