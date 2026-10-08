/// SQLite-backed database of the media library.
///
/// NOTE: In this community rebuild the indexing engine is not implemented
/// yet; the database is an inert stub which reports an empty library.
library;

import 'models.dart';

class MediaLibraryDatabase {
  MediaLibraryDatabase();

  /// Returns the [Track] with the given stable hash, or `null`.
  Future<Track?> selectTrackByHash(String hash) async => null;

  /// Whether a track with the given URI exists in the database.
  Future<bool> contains(String uri) async => false;

  Future<void> dispose() async {}
}
