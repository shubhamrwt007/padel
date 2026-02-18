# Payment Flow Implementation Summary

## Overview
Implemented a flow where the match request API is called automatically after successful payment when a user tries to join a match with insufficient wallet balance.

## Flow Sequence
1. User clicks to join a match → `_requestToJoinMatch()` in `open_match_for_all_court_screen.dart`
2. `requestPlayerForOpenMatch()` API is called in `add_player_controller.dart`
3. If 404 error (insufficient balance), navigate to `PaymentForWallet` with request context
4. User completes payment via `WalletController.createBalance()`
5. On payment success, `_onPaymentSuccess()` automatically calls the request API
6. User is successfully added to the match

## Files Modified

### 1. `wallet_controller.dart`
**Changes:**
- Added pending request context variables:
  - `pendingMatchId`
  - `pendingBookingId`
  - `pendingTeam`
  - `pendingPrice`
- Modified `_onPaymentSuccess()` to check for pending request and execute it
- Added `_executeRequestAfterPayment()` method to call the request API after payment
- Added `get_storage` import

### 2. `payment_for_wallet.dart`
**Changes:**
- Modified payment button's `onPressed` handler
- Added logic to store request context in `WalletController` before calling `createBalance()`
- Passes the following arguments to WalletController:
  - `requestMatchId`
  - `requestBookingId`
  - `requestTeam`
  - `requestPrice`

### 3. `add_player_controller.dart`
**Changes:**
- Modified `requestPlayerForOpenMatch()` DioException handler
- When navigating to `PaymentForWallet`, now passes request context as arguments:
  - `requestMatchId`: matchId.value
  - `requestBookingId`: bookingId
  - `requestTeam`: selectedTeam.value
  - `requestPrice`: price

## How It Works

1. **Request Initiation:**
   ```dart
   await _requestToJoinMatch(team, match?.sId ?? '', match?.bookingId?.sId ?? '', match?.totalAmount/4);
   ```

2. **Insufficient Balance Detection:**
   ```dart
   if (e.response?.statusCode == 404) {
     Get.to(() => PaymentForWallet(...), arguments: {
       'requestMatchId': matchId.value,
       'requestBookingId': bookingId,
       'requestTeam': selectedTeam.value,
       'requestPrice': price,
     });
   }
   ```

3. **Payment Initiation:**
   ```dart
   walletController.pendingMatchId = requestMatchId;
   walletController.pendingBookingId = requestBookingId;
   walletController.pendingTeam = requestTeam;
   walletController.pendingPrice = requestPrice;
   walletController.createBalance(amountToPay);
   ```

4. **Payment Success & Auto Request:**
   ```dart
   Future<void> _onPaymentSuccess(...) async {
     await fetchWallet();
     await fetchTransaction(isRefresh: true);
     
     if (pendingMatchId != null && pendingBookingId != null && pendingTeam != null) {
       await _executeRequestAfterPayment();
     }
   }
   ```

5. **Execute Request:**
   ```dart
   Future<void> _executeRequestAfterPayment() async {
     final addPlayerController = Get.put(AddPlayerController());
     addPlayerController.matchId.value = pendingMatchId!;
     addPlayerController.selectedTeam.value = pendingTeam!;
     addPlayerController.playerId.value = storage.read('userId') ?? '';
     
     await addPlayerController.requestPlayerForOpenMatch(
       bookingId: pendingBookingId!,
       price: pendingPrice,
     );
     
     // Clear pending context
     pendingMatchId = null;
     pendingBookingId = null;
     pendingTeam = null;
     pendingPrice = null;
   }
   ```

## Benefits
- Seamless user experience - no need to manually retry after payment
- Automatic request submission after successful payment
- Clean separation of concerns
- Proper error handling and context cleanup

## Testing Checklist
- [ ] Test with insufficient balance scenario
- [ ] Verify payment success triggers request API
- [ ] Verify payment failure doesn't trigger request API
- [ ] Verify context is cleared after successful request
- [ ] Test with sufficient balance (normal flow should work)
- [ ] Verify match list refreshes after successful join
