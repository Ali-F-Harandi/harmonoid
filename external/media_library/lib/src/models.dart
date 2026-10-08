/// Data models for the media library.
library;

/// Base class of all media library items.
abstract class MediaLibraryItem {
  const MediaLibraryItem();
}

/// A single track present in the media library.
class Track extends MediaLibraryItem {
  Track({
    required this.uri,
    required this.title,
    required this.album,
    required this.albumArtist,
    required this.discNumber,
    required this.trackNumber,
    required this.albumLength,
    required this.year,
    required this.lyrics,
    required this.duration,
    required this.bitrate,
    required this.timestamp,
    required this.artists,
    required this.genres,
  });

  /// URI / path of the underlying audio file.
  final String uri;

  final String title;
  final String album;
  final String albumArtist;
  final int discNumber;
  final int trackNumber;

  /// Total number of tracks in the album; `0` when unknown.
  final int albumLength;
  final int year;

  /// Embedded (LRC) lyrics; empty string when absent.
  final String lyrics;

  /// Duration of the track in milliseconds.
  final int duration;

  /// Bitrate in bits per second; `0` when unknown.
  final int bitrate;

  /// File-system timestamp of the track.
  final DateTime timestamp;

  final Set<String> artists;
  final Set<String> genres;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Track && other.uri == uri;

  @override
  int get hashCode => uri.hashCode;

  @override
  String toString() {
    return 'Track(uri: $uri, title: $title, album: $album, '
        'albumArtist: $albumArtist, year: $year, duration: $duration)';
  }
}

/// An album present in the media library.
class Album extends MediaLibraryItem {
  Album({
    required this.album,
    required this.albumArtist,
    required this.year,
    required this.timestamp,
  });

  final String album;
  final String albumArtist;
  final int year;
  final DateTime timestamp;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Album &&
          other.album == album &&
          other.albumArtist == albumArtist &&
          other.year == year &&
          other.timestamp == timestamp;

  @override
  int get hashCode => Object.hash(album, albumArtist, year, timestamp);

  @override
  String toString() => 'Album($album, $albumArtist, $year)';
}

/// An artist present in the media library.
class Artist extends MediaLibraryItem {
  Artist({required this.artist, required this.timestamp});

  final String artist;
  final DateTime timestamp;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Artist && other.artist == artist;

  @override
  int get hashCode => artist.hashCode;

  @override
  String toString() => 'Artist($artist)';
}

/// A genre present in the media library.
class Genre extends MediaLibraryItem {
  Genre({required this.genre, required this.timestamp});

  final String genre;
  final DateTime timestamp;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Genre && other.genre == genre;

  @override
  int get hashCode => genre.hashCode;

  @override
  String toString() => 'Genre($genre)';
}

/// A user playlist.
class Playlist {
  Playlist({required this.name});

  final String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Playlist && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'Playlist($name)';
}

/// An entry inside a [Playlist].
class PlaylistEntry {
  PlaylistEntry({this.uri, this.hash, required this.title});

  final String? uri;
  final String? hash;
  final String title;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaylistEntry && other.uri == uri && other.hash == hash;

  @override
  int get hashCode => Object.hash(uri, hash);

  @override
  String toString() => 'PlaylistEntry($uri, $hash, $title)';
}
