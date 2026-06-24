   import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:padel_mobile/generated/assets.dart';
   Widget genderIcon(String? gender) {
    switch (gender) {
      case "male only":
        return Icon(Icons.male, size: 14);
      case "female only":
        return Icon(Icons.female, size: 14);
      case "mixed doubles":
        return SvgPicture.asset(
          Assets.images.icMixedGender.path,
          height: 14,
          width: 14,
          fit: BoxFit.contain,
        );
      default:
        return SvgPicture.asset(
          Assets.images.icMixedGender.path,
          height: 14,
          width: 14,
          fit: BoxFit.contain,
        ); // fallback
    }
  }