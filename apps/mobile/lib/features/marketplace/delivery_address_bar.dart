// Made by Dr Ali
// Meituan / Ctrip location + search — high contrast, RTL-safe, no InputDecoration icon bugs.

import 'package:flutter/material.dart';

import '../../theme/obic_colors.dart';
import '../../widgets/obic_soft_motion.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_models.dart';
import '../auth/require_auth.dart';
import '../me/addresses_screen.dart';

/// Pin + eyebrow + editable city + clear «إضافة» / «تعديل».
class DeliveryAddressBar extends StatelessWidget {
  const DeliveryAddressBar({
    super.key,
    required this.authController,
    required this.langCode,
    this.eyebrow,
    this.fallbackCity,
    this.onChanged,
  });

  final AuthController authController;
  final String langCode;

  /// Small label above the city — e.g. «التوصيل إلى» or «الوجهة».
  final String? eyebrow;

  /// Shown as the city line when the user has no saved address yet.
  final String? fallbackCity;

  final VoidCallback? onChanged;

  bool get _ar => langCode.startsWith('ar');
  bool get _zh => langCode.startsWith('zh');

  ObicAddress? get _default {
    final list = authController.user?.addresses ?? const <ObicAddress>[];
    for (final a in list) {
      if (a.isDefault) return a;
    }
    return list.isEmpty ? null : list.first;
  }

  String get _eyebrow {
    if (eyebrow != null && eyebrow!.trim().isNotEmpty) return eyebrow!;
    if (_ar) return 'التوصيل إلى';
    if (_zh) return '配送至';
    return 'Deliver to';
  }

  /// Bold primary line — city (editable), never a long stuffed address.
  String get _cityLine {
    final a = _default;
    if (a != null) {
      final city = a.city.trim();
      if (city.isNotEmpty) return city;
      final label = a.label.trim();
      if (label.isNotEmpty) return label;
      return a.formatted();
    }
    return fallbackCity ??
        (_ar ? 'اختر المدينة' : (_zh ? '选择城市' : 'Choose city'));
  }

  String? get _subLine {
    final a = _default;
    if (a == null) return null;
    final parts = <String>[
      if (a.label.trim().isNotEmpty && a.label.trim() != a.city.trim())
        a.label.trim(),
      if (a.line1.trim().isNotEmpty) a.line1.trim(),
    ];
    if (parts.isEmpty) return null;
    final s = parts.join(' · ');
    // Don't repeat the city line.
    if (s == _cityLine) return null;
    return s;
  }

  Future<void> _openAddresses(BuildContext context) async {
    final ok = await requireAuth(context, authController);
    if (!context.mounted || !ok) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => AddressesScreen(authController: authController),
      ),
    );
    onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final a = _default;
    final action = a == null
        ? (_ar ? 'إضافة' : (_zh ? '添加' : 'Add'))
        : (_ar ? 'تعديل' : (_zh ? '修改' : 'Edit'));
    final title = ObicColors.titleOf(context);
    final muted = ObicColors.mutedOf(context);

    return ObicBounce(
      onTap: () => _openAddresses(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_on_rounded,
              color: ObicColors.blue,
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _eyebrow,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                      color: muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _cityLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            height: 1.2,
                            color: title,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.expand_more_rounded,
                        size: 20,
                        color: muted,
                      ),
                    ],
                  ),
                  if (_subLine != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _subLine!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.2,
                        fontWeight: FontWeight.w500,
                        color: muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: ObicColors.blue.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                action,
                style: const TextStyle(
                  color: ObicColors.blue,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Search field built as a Row — avoids Flutter RTL prefixIcon / hint misalignment.
class MarketplaceSearchField extends StatelessWidget {
  const MarketplaceSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.isRtl,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final bool isRtl;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final ink = ObicColors.inkOf(context);
    final muted = ObicColors.mutedOf(context);
    final fill = ObicColors.isDark(context)
        ? ObicColors.darkSurfaceRaised
        : const Color(0xFFF1F5F9);
    final line = ObicColors.lineOf(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final hasText = controller.text.isNotEmpty;
        return Container(
          height: 46,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: line),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 12),
              const Icon(
                Icons.search_rounded,
                color: ObicColors.blue,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  textInputAction: TextInputAction.search,
                  // Follow ambient Directionality (app already RTL for ar).
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    height: 1.2,
                  ),
                  cursorColor: ObicColors.blue,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: muted,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      height: 1.2,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (hasText)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  onPressed: () {
                    controller.clear();
                    onChanged?.call('');
                  },
                  icon: Icon(Icons.close_rounded, color: muted, size: 20),
                )
              else
                const SizedBox(width: 12),
            ],
          ),
        );
      },
    );
  }
}
