// Made by Dr Ali
// Phone field for China +86, Saudi Arabia +966, and Yemen +967.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../theme/obic_colors.dart';
import 'auth_widgets.dart';

const smsDialChina = '86';
const smsDialSaudi = '966';
const smsDialYemen = '967';

int smsLocalLength(String dialCode) {
  switch (dialCode) {
    case smsDialChina:
      return 11;
    case smsDialSaudi:
    case smsDialYemen:
      return 9;
    default:
      return 11;
  }
}

/// E.164 for a chosen dial code, or null when the local digits do not match.
String? smsMobileFromLocalDigits(String dialCode, String raw) {
  var digits = raw.trim().replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('0')) digits = digits.replaceFirst(RegExp(r'^0+'), '');
  switch (dialCode) {
    case smsDialChina:
      if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(digits)) return null;
      return '+86$digits';
    case smsDialSaudi:
      if (!RegExp(r'^5\d{8}$').hasMatch(digits)) return null;
      return '+966$digits';
    case smsDialYemen:
      if (!RegExp(r'^7\d{8}$').hasMatch(digits)) return null;
      return '+967$digits';
    default:
      return null;
  }
}

class SmsPhoneField extends StatelessWidget {
  const SmsPhoneField({
    super.key,
    required this.controller,
    required this.label,
    required this.dialCode,
    required this.onDialCode,
    this.focusNode,
    this.textInputAction,
    this.focused = false,
  });

  final TextEditingController controller;
  final String label;
  final String dialCode;
  final ValueChanged<String> onDialCode;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final max = smsLocalLength(dialCode);
    final hint = switch (dialCode) {
      smsDialSaudi => '5xxxxxxxx',
      smsDialYemen => '7xxxxxxxx',
      _ => '13800138000',
    };
    final prefix = Directionality(
      textDirection: TextDirection.ltr,
      child: PopupMenuButton<String>(
        initialValue: dialCode,
        onSelected: (code) {
          if (code == dialCode) return;
          final keep = controller.text.replaceAll(RegExp(r'\D'), '');
          final limit = smsLocalLength(code);
          controller.text = keep.length > limit ? keep.substring(0, limit) : keep;
          onDialCode(code);
        },
        itemBuilder: (context) => [
          PopupMenuItem(value: smsDialChina, child: Text(l10n.smsCountryChina)),
          PopupMenuItem(value: smsDialSaudi, child: Text(l10n.smsCountrySaudi)),
          PopupMenuItem(value: smsDialYemen, child: Text(l10n.smsCountryYemen)),
        ],
        child: Padding(
          padding: const EdgeInsets.only(right: 8, top: 14),
          child: Text(
            '+$dialCode',
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: ObicColors.titleOf(context),
            ),
          ),
        ),
      ),
    );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.phone,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.left,
        textInputAction: textInputAction,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(max),
        ],
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: ObicColors.titleOf(context),
        ),
        decoration: authUnderlineDecoration(
          context: context,
          label: label,
          hint: hint,
          focused: focused,
        ).copyWith(
          prefixIcon: prefix,
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        ),
      ),
    );
  }
}
