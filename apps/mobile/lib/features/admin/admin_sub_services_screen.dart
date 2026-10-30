// Made by Dr Ali
// SuperAdmin — inner services (hub items) per parent category.

import 'package:flutter/material.dart';

import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import 'admin_api.dart';

class AdminSubServicesScreen extends StatefulWidget {
  const AdminSubServicesScreen({
    super.key,
    required this.authController,
    required this.serviceId,
    required this.parentTitle,
  });

  final AuthController authController;
  final String serviceId;
  final String parentTitle;

  @override
  State<AdminSubServicesScreen> createState() => _AdminSubServicesScreenState();
}

class _AdminSubServicesScreenState extends State<AdminSubServicesScreen> {
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
      final items = await _api.listSubServices(token, widget.serviceId);
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
        builder: (_) => _SubEditorSheet(
          authController: widget.authController,
          serviceId: widget.serviceId,
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ar ? 'خدمات داخلية' : 'Inner services'),
            Text(
              widget.parentTitle,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: Text(ar ? 'خدمة داخلية' : 'New inner'),
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
                    ? (row['nameAr'] as String? ?? row['id'] as String)
                    : (row['nameEn'] as String? ?? row['id'] as String);
                final zh = row['nameZh'] as String? ?? '';
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(title),
                    subtitle: Text(
                      '${row['id']} · ${row['sortOrder'] ?? 0}'
                      '${zh.isNotEmpty ? ' · $zh' : ''}',
                    ),
                    trailing: Icon(
                      active ? Icons.check_circle : Icons.pause_circle,
                      color: active ? ObicColors.blue : ObicColors.muted,
                    ),
                    onTap: () => _openEditor(row),
                  ),
                );
              },
            ),
    );
  }
}

class _SubEditorSheet extends StatefulWidget {
  const _SubEditorSheet({
    required this.authController,
    required this.serviceId,
    this.existing,
  });

  final AuthController authController;
  final String serviceId;
  final Map<String, dynamic>? existing;

  @override
  State<_SubEditorSheet> createState() => _SubEditorSheetState();
}

class _SubEditorSheetState extends State<_SubEditorSheet> {
  final _api = AdminApi();
  final _externalId = TextEditingController();
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
      _externalId.text = e['id'] as String? ?? '';
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
      _externalId,
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
        'externalId': _externalId.text.trim(),
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
        body['serviceId'] = widget.serviceId;
        await _api.createSubService(accessToken: token, body: body);
      } else {
        await _api.updateSubService(
          accessToken: token,
          id: widget.existing!['uuid'] as String,
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
              ? (ar ? 'تعديل خدمة داخلية' : 'Edit inner service')
              : (ar ? 'خدمة داخلية جديدة' : 'New inner service'),
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
          _field(ar ? 'المعرّف id' : 'External id', _externalId),
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
