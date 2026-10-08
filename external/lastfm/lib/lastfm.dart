/// Last.fm API 2.0 client for Harmonoid.
///
/// Community reimplementation: classic web-API flow with MD5 request signing,
/// desktop (token) authentication, track.updateNowPlaying & track.scrobble.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:http/http.dart' as http;

/// An authenticated Last.fm session.
class Session {
  const Session({required this.name, required this.key});

  factory Session.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return Session(
        name: json['name'] as String? ?? '',
        key: json['key'] as String? ?? '',
      );
    }
    return const Session(name: '', key: '');
  }

  /// Last.fm username.
  final String name;

  /// Session key (permanent auth token).
  final String key;

  Map<String, dynamic> toJson() => <String, dynamic>{'name': name, 'key': key};

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Session && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'Session($name)';
}

/// A single track.scrobble submission.
class ScrobbleRequest {
  ScrobbleRequest({
    required this.artist,
    required this.track,
    this.album,
    required this.timestamp,
    required this.duration,
  });

  final String artist;
  final String track;
  final String? album;

  /// Unix epoch seconds at which the track started playing.
  final int timestamp;

  /// Track duration in seconds.
  final int duration;

  @override
  String toString() => 'ScrobbleRequest($artist, $track)';
}

/// A track.updateNowPlaying submission.
class UpdateNowPlayingRequest {
  UpdateNowPlayingRequest({
    required this.artist,
    required this.track,
    this.album,
    required this.duration,
  });

  final String artist;
  final String track;
  final String? album;

  /// Track duration in seconds.
  final int duration;

  @override
  String toString() => 'UpdateNowPlayingRequest($artist, $track)';
}

/// Thrown when the Last.fm API reports an error.
class LastFmException implements Exception {
  LastFmException(this.message, [this.code]);

  final String message;
  final int? code;

  @override
  String toString() => 'LastFmException: $message (code: $code)';
}

/// Last.fm web API client.
class LastFm {
  LastFm(this.apiKey, this.sharedSecret, this.debugMode);

  static const String _kApiRoot = 'https://ws.audioscrobbler.com/2.0/';
  static const String _kAuthUrl = 'https://www.last.fm/api/auth/';

  final String apiKey;
  final String sharedSecret;
  final bool debugMode;

  Session? _session;

  /// Currently active session; `null` when not authenticated.
  Session? get session => _session;

  /// Restores a previously persisted session.
  void setSession(Session session) => _session = session;

  /// Clears the current session.
  Future<void> clearSession() async => _session = null;

  String _signature(Map<String, String> params) {
    final buffer = StringBuffer();
    for (final key in params.keys.toList()..sort()) {
      if (key == 'format') continue;
      buffer.write(key);
      buffer.write(params[key] ?? '');
    }
    buffer.write(sharedSecret);
    return crypto.md5.convert(utf8.encode(buffer.toString())).toString();
  }

  Future<Map<String, dynamic>?> _call(
    String method,
    Map<String, String> params, {
    bool sign = false,
    bool post = false,
  }) async {
    final query = <String, String>{
      ...params,
      'method': method,
      'api_key': apiKey,
      'format': 'json',
    };
    if (sign) {
      query['api_sig'] = _signature(query);
    }
    final http.Response response;
    if (post) {
      response = await http.post(Uri.parse(_kApiRoot), body: query);
    } else {
      response = await http.get(
        Uri.parse(_kApiRoot).replace(queryParameters: query),
      );
    }
    final dynamic body;
    try {
      body = json.decode(utf8.decode(response.bodyBytes));
    } catch (_) {
      if (response.statusCode != 200) {
        throw LastFmException('HTTP ${response.statusCode}', response.statusCode);
      }
      return null;
    }
    if (body is Map<String, dynamic> && body.containsKey('error')) {
      throw LastFmException(
        body['message'] as String? ?? 'unknown',
        body['error'] as int?,
      );
    }
    return body is Map<String, dynamic> ? body : null;
  }

  /// Runs the desktop (token) authentication flow using [launchUrl] to let
  /// the user authorize the application on last.fm.
  ///
  /// Never throws: errors leave the session unset. If the API credentials
  /// are empty (not compiled in), this is a no-op.
  Future<void> authenticate(Future<bool> Function(Uri url) launchUrl) async {
    if (apiKey.isEmpty || sharedSecret.isEmpty) return;
    try {
      final tokenResponse = await _call('auth.gettoken', <String, String>{}, sign: true);
      final token = tokenResponse?['token'] as String?;
      if (token == null || token.isEmpty) return;

      final authorized = await launchUrl(
        Uri.parse('$_kAuthUrl?api_key=$apiKey&token=$token'),
      );
      if (!authorized) return;

      // The user needs a moment to confirm the authorization page.
      await Future<void>.delayed(const Duration(seconds: 3));

      final sessionResponse = await _call(
        'auth.getSession',
        <String, String>{'token': token},
        sign: true,
      );
      final session = sessionResponse?['session'];
      if (session is Map<String, dynamic>) {
        _session = Session.fromJson(session);
      }
    } catch (exception, stacktrace) {
      if (debugMode) {
        // ignore: avoid_print
        print('LastFm.authenticate: $exception\n$stacktrace');
      }
    }
  }

  /// Reports the currently playing track.
  Future<void> updateNowPlaying(UpdateNowPlayingRequest request) async {
    _submit('track.updateNowPlaying', <String, String>{
      'artist': request.artist,
      'track': request.track,
      if (request.album != null && request.album!.isNotEmpty)
        'album': request.album!,
      'duration': request.duration.toString(),
    });
  }

  /// Scrobbles a played track.
  Future<void> scrobble(ScrobbleRequest request) async {
    _submit('track.scrobble', <String, String>{
      'artist': request.artist,
      'track': request.track,
      if (request.album != null && request.album!.isNotEmpty)
        'album': request.album!,
      'timestamp': request.timestamp.toString(),
      'duration': request.duration.toString(),
    });
  }

  Future<void> _submit(String method, Map<String, String> params) async {
    final sessionKey = _session?.key;
    if (sessionKey == null || sessionKey.isEmpty) return;
    if (apiKey.isEmpty || sharedSecret.isEmpty) return;
    await _call(method, <String, String>{...params, 'sk': sessionKey}, sign: true, post: true);
  }
}
