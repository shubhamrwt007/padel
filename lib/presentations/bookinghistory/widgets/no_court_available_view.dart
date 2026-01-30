import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/presentations/bookinghistory/booking_history_controller.dart';
import '../../../data/request_models/booking/boking_history_model.dart';

class NoCourtAvailableView extends StatelessWidget {
  final BookingHistoryController controller = Get.find<BookingHistoryController>(tag: 'booking_history');
  final BookingHistoryData? booking;
  
  NoCourtAvailableView({super.key, this.booking});

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
                color: Colors.black.withValues(alpha: 0.35),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Oops! That court is no longer\navailable",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 14),

                const Text(
                  "The selected court has just been booked, and no other courts are available at this time. You’ll receive a refund for your share.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 30),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2446C8),
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    final openMatchIdValue = booking?.openMatchId?.sId ?? 
                                            booking?.sId ?? 
                                            booking?.scoreboard?.openMatchId ?? 
                                            "";
                    Get.back();
                    controller.refund(
                      openMatchId: openMatchIdValue,
                      refund: _calculateRefundAmount(),
                    );
                    log("OPENMATCH ID-> $openMatchIdValue");
                  },
                  child: const Text(
                    "Okay",
                    style: TextStyle(fontSize: 16,color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}