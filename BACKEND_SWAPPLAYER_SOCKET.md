# Backend: swapPlayer Socket Event Handler

## Overview
Frontend ab `swapPlayer` socket event emit kar raha hai jab player team swap karta hai. Backend ko is event ko handle karna hai aur `matchCompleted` emit karna hai.

## Frontend Emits

### Event Name: `swapPlayer`

### Data Format:
```json
{
  "scoreboardId": "69cce0add939cfffdf0a0150",
  "teams": [
    {
      "name": "Team A",
      "players": [
        {"playerId": "69b7be786be85c6111f852c2"},
        {"playerId": "69cce1e7d939cfffdf0a8093"}
      ]
    },
    {
      "name": "Team B",
      "players": [
        {"playerId": "696e5aa4c5a128b24b3dac75"},
        {"playerId": "69cce1f8d939cfffdf0aa738"}
      ]
    }
  ],
  "isSwappingDuringMatch": true,
  "preShuffleWinner": "Team A",
  "preShuffleTeamAWins": 2,
  "preShuffleTeamBWins": 1,
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

## Backend Implementation

### Socket Listener (Copy-Paste Ready):

```javascript
// Add this in your socket.io setup
socket.on('swapPlayer', async (data) => {
    console.log('🔄 ========== swapPlayer EVENT RECEIVED ==========');
    console.log('🔄 Data:', JSON.stringify(data, null, 2));
    
    try {
        const { 
            scoreboardId, 
            teams,
            isSwappingDuringMatch, 
            preShuffleWinner,
            preShuffleTeamAWins,
            preShuffleTeamBWins 
        } = data;
        
        console.log('🔄 Scoreboard ID:', scoreboardId);
        console.log('🔄 isSwappingDuringMatch:', isSwappingDuringMatch);
        
        // Update teams in database
        await Scoreboard.updateOne(
            { _id: scoreboardId },
            { $set: { teams: teams } }
        );
        console.log('✅ Teams updated in database');
        
        // If swapping during active match, calculate XP and emit matchCompleted
        if (isSwappingDuringMatch === true) {
            console.log('🏆 SWAP DURING MATCH - Calculating XP...');
            
            // Get scoreboard from database
            const scoreboard = await Scoreboard.findById(scoreboardId)
                .populate('teams.players.playerId');
            
            if (!scoreboard) {
                console.error('❌ Scoreboard not found:', scoreboardId);
                return;
            }
            
            // Get teams
            const teamA = scoreboard.teams.find(t => 
                t.name.toLowerCase().replace(/\s/g, '') === 'teama'
            );
            const teamB = scoreboard.teams.find(t => 
                t.name.toLowerCase().replace(/\s/g, '') === 'teamb'
            );
            
            if (!teamA || !teamB) {
                console.error('❌ Teams not found in scoreboard');
                return;
            }
            
            // Determine winner
            const winningTeam = preShuffleWinner.toLowerCase().includes('a') ? 'teamA' : 'teamB';
            
            // Calculate XP for all 4 players
            const xpChanges = [];
            
            for (const team of [teamA, teamB]) {
                const isWinner = (team === teamA && winningTeam === 'teamA') || 
                                 (team === teamB && winningTeam === 'teamB');
                
                for (const player of team.players) {
                    const playerId = player.playerId._id || player.playerId;
                    
                    // Calculate XP based on match type
                    let xpChange = 0;
                    if (scoreboard.matchType === 'competitive') {
                        const scoreDiff = Math.abs(preShuffleTeamAWins - preShuffleTeamBWins);
                        xpChange = isWinner ? (100 + scoreDiff * 20) : (-50 - scoreDiff * 10);
                    } else {
                        xpChange = isWinner ? 10 : -5;
                    }
                    
                    xpChanges.push({
                        playerId: playerId.toString(),
                        xpChange: xpChange,
                        result: isWinner ? 'W' : 'L'  // CRITICAL: 'W' or 'L'
                    });
                    
                    console.log(`💰 Player ${playerId}: ${xpChange} XP (${isWinner ? 'WIN' : 'LOSS'})`);
                }
            }
            
            console.log('💰 XP Changes calculated:', xpChanges);
            
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
                    xpChanges: xpChanges,  // CRITICAL: Array of 4 players
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
        
        console.log('🔄 ========== swapPlayer EVENT COMPLETED ==========');
        
    } catch (error) {
        console.error('❌ Error handling swapPlayer:', error);
        console.error('Stack:', error.stack);
    }
});
```

## Expected Flow

### 1. Frontend Emits `swapPlayer`
```
📤 SOCKET: swapPlayer emitted: {scoreboardId: xxx, isSwappingDuringMatch: true, ...}
```

### 2. Backend Receives & Processes
```
🔄 ========== swapPlayer EVENT RECEIVED ==========
🔄 isSwappingDuringMatch: true
✅ Teams updated in database
🏆 SWAP DURING MATCH - Calculating XP...
💰 Player xxx: 120 XP (WIN)
💰 Player xxx: 120 XP (WIN)
💰 Player xxx: -60 XP (LOSS)
💰 Player xxx: -60 XP (LOSS)
📡 Emitting matchCompleted to room: scoreboard:xxx
✅ matchCompleted event emitted successfully
✅ Match reset successfully
```

### 3. Frontend Receives `matchCompleted`
```
🏆 Match completed received: {...}
💰 XP CHANGES ARRAY FOUND with 4 items
✅ FOUND CURRENT USER XP!
✅ User WON - xpEarned: 120
```

### 4. All Players See Correct Popup
- 2 Winners → WIN popup (+XP) ✅
- 2 Losers → LOSS popup (-XP) ✅

## Important Points

### 1. Room Name
Make sure frontend and backend use same room format:
- Frontend joins: `scoreboard:${scoreboardId}`
- Backend emits to: `scoreboard:${scoreboardId}`

### 2. xpChanges Array Structure
```javascript
[
  {
    playerId: "string",  // Player's MongoDB ObjectId as string
    xpChange: 120,       // Positive for winners, negative for losers
    result: "W"          // "W" for winner, "L" for loser
  }
]
```

### 3. Critical Fields in matchCompleted
```javascript
{
  isSwapDuringMatch: true,  // Must be true
  xpChanges: [...],         // Must have all 4 players
  // Each player must have 'result' field ('W' or 'L')
}
```

## Testing

### Backend Console Logs (Expected):
```
🔄 ========== swapPlayer EVENT RECEIVED ==========
🔄 Scoreboard ID: 69cce0add939cfffdf0a0150
🔄 isSwappingDuringMatch: true
✅ Teams updated in database
🏆 SWAP DURING MATCH - Calculating XP...
💰 Player 69b7be786be85c6111f852c2: 120 XP (WIN)
💰 Player 69cce1e7d939cfffdf0a8093: 120 XP (WIN)
💰 Player 696e5aa4c5a128b24b3dac75: -60 XP (LOSS)
💰 Player 69cce1f8d939cfffdf0aa738: -60 XP (LOSS)
📡 Emitting matchCompleted to room: scoreboard:69cce0add939cfffdf0a0150
✅ matchCompleted event emitted successfully
✅ Match reset successfully
🔄 ========== swapPlayer EVENT COMPLETED ==========
```

### Frontend Console Logs (Expected):
```
📤 SOCKET: swapPlayer emitted: {...}
🏆 Match completed received: {...}
🔄 isSwapDuringMatch: true
💰 XP CHANGES ARRAY FOUND with 4 items
👤 Current User ID: 69b7be786be85c6111f852c2
✅ FOUND CURRENT USER XP!
✅ Set xpEarned to: 120
✅ User WON - xpEarned: 120
```

## XP Calculation Logic

Current implementation:
```javascript
if (scoreboard.matchType === 'competitive') {
    const scoreDiff = Math.abs(preShuffleTeamAWins - preShuffleTeamBWins);
    xpChange = isWinner ? (100 + scoreDiff * 20) : (-50 - scoreDiff * 10);
} else {
    xpChange = isWinner ? 10 : -5;
}
```

### Examples:
- **Competitive, 2-1 score:**
  - Winners: 100 + (1 × 20) = 120 XP
  - Losers: -50 - (1 × 10) = -60 XP

- **Competitive, 3-0 score:**
  - Winners: 100 + (3 × 20) = 160 XP
  - Losers: -50 - (3 × 10) = -80 XP

- **Friendly:**
  - Winners: +10 XP
  - Losers: -5 XP

Adjust this logic as per your requirements!

## Troubleshooting

### Issue: Players not receiving event
**Check:**
1. Are all players in the room? `socket.join('scoreboard:xxx')`
2. Is room name correct? `scoreboard:${scoreboardId}`
3. Is socket connected? Check `socket.connected`

### Issue: Wrong popup showing
**Check:**
1. Is `xpChanges` array present?
2. Does each player have `result` field?
3. Is `result` exactly 'W' or 'L'?

### Issue: XP not calculating
**Check:**
1. Is scoreboard populated with player details?
2. Are teams found in scoreboard?
3. Is `matchType` set correctly?

## Summary

✅ Frontend emits `swapPlayer` event
✅ Backend calculates XP for all 4 players
✅ Backend emits `matchCompleted` with `xpChanges` array
✅ Frontend shows correct popup to each player
✅ Match resets automatically

Bas yeh socket listener add kar do aur sab kaam karega! 🚀
