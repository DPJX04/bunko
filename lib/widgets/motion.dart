import 'package:flutter/material.dart';

/// Shared motion timing, so every transition in the app moves as one family.
///
/// Durations follow Material 3: quick feedback, routine state changes, and
/// the 300 ms fade through between tabs. Curves use Material's own easing.
abstract final class Motion {
  /// Small feedback, such as a button reacting.
  static const quick = Duration(milliseconds: 150);

  /// Routine state changes, such as the Download button collapsing.
  static const standard = Duration(milliseconds: 250);

  /// Switching tabs: the old tab fades out, then the new one fades in.
  static const fadeThrough = Duration(milliseconds: 300);

  /// Things arriving on screen settle with this curve.
  static const enter = Easing.emphasizedDecelerate;

  /// Things leaving the screen speed up with this curve.
  static const exit = Easing.emphasizedAccelerate;

  /// Size and position changes that stay on screen.
  static const move = Easing.standard;
}

/// Returns [duration], or zero when the phone's Remove animations setting
/// is on, so every change becomes an instant cut.
Duration motionDuration(BuildContext context, Duration duration) {
  return MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}
