/// Audio tag reading for Harmonoid.
///
/// NOTE: This is a community reimplementation. Real tag parsing (via FFI to
/// taglib or another native backend) is not implemented yet — [TagReader.parse]
/// currently derives minimal metadata from the file URI only. See REBUILD.md
/// in the repository root for the phased plan.
library;

import 'dart:io';

import 'package:pool/pool.dart';

/// Tags of an audio file.
///
/// Field-for-field mirror of `media_library`'s `Track` constructor.
class Tags {
  Tags({
    required this.uri,
    this.title = '',
    this.album = '',
    this.albumArtist = '',
    this.discNumber = 0,
    this.trackNumber = 0,
    this.albumLength = 0,
    this.year = 0,
    this.lyrics = '',
    this.duration = 0,
    this.bitrate = 0,
    DateTime? timestamp,
    this.artists = const <String>{},
    this.genres = const <String>{},
  }) : timestamp = timestamp ?? DateTime.now();

  final String uri;
  final String title;
  final String album;
  final String albumArtist;
  final int discNumber;
  final int trackNumber;
  final int albumLength;
  final int year;

  /// Embedded (LRC) lyrics; empty string when absent.
  final String lyrics;

  /// Duration in milliseconds.
  final int duration;
  final int bitrate;
  final DateTime timestamp;
  final Set<String> artists;
  final Set<String> genres;

  @override
  String toString() {
    return 'Tags(uri: $uri, title: $title, album: $album, '
        'albumArtist: $albumArtist, year: $year, duration: $duration)';
  }
}

/// Splits a (possibly multi-valued) tag string into separate values.
///
/// Values may be separated with `;`, `/`, `\` or `//`.
Set<String> splitTagValue(String? tag) {
  if (tag == null) return <String>{};
  return tag
      .split(RegExp(r'[;/\\]+'))
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toSet();
}

/// Reads tags from audio files.
class TagReader {
  TagReader();

  /// Parses the tags of the file at [uri].
  ///
  /// If [cover] is provided (and the backend supports it), the embedded
  /// album-art is written to that file.
  Future<Tags> parse(String uri, {File? cover, Duration? timeout}) async {
    // STUB: derive the title from the file name; everything else unknown.
    final name = uri.split(RegExp(r'[\\/]')).last;
    final title = name.contains('.')
        ? name.substring(0, name.lastIndexOf('.'))
        : name;
    return Tags(uri: uri, title: title);
  }

  /// Returns all tags of the file at [uri] as a flat string map.
  Future<Map<String, String>> metadata(String uri, {File? cover, Duration? timeout}) async {
    final name = uri.split(RegExp(r'[\\/]')).last;
    final title = name.contains('.')
        ? name.substring(0, name.lastIndexOf('.'))
        : name;
    return <String, String>{
      'URI': uri,
      'TITLE': title,
    };
  }

  /// Releases resources.
  Future<void> dispose() async {}
}

/// A pool which limits the number of concurrent tag-parsing operations.
class PooledTagReader {
  PooledTagReader({required int size})
      : _pool = Pool(size.clamp(1, 64));

  final Pool _pool;
  final TagReader _reader = TagReader();

  /// Parses the tags of the file at [uri], queued through the pool.
  Future<Tags> parse(String uri, {File? cover, Duration? timeout}) {
    return _pool.withResource(() => _reader.parse(uri, cover: cover, timeout: timeout));
  }

  /// Releases resources.
  Future<void> dispose() async {
    await _pool.close();
  }
}
