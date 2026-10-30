// Made by Dr Ali
// Phase 5 — OBIC AI assistant: Guide | Chat | History (AR / EN / 中文 / FR UI).

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:obic_mobile/l10n/app_localizations.dart';

import '../../core/api_errors.dart';
import '../../core/connectivity_service.dart';
import '../../core/media_pick.dart';
import '../../theme/obic_colors.dart';
import '../auth/auth_controller.dart';
import '../messages/chat_day_separator.dart';
import 'ai_api.dart';
import 'ai_history_store.dart';
import 'translation_cache.dart';

class ObicAiScreen extends StatefulWidget {
  const ObicAiScreen({super.key, required this.authController, this.onClose});

  final AuthController authController;

  /// When set (in-shell mode), AppBar shows close and bottom shell tabs stay.
  final VoidCallback? onClose;

  @override
  State<ObicAiScreen> createState() => _ObicAiScreenState();
}

class _ObicAiScreenState extends State<ObicAiScreen>
    with SingleTickerProviderStateMixin {
  final _api = AiApi();
  final _store = AiHistoryStore();
  final _input = TextEditingController();
  final _scroll = ScrollController();

  late final TabController _tabs;

  String? _threadId;
  List<_Turn> _turns = [];
  _AiPendingAttachment? _pending;
  List<AiHistoryThread> _history = [];

  bool _loadingStatus = true;
  bool _loadingHistory = true;
  bool _sending = false;
  bool _enabled = false;
  String? _error;
  Completer<void>? _askAbort;
  int _askSerial = 0;

  /// turnIndex → translation (WeChat-style under bubble).
  final Map<int, String> _translations = {};
  final Set<int> _translating = {};
  final Set<int> _translationHidden = {};

  String get _userId => widget.authController.user?.id ?? '';

  String get _localeCode {
    final code = Localizations.localeOf(context).languageCode;
    if (code == 'ar') return 'ar';
    if (code == 'zh') return 'zh';
    return 'en';
  }

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this, initialIndex: 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStatus();
      _loadHistory();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    setState(() {
      _loadingStatus = true;
      _error = null;
    });
    try {
      final token = await widget.authController.ensureAccessToken();
      if (token == null) throw Exception('Not signed in');
      final status = await _api.status(token);
      if (!mounted) return;
      setState(() {
        _enabled = status['enabled'] == true;
        _loadingStatus = false;
      });
      // User id may only be available after ensureAccessToken.
      if (_history.isEmpty && _turns.isEmpty) {
        await _loadHistory();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingStatus = false;
        _error = _friendlyError(e);
      });
    }
  }

  String _friendlyError(Object e) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return friendlyApiError(
      classifyTransportError(e),
      l10n: l10n,
      langCode: lang,
    );
  }

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    final uid = _userId;
    var threads = await _store.loadThreads(uid);
    final activeId = await _store.loadActiveThreadId(uid);

    // Offline: local cache only. Online: pull server threads + hydrate.
    if (!ConnectivityService.instance.isOffline && uid.isNotEmpty) {
      try {
        final token = await widget.authController.ensureAccessToken();
        if (token != null) {
          final remote = await _api.listThreads(token);
          final hydrated = <AiHistoryThread>[];
          for (final row in remote.take(15)) {
            final id = (row['id'] as String?) ?? '';
            if (id.isEmpty) continue;
            final localHit = threads.where((t) => t.id == id).toList();
            if (localHit.isNotEmpty && localHit.first.turns.isNotEmpty) {
              hydrated.add(
                AiHistoryThread(
                  id: id,
                  title: (row['title'] as String?) ?? localHit.first.title,
                  updatedAt:
                      DateTime.tryParse((row['updatedAt'] as String?) ?? '') ??
                      localHit.first.updatedAt,
                  turns: localHit.first.turns,
                  fromServer: true,
                ),
              );
              continue;
            }
            try {
              final detail = await _api.getThread(
                accessToken: token,
                threadId: id,
              );
              hydrated.add(
                AiHistoryThread.fromJson({...detail, 'fromServer': true}),
              );
            } catch (_) {
              hydrated.add(
                AiHistoryThread(
                  id: id,
                  title: (row['title'] as String?) ?? 'OBIC AI',
                  updatedAt:
                      DateTime.tryParse((row['updatedAt'] as String?) ?? '') ??
                      DateTime.now(),
                  turns: const [],
                  fromServer: true,
                ),
              );
            }
          }
          threads = await _store.mergeServerThreads(
            userId: uid,
            serverThreads: hydrated,
          );
        }
      } catch (_) {
        // Keep local cache on sync failure.
      }
    }

    if (!mounted) return;

    AiHistoryThread? active;
    if (activeId != null) {
      for (final t in threads) {
        if (t.id == activeId) {
          active = t;
          break;
        }
      }
    }
    active ??= threads.isNotEmpty ? threads.first : null;

    setState(() {
      _history = threads;
      _loadingHistory = false;
      if (active != null) {
        _threadId = active.id;
        _turns = active.turns.map(_liveTurn).toList();
      }
    });
    if (_turns.isNotEmpty) _scrollToEnd();
  }

  Future<void> _persistCurrent({String? serverThreadId}) async {
    final uid = _userId;
    if (uid.isEmpty) return;
    final durable = _turns.where((t) => !t.isError).toList();
    if (durable.isEmpty && (_threadId == null || _threadId!.isEmpty)) {
      return;
    }
    final oldId = _threadId;
    final id = (serverThreadId != null && serverThreadId.isNotEmpty)
        ? serverThreadId
        : ((_threadId != null && _threadId!.isNotEmpty)
              ? _threadId!
              : 't_${DateTime.now().millisecondsSinceEpoch}');
    final thread = AiHistoryThread(
      id: id,
      title: AiHistoryStore.titleFromTurns(durable.map(_storedTurn).toList()),
      updatedAt: DateTime.now(),
      turns: durable.map(_storedTurn).toList(),
      fromServer: serverThreadId != null && serverThreadId.isNotEmpty,
    );
    if (oldId != null &&
        oldId.isNotEmpty &&
        oldId != id &&
        !RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        ).hasMatch(oldId)) {
      await _store.replaceThreadId(
        userId: uid,
        oldId: oldId,
        newThread: thread,
      );
    } else {
      await _store.upsertThread(uid, thread);
    }
    if (!mounted) return;
    setState(() {
      _threadId = id;
    });
    final refreshed = await _store.loadThreads(uid);
    if (!mounted) return;
    setState(() => _history = refreshed);
  }

  void _clearTranslations() {
    _translations.clear();
    _translating.clear();
    _translationHidden.clear();
  }

  void _startNewChat() {
    unawaited(_beginNewChat());
  }

  /// Clears the on-screen thread. Saved threads stay in [AiHistoryStore].
  Future<void> _beginNewChat() async {
    _stopAsk();
    await _persistCurrent();
    if (!mounted) return;
    setState(() {
      _threadId = null;
      _turns = [];
      _pending = null;
      _error = null;
      _clearTranslations();
    });
    await _store.saveActiveThreadId(_userId, null);
    if (!mounted) return;
    if (_tabs.index != 1) _tabs.animateTo(1);
  }

  void _openThread(AiHistoryThread thread) {
    _stopAsk();
    setState(() {
      _threadId = thread.id;
      _turns = thread.turns.map(_liveTurn).toList();
      _pending = null;
      _error = null;
      _clearTranslations();
    });
    _store.saveActiveThreadId(_userId, thread.id);
    _tabs.animateTo(1);
    _scrollToEnd();
  }

  Future<void> _deleteThread(AiHistoryThread thread) async {
    if (_threadId == thread.id) _stopAsk();
    final uid = _userId;
    if (thread.looksLikeServerId && !ConnectivityService.instance.isOffline) {
      try {
        final token = await widget.authController.ensureAccessToken();
        if (token != null) {
          await _api.deleteThread(accessToken: token, threadId: thread.id);
        }
      } catch (_) {
        // Still drop local copy.
      }
    }
    await _store.deleteThread(uid, thread.id);
    final refreshed = await _store.loadThreads(uid);
    if (!mounted) return;
    setState(() {
      _history = refreshed;
      if (_threadId == thread.id) {
        _threadId = null;
        _turns = [];
        _clearTranslations();
      }
    });
  }

  bool _isServerThreadId(String? id) {
    if (id == null || id.isEmpty) return false;
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(id);
  }

  void _toast(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Copies the visible bubble text. Skips blank text and never includes
  /// hidden prompts — the bubble only holds the user or assistant message.
  Future<void> _copyMessage(String text) async {
    final l10n = AppLocalizations.of(context);
    if (text.trim().isEmpty) {
      _toast(l10n.obicAiNothingToCopy);
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    _toast(l10n.obicAiCopied);
  }

  void _stopAsk() {
    if (!_sending && _askAbort == null) return;
    _askSerial++;
    final abort = _askAbort;
    _askAbort = null;
    if (abort != null && !abort.isCompleted) {
      abort.complete();
    }
    if (mounted && _sending) {
      setState(() => _sending = false);
    }
  }

  _Turn _liveTurn(AiHistoryTurn t) => _Turn(
    role: t.role,
    text: t.text,
    isError: t.isError,
    createdAt: t.createdAt,
    attachmentKind: t.attachmentKind,
    attachmentName: t.attachmentName,
    attachmentMime: t.attachmentMime,
    attachmentPath: t.attachmentPath,
  );

  AiHistoryTurn _storedTurn(_Turn t) => AiHistoryTurn(
    role: t.role,
    text: t.text,
    isError: t.isError,
    createdAt: t.createdAt,
    attachmentKind: t.attachmentKind,
    attachmentName: t.attachmentName,
    attachmentMime: t.attachmentMime,
    attachmentPath: t.attachmentPath,
  );

  Future<void> _chooseAttachment() async {
    if (_sending) return;
    final l10n = AppLocalizations.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: Text(l10n.obicAiAttachPhoto),
                onTap: () => Navigator.pop(ctx, 'photo'),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: Text(l10n.obicAiAttachPdf),
                onTap: () => Navigator.pop(ctx, 'pdf'),
              ),
              ListTile(
                leading: const Icon(Icons.table_chart_outlined),
                title: Text(l10n.obicAiAttachSheet),
                onTap: () => Navigator.pop(ctx, 'sheet'),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case 'photo':
        await _pickPhoto();
      case 'pdf':
        await _pickDocument(const ['pdf']);
      case 'sheet':
        await _pickDocument(const ['csv', 'xls', 'xlsx']);
      default:
        return;
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final shot = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1280,
      );
      if (shot == null || !mounted) return;
      final name = shot.name.trim().isEmpty ? 'photo.jpg' : shot.name;
      await _stageAttachment(
        path: shot.path,
        filename: name,
        kind: 'image',
        mime: _mimeForAiName(name) ?? 'image/jpeg',
      );
    } catch (e) {
      if (!mounted) return;
      final token = classifyMediaPickError(e);
      if (token == 'cancelled') return;
      final l10n = AppLocalizations.of(context);
      _toast(
        token == 'photos_denied' || token == 'camera_denied'
            ? l10n.mediaPhotosPermissionDenied
            : l10n.mediaPickFailed,
      );
    }
  }

  Future<void> _pickDocument(List<String> extensions) async {
    try {
      final file = await openFile(
        acceptedTypeGroups: [XTypeGroup(label: 'file', extensions: extensions)],
      );
      if (file == null || !mounted) return;
      final mime = _mimeForAiName(file.name);
      if (mime == null || mime.startsWith('image/')) {
        _toast(AppLocalizations.of(context).obicAiUnsupportedFile);
        return;
      }
      await _stageAttachment(
        path: file.path,
        filename: file.name,
        kind: 'file',
        mime: mime,
      );
    } catch (e) {
      if (!mounted) return;
      if (classifyMediaPickError(e) == 'cancelled') return;
      _toast(AppLocalizations.of(context).mediaPickFailed);
    }
  }

  Future<void> _stageAttachment({
    required String path,
    required String filename,
    required String kind,
    required String mime,
  }) async {
    final l10n = AppLocalizations.of(context);
    final len = await localFileLength(path);
    if (!mounted) return;
    if (len == null) {
      _toast(l10n.obicAiCouldNotReadFile);
      return;
    }
    if (len > _kAiAttachMaxBytes) {
      _toast(l10n.obicAiFileTooLarge);
      return;
    }
    setState(() {
      _pending = _AiPendingAttachment(
        kind: kind,
        filename: filename,
        mime: mime,
        path: path,
      );
    });
  }

  Future<Map<String, String>?> _encodeAttachment(
    _AiPendingAttachment pending, {
    bool quiet = false,
  }) async {
    final l10n = AppLocalizations.of(context);
    try {
      final bytes = await File(pending.path).readAsBytes();
      if (!mounted) return null;
      if (bytes.length > _kAiAttachMaxBytes) {
        if (!quiet) _toast(l10n.obicAiFileTooLarge);
        return null;
      }
      if (bytes.isEmpty) {
        if (!quiet) _toast(l10n.obicAiCouldNotReadFile);
        return null;
      }
      return {
        'kind': pending.kind,
        'filename': pending.filename,
        'mime': pending.mime,
        'dataBase64': base64Encode(bytes),
      };
    } catch (_) {
      if (mounted && !quiet) _toast(l10n.obicAiCouldNotReadFile);
      return null;
    }
  }

  int? _lastUserIndex() {
    for (var i = _turns.length - 1; i >= 0; i--) {
      final turn = _turns[i];
      if (turn.role == 'user' &&
          (turn.text.trim().isNotEmpty || turn.attachmentKind != null)) {
        return i;
      }
    }
    return null;
  }

  int? _lastAssistantIndex() {
    for (var i = _turns.length - 1; i >= 0; i--) {
      if (_turns[i].role == 'assistant') return i;
    }
    return null;
  }

  String _historyContent(_Turn turn) {
    final text = turn.text.trim();
    final name = (turn.attachmentName ?? '').trim();
    if (turn.attachmentKind == 'image') {
      if (text.isEmpty) {
        return name.isEmpty
            ? 'User sent a photo.'
            : 'User sent a photo ($name).';
      }
      return name.isEmpty
          ? 'User sent a photo and wrote: $text'
          : 'User sent a photo ($name) and wrote: $text';
    }
    if (turn.attachmentKind == 'file') {
      if (text.isEmpty) {
        return name.isEmpty ? 'User sent a file.' : 'User sent a file ($name).';
      }
      return name.isEmpty
          ? 'User sent a file and wrote: $text'
          : 'User sent a file ($name) and wrote: $text';
    }
    return text;
  }

  List<Map<String, String>> _historyBefore(int index) {
    final history = <Map<String, String>>[];
    for (var i = 0; i < index && i < _turns.length; i++) {
      final turn = _turns[i];
      if (turn.isError) continue;
      final content = _historyContent(turn).trim();
      if (content.isEmpty) continue;
      history.add({'role': turn.role, 'content': content});
    }
    if (history.length > 6) {
      return history.sublist(history.length - 6);
    }
    return history;
  }

  /// The photo from a recent turn, so a follow-up still shows the model that image.
  Future<Map<String, String>?> _recentImageAttachment() async {
    final start = _turns.length > 6 ? _turns.length - 6 : 0;
    for (var i = _turns.length - 1; i >= start; i--) {
      final turn = _turns[i];
      if (turn.role != 'user' || turn.attachmentKind != 'image') continue;
      final path = turn.attachmentPath;
      final name = turn.attachmentName;
      final mime = turn.attachmentMime;
      if (path == null || name == null || mime == null) continue;
      if (path.isEmpty || name.isEmpty || mime.isEmpty) continue;
      return _encodeAttachment(
        _AiPendingAttachment(
          kind: 'image',
          filename: name,
          mime: mime,
          path: path,
        ),
        quiet: true,
      );
    }
    return null;
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    final pending = _pending;
    if ((text.isEmpty && pending == null) || _sending) return;
    Map<String, String>? wire;
    if (pending != null) {
      wire = await _encodeAttachment(pending);
      if (wire == null || !mounted) return;
    } else {
      wire = await _recentImageAttachment();
      if (!mounted) return;
    }
    final l10n = AppLocalizations.of(context);
    final userTurn = _Turn(
      role: 'user',
      text: text,
      createdAt: DateTime.now(),
      attachmentKind: pending?.kind,
      attachmentName: pending?.filename,
      attachmentMime: pending?.mime,
      attachmentPath: pending?.path,
    );
    if (ConnectivityService.instance.isOffline) {
      setState(() {
        _turns = [
          ..._turns,
          userTurn,
          _Turn(
            role: 'assistant',
            text: l10n.offlineNeedsNetwork,
            isError: true,
            createdAt: DateTime.now(),
          ),
        ];
        _pending = null;
      });
      _input.clear();
      _scrollToEnd();
      return;
    }
    setState(() {
      _turns = [..._turns, userTurn];
      _pending = null;
      _sending = true;
      _error = null;
    });
    _input.clear();
    _scrollToEnd();
    final userIndex = _turns.length - 1;
    await _dispatchAsk(
      message: text,
      history: _historyBefore(userIndex),
      attachment: wire,
    );
  }

  /// Resends the last user message. Replaces the latest assistant reply
  /// when one is already on screen. There is no regenerate API.
  Future<void> _retryLast() async {
    if (_sending) return;
    final userIndex = _lastUserIndex();
    if (userIndex == null) return;
    final userTurn = _turns[userIndex];
    final message = userTurn.text;
    Map<String, String>? wire;
    final path = userTurn.attachmentPath;
    final kind = userTurn.attachmentKind;
    final name = userTurn.attachmentName;
    final mime = userTurn.attachmentMime;
    if (path != null && kind != null && name != null && mime != null) {
      wire = await _encodeAttachment(
        _AiPendingAttachment(
          kind: kind,
          filename: name,
          mime: mime,
          path: path,
        ),
      );
      if (wire == null || !mounted) return;
    }
    final assistantIndex = _lastAssistantIndex();
    final replaceAt = assistantIndex != null && assistantIndex > userIndex
        ? assistantIndex
        : null;
    if (ConnectivityService.instance.isOffline) {
      final l10n = AppLocalizations.of(context);
      setState(() => _error = l10n.offlineNeedsNetwork);
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    await _dispatchAsk(
      message: message,
      history: _historyBefore(userIndex),
      replaceAssistantAt: replaceAt,
      attachment: wire,
    );
  }

  Future<void> _dispatchAsk({
    required String message,
    required List<Map<String, String>> history,
    int? replaceAssistantAt,
    Map<String, String>? attachment,
  }) async {
    final l10n = AppLocalizations.of(context);
    final serial = ++_askSerial;
    final abort = Completer<void>();
    _askAbort = abort;
    setState(() => _sending = true);
    try {
      final token = await widget.authController.ensureAccessToken();
      if (token == null) throw Exception('Not signed in');
      if (!mounted || serial != _askSerial) return;

      // Placeholder assistant bubble that fills in token-by-token. For a
      // retry, the previous reply stays until the first token lands.
      final replyIndex = replaceAssistantAt ?? _turns.length;
      var placeholderPlaced = replaceAssistantAt == null;
      if (placeholderPlaced) {
        setState(() {
          _turns = _withAssistantReply(
            _Turn(role: 'assistant', text: '', createdAt: DateTime.now()),
            replaceAssistantAt,
          );
        });
      }

      void paintStreaming(String text) {
        if (replyIndex < 0 || replyIndex >= _turns.length) return;
        final next = List<_Turn>.from(_turns);
        next[replyIndex] = _Turn(
          role: 'assistant',
          text: text,
          createdAt: next[replyIndex].createdAt,
        );
        _turns = next;
      }

      final buffer = StringBuffer();
      String? newThreadId;
      var gotDelta = false;
      var aiEnabled = true;
      try {
        await for (final event in _api.askStream(
          accessToken: token,
          message: message,
          locale: _localeCode,
          history: history,
          threadId: _isServerThreadId(_threadId) ? _threadId : null,
          attachment: attachment,
        )) {
          if (!mounted || serial != _askSerial) return;
          if (abort.isCompleted) throw const AiAskCancelled();
          final delta = event['delta'] as String?;
          if (delta != null && delta.isNotEmpty) {
            gotDelta = true;
            buffer.write(delta);
            if (!placeholderPlaced) {
              placeholderPlaced = true;
              setState(() {
                _turns = _withAssistantReply(
                  _Turn(
                    role: 'assistant',
                    text: '',
                    createdAt: DateTime.now(),
                  ),
                  replaceAssistantAt,
                );
              });
            }
            setState(() => paintStreaming(buffer.toString()));
            _scrollToEnd();
          }
          if (event['enabled'] == false) {
            aiEnabled = false;
            final reply = (event['reply'] as String?)?.trim() ?? '';
            if (reply.isNotEmpty && buffer.isEmpty) buffer.write(reply);
          }
          if (event['done'] == true) {
            newThreadId = (event['threadId'] as String?)?.trim();
            break;
          }
          final err = event['error'];
          if (err is String && err.isNotEmpty && buffer.isEmpty) {
            throw Exception(err);
          }
        }
      } catch (e) {
        if (e is AiAskCancelled) rethrow;
        if (buffer.isEmpty && !gotDelta) {
          // Streaming path unavailable (e.g. older server) — one-shot ask.
          final res = await _api.ask(
            accessToken: token,
            message: message,
            locale: _localeCode,
            history: history,
            threadId: _isServerThreadId(_threadId) ? _threadId : null,
            attachment: attachment,
            abortTrigger: abort.future,
          );
          if (!mounted || serial != _askSerial) return;
          aiEnabled = res['enabled'] != false;
          newThreadId = (res['threadId'] as String?)?.trim();
          final reply = (res['reply'] as String?)?.trim() ?? '';
          buffer.write(reply);
        } else if (buffer.isEmpty) {
          rethrow;
        }
        // Otherwise a partial reply already arrived — keep what we have.
      }

      if (!mounted || serial != _askSerial) return;
      if (identical(_askAbort, abort)) _askAbort = null;
      final streamedText = buffer.toString();
      setState(() {
        _enabled = aiEnabled;
        paintStreaming(
          streamedText.trim().isEmpty ? l10n.obicAiEmptyReply : streamedText,
        );
        _sending = false;
        _error = null;
        if (replaceAssistantAt != null) {
          _translations.remove(replaceAssistantAt);
          _translationHidden.remove(replaceAssistantAt);
          _translating.remove(replaceAssistantAt);
        }
      });
      await _persistCurrent(serverThreadId: newThreadId);
      _scrollToEnd();
    } on AiAskCancelled {
      if (!mounted || serial != _askSerial) return;
      setState(() => _sending = false);
    } catch (e) {
      if (!mounted || serial != _askSerial) return;
      final errText = ConnectivityService.instance.isOffline
          ? l10n.offlineNeedsNetwork
          : _friendlyError(e);
      final keepPrevious =
          replaceAssistantAt != null &&
          replaceAssistantAt < _turns.length &&
          !_turns[replaceAssistantAt].isError;
      setState(() {
        _sending = false;
        _error = errText;
        if (!keepPrevious) {
          // Drop the empty streaming placeholder; only the error shows.
          if (replaceAssistantAt == null &&
              _turns.isNotEmpty &&
              _turns.last.role == 'assistant' &&
              _turns.last.text.isEmpty) {
            _turns = _turns.sublist(0, _turns.length - 1);
          }
          _turns = _withAssistantReply(
            _Turn(
              role: 'assistant',
              text: errText,
              isError: true,
              createdAt: DateTime.now(),
            ),
            replaceAssistantAt,
          );
        }
      });
      _scrollToEnd();
    } finally {
      if (identical(_askAbort, abort)) _askAbort = null;
    }
  }

  List<_Turn> _withAssistantReply(_Turn reply, int? replaceAt) {
    final next = List<_Turn>.from(_turns);
    if (replaceAt != null && replaceAt >= 0 && replaceAt < next.length) {
      next[replaceAt] = reply;
      return next;
    }
    next.add(reply);
    return next;
  }

  Future<void> _translateTurn(int index) async {
    if (index < 0 || index >= _turns.length) return;
    final turn = _turns[index];
    if (turn.isError || turn.text.trim().isEmpty) return;
    final l10n = AppLocalizations.of(context);
    final cacheId = '${_threadId ?? 'live'}_$index';
    final target = _localeCode;
    final cached =
        TranslationCache.instance.get(cacheId, target) ?? _translations[index];
    if (cached != null && cached.isNotEmpty) {
      setState(() {
        _translations[index] = cached;
        _translationHidden.remove(index);
      });
      return;
    }
    if (ConnectivityService.instance.isOffline) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.offlineNeedsNetwork)));
      return;
    }
    if (_translating.contains(index)) return;
    setState(() => _translating.add(index));
    try {
      final token = await widget.authController.ensureAccessToken();
      if (token == null) throw Exception('Not signed in');
      final res = await _api.translate(
        accessToken: token,
        text: turn.text,
        targetLocale: target,
        messageId: cacheId,
      );
      final translation = (res['translation'] as String?)?.trim() ?? '';
      if (!mounted) return;
      if (translation.isEmpty) {
        setState(() => _translating.remove(index));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.msgTranslateFailed)));
        return;
      }
      TranslationCache.instance.put(cacheId, target, translation);
      setState(() {
        _translations[index] = translation;
        _translationHidden.remove(index);
        _translating.remove(index);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _translating.remove(index));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.msgTranslateFailed)));
    }
  }

  void _toggleAiOriginal(int index) {
    setState(() {
      if (_translationHidden.contains(index)) {
        _translationHidden.remove(index);
      } else {
        _translationHidden.add(index);
      }
    });
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: ObicColors.scaffoldOf(context),
      appBar: _ObicAiAppBar(
        tabs: _tabs,
        title: l10n.obicAiTitle,
        newChatTooltip: l10n.obicAiNewChat,
        onNewChat: _startNewChat,
        tabInstructions: l10n.obicAiTabInstructions,
        tabChat: l10n.obicAiTabChat,
        tabHistory: l10n.obicAiTabHistory,
        onClose: widget.onClose,
      ),
      body: Column(
        children: [
          if (_loadingStatus)
            const LinearProgressIndicator(minHeight: 2)
          else if (!_enabled)
            Material(
              color: ObicColors.blue.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Text(
                  l10n.obicAiOfflineHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _InstructionsPane(l10n: l10n),
                _ChatPane(
                  l10n: l10n,
                  turns: _turns,
                  sending: _sending,
                  error: _error,
                  scroll: _scroll,
                  input: _input,
                  onSend: _send,
                  onStop: _stopAsk,
                  onAttach: _chooseAttachment,
                  onClearPending: () => setState(() => _pending = null),
                  pending: _pending,
                  onCopy: _copyMessage,
                  onRetry: _retryLast,
                  translations: _translations,
                  translating: _translating,
                  translationHidden: _translationHidden,
                  onTranslate: _translateTurn,
                  onToggleOriginal: _toggleAiOriginal,
                ),
                _HistoryPane(
                  l10n: l10n,
                  loading: _loadingHistory,
                  threads: _history,
                  activeId: _threadId,
                  onOpen: _openThread,
                  onDelete: _deleteThread,
                  onNewChat: _startNewChat,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Isolated AppBar so chat stream/setState ticks don't remount leading/actions.
class _ObicAiAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ObicAiAppBar({
    required this.tabs,
    required this.title,
    required this.newChatTooltip,
    required this.onNewChat,
    required this.tabInstructions,
    required this.tabChat,
    required this.tabHistory,
    this.onClose,
  });

  final TabController tabs;
  final String title;
  final String newChatTooltip;
  final VoidCallback onNewChat;
  final String tabInstructions;
  final String tabChat;
  final String tabHistory;
  final VoidCallback? onClose;

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight + kTextTabBarHeight);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onBar = scheme.onSurface;
    final onBarMuted = onBar.withValues(alpha: 0.62);
    return AppBar(
      foregroundColor: onBar,
      iconTheme: IconThemeData(color: onBar),
      actionsIconTheme: IconThemeData(color: onBar),
      titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: onBar,
        fontWeight: FontWeight.w600,
      ),
      leading: onClose != null
          ? IconButton(
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded),
            )
          : null,
      title: Text(title),
      actions: [
        ListenableBuilder(
          listenable: tabs,
          builder: (context, _) {
            if (tabs.index != 1 && tabs.index != 2) {
              return const SizedBox.shrink();
            }
            return IconButton(
              tooltip: newChatTooltip,
              onPressed: onNewChat,
              icon: const Icon(Icons.edit_note_outlined),
            );
          },
        ),
      ],
      bottom: TabBar(
        controller: tabs,
        labelColor: onBar,
        unselectedLabelColor: onBarMuted,
        indicatorColor: ObicColors.blue,
        tabs: [
          Tab(text: tabInstructions),
          Tab(text: tabChat),
          Tab(text: tabHistory),
        ],
      ),
    );
  }
}

class _InstructionsPane extends StatelessWidget {
  const _InstructionsPane({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Text(
          l10n.obicAiInstructionsTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: ObicColors.titleOf(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.obicAiInstructionsBody,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: ObicColors.inkOf(context),
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _ChatPane extends StatelessWidget {
  const _ChatPane({
    required this.l10n,
    required this.turns,
    required this.sending,
    required this.error,
    required this.scroll,
    required this.input,
    required this.onSend,
    required this.onStop,
    required this.onAttach,
    required this.onClearPending,
    required this.pending,
    required this.onCopy,
    required this.onRetry,
    required this.translations,
    required this.translating,
    required this.translationHidden,
    required this.onTranslate,
    required this.onToggleOriginal,
  });

  final AppLocalizations l10n;
  final List<_Turn> turns;
  final bool sending;
  final String? error;
  final ScrollController scroll;
  final TextEditingController input;
  final VoidCallback onSend;
  final VoidCallback onStop;
  final VoidCallback onAttach;
  final VoidCallback onClearPending;
  final _AiPendingAttachment? pending;
  final Future<void> Function(String text) onCopy;
  final VoidCallback onRetry;
  final Map<int, String> translations;
  final Set<int> translating;
  final Set<int> translationHidden;
  final ValueChanged<int> onTranslate;
  final ValueChanged<int> onToggleOriginal;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            children: [
              if (turns.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Text(
                    l10n.obicAiWelcome,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ObicColors.mutedOf(context),
                    ),
                  ),
                ),
              ..._aiTimelineChildren(
                turns: turns,
                sending: sending,
                l10n: l10n,
                localeName: Localizations.localeOf(context).toString(),
                translations: translations,
                translating: translating,
                translationHidden: translationHidden,
                onTranslate: onTranslate,
                onToggleOriginal: onToggleOriginal,
                onCopy: onCopy,
                onRetry: onRetry,
              ),
              if (sending)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: onStop,
                          style: TextButton.styleFrom(
                            foregroundColor: ObicColors.blue,
                            visualDensity: VisualDensity.compact,
                          ),
                          child: Text(l10n.obicAiStop),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (pending != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        _pendingThumb(pending!),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            pending!.filename,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.obicAiRemoveAttachment,
                          onPressed: sending ? null : onClearPending,
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    IconButton(
                      tooltip: l10n.obicAiAttach,
                      onPressed: sending ? null : onAttach,
                      icon: const Icon(Icons.attach_file_rounded),
                    ),
                    Expanded(
                      child: TextField(
                        controller: input,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => onSend(),
                        decoration: InputDecoration(
                          hintText: l10n.obicAiInputHint,
                          filled: true,
                          fillColor: ObicColors.surfaceOf(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: sending ? l10n.obicAiStop : null,
                      onPressed: sending ? onStop : onSend,
                      style: IconButton.styleFrom(
                        backgroundColor: ObicColors.blue,
                        foregroundColor: Colors.white,
                      ),
                      icon: Icon(
                        sending ? Icons.stop_rounded : Icons.send_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryPane extends StatelessWidget {
  const _HistoryPane({
    required this.l10n,
    required this.loading,
    required this.threads,
    required this.activeId,
    required this.onOpen,
    required this.onDelete,
    required this.onNewChat,
  });

  final AppLocalizations l10n;
  final bool loading;
  final List<AiHistoryThread> threads;
  final String? activeId;
  final ValueChanged<AiHistoryThread> onOpen;
  final ValueChanged<AiHistoryThread> onDelete;
  final VoidCallback onNewChat;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (threads.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.obicAiHistoryEmpty,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ObicColors.mutedOf(context),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onNewChat,
              child: Text(l10n.obicAiNewChat),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: threads.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final t = threads[i];
        final selected = t.id == activeId;
        final dark = ObicColors.isDark(context);
        return Material(
          color: selected
              ? ObicColors.blue.withValues(alpha: dark ? 0.28 : 0.10)
              : ObicColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onOpen(t),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.title.isEmpty ? l10n.obicAiTitle : t.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ObicColors.titleOf(context),
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatWhen(t.updatedAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: ObicColors.titleOf(
                              context,
                            ).withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.obicAiHistoryDelete,
                    onPressed: () => onDelete(t),
                    icon: Icon(
                      Icons.delete_outline,
                      color: ObicColors.titleOf(
                        context,
                      ).withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String _formatWhen(DateTime dt) {
    final local = dt.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }
}

List<Widget> _aiTimelineChildren({
  required List<_Turn> turns,
  required bool sending,
  required AppLocalizations l10n,
  required String localeName,
  required Map<int, String> translations,
  required Set<int> translating,
  required Set<int> translationHidden,
  required ValueChanged<int> onTranslate,
  required ValueChanged<int> onToggleOriginal,
  required Future<void> Function(String text) onCopy,
  required VoidCallback onRetry,
}) {
  var lastAssistant = -1;
  var lastUser = -1;
  for (var i = turns.length - 1; i >= 0; i--) {
    if (lastAssistant < 0 && turns[i].role == 'assistant') lastAssistant = i;
    if (lastUser < 0 &&
        turns[i].role == 'user' &&
        (turns[i].text.trim().isNotEmpty || turns[i].attachmentKind != null)) {
      lastUser = i;
    }
    if (lastAssistant >= 0 && lastUser >= 0) break;
  }
  final out = <Widget>[];
  DateTime? prevAt;
  for (var i = 0; i < turns.length; i++) {
    final turn = turns[i];
    final at = turn.createdAt;
    if (at != null && chatNeedsDaySeparator(prevAt, at)) {
      out.add(
        ChatDaySeparatorChip(
          label: chatDaySeparatorLabel(at, l10n: l10n, localeName: localeName),
        ),
      );
    }
    if (at != null) prevAt = at;
    final canRetry =
        !sending &&
        lastUser >= 0 &&
        ((lastAssistant > lastUser && i == lastAssistant) ||
            (lastAssistant < lastUser && i == lastUser));
    out.add(
      _Bubble(
        turn: turn,
        l10n: l10n,
        translation: translations[i],
        translating: translating.contains(i),
        showTranslation:
            translations[i] != null &&
            translations[i]!.isNotEmpty &&
            !translationHidden.contains(i),
        showCopy: turn.role == 'assistant',
        showRetry: canRetry,
        showTranslate:
            !turn.isError &&
            turn.attachmentKind != 'image' &&
            turn.text.trim().isNotEmpty,
        onCopy: () {
          unawaited(onCopy(turn.text));
        },
        onRetry: onRetry,
        onTranslate: () => onTranslate(i),
        onToggleOriginal: () => onToggleOriginal(i),
      ),
    );
  }
  return out;
}

const int _kAiAttachMaxBytes = 4 * 1024 * 1024;

String? _mimeForAiName(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.pdf')) return 'application/pdf';
  if (lower.endsWith('.csv')) return 'text/csv';
  if (lower.endsWith('.xlsx')) {
    return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
  }
  if (lower.endsWith('.xls')) return 'application/vnd.ms-excel';
  return null;
}

class _AiPendingAttachment {
  const _AiPendingAttachment({
    required this.kind,
    required this.filename,
    required this.mime,
    required this.path,
  });

  final String kind;
  final String filename;
  final String mime;
  final String path;
}

class _Turn {
  const _Turn({
    required this.role,
    required this.text,
    this.isError = false,
    this.createdAt,
    this.attachmentKind,
    this.attachmentName,
    this.attachmentMime,
    this.attachmentPath,
  });

  final String role;
  final String text;
  final bool isError;
  final DateTime? createdAt;
  final String? attachmentKind;
  final String? attachmentName;
  final String? attachmentMime;
  final String? attachmentPath;
}

Widget _pendingThumb(_AiPendingAttachment pending) {
  if (pending.kind == 'image') {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        File(pending.path),
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.image_outlined),
      ),
    );
  }
  return const Icon(Icons.insert_drive_file_outlined);
}

Widget _bubbleBody(_Turn turn, Color fg) {
  final attachment = _turnAttachment(turn, fg);
  final textWidget = Text(
    turn.text,
    textDirection: RegExp(r'[\u0600-\u06FF]').hasMatch(turn.text)
        ? TextDirection.rtl
        : TextDirection.ltr,
    style: TextStyle(color: fg, height: 1.35),
  );
  if (attachment == null) return textWidget;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      attachment,
      if (turn.text.trim().isNotEmpty) ...[
        const SizedBox(height: 8),
        textWidget,
      ],
    ],
  );
}

Widget? _turnAttachment(_Turn turn, Color fg) {
  final kind = turn.attachmentKind;
  final name = turn.attachmentName;
  final path = turn.attachmentPath;
  if (kind == null && (name == null || name.isEmpty)) return null;
  if (kind == 'image' && path != null && path.isNotEmpty) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.file(
        File(path),
        width: 180,
        height: 140,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _attachmentChip(fg, name ?? 'photo'),
      ),
    );
  }
  if (name == null || name.isEmpty) return null;
  return _attachmentChip(fg, name);
}

Widget _attachmentChip(Color fg, String name) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.insert_drive_file_outlined, size: 18, color: fg),
      const SizedBox(width: 6),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 180),
        child: Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: fg, fontSize: 13),
        ),
      ),
    ],
  );
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.turn,
    required this.l10n,
    required this.translation,
    required this.translating,
    required this.showTranslation,
    required this.showCopy,
    required this.showRetry,
    required this.showTranslate,
    required this.onCopy,
    required this.onRetry,
    required this.onTranslate,
    required this.onToggleOriginal,
  });

  final _Turn turn;
  final AppLocalizations l10n;
  final String? translation;
  final bool translating;
  final bool showTranslation;
  final bool showCopy;
  final bool showRetry;
  final bool showTranslate;
  final VoidCallback onCopy;
  final VoidCallback onRetry;
  final VoidCallback onTranslate;
  final VoidCallback onToggleOriginal;

  @override
  Widget build(BuildContext context) {
    final mine = turn.role == 'user';
    final bg = turn.isError
        ? Theme.of(context).colorScheme.errorContainer
        : mine
        ? ObicColors.blue
        : ObicColors.surfaceRaisedOf(context);
    final fg = turn.isError
        ? Theme.of(context).colorScheme.onErrorContainer
        : mine
        ? Colors.white
        : ObicColors.inkOf(context);
    // Physical left/right (WeChat): mine always on the right, even in Arabic RTL.
    final maxW = MediaQuery.sizeOf(context).width - 48;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: mine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: onCopy,
            child: Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(maxWidth: maxW * 0.85),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(16),
                boxShadow: mine
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: _bubbleBody(turn, fg),
            ),
          ),
          if (showCopy || showRetry || showTranslate)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Wrap(
                spacing: 2,
                runSpacing: 2,
                children: [
                  if (showCopy)
                    _AiMiniAction(
                      icon: Icons.copy_rounded,
                      label: l10n.obicAiCopy,
                      onPressed: onCopy,
                    ),
                  if (showRetry)
                    _AiMiniAction(
                      icon: Icons.refresh_rounded,
                      label: l10n.obicAiRetry,
                      onPressed: onRetry,
                    ),
                  if (showTranslate)
                    _AiMiniAction(
                      icon: Icons.translate_rounded,
                      label: l10n.msgTranslate,
                      onPressed: onTranslate,
                    ),
                ],
              ),
            ),
          if (translating)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                l10n.msgTranslating,
                style: TextStyle(
                  fontSize: 11,
                  color: ObicColors.mutedOf(context),
                ),
              ),
            ),
          if (showTranslation && translation != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW * 0.85),
                child: Text(
                  translation!,
                  textDirection:
                      RegExp(r'[\u0600-\u06FF]').hasMatch(translation!)
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: ObicColors.titleOf(context).withValues(alpha: 0.72),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextButton(
                onPressed: onToggleOriginal,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: ObicColors.blue,
                ),
                child: Text(
                  l10n.msgShowOriginal,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ] else if (translation != null && translation!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextButton(
                onPressed: onToggleOriginal,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: ObicColors.blue,
                ),
                child: Text(
                  l10n.msgShowTranslation,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AiMiniAction extends StatelessWidget {
  const _AiMiniAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: ObicColors.blue,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(icon, size: 15),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
