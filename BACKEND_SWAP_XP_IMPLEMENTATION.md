# Backend Implementation: Swap XP Changes

## Current Data Structure (Jo aapko mil raha hai)

```javascript
{
  data: {
    totalScore: { teamA: 0, teamB: 0 },
    teams: [...],
    // ... other fields
  },
  swapXpChanges: [
    {
      playerId: new ObjectId('69b7be786be85c6111f852c2'),
      xpChange: 182.42,
      result: 'W'
    },
    {
      playerId: new ObjectId('69cce1e7d939cfffdf0a8093'),
      xpChange: 219.02,
      result: 'W'
    },
    {
      playerId: new ObjectId('696e5aa4c5a128b24b3dac75'),
      xpChange: -126.62,
      result: 'L'
    },
    {
      playerId: new ObjectId('69cce1f8d939cfffdf0aa738'),
      xpChange: -85.56,
      result: 'L'
    }
  ]
}
```

## Required Socket Event Format

Backend ko yeh emit karna hai:

```javascript
io.to(`scoreboard_${scoreboardId}`).emit('matchCompleted', {
  scoreboardId: scoreboardId,
  isSwapDuringMatch: true,
  
  // Individual player XP changes
  playerXpChanges: [
    {
      playerId: '69b7be786be85c6111f852c2',
      xpChange: 182.42,
      result: 'W'  // 'W' for winner, 'L' for loser
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
  
  // Previous match info (optional, for display)
  preShuffleWinner: 'Team A',  // or 'Team B'
  preShuffleTeamAWins: 2,
  preShuffleTeamBWins: 1
});
```

## Backend Code Example

```javascript
// When swap happens during match
app.put('/court/scoreboard/updateScoreboard', async (req, res) => {
  const { scoreboardId, action, teams, isSwappingDuringMatch } = req.body;

  if (action === 'swap' && isSwappingDuringMatch) {
    // Get scoreboard data
    const scoreboard = await Scoreboard.findById(scoreboardId);
    
    // Calculate XP changes (you already have this logic)
    const swapXpChanges = await calculateSwapXpChanges(scoreboard);
    
    // Emit to ALL players
    io.to(`scoreboard_${scoreboardId}`).emit('matchCompleted', {
      scoreboardId: scoreboardId,
      isSwapDuringMatch: true,
      playerXpChanges: swapXpChanges.map(change => ({
        playerId: change.playerId.toString(),
        xpChange: change.xpChange,
        result: change.result  // 'W' or 'L'
      })),
      preShuffleWinner: determineWinner(scoreboard),
      preShuffleTeamAWins: scoreboard.totalScore.teamA,
      preShuffleTeamBWins: scoreboard.totalScore.teamB
    });

    // Update teams and reset match
    await Scoreboard.updateOne(
      { _id: scoreboardId },
      { 
        $set: { 
          teams: teams,
          'totalScore.teamA': 0,
          'totalScore.teamB': 0,
          sets: []
        }
      }
    );

    res.json({ success: true });
  }
});
```

## Frontend Changes Required

Frontend mein current user ka playerId match karke popup show karna hai:

```dart
void onMatchCompleted(dynamic data) {
  if (data['isSwapDuringMatch'] == true) {
    final List<dynamic> playerXpChanges = data['playerXpChanges'] ?? [];
    final String currentUserId = getCurrentUserId(); // Your method to get current user ID
    
    // Find current player's XP change
    final myXpData = playerXpChanges.firstWhere(
      (change) => change['playerId'] == currentUserId,
      orElse: () => null,
    );
    
    if (myXpData != null) {
      final double xpChange = myXpData['xpChange'].toDouble();
      final String result = myXpData['result']; // 'W' or 'L'
      
      // Show popup based on result
      if (result == 'W') {
        // Show WIN popup with +xpChange
        showMatchSummaryDialog(
          isWinner: true,
          xpEarned: xpChange.abs(),
        );
      } else {
        // Show LOSS popup with -xpChange
        showMatchSummaryDialog(
          isWinner: false,
          xpLost: xpChange.abs(),
        );
      }
    }
  }
}
```

## Key Points

1. **Backend must emit `playerXpChanges` array** with each player's individual XP change
2. **Frontend matches current user's playerId** to show correct popup
3. **Result field ('W' or 'L')** determines WIN or LOSS popup
4. **XP change can be positive or negative** - frontend should use absolute value for display

## Testing

### Test Case 1: Player from Winning Team
- Player ID: `69b7be786be85c6111f852c2`
- XP Change: `+182.42`
- Result: `W`
- Expected: **WIN popup** with "+182.42 XP"

### Test Case 2: Player from Losing Team
- Player ID: `696e5aa4c5a128b24b3dac75`
- XP Change: `-126.62`
- Result: `L`
- Expected: **LOSS popup** with "-126.62 XP"

## Summary

Backend ko bas `playerXpChanges` array emit karna hai socket event mein. Frontend already implement hai, bas `playerXpChanges` field ko handle karna padega current user ke liye.
