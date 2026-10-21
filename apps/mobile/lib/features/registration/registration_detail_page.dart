// Made by Dr Ali
// One registration application: price snapshot, document checklist with
// Green/Yellow/Red, upload + re-upload, passport typed details + OBIC AI
// reading (staff decide — the AI never edits customer data), submit and
// timeline. Mirrors the server state machine; the server is the truth.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/media_pick.dart';
import '../../theme/obic_colors.dart';
import '../auth/auth_api.dart';
import '../auth/auth_controller.dart';
import 'registration_api.dart';
import 'registration_strings.dart';

class RegistrationDetailPage extends StatefulWidget {
  const RegistrationDetailPage({
    super.key,
    required this.authController,
    required this.langCode,
    required this.applicationId,
  });

  final AuthController authController;
  final String langCode;
  final String applicationId;

  @override
  State<RegistrationDetailPage> createState() => _RegistrationDetailPageState();
}

class _RegistrationDetailPageState extends State<RegistrationDetailPage> {
  final _api = RegistrationApi();
  final _picker = ImagePicker();
  RegistrationStrings get s => RegistrationStrings(widget.langCode);

  RegistrationApplication? _app;
  bool _busy = false;
  String? _error;
  String? _notice;
  final _fullName = TextEditingController();
  final _passportNo = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _fullName.dispose();
    _passportNo.dispose();
    super.dispose();
  }

  Future<String> _token() async {
    final token = await widget.authController.accessToken();
    if (token == null) throw Exception('Login required');
    return token;
  }

  Future<void> _load() async {
    try {
      final token = await _token();
      final app = await _api.getApplication(token, widget.applicationId);
      if (!mounted) return;
      setState(() {
        _app = app;
        final fd = app.formData ?? const {};
        if (fd['fullName'] is String && _fullName.text.isEmpty) {
          _fullName.text = fd['fullName'] as String;
        }
        if (fd['passportNumber'] is String && _passportNo.text.isEmpty) {
          _passportNo.text = fd['passportNumber'] as String;
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _run(Future<void> Function(String token) fn) async {
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      final token = await _token();
      await fn(token);
      await _load();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Color _colorOf(String color) {
    switch (color) {
      case 'Green':
        return Colors.green;
      case 'Red':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Future<void> _pickAndUpload(RegistrationDoc doc) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text(s.camera),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(s.gallery),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    PickedLocalMedia? media;
    if (source == ImageSource.camera) {
      media = await takeCameraPhoto(_picker);
    } else {
      final picked = await pickAlbumImages(_picker, limit: 1);
      media = picked.isEmpty ? null : picked.first;
    }
    if (media == null || !mounted) return;
    final pickedMedia = media;
    await _run((token) async {
      final url = await _api.uploadFile(
        accessToken: token,
        path: pickedMedia.path,
        filename: pickedMedia.filename,
      );
      await _api.uploadDocument(
        accessToken: token,
        applicationId: widget.applicationId,
        docType: doc.docType,
        fileUrl: url,
        fileName: pickedMedia.filename,
      );
      // For the passport, offer the AI reading right away (staff decide).
      if (doc.docType == 'passport') {
        await _extractPassport(File(pickedMedia.path));
      }
    });
  }

  Future<void> _extractPassport(File file) async {
    final app = _app;
    if (app == null) return;
    RegistrationDoc? passport;
    for (final d in app.documents) {
      if (d.docType == 'passport') passport = d;
    }
    if (passport == null) return;
    try {
      final token = await _token();
      await _api.extractPassport(
        accessToken: token,
        applicationId: app.id,
        documentId: passport.id,
        file: file,
        typedValues: {
          'fullName': _fullName.text.trim(),
          'passportNumber': _passportNo.text.trim(),
        },
      );
      if (mounted) setState(() => _notice = s.ocrSent);
    } on AuthApiException catch (e) {
      if (e.statusCode == 503 && mounted) {
        setState(() => _notice = s.ocrOff);
      }
      // Other failures: the upload itself succeeded; staff check manually.
    } catch (_) {
      // Reading is optional at upload time; staff can still review the photo.
    }
  }

  Future<void> _savePassportDetails() async {
    await _run((token) async {
      await _api.updateApplication(
        accessToken: token,
        id: widget.applicationId,
        formData: {
          'fullName': _fullName.text.trim(),
          'passportNumber': _passportNo.text.trim(),
        },
      );
    });
  }

  Widget _snapshotCard(RegistrationApplication app) {
    final snap = app.priceSnapshot!;
    final lines = snap['lines'];
    final totals = snap['totals'];
    final totalCents = totals is Map<String, dynamic>
        ? (totals['totalCents'] as num?) ?? 0
        : 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lines is List)
              for (final line in lines)
                if (line is Map<String, dynamic>)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text('${line['itemName']} (${line['version']})'),
                      ),
                      Text(
                        '¥${(((line['obicFeeCents'] as num?) ?? 0) / 100).toStringAsFixed(2)}',
                      ),
                    ],
                  ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  s.total,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '¥${(totalCents / 100).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = _app;
    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      appBar: AppBar(title: Text(s.title)),
      body: app == null
          ? Center(
              child: _error != null
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  : const CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Chip(
                  label: Text('${s.status}: ${app.status}'),
                  backgroundColor: ObicColors.blue.withValues(alpha: 0.12),
                ),
                const SizedBox(height: 8),
                Text('${s.tracking}: ${app.trackingId}'),
                if (app.contractId != null)
                  Text('${s.contract}: ${app.contractId}'),
                Text('${app.city} · ${app.activity}'),
                const SizedBox(height: 12),
                if (app.priceSnapshot != null) _snapshotCard(app),
                const SizedBox(height: 16),
                Text(
                  s.passportDetails,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _fullName,
                  decoration: InputDecoration(labelText: s.fullName),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passportNo,
                  decoration: InputDecoration(labelText: s.passportNumber),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _busy ? null : _savePassportDetails,
                  child: Text(s.saveDetails),
                ),
                const SizedBox(height: 16),
                Text(
                  s.documents,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                for (final doc in app.documents)
                  Card(
                    child: ListTile(
                      title: Text(
                        '${doc.label}${doc.required ? ' (${s.required})' : ''} · v${doc.version}',
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(doc.status),
                          if (doc.reviewNote != null)
                            Text('${s.staffNote}: ${doc.reviewNote}'),
                        ],
                      ),
                      leading: Icon(
                        Icons.circle,
                        color: _colorOf(doc.color),
                        size: 16,
                      ),
                      trailing: TextButton(
                        onPressed: _busy ? null : () => _pickAndUpload(doc),
                        child: Text(doc.version == 0 ? s.upload : s.replace),
                      ),
                    ),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                if (_notice != null) ...[
                  const SizedBox(height: 8),
                  Text(_notice!),
                ],
                const SizedBox(height: 16),
                if (app.status == 'DRAFT' ||
                    app.status == 'NEEDS_CUSTOMER_ACTION')
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: ObicColors.blue,
                    ),
                    onPressed: _busy
                        ? null
                        : () => _run(
                            (token) => _api.submit(token, widget.applicationId),
                          ),
                    child: Text(app.status == 'DRAFT' ? s.submit : s.resubmit),
                  ),
                if (app.status != 'COMPLETED' &&
                    app.status != 'CANCELLED' &&
                    app.status != 'REJECTED')
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => _run(
                            (token) => _api.cancel(token, widget.applicationId),
                          ),
                    child: Text(s.cancel),
                  ),
                const SizedBox(height: 16),
                Text(
                  s.timeline,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                for (final e in app.events.reversed)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '• ${e['action']} ${e['fromStatus'] ?? ''}→${e['toStatus'] ?? ''} ${e['note'] ?? ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
    );
  }
}
