import 'package:flutter/material.dart';

/// [SafeBottomContainer] ek custom container hai jo bottom navigation bar ke overlap issue ko solve karta hai.
/// Ye widget check karta hai ki kya phone mein niche hardware/software system navigation buttons ya gesture bars hain.
/// 
/// - Agar niche buttons/gestures hain (jaise new iPhones ya Android edge-to-edge screens mein):
///   Ye automatic dynamic padding add karega (`MediaQuery.of(context).padding.bottom` ke barabar),
///   jisse aapke bottom bar ki buttons aur contents system buttons ke piche nahi chupengi.
/// 
/// - Agar phone mein niche buttons nahi hain (jaise purane physical buttons wale phone):
///   Ye sirf normal ya aapki provide ki hui minimal padding apply karega, bina faltu space chhode.
/// 
/// **Sabse acchi baat:** Iska background color bottom system bar ke piche tak failta hai,
/// jisse app ka UI float nahi karta aur pure edge-to-edge premium dikhta hai!
class SafeBottomContainer extends StatelessWidget {
  /// Bottom bar ke andar ka content (e.g. Buttons, Row, GNav, etc.)
  final Widget child;

  /// Background color jo bottom screen ke aakhiri edge tak dikhega
  final Color backgroundColor;

  /// Corner radius (jaise upar ke corners round karne ke liye: `BorderRadius.vertical(top: Radius.circular(30))`)
  final BorderRadiusGeometry? borderRadius;

  /// Box shadow agar bottom bar ko elevated look dena ho
  final List<BoxShadow>? boxShadow;

  /// Custom border agar aapko border add karni ho
  final BoxBorder? border;

  /// Custom gradient agar single color ki jagah gradient background lagana ho
  final Gradient? gradient;

  /// Minimum padding jo tab bhi lagegi jab phone mein system buttons na ho (taaki content bilkul chipka na rahe). Default is 0.
  final double minBottomPadding;

  /// Top, left, right padding jo content ke surrounding apply karni ho (niche ki safe padding isme automatically add ho jayegi)
  final EdgeInsetsGeometry? padding;

  /// Agar [true] hoga, toh safe padding sirf tabhi apply hogi jab bottom navigation buttons active honge (yaani bottom padding >= [buttonsThreshold]).
  /// iPhones aur generic screen gestures (jahan buttons nahi hote) ke liye normal padding rahegi.
  final bool onlyForButtons;

  /// System bottom buttons ki height threshold (typically >= 40.0 pixels Android three-buttons bar ke liye)
  final double buttonsThreshold;

  const SafeBottomContainer({
    super.key,
    required this.child,
    this.backgroundColor = Colors.white,
    this.borderRadius,
    this.boxShadow,
    this.border,
    this.gradient,
    this.minBottomPadding = 0.0,
    this.padding,
    this.onlyForButtons = true,
    this.buttonsThreshold = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    // Mobile screen ki bottom system inset (buttons/gesture bar ki height) detect karein
    final double systemBottomPadding = MediaQuery.of(context).padding.bottom;

    // Check karein ki kya mobile mein niche system navigation buttons hain:
    // Android three-buttons bar typically >= 48px hota hai, jabki iPhones gesture indicator 34px hota hai.
    final bool hasBottomButtons = systemBottomPadding >= buttonsThreshold;

    // Agar check enabled hai (onlyForButtons = true), toh safe padding sirf actual buttons wale phones par hi lagegi.
    // Dusre phones (jaise iPhones ya gesture devices) par hum normal minBottomPadding use karenge.
    final double actualBottomPadding = onlyForButtons
        ? (hasBottomButtons ? systemBottomPadding : minBottomPadding)
        : (systemBottomPadding > 0 ? systemBottomPadding : minBottomPadding);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        boxShadow: boxShadow,
        border: border,
        gradient: gradient,
      ),
      // Hum extra padding niche ki side laga rahe hain jo buttons se content ko upar push karegi
      padding: (padding ?? EdgeInsets.zero).add(
        EdgeInsets.only(bottom: actualBottomPadding),
      ),
      child: child,
    );
  }
}
