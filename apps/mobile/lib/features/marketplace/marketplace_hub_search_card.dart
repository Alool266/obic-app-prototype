// Made by Dr Ali
// Meituan/Ctrip hub chrome — one opaque card: location row + full-width RTL search.
// Never sit text on the hero overlap; card is fully opaque white/surface.

import 'package:flutter/material.dart';

import '../../theme/obic_colors.dart';
import '../../widgets/obic_soft_motion.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_models.dart';
import '../auth/require_auth.dart';
import '../me/addresses_screen.dart';

/// Single clean card used by يومي + سفر.
class MarketplaceHubSearchCard extends StatelessWidget {
  const MarketplaceHubSearchCard({
    super.key,
    required this.authController,
    required this.langCode,
    required this.searchController,
    required this.searchHint,
    required this.eyebrow,
    required this.fallbackCity,
    this.onAddressChanged,
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.onUseGps,
    this.gpsBusy = false,
  });

  final AuthController authController;
  final String langCode;
  final TextEditingController searchController;
  final String searchHint;
  final String eyebrow;
  final String fallbackCity;
  final VoidCallback? onAddressChanged;
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<String>? onSearchSubmitted;
  /// One-tap GPS to set current delivery location.
  final VoidCallback? onUseGps;
  final bool gpsBusy;

  bool get _ar => langCode.startsWith('ar');
  bool get _zh => langCode.startsWith('zh');

  ObicAddress? get _default {
    final list = authController.user?.addresses ?? const <ObicAddress>[];
    for (final a in list) {
      if (a.isDefault) return a;
    }
    return list.isEmpty ? null : list.first;
  }

  String get _city {
    final a = _default;
    if (a == null) return fallbackCity;
    final city = a.city.trim();
    if (city.isNotEmpty) return city;
    final label = a.label.trim();
    if (label.isNotEmpty) return label;
    final line = a.line1.trim();
    if (line.isNotEmpty) return line;
    return fallbackCity;
  }

  Future<void> _openAddresses(BuildContext context) async {
    final ok = await requireAuth(context, authController);
    if (!context.mounted || !ok) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => AddressesScreen(authController: authController),
      ),
    );
    onAddressChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final surface = ObicColors.surfaceOf(context);
    final title = ObicColors.titleOf(context);
    final muted = ObicColors.mutedOf(context);
    final a = _default;
    final action = a == null
        ? (_ar ? 'إضافة' : (_zh ? '添加' : 'Add'))
        : (_ar ? 'تعديل' : (_zh ? '修改' : 'Edit'));

    // Force one direction for this card so Row/TextField never fight the
    // ambient locale (root cause of «إضافة» gap + cut search hint).
    final dir = _ar ? TextDirection.rtl : TextDirection.ltr;

    return Directionality(
      textDirection: dir,
      child: Material(
        color: surface,
        elevation: 6,
        shadowColor: ObicColors.navy.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top row: pin + eyebrow/city (tap) + إضافة (tight, no empty gulf).
              ObicBounce(
                onTap: () => _openAddresses(context),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: ObicColors.blue,
                      size: 22,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            eyebrow,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.15,
                              fontWeight: FontWeight.w600,
                              color: muted,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  _city,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.2,
                                    fontWeight: FontWeight.w800,
                                    color: title,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: muted,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (onUseGps != null) ...[
                      Material(
                        color: ObicColors.blue.withValues(alpha: 0.12),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: gpsBusy ? null : onUseGps,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: gpsBusy
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.my_location_rounded,
                                    size: 18,
                                    color: ObicColors.blue,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    // Pill stays adjacent — Intrinsic width, never “far left gulf”.
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: ObicColors.blue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        child: Text(
                          action,
                          style: const TextStyle(
                            color: ObicColors.blue,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _HubSearchField(
                controller: searchController,
                hint: searchHint,
                onChanged: onSearchChanged,
                onSubmitted: onSearchSubmitted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HubSearchField extends StatelessWidget {
  const _HubSearchField({
    required this.controller,
    required this.hint,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final ink = ObicColors.inkOf(context);
    final muted = ObicColors.mutedOf(context);
    final fill = ObicColors.isDark(context)
        ? ObicColors.darkSurfaceRaised
        : const Color(0xFFF1F5F9);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final hasText = controller.text.isNotEmpty;
        return Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 12),
              Icon(Icons.search_rounded, color: ObicColors.blue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  textInputAction: TextInputAction.search,
                  textAlign: TextAlign.start,
                  textAlignVertical: TextAlignVertical.center,
                  style: TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    height: 1.25,
                  ),
                  cursorColor: ObicColors.blue,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: muted,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      height: 1.25,
                    ),
                  ),
                ),
              ),
              if (hasText)
                GestureDetector(
                  onTap: () {
                    controller.clear();
                    onChanged?.call('');
                  },
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: 4,
                      end: 10,
                    ),
                    child: Icon(Icons.cancel, size: 18, color: muted),
                  ),
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
