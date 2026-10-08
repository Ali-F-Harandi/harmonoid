/// Media library engine.
///
/// NOTE: This is a community reimplementation. The original private upstream
/// package is unavailable, so the FILE-SYSTEM INDEXING ENGINE is not
/// implemented yet — [FileSystemMediaLibrary] presents an empty library and
/// all APIs degrade gracefully. The public API surface is complete so that
/// the application compiles & runs; see REBUILD.md in the repository root
/// for the phased plan to implement the real engine.
library;

import 'dart:io';

import 'models.dart';
import 'enums.dart';
import 'lookup_keys.dart';
import 'hash_encoder.dart';
import 'database.dart';
import 'playlists.dart';
import 'utils/constants.dart';

export 'models.dart';
export 'enums.dart';
export 'lookup_keys.dart';
export 'hash_encoder.dart';
export 'database.dart';
export 'playlists.dart';
export 'utils/constants.dart';
export '../playlists/src/utils/constants.dart';

/// Base class for media library implementations.
abstract class MediaLibrary {
  /// All tracks in the library.
  List<Track> get tracks;

  /// All albums in the library.
  List<Album> get albums;

  /// All artists in the library.
  List<Artist> get artists;

  /// All genres in the library.
  List<Genre> get genres;

  /// Albums grouped by album-artist name (insertion ordered).
  Map<String, List<Album>> get albumArtists;

  /// Playlist manager.
  Playlists get playlists;

  /// Whether a refresh is currently running.
  bool get refreshing;

  /// Progress of the current refresh; `null` while discovering files.
  int? get current;

  /// Total number of items in the current refresh.
  int get total;

  AlbumSortType get albumSortType;
  bool get albumSortAscending;
  ArtistSortType get artistSortType;
  bool get artistSortAscending;
  GenreSortType get genreSortType;
  bool get genreSortAscending;
  TrackSortType get trackSortType;
  bool get trackSortAscending;

  /// Refreshes the library from the file-system / database.
  Future<void> refresh({bool insert = true, bool delete = true});

  /// Updates sort settings & re-populates the in-memory collections.
  Future<void> populate({
    AlbumSortType? albumSortType,
    ArtistSortType? artistSortType,
    GenreSortType? genreSortType,
    TrackSortType? trackSortType,
    bool? albumSortAscending,
    bool? artistSortAscending,
    bool? genreSortAscending,
    bool? trackSortAscending,
  });

  /// Notifies about changes in the media library.
  Future<void> notify();

  /// Synchronous lookups.
  Track? lookupTrack(TrackLookupKey key);
  Album? lookupAlbum(AlbumLookupKey key);
  Artist? lookupArtist(ArtistLookupKey key);
  Genre? lookupGenre(GenreLookupKey key);

  /// Tracks of the given [album].
  Future<List<Track>> tracksFromAlbum(Album album);

  /// Tracks of the given [artist].
  Future<List<Track>> tracksFromArtist(Artist artist);

  /// Tracks of the given [genre].
  Future<List<Track>> tracksFromGenre(Genre genre);

  /// Albums of the given [artist].
  Future<List<Album>> albumsFromArtist(Artist artist);

  /// Full-text search over the library.
  Future<List<MediaLibraryItem>> search(String query, {int? limit});

  /// Cover-art URI for the given [item]; `null` when unavailable.
  Future<Uri?> cover(MediaLibraryItem item, {bool? fallback});

  /// Cover-art URI for the track with the given [uri].
  Future<Uri?> coverForUri(String uri);

  /// Returns the cover-art cache file for the track with [uri].
  static File trackUriToCoverFile(Directory covers, String uri) {
    final name = HashEncoder.stringToHash(uri);
    final separator = covers.path.endsWith('/') || covers.path.endsWith('\\')
        ? ''
        : Platform.pathSeparator;
    return File('${covers.path}$separator$name.JPG');
  }
}

/// File-system backed media library.
class FileSystemMediaLibrary extends MediaLibrary {
  FileSystemMediaLibrary({
    required Directory cache,
    required Set<Directory> directories,
    required AlbumSortType albumSortType,
    required ArtistSortType artistSortType,
    required GenreSortType genreSortType,
    required TrackSortType trackSortType,
    required bool albumSortAscending,
    required bool artistSortAscending,
    required bool genreSortAscending,
    required bool trackSortAscending,
    required int minimumFileSize,
    required Set<AlbumGroupingParameter> albumGroupingParameters,
    required bool hideSecondaryArtists,
  })  : _cache = cache,
        _directories = directories,
        _albumSortType = albumSortType,
        _artistSortType = artistSortType,
        _genreSortType = genreSortType,
        _trackSortType = trackSortType,
        _albumSortAscending = albumSortAscending,
        _artistSortAscending = artistSortAscending,
        _genreSortAscending = genreSortAscending,
        _trackSortAscending = trackSortAscending,
        _minimumFileSize = minimumFileSize,
        _albumGroupingParameters = albumGroupingParameters,
        _hideSecondaryArtists = hideSecondaryArtists {
    _ensureCoversDirectory();
  }

  final Directory _cache;
  Set<Directory> _directories;
  AlbumSortType _albumSortType;
  ArtistSortType _artistSortType;
  GenreSortType _genreSortType;
  TrackSortType _trackSortType;
  bool _albumSortAscending;
  bool _artistSortAscending;
  bool _genreSortAscending;
  bool _trackSortAscending;
  int _minimumFileSize;
  Set<AlbumGroupingParameter> _albumGroupingParameters;
  bool _hideSecondaryArtists;

  final MediaLibraryDatabase _db = MediaLibraryDatabase();
  final Playlists _playlists = Playlists();

  /// Cache directory of the library.
  Directory get cache => _cache;

  /// Directory holding cached cover-art files.
  Directory get covers {
    final separator = _cache.path.endsWith('/') || _cache.path.endsWith('\\')
        ? ''
        : Platform.pathSeparator;
    return Directory('${_cache.path}${separator}Covers');
  }

  /// Set of directories currently indexed.
  Set<Directory> get directories => _directories;

  /// File types currently indexed.
  Set<String> get supportedFileTypes => kDefaultSupportedFileTypes;

  /// Underlying database.
  MediaLibraryDatabase get db => _db;

  /// Minimum file size (in bytes) for a file to be indexed.
  int get minimumFileSize => _minimumFileSize;

  /// Current album grouping parameters.
  Set<AlbumGroupingParameter> get albumGroupingParameters =>
      _albumGroupingParameters;

  /// Whether secondary (featured) artists are hidden from listings.
  bool get hideSecondaryArtists => _hideSecondaryArtists;

  void _ensureCoversDirectory() {
    try {
      final directory = covers;
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }
    } catch (_) {}
  }

  @override
  List<Track> get tracks => const <Track>[];

  @override
  List<Album> get albums => const <Album>[];

  @override
  List<Artist> get artists => const <Artist>[];

  @override
  List<Genre> get genres => const <Genre>[];

  @override
  Map<String, List<Album>> get albumArtists => const <String, List<Album>>{};

  @override
  Playlists get playlists => _playlists;

  @override
  bool get refreshing => false;

  @override
  int? get current => null;

  @override
  int get total => 0;

  @override
  AlbumSortType get albumSortType => _albumSortType;

  @override
  bool get albumSortAscending => _albumSortAscending;

  @override
  ArtistSortType get artistSortType => _artistSortType;

  @override
  bool get artistSortAscending => _artistSortAscending;

  @override
  GenreSortType get genreSortType => _genreSortType;

  @override
  bool get genreSortAscending => _genreSortAscending;

  @override
  TrackSortType get trackSortType => _trackSortType;

  @override
  bool get trackSortAscending => _trackSortAscending;

  @override
  Future<void> refresh({bool insert = true, bool delete = true}) async {
    // ENGINE STUB: file-system indexing is not implemented yet.
    _ensureCoversDirectory();
    await notify();
  }

  @override
  Future<void> populate({
    AlbumSortType? albumSortType,
    ArtistSortType? artistSortType,
    GenreSortType? genreSortType,
    TrackSortType? trackSortType,
    bool? albumSortAscending,
    bool? artistSortAscending,
    bool? genreSortAscending,
    bool? trackSortAscending,
  }) async {
    if (albumSortType != null) _albumSortType = albumSortType;
    if (artistSortType != null) _artistSortType = artistSortType;
    if (genreSortType != null) _genreSortType = genreSortType;
    if (trackSortType != null) _trackSortType = trackSortType;
    if (albumSortAscending != null) _albumSortAscending = albumSortAscending;
    if (artistSortAscending != null) _artistSortAscending = artistSortAscending;
    if (genreSortAscending != null) _genreSortAscending = genreSortAscending;
    if (trackSortAscending != null) _trackSortAscending = trackSortAscending;
    await notify();
  }

  @override
  Future<void> notify() async {}

  @override
  Track? lookupTrack(TrackLookupKey key) => null;

  @override
  Album? lookupAlbum(AlbumLookupKey key) => null;

  @override
  Artist? lookupArtist(ArtistLookupKey key) => null;

  @override
  Genre? lookupGenre(GenreLookupKey key) => null;

  @override
  Future<List<Track>> tracksFromAlbum(Album album) async => const <Track>[];

  @override
  Future<List<Track>> tracksFromArtist(Artist artist) async => const <Track>[];

  @override
  Future<List<Track>> tracksFromGenre(Genre genre) async => const <Track>[];

  @override
  Future<List<Album>> albumsFromArtist(Artist artist) async => const <Album>[];

  @override
  Future<List<MediaLibraryItem>> search(String query, {int? limit}) async =>
      const <MediaLibraryItem>[];

  @override
  Future<Uri?> cover(MediaLibraryItem item, {bool? fallback}) async => null;

  @override
  Future<Uri?> coverForUri(String uri) async => null;

  /// Adds a single [file] to the library.
  Future<void> add(File file) async {
    await notify();
  }

  /// Removes the given [tracks] from the library.
  Future<void> remove(List<Track> tracks, {bool delete = true}) async {
    await notify();
  }

  /// Removes the given [directories] from indexing.
  Future<void> removeDirectories(Set<Directory> directories) async {
    _directories.removeAll(directories);
    await notify();
  }

  /// Adds the given [directories] for indexing.
  Future<void> addDirectories(Set<Directory> directories) async {
    _directories.addAll(directories);
    await notify();
  }

  /// Rebuilds the library database from scratch.
  Future<void> reindex() async {
    await notify();
  }

  /// Updates the album grouping parameters.
  void setAlbumGroupingParameters(Set<AlbumGroupingParameter> value) {
    _albumGroupingParameters = value;
  }

  /// Updates the minimum file size.
  void setMinimumFileSize(int value) {
    _minimumFileSize = value;
  }

  /// Updates whether secondary artists are hidden.
  Future<void> setHideSecondaryArtists(bool value) async {
    _hideSecondaryArtists = value;
    await notify();
  }

  /// Parses the tags of the file at [uri] into a [Track].
  ///
  /// Overridden by the application to use [TagReader].
  Future<Track> parse(String uri, File cover, Duration timeout) {
    throw UnimplementedError('FileSystemMediaLibrary.parse');
  }

  /// Splits a multi-valued tag string into a set of values.
  ///
  /// Overridden by the application to use [TagReader].
  Set<String> splitTagValue(String? tag) {
    throw UnimplementedError('FileSystemMediaLibrary.splitTagValue');
  }

  /// Delegate for deleting files on Android (MediaStore consent flow).
  ///
  /// Overridden by the application.
  Future<bool> androidDeleteDelegate(List<Track> tracks) {
    throw UnimplementedError('FileSystemMediaLibrary.androidDeleteDelegate');
  }

  /// Disposes the library & releases resources.
  ///
  /// NOTE: Synchronous (`void`) so that host applications can mix in
  /// `ChangeNotifier` (whose `dispose` is also synchronous).
  void dispose() {}

  /// Closes the underlying database.
  Future<void> close() async {}
}
