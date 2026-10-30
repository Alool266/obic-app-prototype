// Made by Dr Ali
// One keep-alive HTTP client for the app.
//
// Each SocialApi / ServicesApi / image fetch used to open its own client, so
// every screen paid a new TLS handshake. On iOS that handshake is slow, and
// a burst of one-shot image downloads stalled the next API call. Auth keeps
// its own client and the 120s request deadline.

import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import 'phone_activation_lock.dart';

http.Client? _shared;

/// Process-wide client. Do not close it.
http.Client obicHttpClient() {
  final existing = _shared;
  if (existing != null) return existing;
  final io = HttpClient()
    ..idleTimeout = const Duration(seconds: 90)
    ..connectionTimeout = const Duration(seconds: 30)
    ..maxConnectionsPerHost = 6;
  final client = _WriteGuard(IOClient(io));
  _shared = client;
  return client;
}

class _WriteGuard extends http.BaseClient {
  _WriteGuard(this._inner);

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (PhoneActivationLock.block(request.method, request.url)) {
      return Future<http.StreamedResponse>.error(const PhoneActivationRequired());
    }
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
  }
}
