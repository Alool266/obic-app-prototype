// Made by Dr Ali
// Staff desk — list / create / edit hotel & flight offers (media via uploads).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/media_url.dart';
import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import '../admin/admin_api.dart';

class AdminOffersScreen extends StatefulWidget {
  const AdminOffersScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<AdminOffersScreen> createState() => _AdminOffersScreenState();
}

class _AdminOffersScreenState extends State<AdminOffersScreen> {
  final _api = AdminApi();
  final _searchCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  Timer? _debounce;
  String _kindFilter = '';
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  bool _hasFilters = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_scheduleLoad);
    _cityCtrl.addListener(_scheduleLoad);
    _searchCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  void _scheduleLoad() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 420), _load);
  }

  void _clearFilters() {
    _searchCtrl.clear();
    _cityCtrl.clear();
    if (_kindFilter.isNotEmpty) setState(() => _kindFilter = '');
    _load();
  }

  Future<void> _load() async {
    final q = _searchCtrl.text.trim();
    final city = _cityCtrl.text.trim();
    setState(() {
      _loading = true;
      _error = null;
      _hasFilters = q.isNotEmpty || city.isNotEmpty || _kindFilter.isNotEmpty;
    });
    try {
      final token = await widget.authController.ensureAccessToken();
      if (token == null) throw Exception('Not signed in');
      final items = await _api.listOffers(
        token,
        kind: _kindFilter.isEmpty ? null : _kindFilter,
        q: q.isEmpty ? null : q,
        city: city.isEmpty ? null : city,
      );
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
        builder: (_) => OfferEditorScreen(
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
        title: Text(ar ? 'عروض الفنادق والطيران' : 'Hotel & flight offers'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: Text(ar ? 'عرض جديد' : 'New offer'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: '', label: Text(ar ? 'الكل' : 'All')),
                    ButtonSegment(
                      value: 'hotels',
                      label: Text(ar ? 'فنادق' : 'Hotels'),
                    ),
                    ButtonSegment(
                      value: 'flights',
                      label: Text(ar ? 'طيران' : 'Flights'),
                    ),
                    ButtonSegment(
                      value: 'restaurants',
                      label: Text(ar ? 'مطاعم' : 'Food'),
                    ),
                  ],
                  selected: {_kindFilter},
                  onSelectionChanged: (s) {
                    setState(() => _kindFilter = s.first);
                    _load();
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _searchCtrl,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _load(),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: ar
                        ? 'ابحث عن عنوان، وصف، موقع…'
                        : 'Search title, body, location…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchCtrl.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () {
                              _searchCtrl.clear();
                              _load();
                            },
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _cityCtrl,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _load(),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: ar
                              ? 'المدينة (اختياري)'
                              : 'City (optional)',
                          prefixIcon: const Icon(Icons.location_city_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    if (_hasFilters) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _clearFilters,
                        child: Text(ar ? 'مسح' : 'Clear'),
                      ),
                    ],
                  ],
                ),
                if (_hasFilters && !_loading && _items.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    ar
                        ? '${_items.length} ${_items.length == 1 ? 'نتيجة' : 'نتائج'}'
                        : '${_items.length} result${_items.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      color: ObicColors.mutedOf(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text(_error!, textAlign: TextAlign.center))
                : _items.isEmpty
                ? Center(
                    child: Text(
                      _hasFilters
                          ? (ar
                                ? 'لا نتائج لهذا البحث'
                                : 'No results for this search')
                          : (ar
                                ? 'لا عروض بعد — أضف فندق أو تذكرة طيران'
                                : 'No offers yet — add a hotel or flight'),
                      textAlign: TextAlign.center,
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final o = _items[i];
                        final title = ar
                            ? (o['titleAr'] as String? ?? '')
                            : (o['titleEn'] as String? ?? '');
                        final kind = o['kind'] as String? ?? '';
                        final pub = o['isPublished'] == true;
                        final sold = o['isSoldOut'] == true;
                        final expired = o['isExpired'] == true;
                        final cover = _coverUrl(o);
                        return Material(
                          color: ObicColors.card,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _openEditor(o),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: cover.isEmpty
                                        ? Container(
                                            width: 64,
                                            height: 64,
                                            color: ObicColors.line,
                                            child: Icon(
                                              kind == 'flights'
                                                  ? Icons.flight
                                                  : Icons.hotel,
                                            ),
                                          )
                                        : Image.network(
                                            cover,
                                            width: 64,
                                            height: 64,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const SizedBox(
                                                  width: 64,
                                                  height: 64,
                                                ),
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: ObicColors.titleOf(context),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          () {
                                            final kindLabel = kind == 'flights'
                                                ? (ar ? 'طيران' : 'Flight')
                                                : (ar ? 'فندق' : 'Hotel');
                                            final status = !pub
                                                ? (ar ? 'مسودة' : 'Draft')
                                                : sold
                                                ? (ar ? 'نفد' : 'Sold out')
                                                : expired
                                                ? (ar ? 'منتهي' : 'Expired')
                                                : (ar ? 'منشور' : 'Published');
                                            final by =
                                                o['createdByName'] as String?;
                                            final byLine =
                                                (by != null && by.isNotEmpty)
                                                ? (ar
                                                      ? ' · أضافه $by'
                                                      : ' · by $by')
                                                : '';
                                            return '$kindLabel · $status$byLine';
                                          }(),
                                          style: TextStyle(
                                            color: ObicColors.mutedOf(context),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _coverUrl(Map<String, dynamic> o) {
    final media = o['media'];
    if (media is! List) return '';
    for (final m in media) {
      if (m is Map && m['kind'] == 'image' && m['url'] is String) {
        return resolveMediaUrl(m['url'] as String);
      }
    }
    return '';
  }
}

class OfferEditorScreen extends StatefulWidget {
  const OfferEditorScreen({
    super.key,
    required this.authController,
    this.existing,
  });

  final AuthController authController;
  final Map<String, dynamic>? existing;

  @override
  State<OfferEditorScreen> createState() => _OfferEditorScreenState();
}

class _OfferEditorScreenState extends State<OfferEditorScreen> {
  final _api = AdminApi();
  final _picker = ImagePicker();
  late String _kind;
  late final TextEditingController _titleAr;
  late final TextEditingController _titleEn;
  late final TextEditingController _bodyAr;
  late final TextEditingController _bodyEn;
  late final TextEditingController _priceAr;
  late final TextEditingController _priceEn;
  late final TextEditingController _location;
  late final TextEditingController _dates;
  late bool _published;
  late bool _soldOut;
  DateTime? _expiresAt;
  List<Map<String, dynamic>> _media = [];
  bool _busy = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _kind = (e?['kind'] as String?) ?? 'hotels';
    _titleAr = TextEditingController(text: e?['titleAr'] as String? ?? '');
    _titleEn = TextEditingController(text: e?['titleEn'] as String? ?? '');
    _bodyAr = TextEditingController(text: e?['bodyAr'] as String? ?? '');
    _bodyEn = TextEditingController(text: e?['bodyEn'] as String? ?? '');
    _priceAr = TextEditingController(text: e?['priceLabelAr'] as String? ?? '');
    _priceEn = TextEditingController(text: e?['priceLabelEn'] as String? ?? '');
    _location = TextEditingController(
      text: e?['locationLabel'] as String? ?? '',
    );
    _dates = TextEditingController(text: e?['datesLabel'] as String? ?? '');
    _published = e?['isPublished'] == true;
    _soldOut = e?['isSoldOut'] == true;
    final exp = e?['expiresAt'];
    if (exp is String && exp.isNotEmpty) {
      _expiresAt = DateTime.tryParse(exp)?.toLocal();
    }
    final media = e?['media'];
    if (media is List) {
      _media = media
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
  }

  @override
  void dispose() {
    _titleAr.dispose();
    _titleEn.dispose();
    _bodyAr.dispose();
    _bodyEn.dispose();
    _priceAr.dispose();
    _priceEn.dispose();
    _location.dispose();
    _dates.dispose();
    super.dispose();
  }

  Future<void> _pickMedia({required bool video}) async {
    if (_media.length >= 9) return;
    final token = await widget.authController.ensureAccessToken();
    if (token == null) return;
    final XFile? file = video
        ? await _picker.pickVideo(source: ImageSource.gallery)
        : await _picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 85,
          );
    if (file == null) return;
    setState(() => _busy = true);
    try {
      final url = await _api.uploadFile(
        accessToken: token,
        path: file.path,
        filename: file.name,
      );
      if (!mounted) return;
      setState(() {
        _media.add({
          'kind': video ? 'video' : 'image',
          'url': url,
          'name': file.name,
        });
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _save() async {
    final ar = Directionality.of(context) == TextDirection.rtl;
    if (_titleAr.text.trim().isEmpty || _titleEn.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ar
                ? 'العنوان بالعربية والإنجليزية مطلوب'
                : 'AR + EN titles required',
          ),
        ),
      );
      return;
    }
    final token = await widget.authController.ensureAccessToken();
    if (token == null) return;
    setState(() => _busy = true);
    final body = <String, dynamic>{
      'kind': _kind,
      'titleAr': _titleAr.text.trim(),
      'titleEn': _titleEn.text.trim(),
      'bodyAr': _bodyAr.text.trim(),
      'bodyEn': _bodyEn.text.trim(),
      'priceLabelAr': _priceAr.text.trim().isEmpty
          ? null
          : _priceAr.text.trim(),
      'priceLabelEn': _priceEn.text.trim().isEmpty
          ? null
          : _priceEn.text.trim(),
      'locationLabel': _location.text.trim().isEmpty
          ? null
          : _location.text.trim(),
      'datesLabel': _dates.text.trim().isEmpty ? null : _dates.text.trim(),
      'media': _media,
      'isPublished': _published,
      'isSoldOut': _soldOut,
      'expiresAt': _expiresAt?.toUtc().toIso8601String(),
    };
    try {
      if (_isEdit) {
        await _api.updateOffer(
          accessToken: token,
          id: widget.existing!['id'] as String,
          body: body,
        );
      } else {
        await _api.createOffer(accessToken: token, body: body);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _delete() async {
    final id = widget.existing?['id'] as String?;
    if (id == null) return;
    final token = await widget.authController.ensureAccessToken();
    if (token == null) return;
    setState(() => _busy = true);
    try {
      await _api.deleteOffer(accessToken: token, id: id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      appBar: AppBar(
        title: Text(
          _isEdit
              ? (ar ? 'تعديل العرض' : 'Edit offer')
              : (ar ? 'عرض جديد' : 'New offer'),
        ),
        actions: [
          if (_isEdit)
            IconButton(
              onPressed: _busy ? null : _delete,
              icon: const Icon(Icons.delete_outline),
            ),
          TextButton(
            onPressed: _busy ? null : _save,
            child: Text(ar ? 'حفظ' : 'Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'hotels',
                label: Text(ar ? 'فندق' : 'Hotel'),
                icon: const Icon(Icons.hotel),
              ),
              ButtonSegment(
                value: 'flights',
                label: Text(ar ? 'طيران' : 'Flight'),
                icon: const Icon(Icons.flight),
              ),
              ButtonSegment(
                value: 'restaurants',
                label: Text(ar ? 'مطعم' : 'Restaurant'),
                icon: const Icon(Icons.restaurant),
              ),
            ],
            selected: {_kind},
            onSelectionChanged: (s) => setState(() => _kind = s.first),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _titleAr,
            decoration: InputDecoration(
              labelText: ar ? 'العنوان (عربي)' : 'Title (Arabic)',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _titleEn,
            decoration: InputDecoration(
              labelText: ar ? 'العنوان (إنجليزي)' : 'Title (English)',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _location,
            decoration: InputDecoration(
              labelText: ar ? 'المدينة / المسار' : 'City / route',
              hintText: ar
                  ? 'مثال: قوانغتشو أو CAN → RUH'
                  : 'e.g. Guangzhou or CAN → RUH',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _dates,
            decoration: InputDecoration(
              labelText: ar ? 'التواريخ' : 'Dates',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _priceAr,
            decoration: InputDecoration(
              labelText: ar ? 'السعر (عربي)' : 'Price label (AR)',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _priceEn,
            decoration: InputDecoration(
              labelText: ar ? 'السعر (إنجليزي)' : 'Price label (EN)',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _bodyAr,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: ar ? 'التفاصيل (عربي)' : 'Details (Arabic)',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _bodyEn,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: ar ? 'التفاصيل (إنجليزي)' : 'Details (English)',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            ar ? 'صور وفيديو' : 'Photos & video',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: ObicColors.titleOf(context),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _media.length; i++)
                Stack(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: ObicColors.line,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _media[i]['kind'] == 'image'
                          ? Image.network(
                              resolveMediaUrl(_media[i]['url'] as String?),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image),
                            )
                          : const Center(child: Icon(Icons.videocam)),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        iconSize: 18,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => setState(() => _media.removeAt(i)),
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ],
                ),
              if (_media.length < 9) ...[
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _pickMedia(video: false),
                  icon: const Icon(Icons.image),
                  label: Text(ar ? 'صورة' : 'Photo'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _pickMedia(video: true),
                  icon: const Icon(Icons.videocam),
                  label: Text(ar ? 'فيديو' : 'Video'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(ar ? 'نشر للعملاء' : 'Publish to customers'),
            value: _published,
            onChanged: (v) => setState(() => _published = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(ar ? 'نفدت الكمية' : 'Sold out'),
            subtitle: Text(
              ar
                  ? 'يخفي العرض عن العملاء ويمنع الطلب'
                  : 'Hides from customers and blocks requests',
              style: TextStyle(
                fontSize: 12,
                color: ObicColors.mutedOf(context),
              ),
            ),
            value: _soldOut,
            onChanged: (v) => setState(() => _soldOut = v),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(ar ? 'تاريخ الانتهاء' : 'Expires at'),
            subtitle: Text(
              _expiresAt == null
                  ? (ar ? 'بدون انتهاء' : 'No expiry')
                  : _expiresAt!.toLocal().toString().split('.').first,
              style: TextStyle(
                fontSize: 12,
                color: ObicColors.mutedOf(context),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_expiresAt != null)
                  IconButton(
                    tooltip: ar ? 'مسح' : 'Clear',
                    onPressed: () => setState(() => _expiresAt = null),
                    icon: const Icon(Icons.clear),
                  ),
                IconButton(
                  tooltip: ar ? 'اختيار' : 'Pick',
                  onPressed: () async {
                    final now = DateTime.now();
                    final d = await showDatePicker(
                      context: context,
                      initialDate:
                          _expiresAt ?? now.add(const Duration(days: 7)),
                      firstDate: now,
                      lastDate: now.add(const Duration(days: 365 * 3)),
                    );
                    if (d == null || !mounted) return;
                    final t = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(
                        _expiresAt ?? now.add(const Duration(hours: 12)),
                      ),
                    );
                    if (t == null || !mounted) return;
                    setState(() {
                      _expiresAt = DateTime(
                        d.year,
                        d.month,
                        d.day,
                        t.hour,
                        t.minute,
                      );
                    });
                  },
                  icon: const Icon(Icons.event),
                ),
              ],
            ),
          ),
          if (_busy) ...[
            const SizedBox(height: 12),
            const Center(child: CircularProgressIndicator()),
          ],
          const SizedBox(height: 24),
          Text(
            ar ? 'تصميم وتطوير: د. علي' : 'Made by Dr Ali',
            textAlign: TextAlign.center,
            style: TextStyle(color: ObicColors.mutedOf(context), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
