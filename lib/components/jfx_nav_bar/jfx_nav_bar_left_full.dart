import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/navigation_drawer_tile.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:jellyflix/models/auth_state.dart';
import 'package:jellyflix/providers/auth_provider.dart';

class JfxNavBarLeftFull extends StatelessWidget {
  final ValueNotifier<int> selectedIndex;
  final AppLocalizations appLocalizations;
  final WidgetRef ref;
  final Future<bool> Function(BuildContext, AuthState) showOfflineSnackbar;

  const JfxNavBarLeftFull({
    super.key,
    required this.selectedIndex,
    required this.appLocalizations,
    required this.ref,
    required this.showOfflineSnackbar,
  });

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
        color: Colors.black26,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NavigationDrawerTile(
              icon: Icons.home_rounded,
              label: appLocalizations.home,
              selected: selectedIndex.value == 0,
              onTap: () async {
                bool online = await showOfflineSnackbar(
                    context, ref.read(authStateProvider.notifier).state);
                if (online) {
                  selectedIndex.value = 0;
                }
                if (!context.mounted) return;
                context.go(ScreenPaths.home);
              },
            ),
            NavigationDrawerTile(
              icon: Icons.search_rounded,
              label: appLocalizations.search,
              selected: selectedIndex.value == 1,
              onTap: () async {
                bool online = await showOfflineSnackbar(
                    context, ref.read(authStateProvider.notifier).state);
                if (online) {
                  selectedIndex.value = 1;
                }
                if (!context.mounted) return;
                context.go(ScreenPaths.search);
              },
            ),
            NavigationDrawerTile(
              icon: Icons.file_download_outlined,
              label: appLocalizations.downloads,
              selected: selectedIndex.value == 2,
              onTap: () async {
                selectedIndex.value = 2;
                if (!context.mounted) return;
                context.go(ScreenPaths.downloads);
              },
            ),
            NavigationDrawerTile(
              icon: Icons.video_library_outlined,
              label: AppLocalizations.of(context)!.library,
              selected: selectedIndex.value == 3,
              onTap: () async {
                bool online = await showOfflineSnackbar(
                    context, ref.read(authStateProvider.notifier).state);
                if (online) {
                  selectedIndex.value = 3;
                }
                if (!context.mounted) return;
                context.go(ScreenPaths.library);
              },
            ),
            const Expanded(
              child: SizedBox(),
            ),
            NavigationDrawerTile(
              icon: Icons.person_rounded,
              label: appLocalizations.profile,
              selected: selectedIndex.value == 4,
              onTap: () async {
                selectedIndex.value = 4;
                if (!context.mounted) return;
                context.go(ScreenPaths.profile);
              },
            ),
          ],
        ),
      ),
    );
  }
}
