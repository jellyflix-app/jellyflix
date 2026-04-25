import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:jellyflix/providers/auth_provider.dart';

/// Fetches the Jellyfin user setting that controls whether episode thumbnails
/// or series posters are shown in Continue Watching / Next Up carousels.
///
/// Mirrors the `useEpisodeImagesInNextUpAndResume` key stored server-side in
/// DisplayPreferences.customPrefs (client: 'emby', id: 'usersettings').
class UseEpisodeImagesNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    // Re-fetch whenever the auth state changes (e.g. profile switch).
    ref.watch(authStateProvider);
    return ref.read(apiProvider).getUseEpisodeImagesInNextUpAndResume();
  }

  Future<void> toggle(bool value) async {
    await ref.read(apiProvider).setUseEpisodeImagesInNextUpAndResume(value);
    state = AsyncData(value);
  }
}

final useEpisodeImagesProvider =
    AsyncNotifierProvider<UseEpisodeImagesNotifier, bool>(
  UseEpisodeImagesNotifier.new,
);
