// Made by Dr Ali
// Staff clock-in for the company day. Customers never open this screen.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import '../social/social_api.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _api = SocialApi();
  final _note = TextEditingController();
  Map<String, dynamic>? _home;
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await widget.authController.accessToken();
      if (token == null || token.isEmpty) throw StateError('sign-in');
      final home = await _api.attendanceHome(token);
      if (!mounted) return;
      setState(() {
        _home = home;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'failed';
      });
    }
  }

  Future<void> _punch(String kind) async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      final token = await widget.authController.accessToken();
      if (token == null || token.isEmpty) throw StateError('sign-in');
      await _api.punchAttendance(
        accessToken: token,
        kind: kind,
        note: _note.text.trim(),
      );
      _note.clear();
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final home = _home;
    final rule = home?['rule'];
    final today = home?['today']?.toString() ?? '';
    final punches = home?['punches'];
    final rows = punches is List
        ? punches.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList()
        : <Map<String, dynamic>>[];
    final todayRows = rows.where((row) => row['workDate']?.toString() == today).toList();
    final clockIn = _kind(todayRows, 'in');
    final clockOut = _kind(todayRows, 'out');
    final hours = rule is Map
        ? '${_minute(rule['startMinute'])}–${_minute(rule['endMinute'])}'
        : '';

    return Scaffold(
      backgroundColor: ObicColors.surfaceOf(context),
      appBar: AppBar(title: Text(l10n.attendanceTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.attendanceLoadFailed),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _load, child: Text(l10n.attendanceTitle)),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    Text(l10n.attendanceHint, style: TextStyle(color: ObicColors.mutedOf(context))),
                    if (hours.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(hours, style: TextStyle(color: ObicColors.mutedOf(context))),
                    ],
                    const SizedBox(height: 16),
                    _todayLine(l10n, l10n.attendanceClockIn, clockIn),
                    _todayLine(l10n, l10n.attendanceClockOut, clockOut),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _note,
                      maxLength: 200,
                      decoration: InputDecoration(labelText: l10n.attendanceNote),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: _sending || clockIn != null ? null : () => _punch('in'),
                            child: Text(l10n.attendanceClockIn),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _sending || clockIn == null || clockOut != null
                                ? null
                                : () => _punch('out'),
                            child: Text(l10n.attendanceClockOut),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(l10n.attendanceRecent, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    for (final row in rows)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('${row['workDate']} · ${_kindLabel(l10n, row['kind']?.toString())}'),
                        subtitle: Text(_markLabel(l10n, row['mark']?.toString())),
                        trailing: Text(row['clock']?.toString() ?? ''),
                      ),
                  ],
                ),
    );
  }

  Map<String, dynamic>? _kind(List<Map<String, dynamic>> rows, String kind) {
    for (final row in rows) {
      if (row['kind'] == kind) return row;
    }
    return null;
  }

  Widget _todayLine(AppLocalizations l10n, String label, Map<String, dynamic>? punch) {
    final detail = punch == null
        ? l10n.attendanceMissing
        : '${punch['clock'] ?? ''} · ${_markLabel(l10n, punch['mark']?.toString())}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text('$label · $detail'),
    );
  }

  String _kindLabel(AppLocalizations l10n, String? kind) {
    switch (kind) {
      case 'in':
        return l10n.attendanceClockIn;
      case 'out':
        return l10n.attendanceClockOut;
      default:
        return kind ?? '';
    }
  }

  String _markLabel(AppLocalizations l10n, String? mark) {
    switch (mark) {
      case 'on_time':
        return l10n.attendanceOnTime;
      case 'late':
        return l10n.attendanceLate;
      case 'early':
        return l10n.attendanceEarly;
      case 'off_day':
        return l10n.attendanceOffDay;
      default:
        return mark ?? '';
    }
  }

  String _minute(Object? value) {
    final minute = value is num ? value.toInt() : int.tryParse('$value') ?? 0;
    final hour = minute ~/ 60;
    final rest = minute % 60;
    return '${hour.toString().padLeft(2, '0')}:${rest.toString().padLeft(2, '0')}';
  }

}
