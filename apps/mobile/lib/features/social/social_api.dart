// Made by Dr Ali
// Phase 3 social clients — chat, moments, notifications, friends (JWT where needed).

import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../core/api_config.dart';
import '../../core/obic_http.dart';
import '../auth/auth_api.dart';

class SocialApi {
  SocialApi({http.Client? client, String? baseUrl})
    : _client = client ?? obicHttpClient(),
      _baseUrl = (baseUrl ?? kApiBaseUrl).replaceAll(RegExp(r'/$'), '');

  final http.Client _client;
  final String _baseUrl;

  /// Trial cold starts can be slow; keep below auth’s 90s but not infinite.
  static const Duration _kRequestTimeout = Duration(seconds: 45);

  Uri _uri(String path, [Map<String, String>? query]) {
    final u = Uri.parse('$_baseUrl$path');
    if (query == null || query.isEmpty) return u;
    return u.replace(queryParameters: query);
  }

  Map<String, String> _authHeaders(String accessToken) => {
    'Authorization': 'Bearer $accessToken',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Future<List<Map<String, dynamic>>> listThreads(String accessToken) async {
    return _getList('/v1/chat/threads', accessToken);
  }

  /// Staff company directory. Customers receive 403.
  Future<List<Map<String, dynamic>>> listDirectory(String accessToken) {
    return _getList('/v1/directory', accessToken);
  }

  Future<List<Map<String, dynamic>>> listApprovalTemplates(String accessToken) {
    return _getList('/v1/approvals/templates', accessToken);
  }

  Future<List<Map<String, dynamic>>> listApprovals(String accessToken) {
    return _getList('/v1/approvals', accessToken);
  }

  Future<Map<String, dynamic>> openApproval({
    required String accessToken,
    required String templateId,
    required String title,
    String? body,
  }) {
    return _postJson('/v1/approvals', accessToken, {
      'templateId': templateId,
      'title': title,
      if (body != null && body.isNotEmpty) 'body': body,
    });
  }

  Future<Map<String, dynamic>> decideApproval({
    required String accessToken,
    required String requestId,
    required String decision,
    String? comment,
  }) {
    return _postJson('/v1/approvals/$requestId/decide', accessToken, {
      'decision': decision,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });
  }

  Future<Map<String, dynamic>> cancelApproval({
    required String accessToken,
    required String requestId,
  }) {
    return _postJson('/v1/approvals/$requestId/cancel', accessToken, {});
  }

  Future<Map<String, dynamic>> attendanceHome(String accessToken) {
    return _getMap('/v1/attendance', accessToken);
  }

  Future<Map<String, dynamic>> punchAttendance({
    required String accessToken,
    required String kind,
    String? note,
  }) {
    return _postJson('/v1/attendance/punch', accessToken, {
      'kind': kind,
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  Future<Map<String, dynamic>> reportsHome(String accessToken) {
    return _getMap('/v1/reports', accessToken);
  }

  Future<Map<String, dynamic>> submitReport({
    required String accessToken,
    required String kind,
    required String done,
    required String plan,
    String? blockers,
  }) {
    return _postJson('/v1/reports', accessToken, {
      'kind': kind,
      'done': done,
      'plan': plan,
      if (blockers != null && blockers.isNotEmpty) 'blockers': blockers,
    });
  }

  Future<Map<String, dynamic>> officeFormsHome(String accessToken) {
    return _getMap('/v1/office-forms', accessToken);
  }

  Future<Map<String, dynamic>> submitOfficeForm({
    required String accessToken,
    required String formId,
    required Map<String, String> answers,
  }) {
    return _postJson('/v1/office-forms', accessToken, {
      'formId': formId,
      'answers': answers,
    });
  }

  Future<Map<String, dynamic>> collectionFormsHome(String accessToken) {
    return _getMap('/v1/collection-forms', accessToken);
  }

  Future<Map<String, dynamic>> submitCollectionForm({
    required String accessToken,
    required String collectionId,
    required Map<String, String> answers,
  }) {
    return _postJson('/v1/collection-forms/$collectionId', accessToken, {
      'answers': answers,
    });
  }

  Future<Map<String, dynamic>> meetingRoomsHome(String accessToken) {
    return _getMap('/v1/meeting-rooms', accessToken);
  }

  Future<Map<String, dynamic>> bookMeetingRoom({
    required String accessToken,
    required String roomId,
    required String title,
    required DateTime startsAt,
    required DateTime endsAt,
  }) {
    return _postJson('/v1/meeting-rooms/bookings', accessToken, {
      'roomId': roomId,
      'title': title,
      'startsAt': startsAt.toUtc().toIso8601String(),
      'endsAt': endsAt.toUtc().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>> cancelMeetingBooking({
    required String accessToken,
    required String bookingId,
  }) {
    return _postJson('/v1/meeting-rooms/bookings/$bookingId/cancel', accessToken, {});
  }

  Future<Map<String, dynamic>> rosterHome(String accessToken) {
    return _getMap('/v1/roster', accessToken);
  }

  Future<Map<String, dynamic>> requestRosterLeave({
    required String accessToken,
    required String lastDay,
    String? note,
  }) {
    final body = <String, dynamic>{'lastDay': lastDay};
    final trimmed = note?.trim() ?? '';
    if (trimmed.isNotEmpty) body['note'] = trimmed;
    return _postJson('/v1/roster/leave', accessToken, body);
  }

  Future<Map<String, dynamic>> payslipsHome(String accessToken) {
    return _getMap('/v1/payslips', accessToken);
  }

  Future<Map<String, dynamic>> acknowledgePayslip({
    required String accessToken,
    required String payslipId,
  }) {
    return _postJson('/v1/payslips/$payslipId/acknowledge', accessToken, {});
  }

  Future<Map<String, dynamic>> companyContactsHome(String accessToken, {String? query}) {
    final q = query?.trim() ?? '';
    final path = q.isEmpty
        ? '/v1/company-contacts'
        : '/v1/company-contacts?q=${Uri.encodeQueryComponent(q)}';
    return _getMap(path, accessToken);
  }

  Future<Map<String, dynamic>> createCompanyContact({
    required String accessToken,
    required String name,
    String? phone,
    String? orgName,
    String? note,
  }) {
    return _postJson('/v1/company-contacts', accessToken, {
      'name': name,
      'phone': phone?.trim() ?? '',
      'orgName': orgName?.trim() ?? '',
      'note': note?.trim() ?? '',
      'active': true,
    });
  }

  Future<Map<String, dynamic>> updateCompanyContact({
    required String accessToken,
    required String contactId,
    required String name,
    String? phone,
    String? orgName,
    String? note,
    required bool active,
  }) {
    return _patchJson('/v1/company-contacts/$contactId', accessToken, {
      'name': name,
      'phone': phone?.trim() ?? '',
      'orgName': orgName?.trim() ?? '',
      'note': note?.trim() ?? '',
      'active': active,
    });
  }

  Future<Map<String, dynamic>> companyContactTagsHome(String accessToken) {
    return _getMap('/v1/company-contact-tags', accessToken);
  }

  Future<Map<String, dynamic>> setCompanyContactTags({
    required String accessToken,
    required String contactId,
    required List<String> tagIds,
  }) {
    return _putJson('/v1/company-contact-tags/contacts/$contactId', accessToken, {
      'tagIds': tagIds,
    });
  }

  Future<Map<String, dynamic>> companyContactGroupsHome(String accessToken) {
    return _getMap('/v1/company-contact-groups', accessToken);
  }

  Future<Map<String, dynamic>> createCompanyContactGroup({
    required String accessToken,
    required String name,
    String? note,
    required List<String> contactIds,
  }) {
    return _postJson('/v1/company-contact-groups', accessToken, {
      'name': name,
      'note': note?.trim() ?? '',
      'active': true,
      'contactIds': contactIds,
    });
  }

  Future<Map<String, dynamic>> updateCompanyContactGroup({
    required String accessToken,
    required String groupId,
    required String name,
    String? note,
    required bool active,
    required List<String> contactIds,
  }) {
    return _patchJson('/v1/company-contact-groups/$groupId', accessToken, {
      'name': name,
      'note': note?.trim() ?? '',
      'active': active,
      'contactIds': contactIds,
    });
  }

  Future<Map<String, dynamic>> companyWelcomesHome(String accessToken) {
    return _getMap('/v1/company-welcomes', accessToken);
  }

  Future<Map<String, dynamic>> quickRepliesHome(String accessToken) {
    return _getMap('/v1/quick-replies', accessToken);
  }

  Future<Map<String, dynamic>> companyHandoversHome(String accessToken) {
    return _getMap('/v1/company-handovers', accessToken);
  }

  Future<Map<String, dynamic>> companyDriveHome(String accessToken) {
    return _getMap('/v1/company-drive', accessToken);
  }

  Future<Map<String, dynamic>> companyDocumentsHome(String accessToken) {
    return _getMap('/v1/company-documents', accessToken);
  }

  Future<Map<String, dynamic>> companyDocument(String accessToken, String documentId) {
    return _getMap('/v1/company-documents/$documentId', accessToken);
  }

  Future<Map<String, dynamic>> updateCompanyDocument({
    required String accessToken,
    required String documentId,
    required String body,
  }) {
    return _patchJson('/v1/company-documents/$documentId', accessToken, {'body': body});
  }

  Future<Map<String, dynamic>> companySpreadsheetsHome(String accessToken) {
    return _getMap('/v1/company-spreadsheets', accessToken);
  }

  Future<Map<String, dynamic>> companySpreadsheet(String accessToken, String sheetId) {
    return _getMap('/v1/company-spreadsheets/$sheetId', accessToken);
  }

  Future<Map<String, dynamic>> updateCompanySpreadsheet({
    required String accessToken,
    required String sheetId,
    required List<List<String>> rows,
  }) {
    return _patchJson('/v1/company-spreadsheets/$sheetId', accessToken, {'rows': rows});
  }

  Future<Map<String, dynamic>> companyCalendarHome(String accessToken) {
    return _getMap('/v1/company-calendar', accessToken);
  }

  Future<Map<String, dynamic>> createCompanyCalendarEvent({
    required String accessToken,
    required String title,
    required String date,
    required String start,
    required String end,
    required String note,
  }) {
    return _postJson('/v1/company-calendar', accessToken, {
      'title': title,
      'date': date,
      'start': start,
      'end': end,
      if (note.isNotEmpty) 'note': note,
    });
  }

  Future<Map<String, dynamic>> updateCompanyCalendarEvent({
    required String accessToken,
    required String eventId,
    required String title,
    required String date,
    required String start,
    required String end,
    required String note,
    required bool active,
  }) {
    return _patchJson('/v1/company-calendar/$eventId', accessToken, {
      'title': title,
      'date': date,
      'start': start,
      'end': end,
      'note': note,
      'active': active,
    });
  }

  Future<Map<String, dynamic>> companyMailHome(String accessToken) {
    return _getMap('/v1/company-mail', accessToken);
  }

  Future<Map<String, dynamic>> sendCompanyMail({
    required String accessToken,
    required String subject,
    required String body,
    required List<String> userIds,
  }) {
    return _postJson('/v1/company-mail', accessToken, {
      'subject': subject,
      'body': body,
      'userIds': userIds,
    });
  }

  Future<Map<String, dynamic>> markCompanyMailRead({
    required String accessToken,
    required String messageId,
  }) {
    return _postJson('/v1/company-mail/$messageId/read', accessToken, {});
  }

  Future<Map<String, dynamic>> companyMeetingsHome(String accessToken) {
    return _getMap('/v1/company-meetings', accessToken);
  }

  Future<Map<String, dynamic>> createCompanyMeeting({
    required String accessToken,
    required String title,
    required String date,
    required String start,
    required String end,
    required String agenda,
    required String notes,
    required List<String> userIds,
  }) {
    return _postJson('/v1/company-meetings', accessToken, {
      'title': title,
      'date': date,
      'start': start,
      'end': end,
      if (agenda.isNotEmpty) 'agenda': agenda,
      if (notes.isNotEmpty) 'notes': notes,
      'userIds': userIds,
    });
  }

  Future<Map<String, dynamic>> updateCompanyMeeting({
    required String accessToken,
    required String meetingId,
    required String title,
    required String date,
    required String start,
    required String end,
    required String agenda,
    required String notes,
    required bool active,
    required List<String> userIds,
  }) {
    return _patchJson('/v1/company-meetings/$meetingId', accessToken, {
      'title': title,
      'date': date,
      'start': start,
      'end': end,
      'agenda': agenda,
      'notes': notes,
      'active': active,
      'userIds': userIds,
    });
  }

  Future<Map<String, dynamic>> companyFileAnswersHome(String accessToken) {
    return _getMap('/v1/company-file-answers', accessToken);
  }

  Future<Map<String, dynamic>> askCompanyFiles({
    required String accessToken,
    required String question,
  }) {
    return _postJson('/v1/company-file-answers', accessToken, {'question': question});
  }

  Future<Map<String, dynamic>> companyAppsHome(String accessToken) {
    return _getMap('/v1/company-apps', accessToken);
  }

  Future<Map<String, dynamic>> companyDriveFolder(String accessToken, String folderId) {
    return _getMap('/v1/company-drive/folders/$folderId', accessToken);
  }

  Future<Map<String, dynamic>> uploadDriveFile({
    required String accessToken,
    required String folderId,
    required String path,
    required String filename,
  }) async {
    final req = http.MultipartRequest('POST', _uri('/v1/company-drive/folders/$folderId/files'));
    req.headers['Authorization'] = 'Bearer $accessToken';
    req.headers['Accept'] = 'application/json';
    req.files.add(await http.MultipartFile.fromPath('file', path, filename: filename));
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    return _decodeMap(res, 'Drive');
  }

  Future<Uint8List> downloadDriveFile({
    required String accessToken,
    required String fileId,
  }) async {
    final res = await _client
        .get(
          _uri('/v1/company-drive/files/$fileId'),
          headers: {'Authorization': 'Bearer $accessToken', 'Accept': '*/*'},
        )
        .timeout(_kRequestTimeout);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AuthApiException('Drive failed (${res.statusCode})', statusCode: res.statusCode);
    }
    return res.bodyBytes;
  }

  Future<Map<String, dynamic>> createQuickReply({
    required String accessToken,
    required String title,
    required String body,
  }) {
    return _postJson('/v1/quick-replies', accessToken, {
      'title': title,
      'body': body,
      'active': true,
    });
  }

  Future<Map<String, dynamic>> updateQuickReply({
    required String accessToken,
    required String replyId,
    required String title,
    required String body,
    required bool active,
  }) {
    return _patchJson('/v1/quick-replies/$replyId', accessToken, {
      'title': title,
      'body': body,
      'active': active,
    });
  }

  Future<Map<String, dynamic>> openSupportThread(String accessToken) async {
    return _postJson('/v1/chat/threads', accessToken, {'kind': 'support'});
  }

  Future<Map<String, dynamic>> openDirectThread({
    required String accessToken,
    required String peerUserId,
  }) async {
    return _postJson('/v1/chat/threads', accessToken, {
      'kind': 'direct',
      'peerUserId': peerUserId,
    });
  }

  /// Staff: create a service group (customer + assistants).
  Future<Map<String, dynamic>> createGroupThread({
    required String accessToken,
    required String title,
    required List<String> memberUserIds,
  }) async {
    return _postJson('/v1/chat/threads', accessToken, {
      'kind': 'group',
      'title': title,
      'memberUserIds': memberUserIds,
    });
  }

  Future<Map<String, dynamic>> addGroupMembers({
    required String accessToken,
    required String threadId,
    required List<String> userIds,
  }) async {
    return _postJson('/v1/chat/threads/$threadId/members', accessToken, {
      'userIds': userIds,
    });
  }

  Future<Map<String, dynamic>> liveLocation({
    required String accessToken,
    required String conversationId,
    required double lat,
    required double lng,
    double? accuracy,
    int? minutes,
  }) async {
    return _postJson('/v1/chat/live-location', accessToken, {
      'conversationId': conversationId,
      'lat': lat,
      'lng': lng,
      if (accuracy != null) 'accuracy': accuracy,
      if (minutes != null) 'minutes': minutes,
    });
  }

  Future<Map<String, dynamic>> stopLiveLocation({
    required String accessToken,
    required String conversationId,
  }) async {
    return _postJson('/v1/chat/live-location/stop', accessToken, {
      'conversationId': conversationId,
    });
  }

  Future<List<Map<String, dynamic>>> listLiveLocation({
    required String accessToken,
    required String conversationId,
  }) async {
    final json = await _getMap('/v1/chat/live-location', accessToken, {
      'conversationId': conversationId,
    });
    final shares = json['shares'];
    if (shares is! List) return [];
    return shares.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Future<List<Map<String, dynamic>>> listMessages({
    required String accessToken,
    required String threadId,
    String? since,
  }) async {
    return _getList(
      '/v1/chat/threads/$threadId/messages',
      accessToken,
      since == null || since.isEmpty ? null : {'since': since},
    );
  }

  /// Registers this phone for push. Older trial servers return 404; ignore that.
  Future<bool> registerPushDevice({
    required String accessToken,
    required String platform,
    required String token,
  }) async {
    try {
      await _postJson('/v1/push/devices', accessToken, {
        'platform': platform,
        'token': token,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> sendMessage({
    required String accessToken,
    required String threadId,
    String? body,
    String attachmentKind = 'none',
    String? attachmentName,
    String? attachmentUrl,
    String? locale,
  }) async {
    return _postJson('/v1/chat/threads/$threadId/messages', accessToken, {
      'body': ?body,
      'attachmentKind': attachmentKind,
      'attachmentName': ?attachmentName,
      'attachmentUrl': ?attachmentUrl,
      'locale': ?locale,
    });
  }

  /// Staff: pause or resume AI auto-reply on a support/order thread.
  Future<Map<String, dynamic>> updateThreadPrefs({
    required String accessToken,
    required String threadId,
    bool? muted,
    bool? hidden,
    bool? pinned,
    bool? markUnread,
    bool? clearHistory,
    bool? deleteChat,
  }) async {
    return _patchJson('/v1/chat/threads/$threadId/prefs', accessToken, {
      if (muted != null) 'muted': muted,
      if (hidden != null) 'hidden': hidden,
      if (pinned != null) 'pinned': pinned,
      if (markUnread != null) 'markUnread': markUnread,
      if (clearHistory != null) 'clearHistory': clearHistory,
      if (deleteChat != null) 'deleteChat': deleteChat,
    });
  }

  /// WeChat recall — sender only, within ~2 minutes (server enforces).
  Future<Map<String, dynamic>> recallMessage({
    required String accessToken,
    required String threadId,
    required String messageId,
  }) async {
    return _postJson(
      '/v1/chat/threads/$threadId/messages/$messageId/recall',
      accessToken,
      const <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> submitBugReport({
    required String accessToken,
    required String description,
    List<String>? photoUrls,
  }) async {
    return _postJson('/v1/bug-reports', accessToken, {
      'description': description,
      if (photoUrls != null && photoUrls.isNotEmpty) 'photoUrls': photoUrls,
    });
  }

  Future<Map<String, dynamic>> setAiAutoReply({
    required String accessToken,
    required String threadId,
    required bool enabled,
  }) async {
    return _patchJson('/v1/chat/threads/$threadId/ai-auto-reply', accessToken, {
      'enabled': enabled,
    });
  }

  /// Customer: pause AI, route to desk / order assignee, notify staff.
  /// Support requires [branch] + [serviceKey] (handoff form). Order may omit.
  Future<Map<String, dynamic>> requestStaff({
    required String accessToken,
    required String threadId,
    String? locale,
    String? branch,
    String? serviceKey,
    String? orderRef,
    String? note,
  }) async {
    return _postJson('/v1/chat/threads/$threadId/request-staff', accessToken, {
      'locale': ?locale,
      'branch': ?branch,
      'serviceKey': ?serviceKey,
      'orderRef': ?orderRef,
      'note': ?note,
    });
  }

  /// Staff: list same-branch desk employees to invite into support/order chat.
  Future<Map<String, dynamic>> listInviteCandidates({
    required String accessToken,
    required String threadId,
  }) async {
    return _getMap('/v1/chat/threads/$threadId/invite-candidates', accessToken);
  }

  /// Staff: add desk employees to an existing support/order thread.
  Future<Map<String, dynamic>> addParticipants({
    required String accessToken,
    required String threadId,
    required List<String> userIds,
  }) async {
    return _postJson('/v1/chat/threads/$threadId/participants', accessToken, {
      'userIds': userIds,
    });
  }

  Future<Map<String, dynamic>> reportContent({
    required String accessToken,
    required String targetType,
    required String targetId,
    String? reason,
  }) async {
    return _postJson('/v1/moderation/reports', accessToken, {
      'targetType': targetType,
      'targetId': targetId,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
  }

  /// Browse Moments — pass JWT when signed in so likedByMe is accurate.
  Future<List<Map<String, dynamic>>> listMoments({String? accessToken}) async {
    final res = await _client.get(
      _uri('/v1/moments'),
      headers: {
        'Accept': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      },
    );
    return _decodeList(res, 'Moments');
  }

  /// One user’s Moments album (friend / own profile).
  Future<List<Map<String, dynamic>>> listMomentsForUser({
    required String userId,
    String? accessToken,
  }) async {
    final res = await _client.get(
      _uri('/v1/moments/user/$userId'),
      headers: {
        'Accept': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      },
    );
    return _decodeList(res, 'User moments');
  }

  /// Accepted friend or self. Staff and admin fields are not included.
  Future<Map<String, dynamic>> getFriendProfile({
    required String accessToken,
    required String userId,
  }) {
    return _getMap('/v1/friends/$userId/profile', accessToken);
  }

  Future<Map<String, dynamic>> getMomentsProfile({
    required String userId,
    String? accessToken,
  }) async {
    final res = await _client.get(
      _uri('/v1/users/$userId/moments-profile'),
      headers: {
        'Accept': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      },
    );
    return _decodeMap(res, 'Moments profile');
  }

  Future<Map<String, dynamic>> getObicChannel({String? accessToken}) async {
    final res = await _client.get(
      _uri('/v1/channels/obic'),
      headers: {
        'Accept': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      },
    );
    return _decodeMap(res, 'OBIC Channel');
  }

  Future<Map<String, dynamic>> followObicChannel(String accessToken) async {
    return _postJson('/v1/channels/obic/follow', accessToken, {});
  }

  Future<Map<String, dynamic>> unfollowObicChannel(String accessToken) async {
    return _deleteJson('/v1/channels/obic/follow', accessToken);
  }

  Future<List<Map<String, dynamic>>> listObicChannelVideos({
    String? accessToken,
  }) async {
    final res = await _client.get(
      _uri('/v1/channels/obic/videos'),
      headers: {
        'Accept': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      },
    );
    return _decodeList(res, 'Channel videos');
  }

  Future<Map<String, dynamic>> createObicChannelVideo({
    required String accessToken,
    required String videoUrl,
    String? thumbUrl,
    String? caption,
    int? durationSec,
    int? byteSize,
  }) async {
    return _postJson('/v1/channels/obic/videos', accessToken, {
      'videoUrl': videoUrl,
      if (thumbUrl != null && thumbUrl.isNotEmpty) 'thumbUrl': thumbUrl,
      if (caption != null) 'caption': caption,
      if (durationSec != null) 'durationSec': durationSec,
      if (byteSize != null) 'byteSize': byteSize,
    });
  }

  Future<Map<String, dynamic>> deleteObicChannelVideo({
    required String accessToken,
    required String videoId,
  }) async {
    return _deleteJson('/v1/channels/obic/videos/$videoId', accessToken);
  }

  Future<Map<String, dynamic>> getChannelsDiscover({
    String? accessToken,
  }) async {
    final res = await _client.get(
      _uri('/v1/channels/discover'),
      headers: {
        'Accept': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      },
    );
    return _decodeMap(res, 'Discover');
  }

  Future<List<Map<String, dynamic>>> listChannelFeed({
    required String tab,
    String? accessToken,
    int limit = 40,
  }) async {
    final res = await _client.get(
      _uri('/v1/channels/feed', {'tab': tab, 'limit': '$limit'}),
      headers: {
        'Accept': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      },
    );
    return _decodeList(res, 'Channel feed');
  }

  Future<Map<String, dynamic>> getMyChannel(String accessToken) async {
    return _getMap('/v1/channels/me', accessToken);
  }

  Future<Map<String, dynamic>> getUserChannel({
    required String userId,
    String? accessToken,
  }) async {
    final res = await _client.get(
      _uri('/v1/channels/user/$userId'),
      headers: {
        'Accept': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      },
    );
    return _decodeMap(res, 'User channel');
  }

  /// Lookup by slug. Returns null when the channel does not exist.
  /// Does not create a personal channel (unlike [getUserChannel]).
  Future<Map<String, dynamic>?> getChannelBySlug({
    required String slug,
    String? accessToken,
  }) async {
    final res = await _client.get(
      _uri('/v1/channels/$slug'),
      headers: {
        'Accept': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      },
    );
    if (res.statusCode == 404) return null;
    return _decodeMap(res, 'Channel');
  }

  Future<Map<String, dynamic>> followChannel({
    required String accessToken,
    required String idOrSlug,
  }) async {
    return _postJson('/v1/channels/$idOrSlug/follow', accessToken, {});
  }

  Future<Map<String, dynamic>> unfollowChannel({
    required String accessToken,
    required String idOrSlug,
  }) async {
    return _deleteJson('/v1/channels/$idOrSlug/follow', accessToken);
  }

  Future<List<Map<String, dynamic>>> listChannelVideos({
    required String idOrSlug,
    String? accessToken,
  }) async {
    final res = await _client.get(
      _uri('/v1/channels/$idOrSlug/videos'),
      headers: {
        'Accept': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      },
    );
    return _decodeList(res, 'Channel videos');
  }

  Future<Map<String, dynamic>> createChannelVideo({
    required String accessToken,
    required String idOrSlug,
    required String videoUrl,
    String? thumbUrl,
    String? caption,
    int? durationSec,
    int? byteSize,
  }) async {
    return _postJson('/v1/channels/$idOrSlug/videos', accessToken, {
      'videoUrl': videoUrl,
      if (thumbUrl != null && thumbUrl.isNotEmpty) 'thumbUrl': thumbUrl,
      if (caption != null) 'caption': caption,
      if (durationSec != null) 'durationSec': durationSec,
      if (byteSize != null) 'byteSize': byteSize,
    });
  }

  Future<Map<String, dynamic>> likeChannelVideo({
    required String accessToken,
    required String videoId,
  }) async {
    return _postJson('/v1/channels/videos/$videoId/like', accessToken, {});
  }

  Future<List<Map<String, dynamic>>> listChannelVideoComments({
    required String videoId,
    String? accessToken,
  }) async {
    final res = await _client.get(
      _uri('/v1/channels/videos/$videoId/comments'),
      headers: {
        'Accept': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      },
    );
    return _decodeList(res, 'Channel comments');
  }

  Future<Map<String, dynamic>> commentChannelVideo({
    required String accessToken,
    required String videoId,
    required String body,
  }) async {
    return _postJson('/v1/channels/videos/$videoId/comments', accessToken, {
      'body': body,
    });
  }

  Future<Map<String, dynamic>> shareChannelVideo({
    required String accessToken,
    required String videoId,
  }) async {
    return _postJson('/v1/channels/videos/$videoId/share', accessToken, {});
  }

  Future<Map<String, dynamic>> deleteChannelVideo({
    required String accessToken,
    required String videoId,
  }) async {
    return _deleteJson('/v1/channels/videos/$videoId', accessToken);
  }

  Future<Map<String, dynamic>> getMomentNotifyPrefs(String accessToken) async {
    return _getMap('/v1/moments/notify-prefs', accessToken);
  }

  Future<Map<String, dynamic>> updateMomentNotifyPrefs({
    required String accessToken,
    bool? notifyEnabled,
    bool? muteUpdates,
    List<String>? mutedFriendIds,
    List<String>? hiddenFromFriendIds,
  }) async {
    return _patchJson('/v1/moments/notify-prefs', accessToken, {
      if (notifyEnabled != null) 'notifyEnabled': notifyEnabled,
      if (muteUpdates != null) 'muteUpdates': muteUpdates,
      if (mutedFriendIds != null) 'mutedFriendIds': mutedFriendIds,
      if (hiddenFromFriendIds != null)
        'hiddenFromFriendIds': hiddenFromFriendIds,
    });
  }

  Future<Map<String, dynamic>> muteMomentFriend({
    required String accessToken,
    required String friendId,
  }) async {
    return _postJson(
      '/v1/moments/notify-prefs/muted-friends/$friendId',
      accessToken,
      {},
    );
  }

  Future<Map<String, dynamic>> unmuteMomentFriend({
    required String accessToken,
    required String friendId,
  }) async {
    return _deleteJson(
      '/v1/moments/notify-prefs/muted-friends/$friendId',
      accessToken,
    );
  }

  Future<Map<String, dynamic>> hideMomentFromFriend({
    required String accessToken,
    required String friendId,
  }) async {
    return _postJson(
      '/v1/moments/notify-prefs/hidden-from/$friendId',
      accessToken,
      {},
    );
  }

  Future<Map<String, dynamic>> unhideMomentFromFriend({
    required String accessToken,
    required String friendId,
  }) async {
    return _deleteJson(
      '/v1/moments/notify-prefs/hidden-from/$friendId',
      accessToken,
    );
  }

  Future<Map<String, dynamic>> createMoment({
    required String accessToken,
    required String body,
    String? imageUrl,
    List<Map<String, dynamic>>? media,
    String? visibility,
    List<String>? allowedUserIds,
    List<String>? deniedUserIds,
  }) async {
    return _postJson('/v1/moments', accessToken, {
      'body': body,
      if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      if (media != null && media.isNotEmpty) 'media': media,
      if (visibility != null && visibility.isNotEmpty) 'visibility': visibility,
      if (allowedUserIds != null && allowedUserIds.isNotEmpty)
        'allowedUserIds': allowedUserIds,
      if (deniedUserIds != null && deniedUserIds.isNotEmpty)
        'deniedUserIds': deniedUserIds,
    });
  }

  Future<Map<String, dynamic>> deleteMoment({
    required String accessToken,
    required String momentId,
  }) async {
    return _deleteJson('/v1/moments/$momentId', accessToken);
  }

  Future<Map<String, dynamic>> toggleMomentLike({
    required String accessToken,
    required String momentId,
  }) async {
    return _postJson('/v1/moments/$momentId/like', accessToken, {});
  }

  Future<Map<String, dynamic>> addMomentComment({
    required String accessToken,
    required String momentId,
    required String body,
    String? replyToCommentId,
    List<Map<String, dynamic>>? media,
  }) async {
    return _postJson('/v1/moments/$momentId/comments', accessToken, {
      if (body.isNotEmpty) 'body': body,
      if (replyToCommentId != null) 'replyToCommentId': replyToCommentId,
      if (media != null && media.isNotEmpty) 'media': media,
    });
  }

  Future<Map<String, dynamic>> deleteMomentComment({
    required String accessToken,
    required String momentId,
    required String commentId,
  }) async {
    return _deleteJson(
      '/v1/moments/$momentId/comments/$commentId',
      accessToken,
    );
  }

  /// Multipart upload — returns `{ items: [{ kind, url, name, mime, size }] }`.
  Future<List<Map<String, dynamic>>> uploadFiles({
    required String accessToken,
    required List<({String path, String filename})> files,
  }) async {
    final req = http.MultipartRequest('POST', _uri('/v1/uploads'));
    req.headers['Authorization'] = 'Bearer $accessToken';
    req.headers['Accept'] = 'application/json';
    for (final f in files) {
      req.files.add(
        await http.MultipartFile.fromPath(
          'files',
          f.path,
          filename: f.filename,
        ),
      );
    }
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    final map = _decodeMap(res, 'Upload');
    final items = map['items'];
    if (items is! List) return [];
    return items.whereType<Map<String, dynamic>>().toList();
  }

  Future<Map<String, dynamic>> updateAvatar({
    required String accessToken,
    required String avatarUrl,
  }) async {
    final res = await _client.patch(
      _uri('/v1/users/me/avatar'),
      headers: _authHeaders(accessToken),
      body: jsonEncode({'avatarUrl': avatarUrl}),
    );
    return _decodeMap(res, 'Avatar');
  }

  Future<List<Map<String, dynamic>>> listNotifications(
    String accessToken,
  ) async {
    return _getList('/v1/notifications', accessToken);
  }

  Future<int> unreadNotificationCount(String accessToken) async {
    final json = await _getMap('/v1/notifications/unread-count', accessToken);
    final n = json['unreadCount'];
    if (n is int) return n;
    if (n is num) return n.toInt();
    return 0;
  }

  Future<void> markNotificationRead({
    required String accessToken,
    required String id,
  }) async {
    await _patchJson('/v1/notifications/$id/read', accessToken, {});
  }

  /// Hard-delete inbox row (open-chat race: never leave stubs).
  Future<void> dismissNotification({
    required String accessToken,
    required String id,
  }) async {
    await _deleteJson('/v1/notifications/$id', accessToken);
  }

  Future<void> markAllNotificationsRead(String accessToken) async {
    await _postJson('/v1/notifications/read-all', accessToken, {});
  }

  Future<List<Map<String, dynamic>>> listFriends(String accessToken) async {
    return _getList('/v1/friends', accessToken);
  }

  Future<List<Map<String, dynamic>>> searchUsers({
    required String accessToken,
    required String q,
  }) async {
    return _getList('/v1/friends/search', accessToken, {'q': q});
  }

  Future<Map<String, dynamic>> listFriendRequests(String accessToken) async {
    return _getMap('/v1/friends/requests', accessToken);
  }

  /// Pending incoming friend requests (WeChat Contacts badge).
  Future<int> pendingFriendRequestCount(String accessToken) async {
    final json = await listFriendRequests(accessToken);
    final incoming = json['incoming'];
    if (incoming is! List) return 0;
    return incoming.length;
  }

  Future<Map<String, dynamic>> sendFriendRequest({
    required String accessToken,
    String? userId,
    String? phone,
    String? message,
  }) async {
    return _postJson('/v1/friends/requests', accessToken, {
      if (userId != null && userId.isNotEmpty) 'userId': userId,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (message != null && message.trim().isNotEmpty)
        'message': message.trim(),
    });
  }

  Future<Map<String, dynamic>> acceptFriendRequest({
    required String accessToken,
    required String id,
  }) async {
    return _postJson('/v1/friends/requests/$id/accept', accessToken, {});
  }

  Future<Map<String, dynamic>> rejectFriendRequest({
    required String accessToken,
    required String id,
  }) async {
    return _postJson('/v1/friends/requests/$id/reject', accessToken, {});
  }

  Future<List<Map<String, dynamic>>> _getList(
    String path,
    String accessToken, [
    Map<String, String>? query,
  ]) async {
    final res = await _client
        .get(
          _uri(path, query),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        )
        .timeout(_kRequestTimeout);
    return _decodeList(res, path);
  }

  Future<Map<String, dynamic>> _getMap(
    String path,
    String accessToken, [
    Map<String, String>? query,
  ]) async {
    final res = await _client
        .get(
          _uri(path, query),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        )
        .timeout(_kRequestTimeout);
    final json = _decodeMap(res, path);
    return json;
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    String accessToken,
    Map<String, dynamic> body,
  ) async {
    final res = await _client
        .post(
          _uri(path),
          headers: _authHeaders(accessToken),
          body: jsonEncode(body),
        )
        .timeout(_kRequestTimeout);
    return _decodeMap(res, path);
  }

  Future<Map<String, dynamic>> _patchJson(
    String path,
    String accessToken,
    Map<String, dynamic> body,
  ) async {
    final res = await _client
        .patch(
          _uri(path),
          headers: _authHeaders(accessToken),
          body: jsonEncode(body),
        )
        .timeout(_kRequestTimeout);
    return _decodeMap(res, path);
  }

  Future<Map<String, dynamic>> _putJson(
    String path,
    String accessToken,
    Map<String, dynamic> body,
  ) async {
    final res = await _client
        .put(
          _uri(path),
          headers: _authHeaders(accessToken),
          body: jsonEncode(body),
        )
        .timeout(_kRequestTimeout);
    return _decodeMap(res, path);
  }

  Future<Map<String, dynamic>> _deleteJson(
    String path,
    String accessToken,
  ) async {
    final res = await _client
        .delete(_uri(path), headers: _authHeaders(accessToken))
        .timeout(_kRequestTimeout);
    return _decodeMap(res, path);
  }

  List<Map<String, dynamic>> _decodeList(http.Response res, String label) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AuthApiException(
        _errorText(res, label),
        statusCode: res.statusCode,
      );
    }
    if (res.body.isEmpty) return [];
    final decoded = jsonDecode(res.body);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Map<String, dynamic> _decodeMap(http.Response res, String label) {
    Map<String, dynamic> json = {};
    if (res.body.isNotEmpty) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) json = decoded;
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AuthApiException(
        _errorText(res, label, json),
        statusCode: res.statusCode,
      );
    }
    return json;
  }

  String _errorText(
    http.Response res,
    String label, [
    Map<String, dynamic>? json,
  ]) {
    final msg = json?['message'];
    if (msg is String) return msg;
    if (msg is List) return msg.join(', ');
    return '$label failed (${res.statusCode})';
  }
}
