// Made by Dr Ali
// Locked +86 mainland China mobile field — local 11 digits only; prefix not clearable.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/obic_colors.dart';

/// Builds E.164 `+86…` from local 11-digit input, or null if invalid shape.
String? chinaMobileFromLocalDigits(String raw) {
  final digits = raw.trim().replaceAll(RegExp(r'\D'), '');
  var local = digits;
  if (local.startsWith('86') && local.length == 13) {
    local = local.substring(2);
  }
  if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(local)) return null;
  return '+86$local';
}

/// Strip pasted +86 / 0086 down to the 11-digit local mobile.
String stripToChinaLocalDigits(String raw) {
  var digits = raw.trim().replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('0086')) digits = digits.substring(4);
  if (digits.startsWith('86') && digits.length >= 13) {
    digits = digits.substring(2);
  }
  if (digits.length > 11) digits = digits.substring(0, 11);
  return digits;
}

class _ChinaLocalPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final local = stripToChinaLocalDigits(newValue.text);
    return TextEditingValue(
      text: local,
      selection: TextSelection.collapsed(offset: local.length),
    );
  }
}

/// Prefix `+86` is locked (LTR); user types the 11-digit mainland mobile.
class ChinaPhoneField extends StatelessWidget {
  const ChinaPhoneField({
    super.key,
    required this.controller,
    required this.label,
    this.enabled = true,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.underline = false,
    this.focused = false,
  });

  final TextEditingController controller;
  final String label;
  final bool enabled;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  /// When true, use underline style (register/login). Else outlined (gate).
  final bool underline;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final prefix = Directionality(
      textDirection: TextDirection.ltr,
      child: Padding(
        padding: EdgeInsets.only(
          right: underline ? 8 : 10,
          top: underline ? 14 : 0,
        ),
        child: Text(
          '+86',
          textDirection: TextDirection.ltr,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: ObicColors.titleOf(context),
          ),
        ),
      ),
    );

    if (underline) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          keyboardType: TextInputType.phone,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.left,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
            _ChinaLocalPhoneFormatter(),
          ],
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ObicColors.titleOf(context),
          ),
          decoration: InputDecoration(
            labelText: label,
            hintText: '13800138000',
            prefixIcon: prefix,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 2,
              vertical: 14,
            ),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: ObicColors.lineOf(context)),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: ObicColors.lineOf(context)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: ObicColors.blue, width: 1.4),
            ),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        keyboardType: TextInputType.phone,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.left,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(11),
          _ChinaLocalPhoneFormatter(),
        ],
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: ObicColors.titleOf(context),
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: '13800138000',
          prefixIcon: prefix,
          prefixIconConstraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 0,
          ),
          filled: true,
          fillColor: ObicColors.surfaceOf(context),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
