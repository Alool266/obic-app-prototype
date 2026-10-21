// Made by Dr Ali
// Company folders. A photo can be added from the phone. Other files are added on the staff desk.

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import '../social/social_api.dart';

class CompanyDriveScreen extends StatefulWidget {
  const CompanyDriveScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<CompanyDriveScreen> createState() => _CompanyDriveScreenState();
}

class _CompanyDriveScreenState extends State<CompanyDriveScreen> {
  final _api = SocialApi();
  List<Map<String, dynamic>> _folders = [];
  Map<String, dynamic>? _folder;
  List<Map<String, dynamic>> _files = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    setState(() {
      _loading = true;
      _error = null;
      _folder = null;
      _files = [];
    });
    try {
      final token = await widget.authController.accessToken();
      if (token == null || token.isEmpty) throw StateError('sign-in');
      final home = await _api.companyDriveHome(token);
      if (!mounted) return;
      setState(() {
        _folders = _maps(home['folders']);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'failed';
      });
    }
  }

  Future<void> _openFolder(String folderId) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await widget.authController.accessToken();
      if (token == null || token.isEmpty) throw StateError('sign-in');
      final home = await _api.companyDriveFolder(token, folderId);
      if (!mounted) return;
      final folder = home['folder'];
      setState(() {
        _folder = folder is Map ? Map<String, dynamic>.from(folder) : null;
        _files = _maps(home['files']);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'failed';
      });
    }
  }

  Future<void> _addPhoto() async {
    final folderId = _folder?['id']?.toString();
    if (folderId == null || folderId.isEmpty) return;
    final shot = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (shot == null || !mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await widget.authController.accessToken();
      if (token == null || token.isEmpty) throw StateError('sign-in');
      await _api.uploadDriveFile(
        accessToken: token,
        folderId: folderId,
        path: shot.path,
        filename: shot.name,
      );
      if (!mounted) return;
      await _openFolder(folderId);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'failed';
      });
    }
  }

  Future<void> _openFile(Map<String, dynamic> file) async {
    final l10n = AppLocalizations.of(context);
    final mime = file['mime']?.toString() ?? '';
    if (!mime.startsWith('image/')) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.companyDriveOpenOnDesk)));
      return;
    }
    final fileId = file['id']?.toString() ?? '';
    if (fileId.isEmpty) return;
    try {
      final token = await widget.authController.accessToken();
      if (token == null || token.isEmpty) throw StateError('sign-in');
      final bytes = await _api.downloadDriveFile(accessToken: token, fileId: fileId);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => Dialog(child: Image.memory(bytes)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'failed');
    }
  }

  List<Map<String, dynamic>> _maps(Object? value) {
    if (value is! List) return [];
    return value.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
  }

  String _size(Object? value) {
    final size = value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;
    if (size >= 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    if (size >= 1024) return '${(size / 1024).round().clamp(1, 9999)} KB';
    return '$size B';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final folder = _folder;
    return Scaffold(
      backgroundColor: ObicColors.surfaceOf(context),
      appBar: AppBar(
        title: Text(folder?['name']?.toString() ?? l10n.companyDriveTitle),
        leading: folder == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _loadFolders,
              ),
      ),
      floatingActionButton: folder == null
          ? null
          : FloatingActionButton(
              onPressed: _loading ? null : _addPhoto,
              child: const Icon(Icons.add_a_photo_outlined),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(l10n.companyDriveHint, style: TextStyle(color: ObicColors.mutedOf(context))),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(l10n.companyDriveLoadFailed),
                  ),
                if (folder == null && _folders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(l10n.companyDriveNone),
                  ),
                if (folder != null && _files.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(l10n.companyDriveEmpty),
                  ),
                if (folder == null)
                  for (final row in _folders)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.folder_outlined),
                      title: Text(row['name']?.toString() ?? ''),
                      onTap: () => _openFolder(row['id']?.toString() ?? ''),
                    ),
                if (folder != null)
                  for (final row in _files)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(row['name']?.toString() ?? ''),
                      subtitle: Text(_size(row['size'])),
                      onTap: () => _openFile(row),
                    ),
              ],
            ),
    );
  }
}
