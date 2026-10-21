// Made by Dr Ali
// Stakeholder demo: timed walkthrough when DEMO_WALKTHROUGH=true.
// Does not run in normal builds.

import 'package:flutter/material.dart';

import '../../l10n/locale_controller.dart';
import '../me/addresses_screen.dart';
import '../admin/admin_api.dart';
import '../admin/admin_home_screen.dart';
import '../admin/admin_offers_screen.dart';
import '../admin/admin_orders_screen.dart';
import '../admin/admin_services_screen.dart';
import '../admin/admin_sub_services_screen.dart';
import '../admin/admin_staff_screen.dart';
import '../auth/auth_controller.dart';
import '../auth/require_auth.dart';
import '../friends/add_friend_screen.dart';
import '../messages/chat_screen.dart';
import '../messages/create_group_screen.dart';
import '../offers/offers_api.dart';
import '../offers/offers_browse.dart';
import '../notifications/notifications_screen.dart';
import '../ops/ops_hub_screen.dart';
import '../orders/orders_tab.dart';
import '../services/service_catalog.dart';
import '../services/service_detail_page.dart';
import '../services/service_hub_page.dart';
import '../services/service_request_page.dart';
import '../services/service_sub_catalog.dart';
import '../services/services_api.dart';
import '../social/social_api.dart';

/// true when launched with --dart-define=DEMO_WALKTHROUGH=true
const bool kDemoWalkthrough =
    bool.fromEnvironment('DEMO_WALKTHROUGH', defaultValue: false);

/// Capture-only: open a tab/screen and hold
/// (DEMO_SHOT=home|services|detail|hotels|offers_search|offers_search_flights|
///  offer_detail|request|orders|moments|messages|me|admin|admin_staff|admin_offers|
///  service_hub|service_form|admin_orders|service_zh).
const String kDemoShot = String.fromEnvironment('DEMO_SHOT', defaultValue: '');

const String kDemoServiceSlug =
    String.fromEnvironment('DEMO_SERVICE_SLUG', defaultValue: 'property');

const String kDemoLoginEmail =
    String.fromEnvironment('DEMO_LOGIN_EMAIL', defaultValue: '');
const String kDemoLoginPassword =
    String.fromEnvironment('DEMO_LOGIN_PASSWORD', defaultValue: '');
/// Force language for captures: ar | en (empty = app default).
const String kDemoLang = String.fromEnvironment('DEMO_LANG', defaultValue: '');

/// Guest browse → Services → detail → auth sheet → Me → language toggle.
Future<void> runDemoWalkthrough({
  required BuildContext context,
  required void Function(int tabIndex) setTab,
  required AuthController authController,
  required LocaleController localeController,
  required CatalogRepository catalog,
  VoidCallback? onShowOpsHub,
}) async {
  if (kDemoShot.isNotEmpty) {
    await _runNamedShot(
      context: context,
      setTab: setTab,
      authController: authController,
      localeController: localeController,
      catalog: catalog,
      shot: kDemoShot,
      onShowOpsHub: onShowOpsHub,
    );
    return;
  }
  if (!kDemoWalkthrough) return;

  // ignore: avoid_print
  print('OBIC_DEMO: walkthrough_start');

  Future<void> pause(int ms) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  // Home (tiles + banner) — long hold for video + screenshot
  await pause(5000);
  if (!context.mounted) return;
  // ignore: avoid_print
  print('OBIC_DEMO: home_done');

  // Services tab
  setTab(1);
  await pause(4500);
  if (!context.mounted) return;
  // ignore: avoid_print
  print('OBIC_DEMO: services_done');

  final services = await catalog.load();
  if (!context.mounted) return;
  final service =
      services.isNotEmpty ? services.first : localCatalogSeed().first;

  // Service detail
  // ignore: use_build_context_synchronously
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => ServiceDetailPage(
        service: service,
        authController: authController,
        langCode: localeController.langCode,
      ),
    ),
  );
  await pause(4500);
  if (!context.mounted) return;
  // ignore: avoid_print
  print('OBIC_DEMO: detail_done');

  // Auth sheet (login required for Request)
  // ignore: use_build_context_synchronously
  final sheetFuture = showAuthPrompt(context, authController);
  await pause(5000);
  if (!context.mounted) return;
  // ignore: avoid_print
  print('OBIC_DEMO: auth_done');
  // Dismiss sheet via root navigator (sheet is presented above detail).
  Navigator.of(context, rootNavigator: true).pop(false);
  await sheetFuture;
  await pause(600);
  if (!context.mounted) return;

  // Close detail
  if (Navigator.of(context).canPop()) {
    Navigator.of(context).pop();
  }
  await pause(700);
  if (!context.mounted) return;

  // Me — login / register
  setTab(5);
  await pause(5000);
  if (!context.mounted) return;
  // ignore: avoid_print
  print('OBIC_DEMO: me_done');

  // Language → English briefly
  localeController.toggle();
  await pause(2500);
  if (!context.mounted) return;

  // Back to Arabic + Home
  localeController.toggle();
  await pause(500);
  if (!context.mounted) return;
  setTab(0);
  await pause(2000);
  // ignore: avoid_print
  print('OBIC_DEMO: walkthrough_end');
}

Future<void> _maybeDemoLogin(AuthController authController) async {
  if (kDemoLoginEmail.isEmpty || kDemoLoginPassword.isEmpty) return;
  // Always switch to the requested demo account — leftover simulator
  // sessions (e.g. Customer) caused admin shots to show 403 / wrong role.
  final current = authController.user?.email?.toLowerCase();
  final want = kDemoLoginEmail.toLowerCase();
  if (authController.isAuthenticated && current == want) return;
  if (authController.isAuthenticated) {
    await authController.logout();
  }
  await authController.login(
    email: kDemoLoginEmail,
    password: kDemoLoginPassword,
  );
}

Future<void> _runNamedShot({
  required BuildContext context,
  required void Function(int tabIndex) setTab,
  required AuthController authController,
  required LocaleController localeController,
  required CatalogRepository catalog,
  required String shot,
  VoidCallback? onShowOpsHub,
}) async {
  // ignore: avoid_print
  print('OBIC_DEMO: walkthrough_start');
  if (kDemoLang == 'ar' || kDemoLang == 'en' || kDemoLang == 'zh') {
    localeController.setLocale(Locale(kDemoLang));
  }
  await Future<void>.delayed(const Duration(milliseconds: 900));
  if (!context.mounted) return;

  if (shot == 'detail') {
    await _runDetailShot(
      context: context,
      setTab: setTab,
      authController: authController,
      localeController: localeController,
      catalog: catalog,
    );
    return;
  }

  if (shot == 'moments' ||
      shot == 'messages' ||
      shot == 'me' ||
      shot == 'home' ||
      shot == 'admin' ||
      shot == 'admin_staff' ||
      shot == 'admin_services' ||
      shot == 'admin_subs' ||
      shot == 'admin_orders' ||
      shot == 'service_hub' ||
      shot == 'service_hub_cars' ||
      shot == 'home_zh' ||
      shot == 'admin_offers' ||
      shot == 'food_hub' ||
      shot == 'addresses' ||
      shot == 'hotels' ||
      shot == 'offers_search' ||
      shot == 'offers_search_flights' ||
      shot == 'offer_detail' ||
      shot == 'ops' ||
      shot == 'chat' ||
      shot == 'chat_panel' ||
      shot == 'chat_menu' ||
      shot == 'group' ||
      shot == 'create_group' ||
      shot == 'add_friend' ||
      shot == 'add_friend_qr' ||
      shot == 'request' ||
      shot == 'request_branches' ||
      shot == 'service_hub' ||
      shot == 'service_form' ||
      shot == 'admin_orders' ||
      shot == 'admin_orders_crm' ||
      shot == 'order_chat' ||
      shot == 'orders_crm' ||
      shot == 'orders' ||
      shot == 'notifications') {
    await _maybeDemoLogin(authController);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!context.mounted) return;
  }

  if (shot == 'hotels' ||
      shot == 'offers_search' ||
      shot == 'offers_search_flights' ||
      shot == 'offer_detail') {
    try {
      final services = await catalog.load();
      if (!context.mounted) return;
      final parentSlug =
          shot == 'offers_search_flights' ? 'transport' : 'travel';
      final subId = shot == 'offers_search_flights' ? 'flights' : 'hotels';
      ObicService service = localCatalogSeed().firstWhere(
        (s) => s.slug == parentSlug,
        orElse: () => localCatalogSeed().first,
      );
      for (final s in services) {
        if (s.slug == parentSlug) {
          service = s;
          break;
        }
      }
      final subs = subServicesForParent(parentSlug);
      ObicSubService? sub;
      for (final s in subs) {
        if (s.id == subId) {
          sub = s;
          break;
        }
      }
      sub ??= subs.isNotEmpty ? subs.first : null;
      // ignore: use_build_context_synchronously
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ServiceDetailPage(
            service: service,
            authController: authController,
            langCode: localeController.langCode,
            subService: sub,
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 3200));
      if (!context.mounted) return;
      if (shot == 'offer_detail') {
        final items = await OffersApi().listPublished(kind: subId);
        if (!context.mounted) return;
        if (items.isNotEmpty) {
          // ignore: use_build_context_synchronously
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => OfferDetailPage(
                offerId: items.first['id'] as String,
                arabic: localeController.isArabic,
                authController: authController,
                service: service,
                preview: items.first,
              ),
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 2800));
        }
      }
    } catch (_) {}
    // ignore: avoid_print
    print('OBIC_DEMO: ${shot}_done');
    await Future<void>.delayed(const Duration(milliseconds: 14000));
    return;
  }

  if (shot == 'food_hub') {
    try {
      final services = await catalog.load();
      if (!context.mounted) return;
      ObicService service = localCatalogSeed().firstWhere(
        (s) => s.slug == 'food',
        orElse: () => localCatalogSeed().first,
      );
      for (final s in services) {
        if (s.slug == 'food') {
          service = s;
          break;
        }
      }
      // ignore: use_build_context_synchronously
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ServiceHubPage(
            service: service,
            authController: authController,
            langCode: localeController.langCode,
          ),
        ),
      );
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 3800));
    // ignore: avoid_print
    print('OBIC_DEMO: food_hub_done');
    await Future<void>.delayed(const Duration(milliseconds: 14000));
    return;
  }

  if (shot == 'addresses') {
    // ignore: use_build_context_synchronously
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AddressesScreen(authController: authController),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 3500));
    // ignore: avoid_print
    print('OBIC_DEMO: addresses_done');
    await Future<void>.delayed(const Duration(milliseconds: 14000));
    return;
  }

  if (shot == 'admin_offers') {
    // ignore: use_build_context_synchronously
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AdminOffersScreen(authController: authController),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 3500));
    // ignore: avoid_print
    print('OBIC_DEMO: admin_offers_done');
    await Future<void>.delayed(const Duration(milliseconds: 14000));
    return;
  }

  if (shot == 'ops') {
    // Prefer replacing the shell with Ops (most reliable on physical devices).
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!context.mounted) return;
    if (onShowOpsHub != null) {
      onShowOpsHub();
      await Future<void>.delayed(const Duration(milliseconds: 2500));
      // ignore: avoid_print
      print('OBIC_DEMO: ops_done');
      await Future<void>.delayed(const Duration(hours: 2));
      return;
    }
    setTab(5);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!context.mounted) return;
    // ignore: use_build_context_synchronously
    Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const OpsHubScreen(),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 2500));
    // ignore: avoid_print
    print('OBIC_DEMO: ops_done');
    await Future<void>.delayed(const Duration(hours: 2));
    return;
  }

  if (shot == 'add_friend' || shot == 'add_friend_qr') {
    // ignore: use_build_context_synchronously
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AddFriendScreen(
          authController: authController,
          demoInitialTab: shot == 'add_friend_qr' ? 1 : 0,
          demoSearchQuery: shot == 'add_friend' ? '043864' : null,
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 4200));
    // ignore: avoid_print
    print('OBIC_DEMO: ${shot}_done');
    await Future<void>.delayed(const Duration(milliseconds: 14000));
    return;
  }

  if (shot == 'create_group') {
    // ignore: use_build_context_synchronously
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CreateGroupScreen(
          authController: authController,
          demoTitle: 'ييوو · فنادق · خدمة العميل',
          demoSearchQuery: '043864',
          demoAlsoSearch: 'dataentry',
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 5500));
    // ignore: avoid_print
    print('OBIC_DEMO: create_group_done');
    await Future<void>.delayed(const Duration(milliseconds: 14000));
    return;
  }

  if (shot == 'admin') {
    // ignore: use_build_context_synchronously
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AdminHomeScreen(authController: authController),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 3500));
    // ignore: avoid_print
    print('OBIC_DEMO: admin_done');
    await Future<void>.delayed(const Duration(milliseconds: 14000));
    return;
  }

  if (shot == 'admin_staff') {
    // ignore: use_build_context_synchronously
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AdminStaffScreen(authController: authController),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 4000));
    // ignore: avoid_print
    print('OBIC_DEMO: admin_staff_done');
    await Future<void>.delayed(const Duration(milliseconds: 14000));
    return;
  }

  if (shot == 'service_hub' || shot == 'service_zh') {
    try {
      final services = await catalog.load();
      if (!context.mounted) return;
      final slug = kDemoServiceSlug;
      ObicService service = localCatalogSeed().firstWhere(
        (s) => s.slug == slug,
        orElse: () => localCatalogSeed().first,
      );
      for (final s in services) {
        if (s.slug == slug) {
          service = s;
          break;
        }
      }
      // ignore: use_build_context_synchronously
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ServiceHubPage(
            service: service,
            authController: authController,
            langCode: localeController.langCode,
          ),
        ),
      );
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 3800));
    // ignore: avoid_print
    print('OBIC_DEMO: ${shot}_done');
    await Future<void>.delayed(const Duration(milliseconds: 14000));
    return;
  }

  if (shot == 'service_form') {
    try {
      final services = await catalog.load();
      if (!context.mounted) return;
      const slug = 'visa';
      ObicService service = localCatalogSeed().firstWhere(
        (s) => s.slug == slug,
        orElse: () => localCatalogSeed().first,
      );
      for (final s in services) {
        if (s.slug == slug) {
          service = s;
          break;
        }
      }
      final subs = subServicesForParent(slug);
      final sub = subs.isNotEmpty ? subs.first : null;
      // ignore: use_build_context_synchronously
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ServiceRequestPage(
            service: service,
            authController: authController,
            langCode: localeController.langCode,
            subService: sub,
          ),
        ),
      );
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 3800));
    // ignore: avoid_print
    print('OBIC_DEMO: service_form_done');
    await Future<void>.delayed(const Duration(milliseconds: 14000));
    return;
  }

  if (shot == 'admin_services') {
    // ignore: use_build_context_synchronously
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AdminServicesScreen(authController: authController),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 4000));
    // ignore: avoid_print
    print('OBIC_DEMO: admin_services_done');
    await Future<void>.delayed(const Duration(milliseconds: 14000));
    return;
  }

  if (shot == 'admin_subs') {
    try {
      final token = await authController.ensureAccessToken();
      if (token == null) throw Exception('no token');
      final api = AdminApi();
      final services = await api.listServices(token);
      final visa = services.cast<Map<String, dynamic>?>().firstWhere(
            (s) => s?['slug'] == 'visa',
            orElse: () => services.isNotEmpty ? services.first : null,
          );
      if (visa != null && context.mounted) {
        final title = visa['nameEn'] as String? ?? 'Visa';
        // ignore: use_build_context_synchronously
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => AdminSubServicesScreen(
              authController: authController,
              serviceId: visa['id'] as String,
              parentTitle: title,
            ),
          ),
        );
      }
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 4000));
    // ignore: avoid_print
    print('OBIC_DEMO: admin_subs_done');
    await Future<void>.delayed(const Duration(milliseconds: 14000));
    return;
  }

  if (shot == 'admin_orders' || shot == 'admin_orders_crm') {
    // ignore: use_build_context_synchronously
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AdminOrdersScreen(
          authController: authController,
          isSuperAdmin: true,
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 4500));
    // ignore: avoid_print
    print('OBIC_DEMO: ${shot}_done');
    await Future<void>.delayed(const Duration(milliseconds: 14000));
    return;
  }

  if (shot == 'order_chat') {
    try {
      final token = await authController.accessToken();
      if (token != null) {
        final api = ServicesApi();
        final orders = await api.listMyOrders(token);
        if (!context.mounted) return;
        if (orders.isNotEmpty) {
          final chat = await api.openOrderChat(
            accessToken: token,
            orderId: orders.first['id'] as String,
          );
          final threadId = chat['conversationId']?.toString();
          if (threadId != null && context.mounted) {
            // ignore: use_build_context_synchronously
            Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => ChatScreen(
                  authController: authController,
                  threadId: threadId,
                  title: chat['title']?.toString() ?? 'Order',
                ),
              ),
            );
          }
        }
      }
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 3800));
    // ignore: avoid_print
    print('OBIC_DEMO: order_chat_done');
    await Future<void>.delayed(const Duration(milliseconds: 14000));
    return;
  }

  if (shot == 'orders_crm') {
    final ar = localeController.isArabic;
    // ignore: use_build_context_synchronously
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(ar ? 'طلباتي' : 'Orders')),
          body: OrdersTab(authController: authController),
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 3500));
    // ignore: avoid_print
    print('OBIC_DEMO: orders_crm_done');
    await Future<void>.delayed(const Duration(milliseconds: 14000));
    return;
  }

  if (shot == 'request_branches') {
    try {
      final services = await catalog.load();
      if (!context.mounted) return;
      const slug = 'property';
      ObicService service = localCatalogSeed().firstWhere(
        (s) => s.slug == slug,
        orElse: () => localCatalogSeed().first,
      );
      for (final s in services) {
        if (s.slug == slug) {
          service = s;
          break;
        }
      }
      // ignore: use_build_context_synchronously
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ServiceRequestPage(
            service: service,
            authController: authController,
            langCode: localeController.langCode,
          ),
        ),
      );
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 4500));
    // ignore: avoid_print
    print('OBIC_DEMO: request_branches_done');
    await Future<void>.delayed(const Duration(milliseconds: 14000));
    return;
  }

  if (shot == 'request') {
    try {
      final services = await catalog.load();
      if (!context.mounted) return;
      final service =
          services.isNotEmpty ? services.first : localCatalogSeed().first;
      // ignore: use_build_context_synchronously
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ServiceRequestPage(
            service: service,
            authController: authController,
            langCode: localeController.langCode,
          ),
        ),
      );
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 3500));
    // ignore: avoid_print
    print('OBIC_DEMO: request_done');
    await Future<void>.delayed(const Duration(milliseconds: 14000));
    return;
  }

  if (shot == 'notifications') {
    // ignore: use_build_context_synchronously
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            NotificationsScreen(authController: authController),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 3500));
    // ignore: avoid_print
    print('OBIC_DEMO: notifications_done');
    await Future<void>.delayed(const Duration(milliseconds: 14000));
    return;
  }

  if (shot == 'orders') {
    final ar = localeController.isArabic;
    // ignore: use_build_context_synchronously
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(ar ? 'طلباتي' : 'Orders')),
          body: OrdersTab(authController: authController),
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 3500));
    // ignore: avoid_print
    print('OBIC_DEMO: orders_done');
    await Future<void>.delayed(const Duration(milliseconds: 14000));
    return;
  }

  if (shot == 'chat' ||
      shot == 'chat_panel' ||
      shot == 'chat_menu' ||
      shot == 'group') {
    try {
      final token = await authController.accessToken();
      if (token != null) {
        final api = SocialApi();
        var threads = await api.listThreads(token);
        if (threads.isEmpty && shot != 'group') {
          await api.openSupportThread(token);
          threads = await api.listThreads(token);
        }
        Map<String, dynamic>? t;
        if (shot == 'group') {
          for (final row in threads) {
            if (row['kind'] == 'group') {
              t = row;
              break;
            }
          }
        }
        t ??= threads.isNotEmpty ? threads.first : null;
        if (t != null && context.mounted) {
          if (shot == 'chat_menu') {
            try {
              await api.sendMessage(
                accessToken: token,
                threadId: t['id'] as String,
                body: 'OBIC demo message',
              );
            } catch (_) {}
          }
          final title = (t['title'] as String?)?.trim().isNotEmpty == true
              ? t['title'] as String
              : ((t['kind'] == 'group') ? 'Service group' : 'Chat');
          // ignore: use_build_context_synchronously
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => ChatScreen(
                authController: authController,
                threadId: t!['id'] as String,
                title: title,
                demoOpenAttachPanel: shot == 'chat_panel',
                demoOpenMessageMenu: shot == 'chat_menu',
              ),
            ),
          );
        }
      }
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 4200));
    // ignore: avoid_print
    print('OBIC_DEMO: ${shot}_done');
    await Future<void>.delayed(const Duration(milliseconds: 14000));
    return;
  }

  final tab = switch (shot) {
    'home' => 0,
    'near_me' => 0,
    'services' => 1,
    'moments' => 4,
    'messages' => 2,
    'me' => 5,
    _ => 0,
  };
  setTab(tab);
  // Home/near_me need extra time for GPS + branch distances.
  final holdMs = (shot == 'home' || shot == 'services')
      ? 4500
      : shot == 'near_me'
      ? 6000
      : (shot == 'me' || shot == 'messages' || shot == 'moments')
          ? 5500
          : 2800;
  await Future<void>.delayed(Duration(milliseconds: holdMs));
  // ignore: avoid_print
  print('OBIC_DEMO: ${shot}_done');
  await Future<void>.delayed(const Duration(milliseconds: 14000));
}

Future<void> _runDetailShot({
  required BuildContext context,
  required void Function(int tabIndex) setTab,
  required AuthController authController,
  required LocaleController localeController,
  required CatalogRepository catalog,
}) async {
  // ignore: avoid_print
  print('OBIC_DEMO: walkthrough_start');
  await Future<void>.delayed(const Duration(milliseconds: 1000));
  if (!context.mounted) return;
  setTab(1);
  await Future<void>.delayed(const Duration(milliseconds: 1200));
  if (!context.mounted) return;
  final services = await catalog.load();
  if (!context.mounted) return;
  final service =
      services.isNotEmpty ? services.first : localCatalogSeed().first;
  // ignore: use_build_context_synchronously
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => ServiceDetailPage(
        service: service,
        authController: authController,
        langCode: localeController.langCode,
      ),
    ),
  );
  await Future<void>.delayed(const Duration(milliseconds: 5000));
  // ignore: avoid_print
  print('OBIC_DEMO: detail_done');
  await Future<void>.delayed(const Duration(milliseconds: 2000));
}
