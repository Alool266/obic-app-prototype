// Made by Dr Ali
// SuperAdmin staff desk — avatars, known branches/titles, profile edit.

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/obic_bidi.dart';
import '../../core/obic_branches.dart';
import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import '../moments/moment_avatar.dart';
import 'admin_api.dart';

class AdminStaffScreen extends StatefulWidget {
  const AdminStaffScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<AdminStaffScreen> createState() => _AdminStaffScreenState();
}

class _AdminStaffScreenState extends State<AdminStaffScreen> {
  final _api = AdminApi();
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _error;
  String _branchFilter = 'all';
  String _query = '';

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
      final rows = await _api.listStaff(token);
      if (!mounted) return;
      setState(() {
        _rows = rows;
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

  List<Map<String, dynamic>> get _filtered {
    final q = _query.trim().toLowerCase();
    return _rows.where((u) {
      final branch = (u['branchLabel'] as String?) ?? '';
      if (_branchFilter != 'all' && branch != _branchFilter) return false;
      if (q.isEmpty) return true;
      final hay = [
        u['name'],
        u['email'],
        u['phone'],
        u['staffTitle'],
        u['branchLabel'],
        u['role'],
      ].whereType<String>().join(' ').toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  Future<void> _setRole(String id, String role) async {
    try {
      final token = await widget.authController.ensureAccessToken();
      if (token == null) return;
      await _api.updateStaffRole(accessToken: token, userId: id, role: role);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _openEdit(Map<String, dynamic> u) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ObicColors.surfaceOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => _StaffEditSheet(
        user: u,
        authController: widget.authController,
        api: _api,
      ),
    );
    if (changed == true) await _load();
  }

  Future<void> _showAddStaff() async {
    final ar = Directionality.of(context) == TextDirection.rtl;
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String title = '';
    String branch = '';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(ar ? 'إضافة موظف' : 'Add staff'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ar
                      ? 'المشرف الأعلى ينشئ الحساب. الجوال والبريد الحقيقيان لاحقاً في الإنتاج.'
                      : 'SuperAdmin creates the account. Real mobiles/emails come later in production.',
                  style: TextStyle(
                    fontSize: 12,
                    color: ObicColors.mutedOf(context),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: ar ? 'الاسم' : 'Name'),
                ),
                TextField(
                  controller: emailCtrl,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.left,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: ar
                        ? 'البريد (اختياري الآن)'
                        : 'Email (optional now)',
                  ),
                ),
                TextField(
                  controller: phoneCtrl,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.left,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: ar
                        ? 'الجوال (اختياري الآن)'
                        : 'Mobile (optional now)',
                  ),
                ),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.left,
                  decoration: InputDecoration(
                    labelText: ar ? 'كلمة مرور مؤقتة' : 'Temporary password',
                  ),
                ),
                DropdownButtonFormField<String>(
                  value: title.isEmpty ? null : title,
                  decoration: InputDecoration(
                    labelText: ar ? 'المسمى' : 'Desk title',
                  ),
                  items: [
                    for (final t in kObicDeskTitles)
                      DropdownMenuItem(value: t, child: Text(t)),
                  ],
                  onChanged: (v) => setLocal(() => title = v ?? ''),
                ),
                DropdownButtonFormField<String>(
                  value: branch.isEmpty ? null : branch,
                  decoration: InputDecoration(
                    labelText: ar ? 'الفرع' : 'Branch',
                  ),
                  items: [
                    for (final b in kObicBranches)
                      DropdownMenuItem(value: b, child: Text(b)),
                  ],
                  onChanged: (v) => setLocal(() => branch = v ?? ''),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ar ? 'إلغاء' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(ar ? 'إنشاء' : 'Create'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      final token = await widget.authController.ensureAccessToken();
      if (token == null) return;
      await _api.createStaff(
        accessToken: token,
        name: nameCtrl.text.trim(),
        password: passCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
        staffTitle: title,
        branchLabel: branch,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final ar = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      appBar: AppBar(
        title: Text(ar ? 'مكتب الموظفين' : 'Staff desk'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStaff,
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(ar ? 'إضافة موظف' : 'Add staff'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        ar
                            ? 'إضافة موظف من Admin مسموحة · الجوالات والبريد الحقيقيان لاحقاً في الإنتاج.'
                            : 'Add staff from Admin is allowed · real mobiles/emails later in production.',
                        style: TextStyle(
                          fontSize: 12,
                          color: ObicColors.mutedOf(context),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _branchFilter,
                              decoration: InputDecoration(
                                labelText: 'Branch',
                                isDense: true,
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: ObicColors.surfaceOf(context),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: 'all',
                                  child: Text('All branches'),
                                ),
                                ...obicBranches.map(
                                  (b) => DropdownMenuItem(
                                    value: b,
                                    child: Text(b),
                                  ),
                                ),
                                const DropdownMenuItem(
                                  value: 'All branches',
                                  child: Text('All branches (label)'),
                                ),
                                const DropdownMenuItem(
                                  value: 'HQ (temp)',
                                  child: Text('HQ (temp)'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v == null) return;
                                setState(() => _branchFilter = v);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${filtered.length}/${_rows.length}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: ObicColors.mutedOf(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search name, email, title…',
                          prefixIcon: Icon(Icons.search),
                          isDense: true,
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: ObicColors.surfaceOf(context),
                        ),
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('No matching staff'))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final u = filtered[i];
                            final name = (u['name'] as String?) ?? '—';
                            final title = (u['staffTitle'] as String?) ?? '';
                            final branch = (u['branchLabel'] as String?) ?? '';
                            final role = (u['role'] as String?) ?? '';
                            final email = (u['email'] as String?) ?? '';
                            final isSuper = role == 'SuperAdmin';
                            final opsOn = isSuper || u['opsAccess'] == true;
                            final offersOn =
                                isSuper || u['offersAccess'] == true;
                            return Material(
                              color: ObicColors.card,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => _openEdit(u),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      MomentAvatar(
                                        name: name,
                                        avatarUrl: u['avatarUrl'] as String?,
                                        size: 48,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15,
                                                color: ObicColors.titleOf(
                                                  context,
                                                ),
                                              ),
                                            ),
                                            if (title.isNotEmpty)
                                              Text(
                                                title,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: ObicColors.inkOf(
                                                    context,
                                                  ),
                                                ),
                                              ),
                                            const SizedBox(height: 4),
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 4,
                                              children: [
                                                if (branch.isNotEmpty)
                                                  _Pill(
                                                    label: branch,
                                                    soft: true,
                                                  ),
                                                _Pill(
                                                  label: isSuper
                                                      ? 'Super Admin'
                                                      : 'Employee',
                                                  soft: false,
                                                  warn: isSuper,
                                                ),
                                                if (opsOn)
                                                  const _Pill(
                                                    label: 'Ops',
                                                    soft: true,
                                                  ),
                                                if (offersOn)
                                                  const _Pill(
                                                    label: 'Offers',
                                                    soft: true,
                                                  ),
                                              ],
                                            ),
                                            if (email.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 4,
                                                ),
                                                child: ObicIdentifierText(
                                                  email,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: ObicColors.mutedOf(
                                                      context,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        tooltip: 'Role',
                                        onSelected: (r) =>
                                            _setRole(u['id'] as String, r),
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(
                                            value: 'Employee',
                                            child: Text('Set Employee'),
                                          ),
                                          PopupMenuItem(
                                            value: 'SuperAdmin',
                                            child: Text('Set SuperAdmin'),
                                          ),
                                          PopupMenuItem(
                                            value: 'Customer',
                                            child: Text('Set Customer'),
                                          ),
                                        ],
                                        icon: Icon(
                                          Icons.more_vert,
                                          color: ObicColors.mutedOf(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.soft, this.warn = false});

  final String label;
  final bool soft;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final bg = warn
        ? const Color(0xFFFFF7ED)
        : soft
        ? ObicColors.blueSoft
        : const Color(0xFFF1F5F9);
    final fg = warn
        ? const Color(0xFFC2410C)
        : soft
        ? ObicColors.navy
        : const Color(0xFF334155);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

class _StaffEditSheet extends StatefulWidget {
  const _StaffEditSheet({
    required this.user,
    required this.authController,
    required this.api,
  });

  final Map<String, dynamic> user;
  final AuthController authController;
  final AdminApi api;

  @override
  State<_StaffEditSheet> createState() => _StaffEditSheetState();
}

class _StaffEditSheetState extends State<_StaffEditSheet> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _password;
  late String _title;
  late String _branch;
  late String? _avatarUrl;
  late bool _opsAccess;
  late bool _offersAccess;
  bool _saving = false;
  bool _uploading = false;
  String? _error;

  bool get _isEmployee => (widget.user['role'] as String?) == 'Employee';
  bool get _isSuperAdmin => (widget.user['role'] as String?) == 'SuperAdmin';

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _name = TextEditingController(text: (u['name'] as String?) ?? '');
    _phone = TextEditingController(text: (u['phone'] as String?) ?? '');
    _password = TextEditingController();
    _title = (u['staffTitle'] as String?) ?? '';
    _branch = (u['branchLabel'] as String?) ?? '';
    _avatarUrl = u['avatarUrl'] as String?;
    _opsAccess = u['opsAccess'] == true || _isSuperAdmin;
    _offersAccess = u['offersAccess'] == true || _isSuperAdmin;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  List<String> get _titleItems {
    final list = [...obicDeskTitles];
    if (_title.isNotEmpty && !list.contains(_title)) list.insert(0, _title);
    return list;
  }

  List<String> get _branchItems {
    final list = [...obicBranchOptions];
    if (_branch.isNotEmpty && !list.contains(_branch)) list.insert(0, _branch);
    return list;
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (file == null) return;
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final token = await widget.authController.ensureAccessToken();
      if (token == null) throw Exception('Not signed in');
      final url = await widget.api.uploadFile(
        accessToken: token,
        path: file.path,
        filename: file.name,
      );
      if (!mounted) return;
      setState(() => _avatarUrl = url);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final token = await widget.authController.ensureAccessToken();
      if (token == null) throw Exception('Not signed in');
      await widget.api.updateStaffProfile(
        accessToken: token,
        userId: widget.user['id'] as String,
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        staffTitle: _title.trim(),
        branchLabel: _branch.trim(),
        avatarUrl: _avatarUrl ?? '',
        opsAccess: _isEmployee ? _opsAccess : null,
        offersAccess: _isEmployee ? _offersAccess : null,
        newPassword: _password.text.trim().length >= 8
            ? _password.text.trim()
            : null,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ObicColors.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    MomentAvatar(
                      name: _name.text.isNotEmpty
                          ? _name.text
                          : ((widget.user['name'] as String?) ?? '?'),
                      avatarUrl: _avatarUrl,
                      size: 64,
                    ),
                    Material(
                      color: ObicColors.blue,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _uploading ? null : _pickPhoto,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: _uploading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt,
                                  size: 14,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit staff profile',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: ObicColors.titleOf(context),
                        ),
                      ),
                      Text(
                        (widget.user['email'] as String?) ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: ObicColors.mutedOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phone,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.left,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _title,
              decoration: const InputDecoration(
                labelText: 'Desk title',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: '', child: Text('—')),
                ..._titleItems.map(
                  (t) => DropdownMenuItem(value: t, child: Text(t)),
                ),
              ],
              onChanged: (v) => setState(() => _title = v ?? ''),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _branch,
              decoration: const InputDecoration(
                labelText: 'Branch',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: '', child: Text('—')),
                ..._branchItems.map(
                  (b) => DropdownMenuItem(value: b, child: Text(b)),
                ),
              ],
              onChanged: (v) => setState(() => _branch = v ?? ''),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _password,
              obscureText: true,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.left,
              decoration: const InputDecoration(
                labelText: 'New password (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            if (_isEmployee) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Allow Internal Ops',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: ObicColors.titleOf(context),
                  ),
                ),
                subtitle: Text(
                  'Employee can open Internal Ops from Me',
                  style: TextStyle(
                    fontSize: 12,
                    color: ObicColors.mutedOf(context),
                  ),
                ),
                value: _opsAccess,
                activeThumbColor: ObicColors.blue,
                onChanged: (v) => setState(() => _opsAccess = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Allow Hotel & Flight offers',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: ObicColors.titleOf(context),
                  ),
                ),
                subtitle: Text(
                  'Employee can list, create, edit, publish offers',
                  style: TextStyle(
                    fontSize: 12,
                    color: ObicColors.mutedOf(context),
                  ),
                ),
                value: _offersAccess,
                activeThumbColor: ObicColors.blue,
                onChanged: (v) => setState(() => _offersAccess = v),
              ),
            ] else if (_isSuperAdmin) ...[
              const SizedBox(height: 10),
              Text(
                'SuperAdmin always has Internal Ops and Hotel & Flight offers access.',
                style: TextStyle(
                  fontSize: 12,
                  color: ObicColors.mutedOf(context),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: ObicColors.blue,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(_saving ? 'Saving…' : 'Save'),
            ),
            TextButton(
              onPressed: _saving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
