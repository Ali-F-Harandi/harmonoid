/// Playlist storage of the media library.
///
/// NOTE: In this community rebuild playlists are held in-memory only for
/// the current application session; persistence will arrive together with
/// the real indexing engine (see REBUILD.md in the repository root).
library;

import 'models.dart';
import 'hash_encoder.dart';
import 'database.dart';
import '../playlists/src/utils/constants.dart';

/// Manages user playlists (including the special "Liked" & "History" ones).
class Playlists {
  Playlists({MediaLibraryDatabase? db}) : _db = db;

  // ignore: unused_field
  final MediaLibraryDatabase? _db;

  final List<Playlist> _playlists = <Playlist>[];
  final Map<String, List<PlaylistEntry>> _entries = <String, List<PlaylistEntry>>{};
  final Set<String> _liked = <String>{};

  final Playlist _likedPlaylist = Playlist(name: kLikedPlaylistName);
  final Playlist _historyPlaylist = Playlist(name: kHistoryPlaylistName);

  /// All user-created playlists.
  List<Playlist> get playlists => List.unmodifiable(_playlists);

  /// The special "Liked" playlist.
  Playlist get likedPlaylist => _likedPlaylist;

  /// The special "History" playlist.
  Playlist get historyPlaylist => _historyPlaylist;

  /// Reloads playlists from the underlying storage.
  Future<void> refresh() async {}

  /// Creates a new playlist with the given [name].
  Future<void> create(String name) async {
    if (_playlists.any((e) => e.name == name)) return;
    _playlists.add(Playlist(name: name));
    _entries[name] = <PlaylistEntry>[];
  }

  /// Adds an entry to [playlist].
  Future<void> createEntry(
    Playlist playlist, {
    Track? track,
    String? uri,
    String? title,
  }) async {
    final entries = _entries.putIfAbsent(playlist.name, () => <PlaylistEntry>[]);
    if (track != null) {
      entries.add(
        PlaylistEntry(
          uri: track.uri,
          hash: HashEncoder.trackToHash(track),
          title: track.title,
        ),
      );
    } else if (uri != null) {
      entries.add(PlaylistEntry(uri: uri, hash: null, title: title ?? uri));
    }
  }

  /// Returns the entries of the given [playlist], in order.
  Future<List<PlaylistEntry>> playlistEntries(Playlist playlist) async {
    return List<PlaylistEntry>.unmodifiable(
      _entries[playlist.name] ?? const <PlaylistEntry>[],
    );
  }

  /// Deletes [playlistEntry] from its playlist.
  Future<void> deleteEntry(PlaylistEntry playlistEntry) async {
    for (final list in _entries.values) {
      list.removeWhere((e) => e == playlistEntry);
    }
  }

  /// Renames [playlist] to [name].
  Future<void> rename(Playlist playlist, String name) async {
    final index = _playlists.indexOf(playlist);
    if (index == -1) return;
    final entries = _entries.remove(playlist.name);
    _playlists[index] = Playlist(name: name);
    if (entries != null) {
      _entries[name] = entries;
    }
  }

  /// Deletes [playlist].
  Future<void> delete(Playlist playlist) async {
    _playlists.remove(playlist);
    _entries.remove(playlist.name);
  }

  /// Whether the track with the given [uri] is liked.
  bool liked({required String uri}) => _liked.contains(uri);

  /// Marks the track with the given [uri] as liked.
  Future<void> like({required String uri}) async => _liked.add(uri);

  /// Removes the track with the given [uri] from the liked playlist.
  Future<void> unlike({required String uri}) async => _liked.remove(uri);

  /// Appends an entry to the "History" playlist.
  Future<void> addToHistory({Track? track, String? uri, String? title}) async {
    final entries = _entries.putIfAbsent(kHistoryPlaylistName, () => <PlaylistEntry>[]);
    if (track != null) {
      entries.insert(
        0,
        PlaylistEntry(
          uri: track.uri,
          hash: HashEncoder.trackToHash(track),
          title: track.title,
        ),
      );
    } else if (uri != null) {
      entries.insert(0, PlaylistEntry(uri: uri, hash: null, title: title ?? uri));
    }
    // Keep a bounded history.
    if (entries.length > 500) {
      entries.removeRange(500, entries.length);
    }
  }

  /// Replaces [oldHash] with [newHash] in all entries (after tag editing).
  Future<void> replaceHash(String oldHash, String newHash) async {
    for (final list in _entries.values) {
      for (var i = 0; i < list.length; i++) {
        if (list[i].hash == oldHash) {
          final entry = list[i];
          list[i] = PlaylistEntry(uri: entry.uri, hash: newHash, title: entry.title);
        }
      }
    }
  }
}
