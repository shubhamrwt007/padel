import 'dart:async';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class Player {
  final String name;
  final int points;
  final String imageUrl;
  final String record;

  Player(this.name, this.points, this.imageUrl, {this.record = "8-7-0"});
}

class ScoreViewController extends GetxController {
  final players = <Player>[
Player("Dianne", 122, "https://i.pravatar.cc/150?img=1"),
 Player("Jane", 110, "https://i.pravatar.cc/150?img=2"),
  Player("Lily", 100, "https://i.pravatar.cc/150?img=3"),
  Player("Sophia", 95, "https://i.pravatar.cc/150?img=4"),
  Player("Olivia", 90, "https://i.pravatar.cc/150?img=5"),
  Player("Emma", 88, "https://i.pravatar.cc/150?img=6"),
  Player("Ava", 85, "https://i.pravatar.cc/150?img=7"),
  Player("Isabella", 83, "https://i.pravatar.cc/150?img=8"),
  Player("Mia", 80, "https://i.pravatar.cc/150?img=9"),
  Player("Charlotte", 78, "https://i.pravatar.cc/150?img=10"),
  Player("Amelia", 75, "https://i.pravatar.cc/150?img=11"),
  ].obs;

  final selectedTab = 0.obs;
  final leftScore = 16.obs;
  final rightScore = 22.obs;

  // Match time fields
  RxString startTime = "".obs;
  RxString endTime = "".obs;

  // Timer-related variables
  RxInt remainingSeconds = 0.obs;
  Timer? _countdownTimer;
  Timer? _matchTimeCheckTimer;
  RxBool isTimerActive = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize with default times for testing (can be set from arguments or API)
    // Example: startTime.value = "12:00 PM"; endTime.value = "4:00 PM";
    _startMatchTimeCheck();
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    _matchTimeCheckTimer?.cancel();
    super.onClose();
  }

  /// Set match start and end times
  void setMatchTimes(String start, String end) {
    startTime.value = start;
    endTime.value = end;
    _checkAndStartTimer();
  }

  /// Start periodic check to see if match time window has started/ended
  void _startMatchTimeCheck() {
    _matchTimeCheckTimer?.cancel();
    _matchTimeCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkAndStartTimer();
    });
  }

  /// Check if we should start or stop the timer based on match times
  void _checkAndStartTimer() {
    if (startTime.value.isEmpty || endTime.value.isEmpty) {
      if (isTimerActive.value) {
        _stopCountdownTimer();
      }
      return;
    }

    DateTime now = DateTime.now();
    DateTime? startDateTime = _parseTimeToDateTime(startTime.value);
    DateTime? endDateTime = _parseTimeToDateTime(endTime.value);

    if (startDateTime == null || endDateTime == null) return;

    // Handle case where end time is before start time (next day)
    if (endDateTime.isBefore(startDateTime)) {
      endDateTime = endDateTime.add(const Duration(days: 1));
    }

    // Check if we're within the match time window
    bool isWithinWindow = (now.isAfter(startDateTime) || now.isAtSameMomentAs(startDateTime)) 
        && now.isBefore(endDateTime);

    if (isWithinWindow && !isTimerActive.value) {
      // Match has started, start countdown
      _startCountdownTimer();
    } else if (!isWithinWindow && isTimerActive.value) {
      // Match has ended or hasn't started yet, stop countdown
      _stopCountdownTimer();
      remainingSeconds.value = 0;
    } else if (isWithinWindow && isTimerActive.value) {
      // Update remaining time
      remainingSeconds.value = endDateTime.difference(now).inSeconds;
    }
  }

  /// Start the countdown timer
  void _startCountdownTimer() {
    if (isTimerActive.value) return;

    isTimerActive.value = true;
    _countdownTimer?.cancel();

    // Immediately calculate and set the initial remaining time
    // This ensures the timer shows the correct remaining time from the moment it starts
    DateTime now = DateTime.now();
    DateTime? endDateTime = _parseTimeToDateTime(endTime.value);

    if (endDateTime == null) {
      _stopCountdownTimer();
      return;
    }

    // Handle case where end time is before start time (next day)
    DateTime? startDateTime = _parseTimeToDateTime(startTime.value);
    if (startDateTime != null && endDateTime.isBefore(startDateTime)) {
      endDateTime = endDateTime.add(const Duration(days: 1));
    }

    // Set initial remaining time immediately (not waiting for first timer tick)
    int initialRemaining = endDateTime.difference(now).inSeconds;
    if (initialRemaining <= 0) {
      remainingSeconds.value = 0;
      _stopCountdownTimer();
      return;
    } else {
      remainingSeconds.value = initialRemaining;
    }

    // Start periodic timer to update every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      DateTime now = DateTime.now();
      DateTime? endDateTime = _parseTimeToDateTime(endTime.value);

      if (endDateTime == null) {
        _stopCountdownTimer();
        return;
      }

      // Handle case where end time is before start time (next day)
      DateTime? startDateTime = _parseTimeToDateTime(startTime.value);
      if (startDateTime != null && endDateTime.isBefore(startDateTime)) {
        endDateTime = endDateTime.add(const Duration(days: 1));
      }

      int remaining = endDateTime.difference(now).inSeconds;

      if (remaining <= 0) {
        // Match has ended
        remainingSeconds.value = 0;
        _stopCountdownTimer();
      } else {
        remainingSeconds.value = remaining;
      }
    });
  }

  /// Stop the countdown timer
  void _stopCountdownTimer() {
    isTimerActive.value = false;
    _countdownTimer?.cancel();
  }

  /// Parse time string to DateTime object
  DateTime? _parseTimeToDateTime(String timeStr) {
    try {
      if (timeStr.isEmpty) return null;

      String normalizedTime = _normalizeTimeFormat(timeStr.trim());
      DateTime timeObj = DateFormat('h:mm a').parse(normalizedTime);
      DateTime now = DateTime.now();

      DateTime dateTime = DateTime(
        now.year,
        now.month,
        now.day,
        timeObj.hour,
        timeObj.minute,
      );

      // If time is in the past, it might be for next day
      // But we'll let the caller handle this logic
      return dateTime;
    } catch (e) {
      return null;
    }
  }

  /// Normalize time format to "h:mm a" format
  String _normalizeTimeFormat(String time) {
    time = time.trim();
    // Convert "11 am" to "11:00 AM"
    if (!time.contains(':')) {
      final parts = time.split(' ');
      if (parts.length == 2) {
        time = '${parts[0]}:00 ${parts[1].toUpperCase()}';
      }
    } else {
      // Ensure AM/PM is uppercase
      time = time.replaceAllMapped(
        RegExp(r'(am|pm)', caseSensitive: false),
        (match) => match.group(0)!.toUpperCase(),
      );
    }
    return time;
  }

  /// Calculate total match duration in seconds
  int _getTotalMatchDuration() {
    try {
      if (startTime.value.isEmpty || endTime.value.isEmpty) return 0;

      DateTime? startDateTime = _parseTimeToDateTime(startTime.value);
      DateTime? endDateTime = _parseTimeToDateTime(endTime.value);

      if (startDateTime == null || endDateTime == null) return 0;

      // Handle case where end time is before start time (next day)
      if (endDateTime.isBefore(startDateTime)) {
        endDateTime = endDateTime.add(const Duration(days: 1));
      }

      return endDateTime.difference(startDateTime).inSeconds;
    } catch (e) {
      return 0;
    }
  }

  /// Format remaining time as HH:MM:SS or MM:SS based on total match duration
  String get formattedTime {
    if (!isTimerActive.value || remainingSeconds.value <= 0) {
      // Get total match duration to determine format
      int totalDuration = _getTotalMatchDuration();
      
      // If total duration is 0 (times not set), use remaining seconds as fallback
      if (totalDuration == 0 && remainingSeconds.value > 0) {
        totalDuration = remainingSeconds.value;
      }
      
      // If exactly 1 hour (3600 seconds), show MM:SS, if more than 1 hour, show HH:MM:SS
      if (totalDuration > 3600) {
        return '00:00:00';
      } else {
        return '00:00';
      }
    }

    final hours = remainingSeconds.value ~/ 3600;
    final minutes = (remainingSeconds.value % 3600) ~/ 60;
    final seconds = remainingSeconds.value % 60;

    // Get total match duration to determine format
    int totalDuration = _getTotalMatchDuration();
    
    // Determine format:
    // 1. If total duration is available and > 1 hour, use HH:MM:SS
    // 2. If total duration is 0 (not set), check if remaining time >= 1 hour to determine format
    // 3. If exactly 1 hour or less, use MM:SS
    
    bool shouldShowHours = false;
    
    if (totalDuration > 0) {
      // Use total duration if available
      shouldShowHours = totalDuration > 3600;
    } else {
      // Fallback: use remaining time to determine format
      shouldShowHours = remainingSeconds.value > 3600;
    }

    if (shouldShowHours) {
      // Show HH:MM:SS format (e.g., 01:59:59 for 2-hour match, even if only 30 min remaining)
      // Always show hours even if 0, because the match is more than 1 hour long
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      // Show MM:SS format (e.g., 59:59 for 1-hour match or less)
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}