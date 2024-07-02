import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:jellyflix/models/auth_state.dart';
import 'package:jellyflix/providers/auth_provider.dart';

class JfxNavBarBottom extends StatelessWidget {
  final ValueNotifier<int> selectedIndex;
  final AppLocalizations appLocalizations;
  final WidgetRef ref;
  final Future<bool> Function(BuildContext, AuthState) showOfflineSnackbar;

  const JfxNavBarBottom({
    super.key,
    required this.selectedIndex,
    required this.appLocalizations,
    required this.ref,
    required this.showOfflineSnackbar,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
        currentIndex: selectedIndex.value,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black26,
        unselectedItemColor: Colors.grey,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        showUnselectedLabels: false,
        // called when one tab is selected
        onTap: (int index) async {
          switch (index) {
            case 0:
              bool online = await showOfflineSnackbar(
                  context, ref.read(authStateProvider.notifier).state);
              if (online) {
                selectedIndex.value = 0;
              }
              if (!context.mounted) return;
              context.go(ScreenPaths.home);
              break;
            case 1:
              bool online = await showOfflineSnackbar(
                  context, ref.read(authStateProvider.notifier).state);
              if (online) {
                selectedIndex.value = 1;
              }
              if (!context.mounted) return;
              context.go(ScreenPaths.search);
              break;
            case 2:
              selectedIndex.value = 2;
              context.go(ScreenPaths.downloads);
              break;
            case 3:
              bool online = await showOfflineSnackbar(
                  context, ref.read(authStateProvider.notifier).state);
              if (online) {
                selectedIndex.value = 3;
              }
              if (!context.mounted) return;
              context.go(ScreenPaths.library);
              break;
            case 4:
              selectedIndex.value = 4;
              if (!context.mounted) return;
              context.go(ScreenPaths.profile);
              break;
          }
        },
        // bottom tab items
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.home_rounded),
              label: AppLocalizations.of(context)!.home),
          BottomNavigationBarItem(
              icon: const Icon(Icons.search_rounded),
              label: AppLocalizations.of(context)!.search),
          BottomNavigationBarItem(
              icon: const Icon(Icons.file_download_outlined),
              label: AppLocalizations.of(context)!.downloads),
          BottomNavigationBarItem(
              icon: const Icon(Icons.video_library_outlined),
              label: AppLocalizations.of(context)!.library),
          BottomNavigationBarItem(
              icon: const Icon(Icons.person_rounded),
              label: AppLocalizations.of(context)!.profile)
        ]);
  }
}
