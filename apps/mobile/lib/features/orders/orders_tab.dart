// Made by Dr Ali
// Orders / My Requests — service orders + support/team-talk threads.
// List is auth-gated on API; guests see sign-in CTA.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import '../auth/require_auth.dart';
import '../messages/chat_screen.dart';
import '../me/support_chat.dart';
import '../services/services_api.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key, required this.authController});

  final AuthController authController;

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  final _api = ServicesApi();
  Future<List<Map<String, dynamic>>>? _future;

  @override
  void initState() {
    super.initState();
    widget.authController.addListener(_onAuth);
    _reload();
  }

  @override
  void dispose() {
    widget.authController.removeListener(_onAuth);
    super.dispose();
  }

  void _onAuth() {
    _reload();
    setState(() {});
  }

  void _reload() {
    if (!widget.authController.isAuthenticated) {
      _future = null;
      return;
    }
    _future = () async {
      final token = await widget.authController.accessToken();
      if (token == null) return <Map<String, dynamic>>[];
      return _api.listMyOrders(token);
    }();
  }

  bool _isSupport(Map<String, dynamic> row) {
    final type = row['type']?.toString();
    if (type == 'support') return true;
    return row['serviceSlug']?.toString() == 'support' &&
        row['conversationId'] != null &&
        row['serviceId'] == null;
  }

  String _statusLabel(AppLocalizations l10n, String? status) {
    switch (status) {
      case 'Assigned':
        return l10n.statusAssigned;
      case 'InProgress':
        return l10n.statusInProgress;
      case 'WaitingCustomer':
        return l10n.statusWaitingCustomer;
      case 'Completed':
        return l10n.statusCompleted;
      case 'Cancelled':
        return l10n.statusCancelled;
      case 'Open':
        return l10n.statusOpen;
      case 'WithAgent':
        return l10n.statusWithAgent;
      case 'Closed':
        return l10n.statusCompleted;
      default:
        return l10n.statusSubmitted;
    }
  }

  String _rowTitle(AppLocalizations l10n, Map<String, dynamic> row) {
    if (_isSupport(row)) {
      final title = row['title']?.toString().trim();
      if (title != null && title.isNotEmpty) return title;
      return l10n.requestTypeSupport;
    }
    final subEn = row['subServiceNameEn']?.toString().trim();
    final subAr = row['subServiceNameAr']?.toString().trim();
    final lang = Localizations.localeOf(context).languageCode;
    if (lang == 'ar' && subAr != null && subAr.isNotEmpty) return subAr;
    if (subEn != null && subEn.isNotEmpty) return subEn;
    final slug = row['serviceSlug']?.toString() ?? '';
    return slug.isEmpty ? l10n.serviceLabel : slug;
  }

  String _rowSubtitle(Map<String, dynamic> row) {
    if (_isSupport(row)) {
      final branch = row['preferredBranch']?.toString().trim();
      final desk = row['subServiceId']?.toString().trim();
      if (branch != null &&
          branch.isNotEmpty &&
          desk != null &&
          desk.isNotEmpty) {
        return '$branch · $desk';
      }
      if (branch != null && branch.isNotEmpty) return branch;
      final id = row['id']?.toString() ?? '';
      return id.length >= 8 ? id.substring(0, 8) : id;
    }
    final id = row['id']?.toString() ?? '';
    return id.length >= 8 ? id.substring(0, 8) : id;
  }

  Future<void> _openRow(Map<String, dynamic> row) async {
    if (_isSupport(row)) {
      final threadId = row['conversationId']?.toString() ??
          row['id']?.toString();
      if (threadId == null || !mounted) return;
      final title = _rowTitle(AppLocalizations.of(context), row);
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ChatScreen(
            authController: widget.authController,
            threadId: threadId,
            title: title,
            initialKind: 'support',
          ),
        ),
      );
      return;
    }
    await _openOrderChat(row);
  }

  Future<void> _openOrderChat(Map<String, dynamic> order) async {
    final token = await widget.authController.accessToken();
    final orderId = order['id']?.toString();
    if (token == null || orderId == null) return;
    final existing = order['conversationId']?.toString();
    try {
      String? threadId = existing;
      String title = orderId.length >= 8 ? orderId.substring(0, 8) : orderId;
      if (threadId == null || threadId.isEmpty) {
        final chat = await _api.openOrderChat(
          accessToken: token,
          orderId: orderId,
        );
        threadId = chat['conversationId']?.toString();
        title = chat['title']?.toString() ?? title;
      }
      if (threadId == null || !mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ChatScreen(
            authController: widget.authController,
            threadId: threadId!,
            title: title,
            initialKind: 'order',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _createSupportRequest() async {
    await openSupportChat(context, widget.authController);
    if (!mounted) return;
    _reload();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = widget.authController;

    if (!auth.isAuthenticated) {
      return _EmptyCard(
        title: l10n.ordersTitle,
        body: l10n.ordersEmptyGuest,
        action: l10n.authLogin,
        onAction: () async {
          await requireAuth(context, auth);
        },
      );
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = snap.data ?? [];
        if (orders.isEmpty) {
          return _EmptyCard(
            title: l10n.ordersTitle,
            body: l10n.ordersEmptyAuth,
            action: l10n.settingsContactSupport,
            onAction: () {
              _createSupportRequest();
            },
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            _reload();
            setState(() {});
            await _future;
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final o = orders[i];
              final status = o['status']?.toString();
              final support = _isSupport(o);
              return Material(
                color: ObicColors.surfaceOf(context),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => _openRow(o),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color:
                            ObicColors.lineOf(context).withValues(alpha: 0.8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: ObicColors.blueSoftOf(context),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            support
                                ? Icons.support_agent_rounded
                                : Icons.receipt_long_rounded,
                            color: ObicColors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _rowTitle(l10n, o),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: ObicColors.titleOf(context),
                                ),
                              ),
                              Text(
                                _rowSubtitle(o),
                                style: TextStyle(
                                  color: ObicColors.mutedOf(context),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: ObicColors.blueSoftOf(context),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _statusLabel(l10n, status),
                            style: const TextStyle(
                              color: ObicColors.blue,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.title,
    required this.body,
    required this.action,
    required this.onAction,
  });

  final String title;
  final String body;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ObicColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: ObicColors.lineOf(context).withValues(alpha: 0.65),
            ),
            boxShadow: [
              BoxShadow(
                color: ObicColors.navy.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: ObicColors.blueSoftOf(context),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: ObicColors.blue,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: ObicColors.titleOf(context),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                body,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ObicColors.mutedOf(context),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: ObicColors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(action),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
