# Quick Backend Implementation - Copy Paste Ready

## 1. Add Socket Listener (Copy This Entire Block)

```javascript
// Add this in your socket.io setup where you have other socket.on listeners
socket.on('scoreboardSwapped', async (data) => {
    console.log('🔄 scoreboardSwapped received:', data);
    
    try {
        const { 
            scoreboardId, 
            isSwappingDuringMatch, 
            preShuffleWinner,
            preShuffleTeamAWins,
            preShuffleTeamBWins,
            teams 
        } = data;
        
        // If swapping during active match
        if (isSwappingDuringMatch === true) {
            console.log('🏆 Swap during match - calculating XP');
            
            // Get scoreboard
            const scoreboard = await Scoreboard.findById(scoreboardId)
                .populate('teams.players.playerId');
            
            if (!scoreboard) {
                console.error('Scoreboard not found');
                return;
            }
            
            // Get teams
            const teamA = scoreboard.teams.find(t => 
                t.name.toLowerCase().replace(/\s/g, '') === 'teama'
            );
            const teamB = scoreboard.teams.find(t => 
                t.name.toLowerCase().replace(/\s/g, '') === 'teamb'
            );
            
            // Determine winner
            const winningTeam = preShuffleWinner.toLowerCase().includes('a') ? 'teamA' : 'teamB';
            
            // Calculate XP for all 4 players
            const xpChanges = [];
            
            for (const team of [teamA, teamB]) {
                const isWinner = (team === teamA && winningTeam === 'teamA') || 
                                 (team === teamB && winningTeam === 'teamB');
                
                for (const player of team.players) {
                    const playerId = player.playerId._id || player.playerId;
                    
                    // Simple XP calculation (adjust as needed)
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
                        result: isWinner ? 'W' : 'L'
                    });
                }
            }
            
            console.log('💰 XP Changes:', xpChanges);
            
            // Emit matchCompleted to ALL players
            io.to(`scoreboard:${scoreboardId}`).emit('matchCompleted', {
                scoreboardId: scoreboardId,
                isSwapDuringMatch: true,
                preShuffleWinner: preShuffleWinner,
                preShuffleTeamAWins: preShuffleTeamAWins,
                preShuffleTeamBWins: preShuffleTeamBWins,
                swapWinner: preShuffleWinner,
                totalScore: { 
                    teamA: preShuffleTeamAWins, 
                    teamB: preShuffleTeamBWins 
                },
                teams: scoreboard.teams,
                xpChanges: xpChanges,
                timestamp: new Date()
            });
            
            console.log('✅ matchCompleted emitted');
            
            // Reset match
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
        }
        
        // Always emit scoreboardSwapped for UI update
        io.to(`scoreboard:${scoreboardId}`).emit('scoreboardSwapped', {
            scoreboardId: scoreboardId,
            teams: teams,
            isSwappingDuringMatch: isSwappingDuringMatch || false
        });
        
    } catch (error) {
        console.error('❌ Error in scoreboardSwapped:', error);
    }
});
```

## 2. That's It! 

Just add the above code block in your socket setup and it will work.

## Where to Add?

Find this in your backend code:

```javascript
io.on('connection', (socket) => {
    console.log('User connected:', socket.id);
    
    // Your existing socket listeners
    socket.on('joinScoreboard', (data) => { ... });
    socket.on('leaveScoreboard', (data) => { ... });
    
    // ADD THE NEW LISTENER HERE ⬇️
    socket.on('scoreboardSwapped', async (data) => {
        // ... paste the code from above
    });
    
});
```

## Expected Data Format

### Frontend Sends:
```json
{
  "scoreboardId": "69cce0add939cfffdf0a0150",
  "action": "swap",
  "isSwappingDuringMatch": true,
  "preShuffleWinner": "Team A",
  "preShuffleTeamAWins": 2,
  "preShuffleTeamBWins": 1,
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
  ]
}
```

### Backend Emits:
```json
{
  "scoreboardId": "69cce0add939cfffdf0a0150",
  "isSwapDuringMatch": true,
  "preShuffleWinner": "Team A",
  "preShuffleTeamAWins": 2,
  "preShuffleTeamBWins": 1,
  "xpChanges": [
    {
      "playerId": "69b7be786be85c6111f852c2",
      "xpChange": 120,
      "result": "W"
    },
    {
      "playerId": "69cce1e7d939cfffdf0a8093",
      "xpChange": 120,
      "result": "W"
    },
    {
      "playerId": "696e5aa4c5a128b24b3dac75",
      "xpChange": -60,
      "result": "L"
    },
    {
      "playerId": "69cce1f8d939cfffdf0aa738",
      "xpChange": -60,
      "result": "L"
    }
  ]
}
```

## Testing

1. Start backend server
2. Open app on 4 devices/emulators
3. Start a match (Team A: 2 sets, Team B: 1 set)
4. Swap teams
5. Check backend console for logs
6. Check all 4 devices for popup

## Troubleshooting

### If not working:

1. **Check room name:** Make sure frontend and backend use same room format
   - Frontend: `scoreboard:${scoreboardId}` or `scoreboard_${scoreboardId}`
   - Backend: Should match frontend

2. **Check if event is received:**
   ```javascript
   socket.on('scoreboardSwapped', (data) => {
       console.log('✅ EVENT RECEIVED:', data);
       // ... rest of code
   });
   ```

3. **Check if players are in room:**
   ```javascript
   socket.on('joinScoreboard', (data) => {
       socket.join(`scoreboard:${data.scoreboardId}`);
       console.log(`Player ${socket.id} joined room: scoreboard:${data.scoreboardId}`);
   });
   ```

## XP Calculation Logic (Customize This)

Current logic:
- **Competitive Match:**
  - Winner: 100 + (score difference × 20) XP
  - Loser: -50 - (score difference × 10) XP
- **Friendly Match:**
  - Winner: +10 XP
  - Loser: -5 XP

Adjust the calculation in the code as per your requirements!
