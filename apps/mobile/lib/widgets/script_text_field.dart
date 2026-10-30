// Made by Dr Ali
// Text field whose direction follows the first strong letter.

import 'package:flutter/material.dart';

import '../features/messages/group_avatar_collage.dart';

class ObicScriptTextField extends StatefulWidget {
  const ObicScriptTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.decoration,
    this.style,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.keyboardType,
    this.maxLines = 1,
    this.minLines,
    this.autofocus = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final TextStyle? style;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? minLines;
  final bool autofocus;
  final bool autocorrect;
  final bool enableSuggestions;

  @override
  State<ObicScriptTextField> createState() => _ObicScriptTextFieldState();
}

class _ObicScriptTextFieldState extends State<ObicScriptTextField> {
  TextEditingController? _owned;
  TextEditingController get _controller => widget.controller ?? _owned!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _owned = TextEditingController();
    }
    _controller.addListener(_onText);
  }

  @override
  void didUpdateWidget(ObicScriptTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _owned)?.removeListener(_onText);
      if (widget.controller == null && _owned == null) {
        _owned = TextEditingController();
      }
      _controller.addListener(_onText);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onText);
    _owned?.dispose();
    super.dispose();
  }

  void _onText() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final direction = inputTextDirection(
      _controller.text,
      Directionality.of(context),
    );
    return TextField(
      controller: _controller,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      style: widget.style,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      autocorrect: widget.autocorrect,
      enableSuggestions: widget.enableSuggestions,
      textDirection: direction,
      textAlign: TextAlign.start,
      decoration: widget.decoration,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
    );
  }
}
