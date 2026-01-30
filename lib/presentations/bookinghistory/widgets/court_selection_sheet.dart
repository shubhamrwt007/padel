import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/presentations/bookinghistory/booking_history_controller.dart';
import '../../../data/request_models/booking/boking_history_model.dart';

class CourtSelectionSheet extends StatelessWidget {
  final BookingHistoryController controller = Get.find<BookingHistoryController>(tag: 'booking_history');
  final BookingHistoryData? booking;
  
  CourtSelectionSheet({super.key, this.booking});

  var selectedCourtIndex = 0.obs;

  int _calculateRefundAmount() {
    int totalRefund = 0;
    
    // Add amounts from teamA
    if (booking?.teamA != null) {
      for (var player in booking!.teamA!) {
        if (player.amountPaid != null) {
          totalRefund += (player.amountPaid is int) 
              ? player.amountPaid as int 
              : int.tryParse(player.amountPaid.toString()) ?? 0;
        }
      }
    }
    
    // Add amounts from teamB
    if (booking?.teamB != null) {
      for (var player in booking!.teamB!) {
        if (player.amountPaid != null) {
          totalRefund += (player.amountPaid is int) 
              ? player.amountPaid as int 
              : int.tryParse(player.amountPaid.toString()) ?? 0;
        }
      }
    }
    
    return totalRefund;
  }
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                color: Colors.black.withOpacity(0.35),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 100),

                  Text(
                    textAlign: TextAlign.center,
                    "Oops! That court is no longer\navailable",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    textAlign: TextAlign.center,
                    "The selected court has just been booked. You may choose another court for the same time slot or receive a refund for your share.",
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),

                  const SizedBox(height: 30),

                  Obx(() => Column(
                    children: _buildCourtTiles(),
                  )),

                  const Spacer(),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2446C8),
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      _bookSelectedSlot();
                    },
                    child: const Text("Book this slot",
                        style: TextStyle(fontSize: 14,color: Colors.white)),
                  ),

                  const SizedBox(height: 12),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3A3A3A),
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Get.back();
                      controller.refund(
                        openMatchId: booking?.openMatchId?.sId ?? "",
                        refund: _calculateRefundAmount(),
                      );
                    },
                    child: const Text("Refund the payment",
                        style: TextStyle(fontSize: 14,color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCourtTiles() {
    final alternativeCourts = booking?.alternativeCourts ?? [];
    
    if (alternativeCourts.isEmpty) {
      // Fallback to single default court if no alternative courts
      return [_courtTile(
        title: "COURT 1",
        time: "${booking?.startTime ?? '10:00'} – ${booking?.endTime ?? '11:00'}",
        selected: selectedCourtIndex.value == 0,
        onTap: () => selectedCourtIndex.value = 0,
      )];
    }
    
    return List.generate(alternativeCourts.length, (index) {
      final court = alternativeCourts[index];
      final startTime = booking?.startTime ?? '10:00';
      final endTime = booking?.endTime ?? '11:00';
      
      return _courtTile(
        title: court.courtName ?? "COURT ${index + 1}",
        time: "$startTime – $endTime",
        selected: selectedCourtIndex.value == index,
        onTap: () => selectedCourtIndex.value = index,
      );
    });
  }

  Widget _courtTile({
    required String title,
    required String time,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: Get.width*0.7,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2B3A63),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF2446C8) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(time,
                    style: const TextStyle(color: Colors.white70,fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _bookSelectedSlot() {
    final alternativeCourts = booking?.alternativeCourts ?? [];
    
    if (alternativeCourts.isEmpty) return;
    
    final selectedCourt = alternativeCourts[selectedCourtIndex.value];
    final openMatchSlots = booking?.openMatchId?.slot ?? [];
    
    final slotsData = openMatchSlots.map((slot) => {
      "slotId": slot.slotId ?? "",
      "courtId": selectedCourt.courtId ?? "",
    }).toList();
    
    controller.updateNewCourtBooking(
      openMatchId: booking?.openMatchId?.sId ?? "",
      slots: slotsData,
    );
  }
}