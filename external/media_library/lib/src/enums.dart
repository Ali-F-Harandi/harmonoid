/// Sort types for the media library collections.
library;

/// Sort criterion for [Album] listings.
enum AlbumSortType {
  album,
  timestamp,
  year,
  albumArtist,
}

/// Sort criterion for [Artist] listings.
enum ArtistSortType {
  artist,
  timestamp,
}

/// Sort criterion for [Genre] listings.
enum GenreSortType {
  genre,
  timestamp,
}

/// Sort criterion for [Track] listings.
enum TrackSortType {
  title,
  timestamp,
  year,
}

/// Parameters which decide how tracks are grouped into albums.
enum AlbumGroupingParameter {
  album,
  albumArtist,
  year,
}
