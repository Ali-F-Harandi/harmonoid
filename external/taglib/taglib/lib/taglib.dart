/// taglib FFI bindings (tag writing) for Harmonoid.
///
/// NOTE: This is a community reimplementation placeholder. The native taglib
/// library is not bundled yet and no FFI bindings are wired — all [TagLibFile]
/// operations throw [UnsupportedError], which the tag-editor handles by
/// showing its error state. See REBUILD.md in the repository root.
library;

import 'dart:typed_data';

/// Embedded cover-art bytes with an explicit MIME type.
class CoverData {
  CoverData({required this.data, required this.mimeType});

  final Uint8List data;
  final String mimeType;
}

/// An open handle to an audio file for reading & writing tags.
class TagLibFile {
  TagLibFile(String resource) : _resource = resource;

  final String _resource;

  /// Property keys handled by the tag editor UI.
  static const List<String> kProperties = <String>[
    'TITLE',
    'ARTIST',
    'ALBUM',
    'ALBUMARTIST',
    'DATE',
    'GENRE',
    'TRACKNUMBER',
    'DISCNUMBER',
    'COMMENT',
    'LYRICS',
  ];

  /// Reads all properties of the file.
  Future<Map<String, List<String>>> getProperties() async {
    throw UnsupportedError(
      'TagLibFile is not available in this community rebuild yet: $_resource',
    );
  }

  /// Reads the embedded cover-art of the file.
  Future<CoverData?> getCover() async {
    throw UnsupportedError(
      'TagLibFile is not available in this community rebuild yet: $_resource',
    );
  }

  /// Stages a new [cover] for the file.
  Future<void> setCover(CoverData cover) async {
    throw UnsupportedError(
      'TagLibFile is not available in this community rebuild yet: $_resource',
    );
  }

  /// Stages removal of the embedded cover-art.
  Future<void> removeCover() async {
    throw UnsupportedError(
      'TagLibFile is not available in this community rebuild yet: $_resource',
    );
  }

  /// Stages a new [value] for the property [key].
  Future<void> setProperty(String key, List<String> value) async {
    throw UnsupportedError(
      'TagLibFile is not available in this community rebuild yet: $_resource',
    );
  }

  /// Stages removal of the property [key].
  Future<void> removeProperty(String key) async {
    throw UnsupportedError(
      'TagLibFile is not available in this community rebuild yet: $_resource',
    );
  }

  /// Persists all staged changes to disk.
  Future<void> save() async {
    throw UnsupportedError(
      'TagLibFile is not available in this community rebuild yet: $_resource',
    );
  }

  /// Releases the native handle.
  Future<void> dispose() async {}
}
