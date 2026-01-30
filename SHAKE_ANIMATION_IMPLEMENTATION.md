# Shake Animation Implementation

## Summary
Implemented shake animation for all 4 circle avatars in shuffle mode when user taps and drags a player using `flutter_shake_animated` package version 0.0.5.

## Changes Made

### 1. Package Installation
- Added `flutter_shake_animated: 0.0.5` to `pubspec.yaml`
- Ran `flutter pub get` to install the package

### 2. Controller Updates (`score_board_controller.dart`)
- Added `shouldShakeAvatars` observable variable:
  ```dart
  final shouldShakeAvatars = false.obs;
  ```

### 3. Screen Updates (`score_board_screen.dart`)
- Imported the shake animation package:
  ```dart
  import 'package:flutter_shake_animated/flutter_shake_animated.dart';
  ```

- Updated `_buildShufflePlayerItem` method to trigger shake on drag start:
  ```dart
  onDragStarted: () {
    isDragging.value = true;
    controller.shouldShakeAvatars.value = true;
    Future.delayed(const Duration(milliseconds: 500), () {
      controller.shouldShakeAvatars.value = false;
    });
  },
  ```

- Wrapped the avatar container with `ShakeWidget`:
  ```dart
  return Obx(() => ShakeWidget(
    shakeConstant: ShakeHorizontalConstant1(),
    autoPlay: controller.shouldShakeAvatars.value,
    enableWebMouseHover: false,
    child: AnimatedContainer(
      // ... existing avatar code
    ),
  ));
  ```

## How It Works
1. When a user starts dragging a player avatar in shuffle mode, `onDragStarted` is triggered
2. This sets `shouldShakeAvatars.value = true`
3. All 4 avatars wrapped in `ShakeWidget` with `autoPlay` bound to `shouldShakeAvatars` start shaking
4. After 500ms, the shake automatically stops by setting `shouldShakeAvatars.value = false`
5. The shake uses `ShakeHorizontalConstant1()` for a horizontal shake effect

## Testing
To test the implementation:
1. Open the scoreboard screen
2. Add all 4 players
3. Enable shuffle mode by tapping the shuffle icon
4. Tap and drag any player avatar
5. All 4 avatars should shake horizontally when dragging starts
