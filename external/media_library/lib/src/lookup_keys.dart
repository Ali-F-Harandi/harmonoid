/// Lookup keys used for fast in-memory lookups of media library entries.
library;

/// Key for looking up a [Track] by its URI.
class TrackLookupKey {
  const TrackLookupKey({required this.uri});

  final String uri;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TrackLookupKey && other.uri == uri;

  @override
  int get hashCode => uri.hashCode;

  @override
  String toString() => 'TrackLookupKey($uri)';
}

/// Key for looking up an [Artist] by name.
class ArtistLookupKey {
  const ArtistLookupKey({required this.artist});

  final String artist;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ArtistLookupKey && other.artist == artist;

  @override
  int get hashCode => artist.hashCode;

  @override
  String toString() => 'ArtistLookupKey($artist)';
}

/// Key for looking up an [Album].
class AlbumLookupKey {
  const AlbumLookupKey({
    required this.album,
    required this.albumArtist,
    required this.year,
  });

  final String album;
  final String albumArtist;
  final int year;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlbumLookupKey &&
          other.album == album &&
          other.albumArtist == albumArtist &&
          other.year == year;

  @override
  int get hashCode => Object.hash(album, albumArtist, year);

  @override
  String toString() => 'AlbumLookupKey($album, $albumArtist, $year)';
}

/// Key for looking up a [Genre] by name.
class GenreLookupKey {
  const GenreLookupKey({required this.genre});

  final String genre;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is GenreLookupKey && other.genre == genre;

  @override
  int get hashCode => genre.hashCode;

  @override
  String toString() => 'GenreLookupKey($genre)';
}
