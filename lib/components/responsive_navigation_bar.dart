import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/jfx_layout.dart';
import 'package:jellyflix/components/navigation_drawer_tile.dart';
import 'package:jellyflix/models/auth_state.dart';
import 'package:jellyflix/l10n/generated/app_localizations.dart';
import 'package:jellyflix/providers/auth_provider.dart';

class ResponsiveNavigationBar extends HookConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const ResponsiveNavigationBar({Key? key, required this.navigationShell})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = useState(
        ref.read(authStateProvider.notifier).state == AuthState.offline
            ? 2
            : 0);
    final JfxLayout layout = JfxLayout.scalingLayout(context);

    return Scaffold(
      body: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Show the navigaiton rail if screen width >= 640
          if (MediaQuery.of(context).size.width >= 640 &&
              MediaQuery.of(context).size.width < 1100)
            Container(
              decoration: BoxDecoration(
                  // add elevation
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
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
                padding:
                    const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10),
                child: NavigationRail(
                  backgroundColor: Colors.transparent,
                  minWidth: 55.0,
                  selectedIndex:
                      selectedIndex.value == 4 ? null : selectedIndex.value,
                  // Called when one tab is selected
                  onDestinationSelected: (int index) async {
                    bool online = await showOfflineSnackbar(
                        context, ref.read(authStateProvider.notifier).state);
                    if (online || index == 2) {
                      selectedIndex.value = index;
                    }
                    navigationShell.goBranch(
                      index,
                      initialLocation: index == navigationShell.currentIndex,
                    );
                  },

                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: selectedIndex.value == 4
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.3)
                              : Colors.transparent,
                        ),
                        child: IconButton(
                            onPressed: () async {
                              selectedIndex.value = 4;
                              navigationShell.goBranch(4,
                                  initialLocation:
                                      navigationShell.currentIndex == 4);
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
            ),

          if (MediaQuery.of(context).size.width >= 1100)
            Container(
              decoration: BoxDecoration(
                  // add elevation
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
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
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NavigationDrawerTile(
                      icon: Icons.home_rounded,
                      label: AppLocalizations.of(context)!.home,
                      selected: selectedIndex.value == 0,
                      onTap: () async {
                        bool online = await showOfflineSnackbar(context,
                            ref.read(authStateProvider.notifier).state);
                        if (online) {
                          selectedIndex.value = 0;
                        }
                        navigationShell.goBranch(0,
                            initialLocation: navigationShell.currentIndex == 0);
                      },
                    ),
                    NavigationDrawerTile(
                      icon: Icons.search_rounded,
                      label: AppLocalizations.of(context)!.search,
                      selected: selectedIndex.value == 1,
                      onTap: () async {
                        bool online = await showOfflineSnackbar(context,
                            ref.read(authStateProvider.notifier).state);
                        if (online) {
                          selectedIndex.value = 1;
                        }
                        navigationShell.goBranch(1,
                            initialLocation: navigationShell.currentIndex == 1);
                      },
                    ),
                    NavigationDrawerTile(
                      icon: Icons.file_download_outlined,
                      label: AppLocalizations.of(context)!.downloads,
                      selected: selectedIndex.value == 2,
                      onTap: () async {
                        selectedIndex.value = 2;
                        navigationShell.goBranch(2,
                            initialLocation: navigationShell.currentIndex == 2);
                      },
                    ),
                    NavigationDrawerTile(
                      icon: Icons.video_library_outlined,
                      label: AppLocalizations.of(context)!.library,
                      selected: selectedIndex.value == 3,
                      onTap: () async {
                        bool online = await showOfflineSnackbar(context,
                            ref.read(authStateProvider.notifier).state);
                        if (online) {
                          selectedIndex.value = 3;
                        }
                        navigationShell.goBranch(3,
                            initialLocation: navigationShell.currentIndex == 3);
                      },
                    ),
                    const Expanded(
                      child: SizedBox(),
                    ),
                    NavigationDrawerTile(
                      icon: Icons.person_rounded,
                      label: AppLocalizations.of(context)!.profile,
                      selected: selectedIndex.value == 4,
                      onTap: () async {
                        selectedIndex.value = 4;
                        navigationShell.goBranch(4,
                            initialLocation: navigationShell.currentIndex == 4);
                      },
                    ),
                  ],
                ),
              ),
            ),

          // Main content
          // This part is always shown
          // You will see it on both small and wide screen
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width < 640
          ? BottomNavigationBar(
              currentIndex: selectedIndex.value,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.black26,
              unselectedItemColor: Colors.grey,
              selectedItemColor: Theme.of(context).colorScheme.primary,
              showUnselectedLabels: false,
              // called when one tab is selected
              onTap: (int index) async {
                bool online = await showOfflineSnackbar(
                    context, ref.read(authStateProvider.notifier).state);
                if (online || index == 2 || index == 4) {
                  selectedIndex.value = index;
                }
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
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
                ])
          : null,
    );
  }

  Future<bool> showOfflineSnackbar(
      BuildContext context, AuthState authState) async {
    if (authState == AuthState.offline) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.offlineNotice),
            duration: const Duration(seconds: 1),
          ),
        );
      }
      // is Offline
      return false;
    }
    // is Online
    return true;
  }
}
