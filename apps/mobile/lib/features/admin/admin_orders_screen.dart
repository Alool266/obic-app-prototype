// Made by Dr Ali
// Admin orders — Employee sees assigned only; SuperAdmin sees all + assign.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../shell/demo_walkthrough.dart';
import '../../core/api_errors.dart';
import '../../core/obic_org.dart';
import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import '../messages/chat_screen.dart';
import 'admin_api.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({
    super.key,
    required this.authController,
    required this.isSuperAdmin,
    this.canReassignOrders = false,
  });

  final AuthController authController;
  final bool isSuperAdmin;
  final bool canReassignOrders;

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final _api = AdminApi();
  List<Map<String, dynamic>> _rows = [];
  List<Map<String, dynamic>> _staff = [];
  bool _loading = true;
  String? _error;

  bool get _ar => Directionality.of(context) == TextDirection.rtl;

  bool _canUpdateStatus(Map<String, dynamic> o) {
    final u = widget.authController.user;
    if (u == null) return widget.isSuperAdmin;
    return canUpdateOrderStatus(
      role: u.role,
      staffTitle: u.staffTitle,
      branchLabel: u.branchLabel,
      email: u.email,
      preferredBranch: o['preferredBranch'] as String?,
      // List is already scoped to assignee / SuperAdmin.
      assignedToSelf: true,
    );
  }

  String _statusLabel(String status) {
    if (_ar) {
      switch (status) {
        case 'Submitted':
          return 'مُقدَّم';
        case 'Assigned':
          return 'مُعيَّن';
        case 'InProgress':
          return 'قيد التنفيذ';
        case 'WaitingCustomer':
          return 'بانتظار العميل';
        case 'Completed':
          return 'مكتمل';
        case 'Cancelled':
          return 'ملغى';
        default:
          return status;
      }
    }
    return status;
  }

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
      final orders = await _api.listOrders(token);
      List<Map<String, dynamic>> staff = [];
      if (widget.isSuperAdmin || widget.canReassignOrders) {
        staff = await _api.listStaff(token);
        staff = staff.where((s) => s['role'] == 'Employee').toList();
      }
      if (!mounted) return;
      setState(() {
        _rows = orders;
        _staff = staff;
        _loading = false;
      });
      if (kDemoShot == 'admin_orders_crm' && orders.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showDetails(orders.first);
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _setStatus(String id, String status) async {
    Map<String, dynamic>? row;
    for (final o in _rows) {
      if (o['id']?.toString() == id) {
        row = o;
        break;
      }
    }
    if (row != null && !_canUpdateStatus(row)) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorOnlySecretaryCanUpdateStatus)),
      );
      return;
    }
    try {
      final token = await widget.authController.ensureAccessToken();
      if (token == null) return;
      await _api.updateOrder(accessToken: token, orderId: id, status: status);
      await _load();
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final lang = Localizations.localeOf(context).languageCode;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyApiError(e, l10n: l10n, langCode: lang)),
        ),
      );
    }
  }

  Future<void> _openChat(String orderId) async {
    try {
      final token = await widget.authController.ensureAccessToken();
      if (token == null) return;
      final chat = await _api.openOrderChat(
        accessToken: token,
        orderId: orderId,
      );
      final threadId = chat['conversationId']?.toString();
      if (threadId == null || !mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ChatScreen(
            authController: widget.authController,
            threadId: threadId,
            title: chat['title']?.toString() ?? orderId.substring(0, 8),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _assign(String orderId) async {
    if ((!widget.isSuperAdmin && !widget.canReassignOrders) || _staff.isEmpty) {
      return;
    }
    final pick = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(_ar ? 'تعيين موظف' : 'Assign employee'),
        children: [
          for (final s in _staff)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, s['id'] as String),
              child: Text('${s['name']} (${s['email'] ?? ''})'),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, ''),
            child: Text(_ar ? 'إلغاء التعيين' : 'Clear assignment'),
          ),
        ],
      ),
    );
    if (pick == null) return;
    try {
      final token = await widget.authController.ensureAccessToken();
      if (token == null) return;
      await _api.updateOrder(
        accessToken: token,
        orderId: orderId,
        assignedEmployeeId: pick.isEmpty ? null : pick,
        clearAssignee: pick.isEmpty,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  String _serviceTitle(Map<String, dynamic> o) {
    if (_ar) {
      return (o['subServiceNameAr'] as String?) ??
          (o['serviceTitleAr'] as String?) ??
          (o['subServiceNameEn'] as String?) ??
          (o['serviceTitleEn'] as String?) ??
          (o['serviceSlug'] as String?) ??
          '—';
    }
    return (o['subServiceNameEn'] as String?) ??
        (o['serviceTitleEn'] as String?) ??
        (o['serviceSlug'] as String?) ??
        '—';
  }

  void _showDetails(Map<String, dynamic> o) {
    final form = o['formData'];
    final formLines = <String>[];
    if (form is Map) {
      for (final entry in form.entries) {
        formLines.add('${entry.key}: ${entry.value}');
      }
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ObicColors.surfaceOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        minChildSize: 0.45,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
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
            Text(
              _serviceTitle(o),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: ObicColors.titleOf(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_ar ? 'العميل' : 'Customer'}: ${o['customerName'] ?? '—'}\n'
              '${_ar ? 'الهاتف' : 'Phone'}: ${o['customerPhone'] ?? '—'}\n'
              '${_ar ? 'البريد' : 'Email'}: ${o['customerEmail'] ?? '—'}\n'
              '${_ar ? 'الفرع' : 'Branch'}: ${o['preferredBranch'] ?? '—'}\n'
              '${_ar ? 'الحالة' : 'Status'}: ${_statusLabel('${o['status']}')}\n'
              '${_ar ? 'المسؤول' : 'Assignee'}: ${o['assignedEmployeeName'] ?? (_ar ? 'لا أحد' : 'none')}'
              '${o['assignedEmployeeTitle'] != null ? ' (${o['assignedEmployeeTitle']})' : ''}',
              style: TextStyle(
                color: ObicColors.mutedOf(context),
                height: 1.45,
              ),
            ),
            if (formLines.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                _ar ? 'إجابات النموذج' : 'Form answers',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: ObicColors.titleOf(context),
                ),
              ),
              const SizedBox(height: 8),
              ...formLines.map(
                (line) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ObicColors.blueSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(line),
                ),
              ),
            ],
            if ((o['notes'] as String?)?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text(
                _ar ? 'ملاحظات' : 'Notes',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: ObicColors.titleOf(context),
                ),
              ),
              const SizedBox(height: 6),
              Text('${o['notes']}'),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _openChat('${o['id']}');
              },
              icon: const Icon(Icons.chat_rounded),
              label: Text(_ar ? 'محادثة الطلب' : 'Order chat'),
            ),
            const SizedBox(height: 10),
            if (_canUpdateStatus(o) &&
                ('${o['status']}' == 'Submitted' ||
                    '${o['status']}' == 'Assigned'))
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _setStatus('${o['id']}', 'InProgress');
                },
                child: Text(_ar ? 'بدء المعالجة' : 'Start work'),
              ),
            if (_canUpdateStatus(o) && '${o['status']}' == 'InProgress') ...[
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _setStatus('${o['id']}', 'WaitingCustomer');
                },
                child: Text(_ar ? 'بانتظار العميل' : 'Waiting for customer'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _setStatus('${o['id']}', 'Completed');
                },
                child: Text(_ar ? 'إتمام' : 'Mark completed'),
              ),
            ],
            if (_canUpdateStatus(o) && '${o['status']}' == 'WaitingCustomer')
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _setStatus('${o['id']}', 'InProgress');
                },
                child: Text(_ar ? 'استئناف العمل' : 'Resume work'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      appBar: AppBar(title: Text(_ar ? 'قائمة الطلبات' : 'Orders queue')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _rows.length + 1,
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                      child: Text(
                        _ar
                            ? 'النماذج تُوجَّه تلقائياً للموظف حسب الخدمة والفرع. المشرف يرى الكل.'
                            : 'Forms route to the branch desk by service. Super Admin sees all.',
                        style: TextStyle(
                          color: ObicColors.mutedOf(context),
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    );
                  }
                  final o = _rows[i - 1];
                  return Card(
                    elevation: 0,
                    color: ObicColors.card,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      onTap: () => _showDetails(o),
                      title: Text(_serviceTitle(o)),
                      subtitle: Text(
                        '${o['customerName'] ?? '—'} · ${_statusLabel('${o['status']}')}\n'
                        '${_ar ? 'المسؤول' : 'Assigned'}: ${o['assignedEmployeeName'] ?? (_ar ? 'لا أحد' : 'none')}',
                      ),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'assign') {
                            _assign(o['id'] as String);
                          } else if (v == 'view') {
                            _showDetails(o);
                          } else {
                            _setStatus(o['id'] as String, v);
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'view',
                            child: Text(_ar ? 'عرض النموذج' : 'View form'),
                          ),
                          if (_canUpdateStatus(o) &&
                              '${o['status']}' == 'Submitted')
                            PopupMenuItem(
                              value: 'InProgress',
                              child: Text(_ar ? 'بدء المعالجة' : 'Start work'),
                            ),
                          if (_canUpdateStatus(o) &&
                              '${o['status']}' == 'InProgress')
                            PopupMenuItem(
                              value: 'Completed',
                              child: Text(_ar ? 'إتمام' : 'Complete'),
                            ),
                          if (_canUpdateStatus(o))
                            PopupMenuItem(
                              value: 'Cancelled',
                              child: Text(_ar ? 'إلغاء' : 'Cancel'),
                            ),
                          if (widget.isSuperAdmin || widget.canReassignOrders)
                            PopupMenuItem(
                              value: 'assign',
                              child: Text(_ar ? 'تعيين موظف' : 'Assign'),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
