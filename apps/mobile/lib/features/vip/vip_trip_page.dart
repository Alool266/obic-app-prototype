// Made by Dr Ali
// One VIP trip: frozen quotation lines, accept / cancel. A new quotation
// always needs fresh acceptance — the server enforces it, this mirrors it.

import 'package:flutter/material.dart';

import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import 'vip_api.dart';
import 'vip_strings.dart';

class VipTripPage extends StatefulWidget {
  const VipTripPage({
    super.key,
    required this.authController,
    required this.langCode,
    required this.tripId,
  });

  final AuthController authController;
  final String langCode;
  final String tripId;

  @override
  State<VipTripPage> createState() => _VipTripPageState();
}

class _VipTripPageState extends State<VipTripPage> {
  final _api = VipApi();
  VipStrings get s => VipStrings(widget.langCode);

  Map<String, dynamic>? _trip;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<String> _token() async {
    final token = await widget.authController.accessToken();
    if (token == null) throw Exception('Login required');
    return token;
  }

  Future<void> _load() async {
    try {
      final token = await _token();
      final trip = await _api.getTrip(token, widget.tripId);
      if (mounted) setState(() => _trip = trip);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
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

  @override
  Widget build(BuildContext context) {
    final trip = _trip;
    final quotation = trip?['quotation'];
    final lines = quotation is Map<String, dynamic> ? quotation['lines'] : null;
    final totals = quotation is Map<String, dynamic>
        ? quotation['totals']
        : null;
    final totalCents = totals is Map<String, dynamic>
        ? (totals['totalCents'] as num?) ?? 0
        : 0;
    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      appBar: AppBar(title: Text(s.title)),
      body: trip == null
          ? Center(
              child: _error != null
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  : const CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Chip(label: Text('${s.status}: ${trip['status']}')),
                const SizedBox(height: 8),
                Text('${trip['trackingId']} · ${trip['purpose']}'),
                Text(
                  '${(trip['cities'] as List?)?.join(', ') ?? ''} · ${trip['days']} ${s.days} · ${trip['people']}',
                ),
                const SizedBox(height: 16),
                if (lines is List)
                  for (final line in lines)
                    if (line is Map<String, dynamic>)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${line['itemName']} (${line['version']})',
                            ),
                          ),
                          Text(
                            '¥${(((line['obicFeeCents'] as num?) ?? 0) / 100).toStringAsFixed(2)}',
                          ),
                        ],
                      ),
                if (quotation is Map<String, dynamic>) ...[
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        s.total,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '¥${(totalCents / 100).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 16),
                if (trip['status'] == 'DRAFT' || trip['status'] == 'QUOTED')
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: ObicColors.blue,
                    ),
                    onPressed: _busy
                        ? null
                        : () => _run(
                            (token) => _api.quoteTrip(token, widget.tripId),
                          ),
                    child: Text(s.getQuote),
                  ),
                if (trip['status'] == 'QUOTED')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: FilledButton(
                      onPressed: _busy
                          ? null
                          : () => _run(
                              (token) => _api.acceptTrip(token, widget.tripId),
                            ),
                      child: Text(s.accept),
                    ),
                  ),
                if (trip['status'] != 'COMPLETED' &&
                    trip['status'] != 'CANCELLED')
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => _run(
                            (token) => _api.cancelTrip(token, widget.tripId),
                          ),
                    child: Text(s.cancel),
                  ),
              ],
            ),
    );
  }
}
