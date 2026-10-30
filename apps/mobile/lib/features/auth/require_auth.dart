// Made by Dr Ali
// Guest may browse; any action that creates data must pass requireAuth first.
// Login and Register are separate screens/routes (WeChat-style — never one tabbed page).

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../theme/obic_colors.dart';
import '../../theme/obic_elevation.dart';
import 'auth_controller.dart';
import 'login_screen.dart';
import 'register_screen.dart';

/// Returns true when the user is (or becomes) authenticated.
/// Guests see a login sheet; dismiss without signing in → false.
Future<bool> requireAuth(
  BuildContext context,
  AuthController auth, {
  String? message,
}) async {
  if (auth.isAuthenticated) return true;
  final ok = await showAuthPrompt(context, auth, message: message);
  return ok && auth.isAuthenticated;
}

Widget _authScaffold({
  required BuildContext routeContext,
  required Widget body,
}) {
  return Scaffold(
    backgroundColor: ObicColors.navy,
    extendBodyBehindAppBar: true,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: Colors.white,
      title: const SizedBox.shrink(),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.pop(routeContext),
      ),
    ),
    body: SafeArea(top: false, child: body),
  );
}

/// Full-screen Login route. Pops after success.
///
/// [forAddAccount] true when opened from the account switcher "Add account"
/// row — back must not sign out the current session (session is never cleared).
Future<void> openLoginScreen(
  BuildContext context,
  AuthController auth, {
  bool forAddAccount = false,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (routeContext) {
        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, _) async {
            if (!didPop) return;
            // Belt-and-suspenders for any path that cleared session.
            if (forAddAccount && !auth.isAuthenticated) {
              await auth.restoreAfterCancelledAddAccount();
            }
          },
          child: _authScaffold(
            routeContext: routeContext,
            body: LoginScreen(
              auth: auth,
              onSuccess: () => Navigator.pop(routeContext),
              onGoRegister: () async {
                await openRegisterScreen(
                  routeContext,
                  auth,
                  fromLogin: true,
                  forAddAccount: forAddAccount,
                );
                if (auth.isAuthenticated && routeContext.mounted) {
                  Navigator.pop(routeContext);
                }
              },
            ),
          ),
        );
      },
    ),
  );
}

/// Full-screen Register route. Pops after success.
///
/// [fromLogin] true when pushed from Login — "Sign in" pops back.
/// Otherwise "Sign in" replaces this route with Login.
Future<void> openRegisterScreen(
  BuildContext context,
  AuthController auth, {
  bool fromLogin = false,
  bool forAddAccount = false,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (routeContext) {
        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, _) async {
            if (!didPop) return;
            if (forAddAccount && !auth.isAuthenticated) {
              await auth.restoreAfterCancelledAddAccount();
            }
          },
          child: _authScaffold(
            routeContext: routeContext,
            body: RegisterScreen(
              auth: auth,
              onSuccess: () => Navigator.pop(routeContext),
              onGoLogin: () {
                if (fromLogin) {
                  Navigator.pop(routeContext);
                } else {
                  Navigator.pushReplacement(
                    routeContext,
                    MaterialPageRoute(
                      builder: (loginCtx) => PopScope(
                        canPop: true,
                        onPopInvokedWithResult: (didPop, _) async {
                          if (!didPop) return;
                          if (forAddAccount && !auth.isAuthenticated) {
                            await auth.restoreAfterCancelledAddAccount();
                          }
                        },
                        child: _authScaffold(
                          routeContext: loginCtx,
                          body: LoginScreen(
                            auth: auth,
                            onSuccess: () => Navigator.pop(loginCtx),
                            onGoRegister: () async {
                              await openRegisterScreen(
                                loginCtx,
                                auth,
                                fromLogin: true,
                                forAddAccount: forAddAccount,
                              );
                              if (auth.isAuthenticated && loginCtx.mounted) {
                                Navigator.pop(loginCtx);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        );
      },
    ),
  );
}

/// Opens Login by default; [initialMode] 1 opens Register.
Future<void> openAuthScreen(
  BuildContext context,
  AuthController auth, {
  int initialMode = 0,
}) {
  if (initialMode == 1) {
    return openRegisterScreen(context, auth);
  }
  return openLoginScreen(context, auth);
}

/// Bottom sheet: starts on Login. Register is a separate page (bottom link).
Future<bool> showAuthPrompt(
  BuildContext context,
  AuthController auth, {
  String? message,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: ObicColors.surfaceOf(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(ObicElevation.radiusXl),
      ),
    ),
    builder: (sheetContext) {
      final l10n = AppLocalizations.of(sheetContext);
      final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.96,
          builder: (context, scrollController) {
            return _AuthSheetPager(
              auth: auth,
              scrollController: scrollController,
              message: message ?? l10n.authRequiredBody,
              title: l10n.authRequiredTitle,
              closeLabel: l10n.authClose,
              onClose: () => Navigator.pop(sheetContext, false),
              onSuccess: () => Navigator.pop(sheetContext, true),
            );
          },
        ),
      );
    },
  );
  return result == true;
}

/// Sheet host: Login and Register as distinct pages (no Sign-in|Register tabs).
class _AuthSheetPager extends StatefulWidget {
  const _AuthSheetPager({
    required this.auth,
    required this.scrollController,
    required this.message,
    required this.title,
    required this.closeLabel,
    required this.onClose,
    required this.onSuccess,
  });

  final AuthController auth;
  final ScrollController scrollController;
  final String message;
  final String title;
  final String closeLabel;
  final VoidCallback onClose;
  final VoidCallback onSuccess;

  @override
  State<_AuthSheetPager> createState() => _AuthSheetPagerState();
}

class _AuthSheetPagerState extends State<_AuthSheetPager> {
  /// false = Login page, true = Register page.
  bool _showRegister = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: ObicColors.lineOf(context),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                tooltip: widget.closeLabel,
                onPressed: widget.onClose,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
          child: Text(
            widget.message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _showRegister
                ? RegisterScreen(
                    key: const ValueKey('register'),
                    auth: widget.auth,
                    scrollController: widget.scrollController,
                    onSuccess: widget.onSuccess,
                    onGoLogin: () => setState(() => _showRegister = false),
                  )
                : LoginScreen(
                    key: const ValueKey('login'),
                    auth: widget.auth,
                    scrollController: widget.scrollController,
                    onSuccess: widget.onSuccess,
                    onGoRegister: () => setState(() => _showRegister = true),
                  ),
          ),
        ),
      ],
    );
  }
}
