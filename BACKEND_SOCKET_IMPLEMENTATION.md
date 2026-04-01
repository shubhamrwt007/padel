# Backend Implementation: Team Swap During Match

## Current Backend Code (matchCompleted emit)

```javascript
if (io) {
    console.log('===========hit=====')
    io.to(`scoreboard:${scoreboard._id}`).emit('matchCompleted', {
        scoreboardId: scoreboard._id,
        swapWinner,
        totalScore: { teamA: a, teamB: b },
        teams: populatedScoreboard?.teams || scoreboard.teams,
        xpChanges: xpChangesWithDetails,
        timestamp: new Date()
    });
}
```

## Required Changes

### 1. Listen for `scoreboardSwapped` Event

Add this socket listener in your backend socket setup:

```javascript
// Socket event listener for team swap
socket.on('scoreboardSwapped', async (data) => {
    console.log('🔄 ========== scoreboardSwapped EVENT RECEIVED ==========');
    console.log('🔄 Data:', JSON.stringify(data, null, 2));
    
    try {
        const { 
            scoreboardId, 
            isSwappingDuringMatch, 
            preShuffleWinner,
            preShuffleTeamAWins,
            preShuffleTeamBWins,
            teams 
        } = data;
        
        console.log('🔄 isSwappingDuringMatch:', isSwappingDuringMatch);
        
        // If swapping during active match, calculate XP and emit matchCompleted
        if (isSwappingDuringMatch === true) {
            console.log('🏆 SWAP DURING MATCH DETECTED - Calculating XP...');
            
            // Get scoreboard from database
            const scoreboard = await Scoreboard.findById(scoreboardId)
                .populate('teams.players.playerId');
            
            if (!scoreboard) {
                console.error('❌ Scoreboard not found:', scoreboardId);
                return;
            }
            
            // Calculate XP changes for all 4 players
            const xpChangesWithDetails = await calculateSwapXpChanges(
                scoreboard,
                preShuffleWinner,
                preShuffleTeamAWins,
                preShuffleTeamBWins
            );
            
            console.log('💰 XP Changes calculated:', xpChangesWithDetails);
            
            // Emit matchCompleted to ALL players in this scoreboard
            if (io) {
                console.log('📡 Emitting matchCompleted to room: scoreboard:' + scoreboardId);
                
                io.to(`scoreboard:${scoreboardId}`).emit('matchCompleted', {
                    scoreboardId: scoreboardId,
                    isSwapDuringMatch: true,  // CRITICAL FLAG
                    preShuffleWinner: preShuffleWinner,
                    preShuffleTeamAWins: preShuffleTeamAWins,
                    preShuffleTeamBWins: preShuffleTeamBWins,
                    swapWinner: preShuffleWinner,
                    totalScore: { 
                        teamA: preShuffleTeamAWins, 
                        teamB: preShuffleTeamBWins 
                    },
                    teams: scoreboard.teams,
                    xpChanges: xpChangesWithDetails,  // Array of 4 players with XP
                    timestamp: new Date()
                });
                
                console.log('✅ matchCompleted event emitted successfully');
            }
            
            // Reset match state in database
            await Scoreboard.updateOne(
                { _id: scoreboardId },
                {
                    $set: {
                        sets: [],
                        'totalScore.teamA': 0,
                        'totalScore.teamB': 0,
                        winner: null,
                        isCompleted: false
                    }
                }
            );
            
            console.log('✅ Match reset successfully');
        } else {
            console.log('ℹ️ Normal swap (not during match) - no XP calculation needed');
        }
        
        // Emit scoreboardSwapped for UI update (for all swaps)
        if (io) {
            io.to(`scoreboard:${scoreboardId}`).emit('scoreboardSwapped', {
                scoreboardId: scoreboardId,
                teams: teams,
                isSwappingDuringMatch: isSwappingDuringMatch || false
            });
            console.log('✅ scoreboardSwapped event emitted for UI update');
        }
        
    } catch (error) {
        console.error('❌ Error handling scoreboardSwapped:', error);
    }
});
```

### 2. Calculate XP Changes Function

Add this function to calculate XP for all 4 players:

```javascript
async function calculateSwapXpChanges(scoreboard, winner, teamAWins, teamBWins) {
    console.log('💰 Calculating XP changes...');
    console.log('   Winner:', winner);
    console.log('   Team A Wins:', teamAWins);
    console.log('   Team B Wins:', teamBWins);
    
    const xpChanges = [];
    
    // Determine winning and losing teams
    const winningTeam = winner.toLowerCase().includes('a') ? 'teamA' : 'teamB';
    const losingTeam = winningTeam === 'teamA' ? 'teamB' : 'teamA';
    
    // Get teams from scoreboard
    const teamA = scoreboard.teams.find(t => t.name.toLowerCase().includes('a'));
    const teamB = scoreboard.teams.find(t => t.name.toLowerCase().includes('b'));
    
    if (!teamA || !teamB) {
        console.error('❌ Teams not found in scoreboard');
        return [];
    }
    
    // Calculate XP for each player
    for (const team of [teamA, teamB]) {
        const isWinningTeam = (team === teamA && winningTeam === 'teamA') || 
                              (team === teamB && winningTeam === 'teamB');
        
        for (const player of team.players) {
            const playerId = player.playerId._id || player.playerId;
            
            // Calculate XP based on match type and result
            let xpChange = 0;
            
            if (scoreboard.matchType === 'competitive') {
                // Competitive match XP calculation
                if (isWinningTeam) {
                    xpChange = calculateWinnerXP(teamAWins, teamBWins);
                } else {
                    xpChange = calculateLoserXP(teamAWins, teamBWins);
                }
            } else {
                // Friendly match - minimal or no XP
                xpChange = isWinningTeam ? 10 : -5;
            }
            
            xpChanges.push({
                playerId: playerId,
                xpChange: xpChange,
                result: isWinningTeam ? 'W' : 'L'
            });
            
            console.log(`   Player ${playerId}: ${xpChange} XP (${isWinningTeam ? 'WIN' : 'LOSS'})`);
        }
    }
    
    return xpChanges;
}

// Helper function to calculate winner XP
function calculateWinnerXP(teamAWins, teamBWins) {
    const scoreDiff = Math.abs(teamAWins - teamBWins);
    const baseXP = 100;
    const bonusXP = scoreDiff * 20;
    return baseXP + bonusXP;
}

// Helper function to calculate loser XP (negative)
function calculateLoserXP(teamAWins, teamBWins) {
    const scoreDiff = Math.abs(teamAWins - teamBWins);
    const baseXP = -50;
    const penaltyXP = scoreDiff * -10;
    return baseXP + penaltyXP;
}
```

### 3. Update Your Existing updateScoreBoard API

In your `updateScoreBoard` API endpoint, add this check:

```javascript
// PUT /court/scoreboard/updateScoreboard
router.put('/updateScoreboard', async (req, res) => {
    try {
        const { 
            scoreboardId, 
            action, 
            teams, 
            isSwappingDuringMatch,
            preShuffleWinner,
            preShuffleTeamAWins,
            preShuffleTeamBWins 
        } = req.body;
        
        console.log('📝 updateScoreboard API called');
        console.log('   Action:', action);
        console.log('   isSwappingDuringMatch:', isSwappingDuringMatch);
        
        if (action === 'swap') {
            // Update teams in database
            await Scoreboard.updateOne(
                { _id: scoreboardId },
                { $set: { teams: teams } }
            );
            
            console.log('✅ Teams updated in database');
            
            // If swapping during match, the socket listener will handle XP calculation
            // Just return success here
            res.json({ 
                success: true, 
                message: 'Teams swapped successfully' 
            });
        } else {
            // Handle other actions (add set, update score, etc.)
            // ... your existing code
        }
        
    } catch (error) {
        console.error('❌ Error in updateScoreboard:', error);
        res.status(500).json({ 
            success: false, 
            message: error.message 
        });
    }
});
```

## Complete Flow

### 1. Frontend Emits (Already Done)
```javascript
repository.emitScoreboardSwapped({
  scoreboardId: 'xxx',
  action: 'swap',
  isSwappingDuringMatch: true,
  preShuffleWinner: 'Team A',
  preShuffleTeamAWins: 2,
  preShuffleTeamBWins: 1,
  teams: [...]
});
```

### 2. Backend Receives (New Code Above)
```javascript
socket.on('scoreboardSwapped', async (data) => {
  // Calculate XP
  // Emit matchCompleted
  // Reset match
});
```

### 3. Backend Emits (Using Your Existing Code)
```javascript
io.to(`scoreboard:${scoreboardId}`).emit('matchCompleted', {
  scoreboardId: scoreboardId,
  isSwapDuringMatch: true,  // ← IMPORTANT
  preShuffleWinner: 'Team A',
  preShuffleTeamAWins: 2,
  preShuffleTeamBWins: 1,
  xpChanges: [
    {playerId: 'xxx', xpChange: 182.42, result: 'W'},
    {playerId: 'xxx', xpChange: 219.02, result: 'W'},
    {playerId: 'xxx', xpChange: -126.62, result: 'L'},
    {playerId: 'xxx', xpChange: -85.56, result: 'L'}
  ]
});
```

### 4. Frontend Receives (Already Done)
```dart
repository.onMatchCompleted((data) {
  // Show popup based on xpChanges
});
```

## Testing

### Backend Console Logs (Expected):
```
🔄 ========== scoreboardSwapped EVENT RECEIVED ==========
🔄 Data: {...}
🔄 isSwappingDuringMatch: true
🏆 SWAP DURING MATCH DETECTED - Calculating XP...
💰 Calculating XP changes...
   Winner: Team A
   Team A Wins: 2
   Team B Wins: 1
   Player 69b7be786be85c6111f852c2: 120 XP (WIN)
   Player 69cce1e7d939cfffdf0a8093: 120 XP (WIN)
   Player 696e5aa4c5a128b24b3dac75: -60 XP (LOSS)
   Player 69cce1f8d939cfffdf0aa738: -60 XP (LOSS)
💰 XP Changes calculated: [...]
📡 Emitting matchCompleted to room: scoreboard:xxx
✅ matchCompleted event emitted successfully
✅ Match reset successfully
✅ scoreboardSwapped event emitted for UI update
```

### Frontend Console Logs (Expected):
```
📤 SOCKET: scoreboardSwapped emitted: {...}
🏆 Match completed received: {...}
🔄 isSwapDuringMatch: true
💰 Player 0: {playerId: xxx, xpChange: 120, result: W}
💰 Player 1: {playerId: xxx, xpChange: 120, result: W}
💰 Player 2: {playerId: xxx, xpChange: -60, result: L}
💰 Player 3: {playerId: xxx, xpChange: -60, result: L}
🔔 Showing match summary dialog to player
```

## Important Notes

1. **Room Name:** Backend uses `scoreboard:${scoreboardId}` but frontend might use `scoreboard_${scoreboardId}`. Make sure they match!

2. **XP Calculation:** Adjust the `calculateWinnerXP` and `calculateLoserXP` functions based on your game logic.

3. **Match Type:** Check if match is competitive or friendly before calculating XP.

4. **Error Handling:** Add proper error handling for database operations.

5. **Player Population:** Make sure to populate player details when fetching scoreboard.

## Summary

Backend ko yeh karna hai:
1. ✅ Listen for `scoreboardSwapped` event
2. ✅ Check if `isSwappingDuringMatch === true`
3. ✅ Calculate XP for all 4 players
4. ✅ Emit `matchCompleted` with `xpChanges` array
5. ✅ Reset match state in database
6. ✅ Emit `scoreboardSwapped` for UI update

Frontend already ready hai! 🚀
