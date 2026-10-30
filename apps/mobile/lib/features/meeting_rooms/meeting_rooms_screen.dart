// Made by Dr Ali
// Staff book a meeting room. The same room cannot be taken twice at once.

import 'package:flutter/material.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import '../social/social_api.dart';

class MeetingRoomsScreen extends StatefulWidget {
  const MeetingRoomsScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<MeetingRoomsScreen> createState() => _MeetingRoomsScreenState();
}

class _MeetingRoomsScreenState extends State<MeetingRoomsScreen> {
  final _api = SocialApi();
  final _title = TextEditingController();
  Map<String, dynamic>? _home;
  String? _roomId;
  DateTime? _start;
  DateTime? _end;
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
    _title.dispose();
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
      final home = await _api.meetingRoomsHome(token);
      if (!mounted) return;
      final rooms = _maps(home['rooms']);
      setState(() {
        _home = home;
        _loading = false;
        _roomId ??= rooms.isEmpty ? null : rooms.first['id']?.toString();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'failed';
      });
    }
  }

  List<Map<String, dynamic>> _maps(Object? value) {
    if (value is! List) return [];
    return value.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Future<DateTime?> _pick(DateTime? current) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current ?? now),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _book() async {
    final roomId = _roomId;
    final start = _start;
    final end = _end;
    final title = _title.text.trim();
    if (roomId == null || start == null || end == null || title.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final token = await widget.authController.accessToken();
      if (token == null || token.isEmpty) throw StateError('sign-in');
      await _api.bookMeetingRoom(
        accessToken: token,
        roomId: roomId,
        title: title,
        startsAt: start,
        endsAt: end,
      );
      _title.clear();
      _start = null;
      _end = null;
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _cancel(String id) async {
    try {
      final token = await widget.authController.accessToken();
      if (token == null || token.isEmpty) return;
      await _api.cancelMeetingBooking(accessToken: token, bookingId: id);
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final rooms = _maps(_home?['rooms']);
    final bookings = _maps(_home?['bookings']);
    return Scaffold(
      backgroundColor: ObicColors.surfaceOf(context),
      appBar: AppBar(title: Text(l10n.roomsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.roomsLoadFailed),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _load, child: Text(l10n.roomsTitle)),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    Text(l10n.roomsHint, style: TextStyle(color: ObicColors.mutedOf(context))),
                    const SizedBox(height: 12),
                    if (rooms.isEmpty)
                      Text(l10n.roomsNone, style: TextStyle(color: ObicColors.mutedOf(context)))
                    else ...[
                      DropdownButtonFormField<String>(
                        initialValue: _roomId,
                        decoration: InputDecoration(labelText: l10n.roomsTitle),
                        items: [
                          for (final row in rooms)
                            DropdownMenuItem(
                              value: row['id']?.toString(),
                              child: Text('${_name(row, lang)} · ${row['capacity']}'),
                            ),
                        ],
                        onChanged: (value) => setState(() => _roomId = value),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _title,
                        maxLength: 120,
                        decoration: InputDecoration(labelText: l10n.roomsPurpose),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.roomsStart),
                        subtitle: Text(_start == null ? l10n.roomsPick : _clock(_start!)),
                        onTap: () async {
                          final picked = await _pick(_start);
                          if (picked != null) setState(() => _start = picked);
                        },
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.roomsEnd),
                        subtitle: Text(_end == null ? l10n.roomsPick : _clock(_end!)),
                        onTap: () async {
                          final picked = await _pick(_end);
                          if (picked != null) setState(() => _end = picked);
                        },
                      ),
                      FilledButton(
                        onPressed: _sending ? null : _book,
                        child: Text(l10n.roomsBook),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(l10n.roomsUpcoming, style: Theme.of(context).textTheme.titleMedium),
                    if (bookings.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(l10n.roomsNone, style: TextStyle(color: ObicColors.mutedOf(context))),
                      ),
                    for (final row in bookings)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('${row['title']} · ${_roomName(rooms, row['roomId']?.toString(), lang)}'),
                        subtitle: Text(
                          '${_clock(DateTime.parse(row['startsAt'].toString()).toLocal())} – ${_clock(DateTime.parse(row['endsAt'].toString()).toLocal())}\n${row['bookerName'] ?? ''}',
                        ),
                        trailing: row['canCancel'] == true
                            ? TextButton(
                                onPressed: () => _cancel(row['id'].toString()),
                                child: Text(l10n.roomsCancel),
                              )
                            : null,
                      ),
                  ],
                ),
    );
  }

  String _name(Map<String, dynamic> row, String lang) {
    if (lang == 'ar') return row['nameAr']?.toString() ?? '';
    if (lang == 'zh') return row['nameZh']?.toString() ?? '';
    return row['nameEn']?.toString() ?? '';
  }

  String _roomName(List<Map<String, dynamic>> rooms, String? id, String lang) {
    for (final row in rooms) {
      if (row['id']?.toString() == id) return _name(row, lang);
    }
    return '';
  }

  String _clock(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.year}-$month-$day $hour:$minute';
  }
}
