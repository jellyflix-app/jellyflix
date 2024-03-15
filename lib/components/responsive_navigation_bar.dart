import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/navigation_drawer_tile.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:jellyflix/providers/connectivity_provider.dart';
import 'package:jellyflix/services/connectivity_service.dart';

class ResponsiveNavigationBar extends HookConsumerWidget {
  final Widget body;

  const ResponsiveNavigationBar({Key? key, required this.body})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = useState(0);

    // switch index if offline
    ref.read(connectivityProvider).checkConnectivityOnce().then(
      (online) {
        if (!online) {
          selectedIndex.value = 2;
        }
      },
    );
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
                padding:
                    const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10),
                child: NavigationRail(
                  backgroundColor: Colors.transparent,
                  minWidth: 55.0,
                  selectedIndex:
                      selectedIndex.value == 4 ? null : selectedIndex.value,
                  // Called when one tab is selected
                  onDestinationSelected: (int index) async {
                    switch (index) {
                      case 0:
                        bool online = await showOfflineSnackbar(
                            context, ref.read(connectivityProvider));
                        if (online) {
                          selectedIndex.value = 0;
                        }
                        if (!context.mounted) return;
                        context.go(ScreenPaths.home);
                        break;
                      case 1:
                        bool online = await showOfflineSnackbar(
                            context, ref.read(connectivityProvider));
                        if (online) {
                          selectedIndex.value = 1;
                        }
                        if (!context.mounted) return;
                        context.go(ScreenPaths.search);
                        break;
                      case 2:
                        bool online = await showOfflineSnackbar(
                            context, ref.read(connectivityProvider));
                        if (online) {
                          selectedIndex.value = 2;
                        }
                        if (!context.mounted) return;
                        context.go(ScreenPaths.downloads);
                        break;
                      case 3:
                        bool online = await showOfflineSnackbar(
                            context, ref.read(connectivityProvider));
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
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.3)
                              : Colors.transparent,
                        ),
                        child: IconButton(
                            onPressed: () async {
                              bool online = await showOfflineSnackbar(
                                  context, ref.read(connectivityProvider));
                              if (online) {
                                selectedIndex.value = 1;
                              }
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
                        label: Text(AppLocalizations.of(context)!.home)),
                    NavigationRailDestination(
                        icon: const Icon(Icons.search_rounded),
                        label: Text(AppLocalizations.of(context)!.search)),
                    NavigationRailDestination(
                        icon: const Icon(Icons.file_download_outlined),
                        label: Text(AppLocalizations.of(context)!.downloads)),
                    NavigationRailDestination(
                        icon: const Icon(Icons.video_library_outlined),
                        label: Text(AppLocalizations.of(context)!.library)),
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
                        bool online = await showOfflineSnackbar(
                            context, ref.read(connectivityProvider));
                        if (online) {
                          selectedIndex.value = 0;
                        }
                        if (!context.mounted) return;
                        context.go(ScreenPaths.home);
                      },
                    ),
                    NavigationDrawerTile(
                      icon: Icons.search_rounded,
                      label: AppLocalizations.of(context)!.search,
                      selected: selectedIndex.value == 1,
                      onTap: () async {
                        bool online = await showOfflineSnackbar(
                            context, ref.read(connectivityProvider));
                        if (online) {
                          selectedIndex.value = 1;
                        }
                        if (!context.mounted) return;
                        context.go(ScreenPaths.search);
                      },
                    ),
                    NavigationDrawerTile(
                      icon: Icons.file_download_outlined,
                      label: AppLocalizations.of(context)!.downloads,
                      selected: selectedIndex.value == 2,
                      onTap: () async {
                        bool online = await showOfflineSnackbar(
                            context, ref.read(connectivityProvider));
                        if (online) {
                          selectedIndex.value = 2;
                        }
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
                            context, ref.read(connectivityProvider));
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
                      label: AppLocalizations.of(context)!.profile,
                      selected: selectedIndex.value == 4,
                      onTap: () async {
                        bool online = await showOfflineSnackbar(
                            context, ref.read(connectivityProvider));
                        if (online) {
                          selectedIndex.value = 4;
                        }
                        if (!context.mounted) return;
                        context.go(ScreenPaths.profile);
                      },
                    ),
                  ],
                ),
              ),
            ),

          // Main content
          // This part is always shown
          // You will see it on both small and wide screen
          Expanded(child: body),
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
                switch (index) {
                  case 0:
                    bool online = await showOfflineSnackbar(
                        context, ref.read(connectivityProvider));
                    if (online) {
                      selectedIndex.value = 0;
                    }
                    if (!context.mounted) return;
                    context.go(ScreenPaths.home);
                    break;
                  case 1:
                    bool online = await showOfflineSnackbar(
                        context, ref.read(connectivityProvider));
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
                        context, ref.read(connectivityProvider));
                    if (online) {
                      selectedIndex.value = 3;
                    }
                    if (!context.mounted) return;
                    context.go(ScreenPaths.library);
                    break;
                  case 4:
                    bool online = await showOfflineSnackbar(
                        context, ref.read(connectivityProvider));
                    if (online) {
                      selectedIndex.value = 4;
                    }
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
                ])
          : null,
    );
  }

  Future<bool> showOfflineSnackbar(
      BuildContext context, ConnectivityService connectivityService) async {
    if (!await connectivityService.checkConnectivityOnce()) {
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
