import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/jfx_layout.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:jellyflix/models/auth_state.dart';
import 'package:jellyflix/providers/auth_provider.dart';

class JfxNavBarLeftNarrow extends StatelessWidget {
  final ValueNotifier<int> selectedIndex;
  final AppLocalizations appLocalizations;
  final WidgetRef ref;
  final JfxLayout layout;
  final Future<bool> Function(BuildContext, AuthState) showOfflineSnackbar;

  const JfxNavBarLeftNarrow(
      {super.key,
      required this.selectedIndex,
      required this.appLocalizations,
      required this.ref,
      required this.showOfflineSnackbar,
      required this.layout});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          // add elevation
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              spreadRadius: 5,
            )
          ],
          // right corners are rounded
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
          color: Colors.black26),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10),
        child: NavigationRail(
          backgroundColor: Colors.transparent,
          minWidth: 55.0,
          selectedIndex: selectedIndex.value == 4 ? null : selectedIndex.value,
          // Called when one tab is selected
          onDestinationSelected: (int index) async {
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

                if (!context.mounted) return;
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
            }
          },

          trailing: Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: selectedIndex.value == 4
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                      : Colors.transparent,
                ),
                child: IconButton(
                    onPressed: () async {
                      selectedIndex.value = 4;
                      if (!context.mounted) return;
                      context.go(ScreenPaths.profile);
                    },
                    icon: const Icon(Icons.person_rounded)),
              ),
            ),
          ),

          // navigation rail items
          destinations: [
            NavigationRailDestination(
                icon: const Icon(Icons.home_rounded),
                label: Text(AppLocalizations.of(context)!.home,
                    style: layout.text.bodyLarge)),
            NavigationRailDestination(
                icon: const Icon(Icons.search_rounded),
                label: Text(AppLocalizations.of(context)!.search,
                    style: layout.text.bodyLarge)),
            NavigationRailDestination(
                icon: const Icon(Icons.file_download_outlined),
                label: Text(AppLocalizations.of(context)!.downloads,
                    style: layout.text.bodyLarge)),
            NavigationRailDestination(
                icon: const Icon(Icons.video_library_outlined),
                label: Text(AppLocalizations.of(context)!.library,
                    style: layout.text.bodyLarge)),
          ],
        ),
      ),
    );
  }
}
