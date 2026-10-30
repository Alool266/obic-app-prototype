// Made by Dr Ali
// SuperAdmin — browse and edit public service catalog.

import 'package:flutter/material.dart';

import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import 'admin_api.dart';
import 'admin_sub_services_screen.dart';

class AdminServicesScreen extends StatefulWidget {
  const AdminServicesScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<AdminServicesScreen> createState() => _AdminServicesScreenState();
}

class _AdminServicesScreenState extends State<AdminServicesScreen> {
  final _api = AdminApi();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await widget.authController.ensureAccessToken();
      if (token == null) throw Exception('Not signed in');
      final items = await _api.listServices(token);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _openEditor([Map<String, dynamic>? existing]) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _ServiceEditorSheet(
          authController: widget.authController,
          existing: existing,
        ),
      ),
    );
    if (ok == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final ar = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      appBar: AppBar(
        title: Text(ar ? 'كتالوج الخدمات' : 'Service catalog'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: Text(ar ? 'خدمة جديدة' : 'New service'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
              itemCount: _items.length,
              itemBuilder: (context, i) {
                final row = _items[i];
                final active = row['isActive'] != false;
                final title = ar
                    ? (row['nameAr'] as String? ?? row['slug'] as String)
                    : (row['nameEn'] as String? ?? row['slug'] as String);
                final zh = row['nameZh'] as String? ?? '';
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(title),
                    subtitle: Text(
                      '${row['slug']} · ${row['sortOrder'] ?? 0}'
                      '${zh.isNotEmpty ? ' · $zh' : ''}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: ar ? 'خدمات داخلية' : 'Inner services',
                          icon: const Icon(Icons.list_alt_outlined),
                          onPressed: () {
                            Navigator.of(context).push<void>(
                              MaterialPageRoute(
                                builder: (_) => AdminSubServicesScreen(
                                  authController: widget.authController,
                                  serviceId: row['id'] as String,
                                  parentTitle: title,
                                ),
                              ),
                            );
                          },
                        ),
                        Icon(
                          active ? Icons.check_circle : Icons.pause_circle,
                          color: active ? ObicColors.blue : ObicColors.muted,
                        ),
                      ],
                    ),
                    onTap: () => _openEditor(row),
                  ),
                );
              },
            ),
    );
  }
}

class _ServiceEditorSheet extends StatefulWidget {
  const _ServiceEditorSheet({required this.authController, this.existing});

  final AuthController authController;
  final Map<String, dynamic>? existing;

  @override
  State<_ServiceEditorSheet> createState() => _ServiceEditorSheetState();
}

class _ServiceEditorSheetState extends State<_ServiceEditorSheet> {
  final _api = AdminApi();
  final _slug = TextEditingController();
  final _icon = TextEditingController();
  final _sort = TextEditingController(text: '0');
  final _nameAr = TextEditingController();
  final _nameEn = TextEditingController();
  final _nameZh = TextEditingController();
  final _descAr = TextEditingController();
  final _descEn = TextEditingController();
  final _descZh = TextEditingController();
  final _priceAr = TextEditingController();
  final _priceEn = TextEditingController();
  final _priceZh = TextEditingController();
  bool _active = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _slug.text = e['slug'] as String? ?? '';
      _icon.text = e['icon'] as String? ?? '';
      _sort.text = '${e['sortOrder'] ?? 0}';
      _nameAr.text = e['nameAr'] as String? ?? '';
      _nameEn.text = e['nameEn'] as String? ?? '';
      _nameZh.text = e['nameZh'] as String? ?? '';
      _descAr.text = e['descAr'] as String? ?? '';
      _descEn.text = e['descEn'] as String? ?? '';
      _descZh.text = e['descZh'] as String? ?? '';
      _priceAr.text = e['priceAr'] as String? ?? '';
      _priceEn.text = e['priceEn'] as String? ?? '';
      _priceZh.text = e['priceZh'] as String? ?? '';
      _active = e['isActive'] != false;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _slug,
      _icon,
      _sort,
      _nameAr,
      _nameEn,
      _nameZh,
      _descAr,
      _descEn,
      _descZh,
      _priceAr,
      _priceEn,
      _priceZh,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final token = await widget.authController.ensureAccessToken();
      if (token == null) throw Exception('Not signed in');
      final body = <String, dynamic>{
        'slug': _slug.text.trim(),
        'icon': _icon.text.trim(),
        'sortOrder': int.tryParse(_sort.text.trim()) ?? 0,
        'nameAr': _nameAr.text.trim(),
        'nameEn': _nameEn.text.trim(),
        'nameZh': _nameZh.text.trim(),
        'descAr': _descAr.text.trim(),
        'descEn': _descEn.text.trim(),
        'descZh': _descZh.text.trim(),
        'priceAr': _priceAr.text.trim(),
        'priceEn': _priceEn.text.trim(),
        'priceZh': _priceZh.text.trim(),
        'isActive': _active,
      };
      if (widget.existing == null) {
        await _api.createService(accessToken: token, body: body);
      } else {
        await _api.updateService(
          accessToken: token,
          id: widget.existing!['id'] as String,
          body: body,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = Directionality.of(context) == TextDirection.rtl;
    final editing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          editing
              ? (ar ? 'تعديل خدمة' : 'Edit service')
              : (ar ? 'خدمة جديدة' : 'New service'),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : _save,
            child: Text(ar ? 'حفظ' : 'Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field(ar ? 'المعرّف slug' : 'Slug', _slug),
          _field(ar ? 'أيقونة' : 'Icon key', _icon),
          _field(ar ? 'ترتيب' : 'Sort order', _sort),
          SwitchListTile(
            value: _active,
            onChanged: (v) => setState(() => _active = v),
            title: Text(ar ? 'نشط' : 'Active'),
          ),
          _field('الاسم AR', _nameAr),
          _field('Name EN', _nameEn),
          _field('名称 ZH', _nameZh),
          _field('الوصف AR', _descAr, maxLines: 3),
          _field('Description EN', _descEn, maxLines: 3),
          _field('描述 ZH', _descZh, maxLines: 3),
          _field('السعر AR', _priceAr),
          _field('Price EN', _priceEn),
          _field('价格 ZH', _priceZh),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController c, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
