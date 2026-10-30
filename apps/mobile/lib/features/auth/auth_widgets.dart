// Made by Dr Ali
// Shared auth UI — WeChat-simple underlines + OBIC navy/blue depth.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/obic_colors.dart';
import '../../theme/obic_elevation.dart';
import '../../widgets/obic_logo.dart';

/// WeChat-style underline field; blue accent when focused.
InputDecoration authUnderlineDecoration({
  required BuildContext context,
  required String label,
  String? hint,
  Widget? suffix,
  required bool focused,
}) {
  final muted = ObicColors.mutedOf(context);
  final line = ObicColors.lineOf(context);
  final borderColor = focused ? ObicColors.blue : line;
  return InputDecoration(
    labelText: label,
    hintText: hint,
    suffixIcon: suffix,
    floatingLabelBehavior: FloatingLabelBehavior.auto,
    labelStyle: TextStyle(
      color: focused ? ObicColors.blue : muted,
      fontWeight: FontWeight.w500,
      fontSize: 15,
    ),
    floatingLabelStyle: TextStyle(
      color: focused ? ObicColors.blue : muted,
      fontWeight: FontWeight.w600,
      fontSize: 13,
    ),
    hintStyle: TextStyle(
      color: muted.withValues(alpha: 0.55),
      fontWeight: FontWeight.w400,
    ),
    filled: false,
    contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 14),
    border: UnderlineInputBorder(
      borderSide: BorderSide(color: line.withValues(alpha: 0.9)),
    ),
    enabledBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: line.withValues(alpha: 0.9)),
    ),
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: borderColor, width: 1.4),
    ),
  );
}

class AuthBrandMark extends StatelessWidget {
  const AuthBrandMark({
    super.key,
    required this.title,
    this.compact = false,
    this.onNavy = false,
  });

  final String title;
  final bool compact;
  final bool onNavy;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 56.0 : 72.0;
    final titleColor =
        onNavy ? Colors.white : ObicColors.titleOf(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: onNavy
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : ObicElevation.level1,
            border: Border.all(
              color: onNavy
                  ? Colors.white.withValues(alpha: 0.22)
                  : ObicColors.lineOf(context).withValues(alpha: 0.6),
              width: 1.2,
            ),
          ),
          child: ObicLogo(size: size, borderRadius: size * 0.22, metal: true),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: titleColor,
            fontWeight: FontWeight.w700,
            fontSize: compact ? 22 : 26,
            letterSpacing: 2.4,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 28,
          height: 2.5,
          decoration: BoxDecoration(
            color: ObicColors.blue,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: ObicColors.blue.withValues(alpha: 0.35),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AuthPrimaryCta extends StatelessWidget {
  const AuthPrimaryCta({
    super.key,
    required this.pressed,
    required this.scale,
    required this.busy,
    required this.label,
    required this.onTapDown,
    required this.onTapCancel,
    required this.onTap,
  });

  final bool pressed;
  final AnimationController scale;
  final bool busy;
  final String label;
  final VoidCallback onTapDown;
  final VoidCallback onTapCancel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: scale,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: busy
                ? [
                    ObicColors.blue.withValues(alpha: 0.55),
                    ObicColors.blueDeep.withValues(alpha: 0.55),
                  ]
                : [ObicColors.blue, ObicColors.blueDeep],
          ),
          boxShadow: busy ? null : ObicElevation.cta(pressed: pressed),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            onTapDown: onTap == null ? null : (_) => onTapDown(),
            onTapCancel: onTap == null ? null : onTapCancel,
            child: Center(
              child: busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        letterSpacing: 0.15,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown only after a short wait so a warm login stays a plain spinner,
/// while a cold API is not a circle with no explanation.
class AuthConnectingHint extends StatefulWidget {
  const AuthConnectingHint({
    super.key,
    required this.active,
    required this.message,
  });

  final bool active;
  final String message;

  @override
  State<AuthConnectingHint> createState() => _AuthConnectingHintState();
}

class _AuthConnectingHintState extends State<AuthConnectingHint> {
  static const _delay = Duration(seconds: 8);

  Timer? _timer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _sync(widget.active);
  }

  @override
  void didUpdateWidget(AuthConnectingHint oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) _sync(widget.active);
  }

  void _sync(bool active) {
    _timer?.cancel();
    _timer = null;
    if (!active) {
      if (_visible) setState(() => _visible = false);
      return;
    }
    if (_visible) return;
    _timer = Timer(_delay, () {
      if (mounted && widget.active) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      alignment: Alignment.topCenter,
      child: _visible
          ? Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                widget.message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ObicColors.mutedOf(context),
                      height: 1.35,
                    ),
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}

class AuthSocialStub extends StatelessWidget {
  const AuthSocialStub({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: ObicColors.titleOf(context),
        side: BorderSide(color: ObicColors.lineOf(context).withValues(alpha: 0.95)),
        backgroundColor: ObicColors.isDark(context)
            ? ObicColors.darkSurfaceRaised
            : ObicColors.card.withValues(alpha: 0.9),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
    );
  }
}

class AuthCardShell extends StatelessWidget {
  const AuthCardShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ObicColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(ObicElevation.radiusLg),
        border: Border.all(color: ObicColors.lineOf(context).withValues(alpha: 0.55)),
        boxShadow: ObicElevation.level2,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
        child: child,
      ),
    );
  }
}

/// Full-page navy → cool canvas used on Login / Register routes.
Decoration authPageDecoration({
  required bool embedded,
  BuildContext? context,
}) {
  final dark = context != null && ObicColors.isDark(context);
  final embTop = dark ? ObicColors.darkCanvas : ObicColors.background;
  final embCard = dark ? ObicColors.darkSurface : ObicColors.card;
  final endCanvas = dark ? ObicColors.darkCanvas : ObicColors.background;
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: embedded
          ? [embTop, embCard, embCard]
          : [
              ObicColors.navy,
              ObicColors.navySoft,
              const Color(0xFF16355A),
              endCanvas,
              endCanvas,
            ],
      stops: embedded ? const [0, 0.35, 1] : const [0, 0.16, 0.30, 0.48, 1],
    ),
  );
}

/// Email | Phone text switch — not Sign-in | Register.
class AuthChannelToggle extends StatelessWidget {
  const AuthChannelToggle({
    super.key,
    required this.left,
    required this.right,
    required this.index,
    required this.onChanged,
  });

  final String left;
  final String right;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _chip(context, 0, left),
        const SizedBox(width: 16),
        _chip(context, 1, right),
      ],
    );
  }

  Widget _chip(BuildContext context, int i, String label) {
    final selected = index == i;
    return GestureDetector(
      onTap: () => onChanged(i),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? ObicColors.titleOf(context)
                : ObicColors.mutedOf(context),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
            letterSpacing: selected ? 0.2 : 0,
          ),
        ),
      ),
    );
  }
}

class AuthBottomSwitch extends StatelessWidget {
  const AuthBottomSwitch({
    super.key,
    required this.prompt,
    required this.actionLabel,
    required this.onAction,
  });

  final String prompt;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            prompt,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ObicColors.mutedOf(context),
                  fontSize: 14,
                ),
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            foregroundColor: ObicColors.blue,
            padding: const EdgeInsetsDirectional.only(start: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            actionLabel,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            height: 1,
            thickness: 0.5,
            color: ObicColors.lineOf(context).withValues(alpha: 0.9),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ObicColors.mutedOf(context),
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
          ),
        ),
        Expanded(
          child: Divider(
            height: 1,
            thickness: 0.5,
            color: ObicColors.lineOf(context).withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}
