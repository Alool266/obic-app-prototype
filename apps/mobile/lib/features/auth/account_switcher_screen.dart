// Made by Dr Ali
// WeChat-style account switcher — vault list + Add account (never naked logout).

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../core/obic_bidi.dart';
import '../../theme/obic_colors.dart';
import '../moments/moment_avatar.dart';
import 'account_vault.dart';
import 'auth_controller.dart';
import 'require_auth.dart';

class AccountSwitcherScreen extends StatefulWidget {
  const AccountSwitcherScreen({super.key, required this.auth});

  final AuthController auth;

  @override
  State<AccountSwitcherScreen> createState() => _AccountSwitcherScreenState();
}

class _AccountSwitcherScreenState extends State<AccountSwitcherScreen> {
  List<SavedAccount> _accounts = const [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final rows = await widget.auth.listSavedAccounts();
    if (!mounted) return;
    setState(() {
      _accounts = rows;
      _loading = false;
    });
  }

  Future<void> _switchTo(SavedAccount account) async {
    if (_busy) return;
    final currentId = widget.auth.user?.id;
    if (currentId != null && currentId == account.userId) {
      Navigator.pop(context);
      return;
    }
    setState(() => _busy = true);
    final ok = await widget.auth.switchToAccount(account.userId);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      Navigator.pop(context);
    } else {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.authFailed)));
      await _reload();
    }
  }

  Future<void> _addAccount() async {
    if (_busy) return;
    setState(() => _busy = true);
    // Sync current into vault only — do not clear session (WeChat).
    await widget.auth.prepareAddAccount();
    if (!mounted) return;
    setState(() => _busy = false);
    await openLoginScreen(context, widget.auth, forAddAccount: true);
    // Safety: if an old client path cleared session, restore first vaulted account.
    if (!widget.auth.isAuthenticated) {
      await widget.auth.restoreAfterCancelledAddAccount();
    }
    if (!mounted) return;
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentId = widget.auth.user?.id;

    return Scaffold(
      backgroundColor: ObicColors.canvasOf(context),
      appBar: AppBar(
        backgroundColor: ObicColors.canvasOf(context),
        elevation: 0,
        foregroundColor: ObicColors.inkOf(context),
        surfaceTintColor: Colors.transparent,
        title: Text(
          l10n.switchAccountTitle,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: ObicColors.inkOf(context),
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 36,
            color: ObicColors.mutedOf(context).withValues(alpha: 0.55),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.switchAccountHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: ObicColors.inkOf(context),
            ),
          ),
          const SizedBox(height: 28),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            for (final account in _accounts) ...[
              _AccountCard(
                account: account,
                isCurrent: currentId != null && currentId == account.userId,
                onTap: _busy ? null : () => _switchTo(account),
              ),
              const SizedBox(height: 12),
            ],
            _AddAccountCard(
              label: l10n.switchAccountAdd,
              onTap: _busy ? null : _addAccount,
            ),
          ],
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.account,
    required this.onTap,
    this.isCurrent = false,
  });

  final SavedAccount account;
  final VoidCallback? onTap;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final user = account.user;
    final name = user?.name ?? '—';
    final subtitle = user?.email ?? user?.phone ?? account.userId;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              MomentAvatar(
                name: name,
                avatarUrl: user?.avatarUrl,
                size: 52,
                borderRadius: 8,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: ObicColors.inkOf(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ObicIdentifierText(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: ObicColors.mutedOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (isCurrent)
                const Icon(
                  Icons.check_rounded,
                  color: ObicColors.blue,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddAccountCard extends StatelessWidget {
  const _AddAccountCard({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ObicColors.mutedOf(context).withValues(alpha: 0.45),
                    style: BorderStyle.solid,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.add,
                  color: ObicColors.mutedOf(context).withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: ObicColors.inkOf(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
