/// Stable string hashing used for cover-art file names & playlist entries.
library;

import 'models.dart';

/// Exposes stable hashing helpers.
abstract class HashEncoder {
  HashEncoder._();

  /// Returns a stable hash for the given [Track].
  ///
  /// The value is persisted inside playlist entries, so it MUST remain
  /// stable across application launches.
  static String trackToHash(Track track) => stringToHash(track.uri);

  /// FNV-1a 64-bit hash of an arbitrary string, rendered as 16 hex digits.
  static String stringToHash(String value) {
    var hash = 0xcbf29ce484222325;
    for (final code in value.codeUnits) {
      hash ^= code;
      hash = (hash * 0x100000001b3) & 0xffffffffffffffff;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }
}
