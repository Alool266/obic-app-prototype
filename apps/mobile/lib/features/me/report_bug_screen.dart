// Made by Dr Ali
// Report a bug — description + optional photos via /v1/uploads + /v1/bug-reports.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';
import 'package:path/path.dart' as p;

import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import '../social/social_api.dart';

class ReportBugScreen extends StatefulWidget {
  const ReportBugScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<ReportBugScreen> createState() => _ReportBugScreenState();
}

class _ReportBugScreenState extends State<ReportBugScreen> {
  final _api = SocialApi();
  final _description = TextEditingController();
  final _photos = <String>[];
  bool _submitting = false;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final shots = await ImagePicker().pickMultiImage(
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (shots.isEmpty || !mounted) return;
    setState(() {
      for (final s in shots) {
        if (_photos.length >= 4) break;
        _photos.add(s.path);
      }
    });
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final text = _description.text.trim();
    if (text.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reportBugTooShort)),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final token = await widget.authController.ensureAccessToken();
      if (token == null) throw Exception('Not signed in');
      final urls = <String>[];
      if (_photos.isNotEmpty) {
        final items = await _api.uploadFiles(
          accessToken: token,
          files: [
            for (final path in _photos)
              (path: path, filename: p.basename(path)),
          ],
        );
        for (final item in items) {
          final url = item['url'] as String?;
          if (url != null && url.isNotEmpty) urls.add(url);
        }
      }
      await _api.submitBugReport(
        accessToken: token,
        description: text,
        photoUrls: urls.isEmpty ? null : urls,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reportBugThanks)),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: ObicColors.canvasOf(context),
      appBar: AppBar(
        title: Text(l10n.reportBugTitle),
        backgroundColor: ObicColors.surfaceOf(context),
        foregroundColor: ObicColors.inkOf(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.reportBugSubmit),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _description,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: l10n.reportBugDescriptionHint,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _photos.length >= 4 ? null : _pickPhotos,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(l10n.reportBugAddPhotos),
          ),
          if (_photos.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_photos[i]),
                          width: 88,
                          height: 88,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(28, 28),
                            padding: EdgeInsets.zero,
                          ),
                          iconSize: 16,
                          onPressed: () {
                            setState(() => _photos.removeAt(i));
                          },
                          icon: const Icon(Icons.close),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
