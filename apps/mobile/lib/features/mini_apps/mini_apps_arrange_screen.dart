// Made by Dr Ali
// Drag to reorder, pin, hide, and put a hidden mini app back.

import 'package:flutter/material.dart';

import '../../theme/obic_colors.dart';
import 'mini_apps_catalog.dart';
import 'mini_apps_layout.dart';

class MiniAppsArrangeScreen extends StatefulWidget {
  const MiniAppsArrangeScreen({
    super.key,
    required this.apps,
    required this.userId,
  });

  final List<MiniAppEntry> apps;
  final String userId;

  @override
  State<MiniAppsArrangeScreen> createState() => _MiniAppsArrangeScreenState();
}

class _MiniAppsArrangeScreenState extends State<MiniAppsArrangeScreen> {
  late final MiniAppLayoutStore _store = MiniAppLayoutStore(widget.userId);
  MiniAppLayout _layout = MiniAppLayout.empty;
  late List<MiniAppEntry> _visible = List.of(widget.apps);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final layout = await _store.load();
    if (!mounted) return;
    setState(() {
      _layout = layout;
      _visible = applyMiniAppLayout(widget.apps, layout);
    });
  }

  Future<void> _commit(List<MiniAppEntry> visible, MiniAppLayout layout) async {
    final next = MiniAppLayout(
      order: [for (final app in visible) app.id],
      pinned: layout.pinned,
      hidden: layout.hidden,
    );
    setState(() {
      _layout = next;
      _visible = List.of(visible);
    });
    await _store.save(next);
  }

  String _t(String en, String ar, String zh, String fr) {
    final code = Localizations.localeOf(context).languageCode;
    if (code.startsWith('ar')) return ar;
    if (code.startsWith('zh')) return zh;
    if (code.startsWith('fr')) return fr;
    return en;
  }

  @override
  Widget build(BuildContext context) {
    final hidden = widget.apps.where((app) => _layout.hidden.contains(app.id)).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Mini apps', 'التطبيقات المصغرة', '小程序', 'Mini-apps')),
      ),
      body: Column(
        children: [
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.only(bottom: 12),
              itemCount: _visible.length,
              onReorderItem: (oldIndex, newIndex) {
                final next = List<MiniAppEntry>.of(_visible);
                final item = next.removeAt(oldIndex);
                next.insert(newIndex, item);
                _commit(next, _layout);
              },
              itemBuilder: (context, index) {
                final app = _visible[index];
                final pinned = _layout.pinned.contains(app.id);
                return ListTile(
                  key: ValueKey(app.id),
                  title: Text(app.name),
                  leading: Icon(
                    pinned ? Icons.push_pin_rounded : Icons.drag_handle_rounded,
                    color: pinned ? ObicColors.blue : ObicColors.mutedOf(context),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: pinned
                            ? _t('Unpin', 'إلغاء التثبيت', '取消置顶', 'Désépingler')
                            : _t('Pin', 'تثبيت', '置顶', 'Épingler'),
                        onPressed: () {
                          final pins = Set<String>.of(_layout.pinned);
                          if (!pins.add(app.id)) pins.remove(app.id);
                          final layout = MiniAppLayout(
                            order: _layout.order,
                            pinned: pins,
                            hidden: _layout.hidden,
                          );
                          final visible = applyMiniAppLayout(widget.apps, layout);
                          _commit(visible, layout);
                        },
                        icon: Icon(pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined),
                      ),
                      IconButton(
                        tooltip: _t('Remove', 'إزالة', '移除', 'Retirer'),
                        onPressed: () {
                          final hiddenIds = Set<String>.of(_layout.hidden)..add(app.id);
                          final pins = Set<String>.of(_layout.pinned)..remove(app.id);
                          final layout = MiniAppLayout(
                            order: _layout.order,
                            pinned: pins,
                            hidden: hiddenIds,
                          );
                          _commit(applyMiniAppLayout(widget.apps, layout), layout);
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (hidden.isNotEmpty)
            Material(
              color: ObicColors.surfaceOf(context),
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
                  for (final app in hidden)
                    ListTile(
                      title: Text(app.name),
                      trailing: const Icon(Icons.add_rounded),
                      onTap: () {
                        final hiddenIds = Set<String>.of(_layout.hidden)..remove(app.id);
                        final layout = MiniAppLayout(
                          order: [..._layout.order, app.id],
                          pinned: _layout.pinned,
                          hidden: hiddenIds,
                        );
                        _commit(applyMiniAppLayout(widget.apps, layout), layout);
                      },
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
