/* Parent component for all responsive navigation bar subcomponents */
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/jfx_nav_bar_buttons.dart';
import 'package:jellyflix/models/auth_state.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:jellyflix/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:jellyflix/models/screen_paths.dart';

class JfxNavBar extends HookConsumerWidget {
  final Widget body;

  const JfxNavBar({Key? key, required this.body}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = useState(
        ref.read(authStateProvider.notifier).state == AuthState.offline
            ? 2
            : 0);

    return Scaffold(
      body: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Show the navigaiton rail if screen width >= 640
          if (MediaQuery.of(context).size.width >= 640)
            JfxNavBarLeft(
                selectedIndex: selectedIndex,
                appLocalizations: AppLocalizations.of(context)!,
                ref: ref,
                showOfflineSnackbar: showOfflineSnackbar),
          // Main content
          // This part is always shown
          // You will see it on both small and wide screen
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width < 640
          ? JfxNavBarBottom(
              selectedIndex: selectedIndex,
              appLocalizations: AppLocalizations.of(context)!,
              ref: ref,
              showOfflineSnackbar: showOfflineSnackbar,
            )
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

class JfxNavBarLeft extends StatelessWidget {
  final ValueNotifier<int> selectedIndex;
  final AppLocalizations appLocalizations;
  final WidgetRef ref;
  final Future<bool> Function(BuildContext, AuthState) showOfflineSnackbar;

  const JfxNavBarLeft({
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
            JfxNavBarButtonSmall(
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
            JfxNavBarButtonSmall(
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
            JfxNavBarButtonSmall(
              icon: Icons.file_download_outlined,
              label: appLocalizations.downloads,
              selected: selectedIndex.value == 2,
              onTap: () async {
                selectedIndex.value = 2;
                if (!context.mounted) return;
                context.go(ScreenPaths.downloads);
              },
            ),
            JfxNavBarButtonSmall(
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
            JfxNavBarPopupMenuButton(
              icon: Icons.video_library_outlined,
              label: 'More',
              selected: selectedIndex.value == 9,
              onOpened: () {},
              onCanceled: () {},
              onSelected: () async {
                bool online = await showOfflineSnackbar(
                    context, ref.read(authStateProvider.notifier).state);
                if (online) {
                  selectedIndex.value = 9;
                }
              },
              items: const [
                PopupMenuItem<String>(
                  value: 'hello',
                  child: Text('Hello'),
                ),
                PopupMenuItem<String>(
                  value: 'about',
                  child: Text('About'),
                ),
                PopupMenuItem<String>(
                  value: 'contact',
                  child: Text('Contact'),
                ),
              ],
            ),
            const Expanded(
              child: SizedBox(),
            ),
            JfxNavBarTile(
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
