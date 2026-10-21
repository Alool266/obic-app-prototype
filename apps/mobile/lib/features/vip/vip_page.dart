// Made by Dr Ali
// VIP hub (boss M06): timed consultations with hard stop + VIP trip builder
// with frozen quotations. Prices come only from server Active versions —
// while Draft, the server answers clearly and the app shows its message.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import 'vip_api.dart';
import 'vip_strings.dart';
import 'vip_trip_page.dart';

class VipPage extends StatefulWidget {
  const VipPage({
    super.key,
    required this.authController,
    required this.langCode,
  });

  final AuthController authController;
  final String langCode;

  @override
  State<VipPage> createState() => _VipPageState();
}

class _VipPageState extends State<VipPage> {
  final _api = VipApi();
  VipStrings get s => VipStrings(widget.langCode);

  List<Map<String, dynamic>> _sessions = [];
  List<Map<String, dynamic>> _trips = [];
  bool _busy = false;
  String? _error;
  Timer? _ticker;

  // Trip form
  String _purpose = kTripPurposes.first;
  final _cities = TextEditingController();
  final _days = TextEditingController(text: '5');
  final _people = TextEditingController(text: '1');
  final _notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    // Live countdown for ACTIVE consultations (server stays the truth).
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _cities.dispose();
    _days.dispose();
    _people.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<String> _token() async {
    final token = await widget.authController.accessToken();
    if (token == null) throw Exception('Login required');
    return token;
  }

  Future<void> _load() async {
    try {
      final token = await _token();
      final sessions = await _api.myConsultations(token);
      final trips = await _api.myTrips(token);
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _trips = trips;
        });
      }
    } catch (_) {
      // Hub stays usable offline of these lists.
    }
  }

  Future<void> _run(Future<void> Function(String token) fn) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final token = await _token();
      await fn(token);
      await _load();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _fmtRemaining(Map<String, dynamic> session) {
    final seconds = (session['remainingSeconds'] as num?)?.toInt() ?? 0;
    final m = seconds ~/ 60;
    final sec = seconds % 60;
    return '$m:${sec.toString().padLeft(2, '0')} ${s.remaining}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      appBar: AppBar(title: Text(s.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(s.consultations, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(s.consultHint, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in kConsultationPrices.entries)
                ActionChip(
                  label: Text('${entry.key} ${s.minutes} · ${entry.value}'),
                  onPressed: _busy
                      ? null
                      : () => _run(
                          (token) => _api.createConsultation(token, entry.key),
                        ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            s.mySessions,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (_sessions.isEmpty) Text(s.none),
          for (final session in _sessions)
            Card(
              child: ListTile(
                title: Text(
                  '${session['minutes']} ${s.minutes} — ${session['status']}',
                ),
                subtitle: Text(
                  session['status'] == 'ACTIVE'
                      ? _fmtRemaining(session)
                      : session['status'] == 'PENDING_PAYMENT'
                      ? s.pendingPayment
                      : '',
                ),
                trailing: session['status'] == 'READY'
                    ? FilledButton(
                        onPressed: _busy
                            ? null
                            : () => _run(
                                (token) => _api.startConsultation(
                                  token,
                                  session['id'] as String,
                                ),
                              ),
                        child: Text(s.start),
                      )
                    : session['status'] == 'ACTIVE'
                    ? OutlinedButton(
                        onPressed: _busy
                            ? null
                            : () => _run(
                                (token) => _api.endConsultation(
                                  token,
                                  session['id'] as String,
                                ),
                              ),
                        child: Text(s.end),
                      )
                    : null,
              ),
            ),
          const SizedBox(height: 24),
          Text(s.tripBuilder, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            s.coordinationNote,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _purpose,
            decoration: InputDecoration(labelText: s.purpose),
            items: [
              for (final p in kTripPurposes)
                DropdownMenuItem(value: p, child: Text(p)),
            ],
            onChanged: (v) => setState(() => _purpose = v ?? _purpose),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cities,
            decoration: InputDecoration(labelText: s.cities),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _days,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: s.days),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _people,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: s.people),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            decoration: InputDecoration(labelText: s.notes),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ObicColors.blue),
            onPressed: _busy
                ? null
                : () => _run((token) async {
                    final trip = await _api.createTrip(
                      token: token,
                      purpose: _purpose,
                      cities: _cities.text
                          .split(',')
                          .map((c) => c.trim())
                          .where((c) => c.isNotEmpty)
                          .toList(),
                      days: int.tryParse(_days.text.trim()) ?? 0,
                      people: int.tryParse(_people.text.trim()) ?? 1,
                      notes: _notes.text.trim(),
                    );
                    if (!context.mounted) return;
                    await Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => VipTripPage(
                          authController: widget.authController,
                          langCode: widget.langCode,
                          tripId: trip['id'] as String,
                        ),
                      ),
                    );
                  }),
            child: Text(s.createTrip),
          ),
          const SizedBox(height: 16),
          Text(s.myTrips, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (_trips.isEmpty) Text(s.none),
          for (final trip in _trips)
            Card(
              child: ListTile(
                title: Text(
                  '${trip['trackingId']} · ${trip['purpose']} · ${trip['days']} ${s.days}',
                ),
                subtitle: Text('${s.status}: ${trip['status']}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => VipTripPage(
                        authController: widget.authController,
                        langCode: widget.langCode,
                        tripId: trip['id'] as String,
                      ),
                    ),
                  );
                  _load();
                },
              ),
            ),
        ],
      ),
    );
  }
}
