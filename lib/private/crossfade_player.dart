/// Crossfade-capable platform player for Harmonoid.
///
/// NOTE: This is a community reimplementation. It inherits the complete
/// native playback stack from [NativePlayer] (mpv); the crossfade behavior
/// itself (dual-deck volume ramping) is not implemented yet — the configured
/// [CrossfadePlayerConfiguration.crossfadeDuration] is only stored/reported.
/// See REBUILD.md in the repository root.
library;

import 'package:media_kit/media_kit.dart';

/// [PlayerConfiguration] with an additional crossfade duration.
class CrossfadePlayerConfiguration extends PlayerConfiguration {
  const CrossfadePlayerConfiguration({
    super.title,
    super.osc,
    super.pitch,
    super.logLevel,
    super.bufferSize,
    this.crossfadeDuration = Duration.zero,
  });

  /// Duration of the crossfade between consecutive tracks.
  final Duration crossfadeDuration;
}

/// A [NativePlayer] with (stubbed) crossfade support.
class CrossfadePlayer extends NativePlayer {
  CrossfadePlayer({required CrossfadePlayerConfiguration configuration})
      : crossfadeDuration = configuration.crossfadeDuration,
        super(configuration: configuration);

  /// Currently configured crossfade duration.
  Duration crossfadeDuration;

  /// Updates the crossfade duration.
  Future<void> setCrossfadeDuration(Duration value) async {
    crossfadeDuration = value;
  }
}
