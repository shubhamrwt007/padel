# Backend Requirements for Team Shuffle Popup

## Overview
When players swap teams during an active match, the backend needs to:
1. Receive the `scoreboardSwapped` socket event
2. Calculate XP for winners/losers
3. Emit `teamShuffleResult` to all 4 players
4. Reset the match state

## Current Flow

### 1. Client Emits `scoreboardSwapped`

When a player saves team swaps, the client sends:

```javascript
{
  scoreboardId: "abc123",
  action: "swap",
  teams: [
    {
      name: "Team A",
      players: [
        { playerId: "player1" },
        { playerId: "player2" }
      ]
    },
    {
      name: "Team B",
      players: [
        { playerId: "player3" },
        { playerId: "player4" }
      ]
    }
  ],
  isSwappingDuringMatch: true,  // ← NEW FIELD
  preShuffleWinner: "Team A",   // ← NEW FIELD
  preShuffleTeamAWins: 2,       // ← NEW FIELD
  preShuffleTeamBWins: 1        // ← NEW FIELD
}
```

### 2. Backend Should Handle This

```javascript
socket.on('scoreboardSwapped', async (data) => {
  console.log('📥 Received scoreboardSwapped:', data);
  
  const { 
    scoreboardId, 
    teams, 
    isSwappingDuringMatch,
    preShuffleWinner,
    preShuffleTeamAWins,
    preShuffleTeamBWins
  } = data;
  
  // Update teams in database
  await updateScoreboardTeams(scoreboardId, teams);
  
  // Broadcast team swap to all players
  io.to(scoreboardId).emit('scoreboardSwapped', data);
  
  // If swapping during match, calculate and emit shuffle result
  if (isSwappingDuringMatch) {
    console.log('🎯 Swapping during match - calculating XP');
    
    // Determine team results
    let teamAResult = 'LOSE';
    let teamBResult = 'WIN';
    
    if (preShuffleWinner === 'Team A') {
      teamAResult = 'WIN';
      teamBResult = 'LOSE';
    } else if (preShuffleWinner === 'Team B') {
      teamAResult = 'LOSE';
      teamBResult = 'WIN';
    } else if (preShuffleTeamAWins === preShuffleTeamBWins) {
      teamAResult = 'DRAW';
      teamBResult = 'DRAW';
    }
    
    // Calculate XP for each player
    const xpEarned = calculateXPForWinner(preShuffleTeamAWins, preShuffleTeamBWins);
    const xpLost = calculateXPForLoser(preShuffleTeamAWins, preShuffleTeamBWins);
    
    // Update XP in database for each player
    const winningTeam = teamAResult === 'WIN' ? teams[0] : teams[1];
    const losingTeam = teamAResult === 'LOSE' ? teams[0] : teams[1];
    
    for (const player of winningTeam.players) {
      await updatePlayerXP(player.playerId, xpEarned);
    }
    
    for (const player of losingTeam.players) {
      await updatePlayerXP(player.playerId, -xpLost);
    }
    
    // Emit shuffle result to ALL players
    const shuffleResultData = {
      scoreboardId,
      teamAResult,
      teamBResult,
      teamAScore: preShuffleTeamAWins,
      teamBScore: preShuffleTeamBWins,
      xpEarned,
      xpLost,
      currentXP: xpEarned,  // Alternative key
      xpChange: xpEarned    // Alternative key
    };
    
    console.log('📤 Emitting teamShuffleResult:', shuffleResultData);
    io.to(scoreboardId).emit('teamShuffleResult', shuffleResultData);
    
    // Reset match state
    await resetMatchState(scoreboardId);
  }
});
```

## XP Calculation Examples

### Example 1: Competitive Match
```javascript
function calculateXPForWinner(winnerScore, loserScore) {
  const scoreDiff = winnerScore - loserScore;
  const baseXP = 100;
  const bonusXP = scoreDiff * 10;
  return baseXP + bonusXP;
}

function calculateXPForLoser(winnerScore, loserScore) {
  const scoreDiff = winnerScore - loserScore;
  const baseXP = 50;
  const penaltyXP = scoreDiff * 5;
  return baseXP + penaltyXP;
}

// Example: Team A wins 3-1
// Winner XP: 100 + (2 * 10) = 120
// Loser XP: 50 + (2 * 5) = 60
```

### Example 2: Friendly Match
```javascript
function calculateXPForWinner(winnerScore, loserScore) {
  return 50; // Fixed XP for friendly
}

function calculateXPForLoser(winnerScore, loserScore) {
  return 25; // Fixed XP for friendly
}
```

## Reset Match State

After emitting `teamShuffleResult`, reset the match:

```javascript
async function resetMatchState(scoreboardId) {
  await Scoreboard.findByIdAndUpdate(scoreboardId, {
    sets: [],
    totalScore: { teamA: 0, teamB: 0 },
    winner: null,
    isCompleted: false
  });
  
  console.log('✅ Match state reset for scoreboard:', scoreboardId);
}
```

## Complete Backend Handler

```javascript
// Socket event handler
socket.on('scoreboardSwapped', async (data) => {
  try {
    const { 
      scoreboardId, 
      teams, 
      isSwappingDuringMatch,
      preShuffleWinner,
      preShuffleTeamAWins,
      preShuffleTeamBWins
    } = data;
    
    console.log('📥 scoreboardSwapped received:', {
      scoreboardId,
      isSwappingDuringMatch,
      preShuffleWinner,
      scores: `${preShuffleTeamAWins}-${preShuffleTeamBWins}`
    });
    
    // 1. Update teams in database
    await Scoreboard.findByIdAndUpdate(scoreboardId, { teams });
    console.log('✅ Teams updated in database');
    
    // 2. Broadcast to all players
    io.to(scoreboardId).emit('scoreboardSwapped', data);
    console.log('📡 scoreboardSwapped broadcasted');
    
    // 3. Handle shuffle result if during match
    if (isSwappingDuringMatch) {
      console.log('🎯 Processing shuffle result...');
      
      // Determine results
      let teamAResult = 'LOSE';
      let teamBResult = 'WIN';
      
      if (preShuffleWinner === 'Team A') {
        teamAResult = 'WIN';
        teamBResult = 'LOSE';
      } else if (preShuffleWinner === 'Team B') {
        teamAResult = 'LOSE';
        teamBResult = 'WIN';
      } else if (preShuffleTeamAWins === preShuffleTeamBWins) {
        teamAResult = 'DRAW';
        teamBResult = 'DRAW';
      }
      
      // Calculate XP
      const xpEarned = calculateXPForWinner(preShuffleTeamAWins, preShuffleTeamBWins);
      const xpLost = calculateXPForLoser(preShuffleTeamAWins, preShuffleTeamBWins);
      
      console.log('💰 XP calculated:', { xpEarned, xpLost });
      
      // Update player XP
      const winningTeam = teamAResult === 'WIN' ? teams[0] : teams[1];
      const losingTeam = teamAResult === 'LOSE' ? teams[0] : teams[1];
      
      if (teamAResult !== 'DRAW') {
        for (const player of winningTeam.players) {
          await User.findByIdAndUpdate(player.playerId, {
            $inc: { xp: xpEarned }
          });
        }
        
        for (const player of losingTeam.players) {
          await User.findByIdAndUpdate(player.playerId, {
            $inc: { xp: -xpLost }
          });
        }
        console.log('✅ Player XP updated');
      }
      
      // Emit shuffle result
      const shuffleResultData = {
        scoreboardId,
        teamAResult,
        teamBResult,
        teamAScore: preShuffleTeamAWins,
        teamBScore: preShuffleTeamBWins,
        xpEarned,
        xpLost,
        currentXP: xpEarned,
        xpChange: xpEarned
      };
      
      console.log('📤 Emitting teamShuffleResult:', shuffleResultData);
      io.to(scoreboardId).emit('teamShuffleResult', shuffleResultData);
      
      // Reset match
      await Scoreboard.findByIdAndUpdate(scoreboardId, {
        sets: [],
        totalScore: { teamA: 0, teamB: 0 },
        winner: null,
        isCompleted: false
      });
      console.log('✅ Match reset complete');
    }
    
  } catch (error) {
    console.error('❌ Error handling scoreboardSwapped:', error);
  }
});
```

## Testing

### Test Case 1: Swap During Match
1. Start match with 4 players
2. Add sets and scores (e.g., Team A: 2, Team B: 1)
3. Swap teams
4. Backend should:
   - Receive `scoreboardSwapped` with `isSwappingDuringMatch: true`
   - Calculate XP
   - Emit `teamShuffleResult` to all 4 players
   - Reset match state

### Test Case 2: Swap Before Match
1. Add 4 players
2. Swap teams (before starting game)
3. Backend should:
   - Receive `scoreboardSwapped` with `isSwappingDuringMatch: false`
   - Update teams
   - NOT emit `teamShuffleResult`
   - NOT reset match

## Client Logs to Verify

When backend is working correctly, clients will see:

```
📤 SENDING SWAP API BODY
✅ SWAP API CALL SUCCESSFUL
📡 scoreboardSwapped SOCKET EVENT EMITTED
⏳ Waiting for backend to process and emit teamShuffleResult...
🏆 SOCKET: teamShuffleResult received: {data}
🔔 SOCKET HANDLER CALLED
🔍 FULL SOCKET DATA: {data with XP}
```

## Summary

**Backend must:**
1. ✅ Listen to `scoreboardSwapped` event
2. ✅ Check `isSwappingDuringMatch` flag
3. ✅ Calculate XP if swapping during match
4. ✅ Emit `teamShuffleResult` to ALL players in room
5. ✅ Reset match state after shuffle

**Backend must NOT:**
- ❌ Use `socket.broadcast.emit()` (excludes sender)
- ❌ Forget to include XP values in response
- ❌ Forget to reset match state

**Key Point:** The backend is the single source of truth for XP calculation and match results.
