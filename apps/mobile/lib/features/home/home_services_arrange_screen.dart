// Made by Dr Ali
// Drag reorder, favorite (نجمة), hide, and restore Home service icons.

import 'package:flutter/material.dart';

import '../../theme/obic_colors.dart';
import '../services/service_catalog.dart';
import 'home_regional_icons.dart';
import 'home_service_layout.dart';

class HomeServicesArrangeScreen extends StatefulWidget {
  const HomeServicesArrangeScreen({
    super.key,
    required this.services,
    required this.userId,
    required this.langCode,
    this.accessToken,
    this.initial,
  });

  final List<ObicService> services;
  final String userId;
  final String langCode;
  final String? accessToken;
  final HomeServiceLayout? initial;

  @override
  State<HomeServicesArrangeScreen> createState() =>
      _HomeServicesArrangeScreenState();
}

class _HomeServicesArrangeScreenState extends State<HomeServicesArrangeScreen> {
  late final HomeServiceLayoutStore _store =
      HomeServiceLayoutStore(userId: widget.userId);
  HomeServiceLayout _layout = HomeServiceLayout.empty;
  late List<ObicService> _visible;

  @override
  void initState() {
    super.initState();
    _layout = widget.initial ?? HomeServiceLayout.empty;
    _visible = applyHomeServiceLayout(widget.services, _layout);
    if (widget.initial == null) {
      _load();
    }
  }

  Future<void> _load() async {
    final layout = await _store.load(accessToken: widget.accessToken);
    if (!mounted) return;
    setState(() {
      _layout = layout;
      _visible = applyHomeServiceLayout(widget.services, layout);
    });
  }

  Future<void> _commit(
    List<ObicService> visible,
    HomeServiceLayout layout,
  ) async {
    final next = HomeServiceLayout(
      order: [for (final s in visible) s.slug],
      favorites: layout.favorites,
      hidden: layout.hidden,
      // Preserve mini-app shelf — do not wipe parallel mini-apps layout.
      miniOrder: layout.miniOrder,
      miniFavorites: layout.miniFavorites,
      miniHidden: layout.miniHidden,
    );
    setState(() {
      _layout = next;
      _visible = List.of(visible);
    });
    await _store.save(next, accessToken: widget.accessToken);
  }

  String _t(String en, String ar, String zh, String fr) {
    final code = widget.langCode;
    if (code.startsWith('ar')) return ar;
    if (code.startsWith('zh')) return zh;
    if (code.startsWith('fr')) return fr;
    return en;
  }

  @override
  Widget build(BuildContext context) {
    final hidden = widget.services
        .where((s) => _layout.hidden.contains(s.slug))
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _t('Home icons', 'أيقونات الرئيسية', '首页图标', 'Icônes d’accueil'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_layout),
            child: Text(_t('Done', 'تم', '完成', 'OK')),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              _t(
                'Drag to reorder. Star to favorite. Remove hides from Home only.',
                'اسحب لإعادة الترتيب. النجمة للمفضّل. الإزالة تخفي من الرئيسية فقط.',
                '拖动排序。星标收藏。移除仅从首页隐藏。',
                'Glissez pour réordonner. Étoile = favori. Retirer masque seulement l’accueil.',
              ),
              style: TextStyle(
                color: ObicColors.mutedOf(context),
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.only(bottom: 12),
              itemCount: _visible.length,
              onReorderItem: (oldIndex, newIndex) {
                final next = List<ObicService>.of(_visible);
                final item = next.removeAt(oldIndex);
                next.insert(newIndex, item);
                _commit(next, _layout);
              },
              itemBuilder: (context, index) {
                final service = _visible[index];
                final fav = _layout.favorites.contains(service.slug);
                final theme = ServiceTheme.of(service.colorKey);
                return ListTile(
                  key: ValueKey(service.slug),
                  leading: isRegionalHomeIconSlug(service.slug)
                      ? RegionalHomeCoverGlyph(slug: service.slug, size: 40)
                      : CircleAvatar(
                          backgroundColor: theme.soft,
                          child: Icon(
                            serviceIconData(service.icon),
                            color: theme.ink,
                            size: 22,
                          ),
                        ),
                  title: Text(service.name(widget.langCode)),
                  subtitle: fav
                      ? Text(
                          _t('Favorite', 'مفضّل', '收藏', 'Favori'),
                          style: TextStyle(
                            color: ObicColors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: fav
                            ? _t(
                                'Unfavorite',
                                'إزالة من المفضّل',
                                '取消收藏',
                                'Retirer des favoris',
                              )
                            : _t(
                                'Favorite',
                                'مفضّل',
                                '收藏',
                                'Favori',
                              ),
                        onPressed: () {
                          final favs = Set<String>.of(_layout.favorites);
                          if (!favs.add(service.slug)) favs.remove(service.slug);
                          final layout = _layout.copyWith(favorites: favs);
                          final visible =
                              applyHomeServiceLayout(widget.services, layout);
                          _commit(visible, layout);
                        },
                        icon: Icon(
                          fav ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: fav ? const Color(0xFFFBBF24) : null,
                        ),
                      ),
                      IconButton(
                        tooltip: _t('Hide', 'إخفاء', '隐藏', 'Masquer'),
                        onPressed: () {
                          final hiddenIds =
                              Set<String>.of(_layout.hidden)..add(service.slug);
                          final favs = Set<String>.of(_layout.favorites)
                            ..remove(service.slug);
                          final layout = _layout.copyWith(
                            favorites: favs,
                            hidden: hiddenIds,
                          );
                          _commit(
                            applyHomeServiceLayout(widget.services, layout),
                            layout,
                          );
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      const Icon(Icons.drag_handle_rounded),
                    ],
                  ),
                );
              },
            ),
          ),
          if (hidden.isNotEmpty)
            Material(
              color: ObicColors.surfaceOf(context),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        _t('Add back', 'إعادة الإضافة', '加回', 'Remettre'),
                        style: TextStyle(
                          color: ObicColors.mutedOf(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    for (final service in hidden)
                      ListTile(
                        leading: Icon(
                          serviceIconData(service.icon),
                          color: ObicColors.mutedOf(context),
                        ),
                        title: Text(service.name(widget.langCode)),
                        trailing: const Icon(Icons.add_rounded),
                        onTap: () {
                          final hiddenIds = Set<String>.of(_layout.hidden)
                            ..remove(service.slug);
                          final layout = _layout.copyWith(
                            order: [..._layout.order, service.slug],
                            hidden: hiddenIds,
                          );
                          _commit(
                            applyHomeServiceLayout(widget.services, layout),
                            layout,
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
