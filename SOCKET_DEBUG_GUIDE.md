# Socket Event Debugging Guide

## Problem: Logs Not Appearing

Agar `scoreboardSwapped` event ke logs print nahi ho rahe, toh yeh check karo:

## Step 1: Check Socket Connection

### Expected Logs on App Start:
```
🔌 SOCKET: Connecting to http://your-socket-url
🔌 SOCKET: User ID: 69b7be786be85c6111f852c2
🔌 SOCKET: Connection initiated
✅ SOCKET: Connected successfully!
```

### If NOT seeing these logs:
- Socket connection fail ho raha hai
- Check `AppEndpoints.socketUrl` in your code
- Check if backend socket server is running

## Step 2: Check Scoreboard Join

### Expected Logs:
```
🔵 SCOREBOARD ID: 69cce0add939cfffdf0a0150
🔵 SOCKET: Connecting to scoreboard with ID: 69cce0add939cfffdf0a0150
🚪 Joined scoreboard: 69cce0add939cfffdf0a0150
```

### If NOT seeing these logs:
- `scoreboardId` empty hai
- `onInit` method properly call nahi ho raha

## Step 3: Check Listener Registration

### Expected Logs:
```
🎯 REPOSITORY: Registering scoreboardSwapped listener
✅ REPOSITORY: scoreboardSwapped listener registered successfully
```

### If NOT seeing these logs:
- `repository.onScoreboardSwapped()` call nahi ho raha
- Check `onInit()` method in controller

## Step 4: Perform Team Swap

### When you click "Save" after swapping teams:

#### Expected Logs (Frontend Emitting):
```
🔄 SWAP INITIATED - isSwappingDuringMatch: true, isGameStarted: true, sets.length: 3
📊 PRE-SHUFFLE STATE - Winner: Team A, Team A: 2, Team B: 1
========== SENDING SWAP API ==========
   ScoreboardId: 69cce0add939cfffdf0a0150
   Action: swap
   isSwappingDuringMatch: true
   preShuffleWinner: Team A
   preShuffleTeamAWins: 2
   preShuffleTeamBWins: 1
   Teams: [...]
========================================
✅ SWAP API CALL SUCCESSFUL
🏆 SWAPPING DURING MATCH - Preparing to notify all players
📤 ========== EMITTING SOCKET EVENT ==========
📤 Event: scoreboardSwapped
📤 Body: {scoreboardId: xxx, isSwappingDuringMatch: true, ...}
📤 ============================================
📡 scoreboardSwapped SOCKET EVENT EMITTED with match completion data
📤 SOCKET: scoreboardSwapped emitted: {...}
```

#### Expected Logs (Backend Receiving - Check Backend Logs):
```
[Backend] Socket event received: scoreboardSwapped
[Backend] Data: {scoreboardId: xxx, isSwappingDuringMatch: true, ...}
```

#### Expected Logs (Frontend Receiving from Backend):
```
🔔 SOCKET EVENT: scoreboardSwapped -> {data}
🔄 ========== REPOSITORY: scoreboardSwapped EVENT ==========
🔄 REPOSITORY: Raw data received: {data}
🔄 REPOSITORY: Data type: _InternalLinkedHashMap<String, dynamic>
🔄 REPOSITORY: Data is NOT null
🔄 REPOSITORY: Data is a Map
🔄 REPOSITORY: Available keys: [scoreboardId, isSwappingDuringMatch, ...]
🔍 REPOSITORY KEY: "scoreboardId" => VALUE: xxx (String)
🔍 REPOSITORY KEY: "isSwappingDuringMatch" => VALUE: true (bool)
💰 REPOSITORY: swapXpChanges FOUND!
💰 REPOSITORY: swapXpChanges = [...]
💰 REPOSITORY: swapXpChanges is a List with 4 items
💰 REPOSITORY Player 0: {playerId: xxx, xpChange: 182.42, result: W}
...
🔄 ========== REPOSITORY: Calling callback ==========
🔄 ========== SCOREBOARD SWAPPED EVENT RECEIVED ==========
🔄 Full data: {data}
...
```

## Troubleshooting

### Case 1: No Logs at All
**Problem:** Socket connection nahi ho raha

**Solution:**
1. Check if socket URL correct hai
2. Check if backend socket server running hai
3. Check network connectivity
4. Check if userId properly set hai

**Test Command:**
```dart
// Add this in your controller onInit
print('🧪 Testing socket connection...');
repository.testConnection(); // If this method exists
```

### Case 2: Connection Logs Present, But No Event Logs
**Problem:** Socket connected hai but events receive nahi ho rahe

**Solution:**
1. Check if `joinScoreboard` properly call ho raha hai
2. Check if backend properly emit kar raha hai
3. Check backend logs for socket emission

**Backend Should Emit:**
```javascript
io.to(`scoreboard_${scoreboardId}`).emit('scoreboardSwapped', {
  scoreboardId: scoreboardId,
  isSwappingDuringMatch: true,
  swapXpChanges: [...]
});
```

### Case 3: Emit Logs Present, But Receive Logs Missing
**Problem:** Frontend emit kar raha hai but receive nahi kar raha

**Possible Reasons:**
1. Backend ne event receive kiya but wapas emit nahi kiya
2. Backend ne galat room mein emit kiya
3. Backend ne galat event name se emit kiya
4. Player us room mein join nahi hai

**Check Backend:**
```javascript
// Backend should have
socket.on('scoreboardSwapped', (data) => {
  console.log('Received scoreboardSwapped:', data);
  
  // Emit to all players in the room
  io.to(`scoreboard_${data.scoreboardId}`).emit('scoreboardSwapped', {
    ...data,
    swapXpChanges: [...] // Add this
  });
});
```

### Case 4: onAny Logs Present, But Specific Event Logs Missing
**Problem:** `onAny` mein event dikh raha hai but specific listener trigger nahi ho raha

**Check:**
```
🔔 SOCKET EVENT: scoreboardSwapped -> {data}
```

Agar yeh log dikh raha hai but REPOSITORY logs nahi dikh rahe, toh:
- Listener properly registered nahi hai
- Event name mismatch hai (case-sensitive)

**Solution:**
```dart
// Make sure this is called in onInit
repository.onScoreboardSwapped((data) {
  print('🔄 Callback triggered!');
  // ...
});
```

## Testing Checklist

- [ ] Socket connection successful (`✅ SOCKET: Connected successfully!`)
- [ ] Scoreboard joined (`🚪 Joined scoreboard: xxx`)
- [ ] Listener registered (`✅ REPOSITORY: scoreboardSwapped listener registered`)
- [ ] Team swap initiated (`🔄 SWAP INITIATED`)
- [ ] API call successful (`✅ SWAP API CALL SUCCESSFUL`)
- [ ] Socket event emitted (`📤 SOCKET: scoreboardSwapped emitted`)
- [ ] Backend received event (check backend logs)
- [ ] Backend emitted event back (check backend logs)
- [ ] Frontend received event (`🔔 SOCKET EVENT: scoreboardSwapped`)
- [ ] Repository callback triggered (`🔄 REPOSITORY: scoreboardSwapped EVENT`)
- [ ] Controller callback triggered (`🔄 SCOREBOARD SWAPPED EVENT RECEIVED`)

## Quick Debug Commands

### 1. Check Socket Status
```dart
print('Socket connected: ${repository._socket?.connected}');
print('Socket ID: ${repository._socket?.id}');
```

### 2. Manually Emit Test Event
```dart
repository._socket?.emit('test', {'message': 'Hello'});
```

### 3. Check All Active Listeners
```dart
// In repository
_socket?.onAny((event, data) {
  print('🔔 ANY EVENT: $event -> $data');
});
```

### 4. Force Re-register Listener
```dart
// In controller onInit, after joinScoreboard
Future.delayed(Duration(seconds: 2), () {
  print('🔄 Re-registering listener...');
  repository.onScoreboardSwapped((data) {
    print('🔄 LATE REGISTRATION: $data');
  });
});
```

## Expected Complete Flow

```
1. App starts
   ✅ SOCKET: Connected successfully!

2. User opens scoreboard
   🔵 SCOREBOARD ID: xxx
   🚪 Joined scoreboard: xxx
   ✅ REPOSITORY: scoreboardSwapped listener registered

3. User swaps teams during match
   🔄 SWAP INITIATED - isSwappingDuringMatch: true
   ========== SENDING SWAP API ==========
   ✅ SWAP API CALL SUCCESSFUL
   📤 SOCKET: scoreboardSwapped emitted

4. Backend processes and emits back
   [Backend] Received scoreboardSwapped
   [Backend] Emitting to room: scoreboard_xxx

5. All 4 players receive event
   🔔 SOCKET EVENT: scoreboardSwapped -> {data}
   🔄 REPOSITORY: scoreboardSwapped EVENT
   💰 REPOSITORY: swapXpChanges FOUND!
   🔄 SCOREBOARD SWAPPED EVENT RECEIVED
   💰 SWAP XP CHANGES FOUND: [...]
```

## If Still No Logs

### Last Resort Debugging:

1. **Add print in repository constructor:**
```dart
ScoreBoardRepository._internal() {
  print('🏗️ Repository initialized');
}
```

2. **Add print in socket connection:**
```dart
void _connectSocket() {
  print('🔌 _connectSocket called');
  // ... rest of code
}
```

3. **Add print in joinScoreboard:**
```dart
void joinScoreboard(String scoreboardId) {
  print('🚪 joinScoreboard called with: $scoreboardId');
  print('🚪 Socket null: ${_socket == null}');
  print('🚪 Socket connected: ${_socket?.connected}');
  // ... rest of code
}
```

4. **Check if onInit is even called:**
```dart
@override
void onInit() async {
  print('🎬 CONTROLLER onInit CALLED');
  super.onInit();
  // ... rest of code
}
```

## Contact Backend Team

Agar frontend logs sab dikh rahe hain but event receive nahi ho raha, toh backend team ko yeh share karo:

```
Frontend is emitting:
Event: scoreboardSwapped
Data: {
  scoreboardId: "xxx",
  isSwappingDuringMatch: true,
  preShuffleWinner: "Team A",
  preShuffleTeamAWins: 2,
  preShuffleTeamBWins: 1,
  teams: [...]
}

Backend should emit back:
Event: scoreboardSwapped
Room: scoreboard_xxx
Data: {
  scoreboardId: "xxx",
  isSwappingDuringMatch: true,
  swapXpChanges: [
    {playerId: "xxx", xpChange: 182.42, result: "W"},
    {playerId: "xxx", xpChange: 219.02, result: "W"},
    {playerId: "xxx", xpChange: -126.62, result: "L"},
    {playerId: "xxx", xpChange: -85.56, result: "L"}
  ],
  preShuffleWinner: "Team A",
  preShuffleTeamAWins: 2,
  preShuffleTeamBWins: 1,
  teams: [...]
}
```
