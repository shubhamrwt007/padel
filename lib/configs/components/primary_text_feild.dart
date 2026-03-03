import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../app_colors.dart';

class PrimaryTextField extends StatelessWidget {
  final String hintText;
  final int? maxLength;
  final int? maxLine;
  final int? minLine;
  final double? width,height;
  final BoxBorder? border;
  final Color? color;
  final bool? enabled;
  final TextStyle? style;
  final Widget? suffixIcon;
  final TextEditingController? controller;
  final bool? readOnly;
  final TextInputType? keyboardType;
  final FocusNode? focusNode;
  final Function(String)? onFieldSubmitted;
  final TextInputAction? action;
  final List<TextInputFormatter>?formatter;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final String? prefixText;
  final String? initialValue;
  final Widget? prefix;
  final Widget? prefixIcon;
  final EdgeInsets? scrollPadding;
  final bool? obscureText;
  final TextStyle? hintStyle;
  final TextStyle? labelStyle;
  final EdgeInsetsGeometry? contentPadding;
  final TextCapitalization? textCapitalization;
  final String? labelText;
  const PrimaryTextField({
    super.key,
    this.action,
    this.initialValue,
    this.onFieldSubmitted,
    this.validator,
    required this.hintText,
    this.maxLength,
    this.maxLine,
    this.minLine,
    this.width,
    this.formatter,
    this.focusNode,
    this.height,
    this.border,
    this.color,
    this.enabled = true,
    this.style,
    this.suffixIcon,
    this.controller,
    this.readOnly = false,
    this.keyboardType,
    this.onChanged,
    this.prefixText,
    this.prefix,this.prefixIcon,
    this.scrollPadding, this.obscureText,
    this.hintStyle,this.labelStyle, this.contentPadding,
    this.textCapitalization,this.labelText
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      enableInteractiveSelection: true,
      initialValue: initialValue,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: validator,
      obscureText: obscureText??false,
      obscuringCharacter: "●",
      scrollPadding: scrollPadding?? const EdgeInsets.all(0),
      inputFormatters: formatter,
      onFieldSubmitted:onFieldSubmitted ,
      readOnly: readOnly??false,
      controller: controller,
      enabled: enabled,
      maxLength: maxLength,
      textCapitalization: textCapitalization??TextCapitalization.none,
      style:style?? Theme.of(context)
          .textTheme.headlineMedium!.copyWith(color: AppColors.textColor,fontWeight: FontWeight.w500),
      keyboardType: keyboardType??TextInputType.text,
      maxLines: maxLine,
      minLines: minLine,
      onChanged:  onChanged,
      textInputAction:action,
      decoration: InputDecoration(
        suffixIcon:suffixIcon,
        prefixText:prefixText,
        prefix:prefix ,
        prefixIcon: prefixIcon,
        // contentPadding: EdgeInsets.only(left: Get.width*0.04),
        contentPadding:contentPadding?? EdgeInsets.symmetric(
          horizontal: Get.width * 0.04,
          vertical: (height ?? 57) * 0.26,
        ),
        counterText: "",
        hintText: hintText,
        labelText: labelText,
        hintStyle:hintStyle?? Theme.of(context).textTheme.headlineMedium!.copyWith(color: AppColors.textColor,fontWeight: FontWeight.w500),
        labelStyle:labelStyle?? Theme.of(context).textTheme.headlineMedium!.copyWith(color: AppColors.textColor,fontWeight: FontWeight.w500),
        border:  OutlineInputBorder(
          borderSide: BorderSide(color: Colors.transparent,width: 2),
          borderRadius: BorderRadius.circular(5),

        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primaryColor,width: 2),
          borderRadius: BorderRadius.circular(5),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey,width: 1),
          borderRadius: BorderRadius.circular(5),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.redColor,width: 2),
          borderRadius: BorderRadius.circular(5),
        ),
        filled: true,
        fillColor: color??AppColors.textFieldColor,
      ),
    );
  }
}