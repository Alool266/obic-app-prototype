// Made by Dr Ali
// Restore soft-deleted accounts — SuperAdmin / Ops staff via Admin API.

import 'package:flutter/material.dart';

import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import 'admin_api.dart';

class AdminAccountsScreen extends StatefulWidget {
  const AdminAccountsScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<AdminAccountsScreen> createState() => _AdminAccountsScreenState();
}

class _AdminAccountsScreenState extends State<AdminAccountsScreen> {
  final _api = AdminApi();
  final _q = TextEditingController();
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _error;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await widget.authController.ensureAccessToken();
      if (token == null) throw Exception('Not signed in');
      final rows = await _api.listDeactivatedUsers(
        accessToken: token,
        q: _q.text.trim().isEmpty ? null : _q.text.trim(),
      );
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

  Future<void> _restore(String id) async {
    final ar = Directionality.of(context) == TextDirection.rtl;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ar ? 'استعادة الحساب؟' : 'Restore account?'),
        content: Text(
          ar
              ? 'سيتمكن المستخدم من تسجيل الدخول بنفس كلمة المرور.'
              : 'The user will be able to sign in with the same password.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ar ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ar ? 'استعادة' : 'Restore'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busyId = id);
    try {
      final token = await widget.authController.ensureAccessToken();
      if (token == null) return;
      await _api.restoreUser(accessToken: token, userId: id);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ar ? 'تمت الاستعادة' : 'Account restored')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      appBar: AppBar(
        title: Text(ar ? 'حسابات موقوفة' : 'Deactivated accounts'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _q,
                    decoration: InputDecoration(
                      hintText: ar
                          ? 'بريد / هاتف / اسم / OBIC ID'
                          : 'Email / phone / name / OBIC ID',
                      filled: true,
                      fillColor: ObicColors.surfaceOf(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _load(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _load,
                  child: Text(ar ? 'بحث' : 'Search'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              ar
                  ? 'المشرف الأعلى أو موظف Ops — بعد الاستعادة يسجّل الدخول بنفس كلمة المرور.'
                  : 'SuperAdmin or Ops staff — after restore, user signs in with the same password.',
              style: TextStyle(
                fontSize: 12,
                color: ObicColors.mutedOf(context),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _rows.isEmpty
                ? Center(
                    child: Text(
                      ar ? 'لا حسابات موقوفة' : 'No deactivated accounts',
                      style: TextStyle(color: ObicColors.mutedOf(context)),
                    ),
                  )
                : ListView.separated(
                    itemCount: _rows.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final u = _rows[i];
                      final id = u['id'] as String? ?? '';
                      final name = (u['name'] as String?) ?? '—';
                      final email = u['email'] as String?;
                      final phone = u['phone'] as String?;
                      final role = u['role'] as String? ?? '';
                      final deletedAt = u['deletedAt']?.toString() ?? '';
                      final sub = [
                        if (email != null && email.isNotEmpty) email,
                        if (phone != null && phone.isNotEmpty) phone,
                        if (role.isNotEmpty) role,
                      ].join(' · ');
                      return ListTile(
                        title: Text(name),
                        subtitle: Text(
                          [
                            if (sub.isNotEmpty) sub,
                            if (deletedAt.isNotEmpty) deletedAt,
                          ].join('\n'),
                        ),
                        isThreeLine: deletedAt.isNotEmpty,
                        trailing: TextButton(
                          onPressed: _busyId == id ? null : () => _restore(id),
                          child: _busyId == id
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(ar ? 'استعادة' : 'Restore'),
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
