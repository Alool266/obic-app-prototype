// Made by Dr Ali
// In-app VIP desk (boss M06): trips + timed consultations. Staff record
// external payment references, assign the responsible employee, create
// the official group after acceptance + payment, and move trip states.

import 'package:flutter/material.dart';

import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import 'admin_boss_api.dart';
import 'admin_boss_strings.dart';

class AdminVipScreen extends StatefulWidget {
  const AdminVipScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<AdminVipScreen> createState() => _AdminVipScreenState();
}

class _AdminVipScreenState extends State<AdminVipScreen> {
  final _api = AdminBossApi();
  List<Map<String, dynamic>> _trips = [];
  List<Map<String, dynamic>> _sessions = [];
  bool _loading = true;
  String? _error;

  AdminBossStrings get s =>
      AdminBossStrings(Localizations.localeOf(context).languageCode);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<String> _token() async {
    final token = await widget.authController.ensureAccessToken();
    if (token == null) throw Exception('session_expired');
    return token;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await _token();
      final trips = await _api.vipTrips(token);
      final sessions = await _api.vipConsultations(token);
      if (!mounted) return;
      setState(() {
        _trips = trips;
        _sessions = sessions;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<String?> _prompt(String title) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(s.save),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _guard(Future<void> Function(String token) fn) async {
    try {
      final token = await _token();
      await fn(token);
      await _load();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  List<String> _nextTrip(String status) {
    switch (status) {
      case 'GROUP_CREATED':
        return ['IN_PROGRESS', 'CANCELLED'];
      case 'IN_PROGRESS':
        return ['COMPLETED', 'CANCELLED'];
      case 'DRAFT':
      case 'QUOTED':
      case 'ACCEPTED':
        return ['CANCELLED'];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      appBar: AppBar(
        title: Text(s.vipTitle),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                Text(s.trips, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (_trips.isEmpty) Text(s.none),
                for (final trip in _trips)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${trip['trackingId']} · ${trip['purpose']} · ${trip['days']}d',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${(trip['cities'] as List?)?.join(', ') ?? ''} — ${trip['status']}${trip['paidReference'] != null ? ' · ${trip['paidReference']}' : ''}',
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            children: [
                              if (trip['status'] == 'ACCEPTED' &&
                                  trip['paidReference'] == null)
                                ActionChip(
                                  label: Text(s.markPaid),
                                  onPressed: () async {
                                    final ref = await _prompt(s.paidPrompt);
                                    if (ref == null || ref.isEmpty) return;
                                    await _guard(
                                      (token) => _api.vipMarkTripPaid(
                                        token: token,
                                        tripId: trip['id'] as String,
                                        reference: ref,
                                      ),
                                    );
                                  },
                                ),
                              ActionChip(
                                label: Text(s.assign),
                                onPressed: () async {
                                  final id = await _prompt(s.assignPrompt);
                                  if (id == null || id.isEmpty) return;
                                  await _guard(
                                    (token) => _api.vipAssignTrip(
                                      token: token,
                                      tripId: trip['id'] as String,
                                      employeeId: id,
                                    ),
                                  );
                                },
                              ),
                              if (trip['status'] == 'ACCEPTED' &&
                                  trip['paidReference'] != null &&
                                  trip['groupConversationId'] == null)
                                ActionChip(
                                  label: Text(s.createGroup),
                                  onPressed: () async {
                                    final raw = await _prompt(s.groupPrompt);
                                    if (raw == null || raw.isEmpty) return;
                                    await _guard(
                                      (token) => _api.vipCreateGroup(
                                        token: token,
                                        tripId: trip['id'] as String,
                                        memberUserIds: raw
                                            .split(',')
                                            .map((x) => x.trim())
                                            .where((x) => x.isNotEmpty)
                                            .toList(),
                                      ),
                                    );
                                  },
                                ),
                              for (final to in _nextTrip(
                                trip['status'] as String,
                              ))
                                ActionChip(
                                  label: Text('→ $to'),
                                  onPressed: () => _guard(
                                    (token) => _api.vipTransitionTrip(
                                      token: token,
                                      tripId: trip['id'] as String,
                                      status: to,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                Text(
                  s.sessions,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_sessions.isEmpty) Text(s.none),
                for (final session in _sessions)
                  Card(
                    child: ListTile(
                      title: Text(
                        '${session['minutes']} min — ${session['status']}',
                      ),
                      subtitle: Text('${session['paidReference'] ?? ''}'),
                      trailing: session['status'] == 'PENDING_PAYMENT'
                          ? ActionChip(
                              label: Text(s.markPaid),
                              onPressed: () async {
                                final ref = await _prompt(s.paidPrompt);
                                if (ref == null || ref.isEmpty) return;
                                await _guard(
                                  (token) => _api.vipMarkConsultationPaid(
                                    token: token,
                                    sessionId: session['id'] as String,
                                    reference: ref,
                                  ),
                                );
                              },
                            )
                          : null,
                    ),
                  ),
              ],
            ),
    );
  }
}
