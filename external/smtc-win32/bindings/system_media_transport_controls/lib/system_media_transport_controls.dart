/// Windows System Media Transport Controls (SMTC) bindings for Harmonoid.
///
/// NOTE: This is a community reimplementation placeholder. The native
/// `smtc-win32.dll` is not built/bundled in this rebuild, so all operations
/// are inert no-ops — the Windows media overlay simply stays unused.
/// See REBUILD.md in the repository root for the plan to restore it with a
/// fresh WinRT implementation.
library;

/// SMTC button events raised by the system shell.
enum SMTCEvent {
  play,
  pause,
  next,
  previous,
  stop,
  fastForward,
  rewind,
}

/// Media playback status reported to the system shell.
enum SMTCStatus {
  closed,
  opened,
  changing,
  stopped,
  playing,
  paused,
}

/// Controls the Windows System Media Transport Controls.
class SystemMediaTransportControls {
  SystemMediaTransportControls._();

  static SystemMediaTransportControls? _instance;

  // ignore: unused_field
  void Function(SMTCEvent event)? _onEvent;

  /// Loads the native library. No-op in this rebuild.
  static void ensureInitialized() {}

  /// The singleton instance.
  static SystemMediaTransportControls get instance =>
      _instance ??= SystemMediaTransportControls._();

  /// Registers the handler for shell media buttons.
  void create(void Function(SMTCEvent event) onEvent) {
    _onEvent = onEvent;
  }

  /// Updates the playback status.
  void setStatus(SMTCStatus status) {}

  /// Updates the playback timeline (milliseconds).
  void setTimelineData({required int endTime, required int position}) {}

  /// Updates the metadata of the currently playing media.
  void setMusicData({
    String? albumTitle,
    String? albumArtist,
    String? artist,
    String? title,
  }) {}

  /// Updates the artwork of the currently playing media.
  Future<void> setArtwork(dynamic artwork) async {}

  /// Releases resources.
  void dispose() {
    _onEvent = null;
  }
}
