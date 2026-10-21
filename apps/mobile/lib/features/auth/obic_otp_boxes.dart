// Made by Dr Ali
// Apple-style 6-digit OTP boxes — digits always LTR; paste + autofill friendly.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/obic_colors.dart';

/// Shared PIN/OTP entry used by phone-verify and email-verify flows.
class ObicOtpBoxes extends StatefulWidget {
  const ObicOtpBoxes({
    super.key,
    this.length = 6,
    this.autofocus = true,
    this.enabled = true,
    this.hasError = false,
    this.onChanged,
    this.onCompleted,
    this.controller,
    this.focusNode,
  });

  final int length;
  final bool autofocus;
  final bool enabled;
  final bool hasError;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  @override
  State<ObicOtpBoxes> createState() => ObicOtpBoxesState();
}

class ObicOtpBoxesState extends State<ObicOtpBoxes> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final bool _ownsController;
  late final bool _ownsFocus;

  String get code => _controller.text;

  void clear() {
    _controller.clear();
    widget.onChanged?.call('');
    _focusNode.requestFocus();
  }

  void requestFocus() => _focusNode.requestFocus();

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _ownsFocus = widget.focusNode == null;
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    if (_ownsController) _controller.dispose();
    if (_ownsFocus) _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final digits = _controller.text.replaceAll(RegExp(r'\D'), '');
    final clipped = digits.length > widget.length
        ? digits.substring(0, widget.length)
        : digits;
    if (clipped != _controller.text) {
      _controller.value = TextEditingValue(
        text: clipped,
        selection: TextSelection.collapsed(offset: clipped.length),
      );
      return;
    }
    widget.onChanged?.call(clipped);
    if (clipped.length == widget.length) {
      widget.onCompleted?.call(clipped);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final dark = ObicColors.isDark(context);
    final fill = dark ? ObicColors.surfaceOf(context) : Colors.white;
    final line = ObicColors.lineOf(context);
    final errorBorder = ObicColors.badgeRed;
    final focused = _focusNode.hasFocus;
    final text = _controller.text;
    final activeIndex = text.length.clamp(0, widget.length - 1);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled
            ? () {
                _focusNode.requestFocus();
                SystemChannels.textInput.invokeMethod('TextInput.show');
              }
            : null,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Hidden field drives keyboard, paste, and SMS OTP autofill.
            Opacity(
              opacity: 0,
              child: SizedBox(
                height: 1,
                width: 1,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  autofocus: widget.autofocus,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.left,
                  textInputAction: TextInputAction.done,
                  maxLength: widget.length,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(color: Colors.transparent),
                  cursorColor: Colors.transparent,
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                  ),
                  onTap: () => setState(() {}),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
            Row(
              children: List.generate(widget.length, (i) {
                final digit = i < text.length ? text[i] : '';
                final isActive = focused && widget.enabled && i == activeIndex;
                final borderColor = widget.hasError
                    ? errorBorder
                    : isActive
                    ? ObicColors.blue
                    : line;
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    curve: Curves.easeOut,
                    height: 52,
                    margin: EdgeInsetsDirectional.only(
                      end: i == widget.length - 1 ? 0 : 8,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: fill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: borderColor,
                        width: isActive || widget.hasError ? 1.6 : 1.1,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: ObicColors.blue.withValues(alpha: 0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      digit,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1,
                        color: ObicColors.titleOf(context),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
