import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/navigation_drawer_tile.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:jellyflix/providers/router_provider.dart';

class ResponsiveNavigationBar extends HookConsumerWidget {
  final Widget body;

  const ResponsiveNavigationBar({Key? key, required this.body})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  selectedIndex: ref.read(selectedScreenIndexProvider) == 3
                      ? null
                      : ref.read(selectedScreenIndexProvider),
                  // Called when one tab is selected
                  onDestinationSelected: (int index) {
                    switch (index) {
                      case 0:
                        ref.read(selectedScreenIndexProvider.notifier).state =
                            0;
                        context.push(ScreenPaths.home);
                        break;
                      case 1:
                        ref.read(selectedScreenIndexProvider.notifier).state =
                            1;
                        context.push(ScreenPaths.search);
                        break;
                      case 2:
                        ref.read(selectedScreenIndexProvider.notifier).state =
                            2;
                        context.push(ScreenPaths.library);
                        break;
                    }
                  },

                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: ref.read(selectedScreenIndexProvider) == 3
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.3)
                              : Colors.transparent,
                        ),
                        child: IconButton(
                            onPressed: () {
                              ref
                                  .read(selectedScreenIndexProvider.notifier)
                                  .state = 3;
                              context.push(ScreenPaths.profile);
                            },
                            icon: const Icon(Icons.person_rounded)),
                      ),
                    ),
                  ),

                  // navigation rail items
                  destinations: const [
                    NavigationRailDestination(
                        icon: Icon(Icons.home_rounded), label: Text('Home')),
                    NavigationRailDestination(
                        icon: Icon(Icons.search_rounded),
                        label: Text('Search')),
                    NavigationRailDestination(
                        icon: Icon(Icons.video_library_outlined),
                        label: Text('Library')),
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
                      label: "Home",
                      selected: ref.read(selectedScreenIndexProvider) == 0,
                      onTap: () {
                        ref.read(selectedScreenIndexProvider.notifier).state =
                            0;
                        context.push(ScreenPaths.home);
                      },
                    ),
                    NavigationDrawerTile(
                      icon: Icons.search_rounded,
                      label: "Search",
                      selected: ref.read(selectedScreenIndexProvider) == 1,
                      onTap: () {
                        ref.read(selectedScreenIndexProvider.notifier).state =
                            1;
                        context.push(ScreenPaths.search);
                      },
                    ),
                    NavigationDrawerTile(
                      icon: Icons.video_library_outlined,
                      label: "Library",
                      selected: ref.read(selectedScreenIndexProvider) == 2,
                      onTap: () {
                        ref.read(selectedScreenIndexProvider.notifier).state =
                            2;
                        context.push(ScreenPaths.library);
                      },
                    ),
                    const Expanded(
                      child: SizedBox(),
                    ),
                    NavigationDrawerTile(
                      icon: Icons.person_rounded,
                      label: "Profile",
                      selected: ref.read(selectedScreenIndexProvider) == 3,
                      onTap: () {
                        ref.read(selectedScreenIndexProvider.notifier).state =
                            3;
                        context.push(ScreenPaths.profile);
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
              currentIndex: ref.read(selectedScreenIndexProvider),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.black26,
              showSelectedLabels: false,
              unselectedItemColor: Colors.grey,
              selectedItemColor: Theme.of(context).colorScheme.primary,
              showUnselectedLabels: false,
              // called when one tab is selected
              onTap: (int index) {
                switch (index) {
                  case 0:
                    ref.read(selectedScreenIndexProvider.notifier).state = 0;
                    context.push(ScreenPaths.home);
                    break;
                  case 1:
                    ref.read(selectedScreenIndexProvider.notifier).state = 1;
                    context.push(ScreenPaths.search);
                    break;
                  case 2:
                    ref.read(selectedScreenIndexProvider.notifier).state = 2;
                    context.push(ScreenPaths.library);
                    break;
                  case 3:
                    ref.read(selectedScreenIndexProvider.notifier).state = 3;
                    context.push(ScreenPaths.profile);
                    break;
                }
              },
              // bottom tab items
              items: const [
                  BottomNavigationBarItem(
                      icon: Icon(Icons.home_rounded), label: 'Home'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.search_rounded), label: 'Search'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.video_library_outlined),
                      label: 'Library'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.person_rounded), label: 'Profile')
                ])
          : null,
    );
  }
}
