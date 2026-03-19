import 'socket_service.dart';

class SlotWiseService {
  // Use singleton instance instead of creating new one
  SocketService get _socketService => SocketService.instance;
 
  // Subscribe karo ek date ke liye
  void subscribeToSlotWise({
    required String clubId,
    required String date,         // format: "2026-03-19"
    required String locationId,
    required String categoryId,
    required String sId,
    required String locId,
    required String day,
    required Function(dynamic data) onInitialData,   // ack se initial data
    required Function(dynamic data) onSlotUpdate,    // real-time updates
  }) {
    // Set callback for real-time updates FIRST
    _socketService.setSlotDataUpdateCallback(onSlotUpdate);
    
    // Then subscribe to slot-wise updates
    _socketService.subscribeToSlotWiseUpdates(
      clubId: clubId,
      date: date,
      locationId: locationId,
      categoryId: categoryId,
      sId: sId,
      day: day,
      locId: locId,
      onInitialData: onInitialData,
    );
  }
 
  // Unsubscribe karo jab page close ho
  void unsubscribe(String clubId, String date) {
    _socketService.unsubscribeFromSlotWiseUpdates(
      clubId: clubId,
      date: date,
    );
    _socketService.clearSlotDataUpdateCallback();
  }
}