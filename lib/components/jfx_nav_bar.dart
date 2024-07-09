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

    final screenWidth = MediaQuery.of(context).size.width;

    AppLocalizations appLocalizations = AppLocalizations.of(context)!;

    List<Widget> navButtons = [
      JfxNavBarButton(
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
      JfxNavBarButton(
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
      JfxNavBarButton(
        icon: Icons.file_download_outlined,
        label: appLocalizations.downloads,
        selected: selectedIndex.value == 2,
        onTap: () async {
          selectedIndex.value = 2;
          if (!context.mounted) return;
          context.go(ScreenPaths.downloads);
        },
      ),
      JfxNavBarButton(
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
      JfxNavBarButton(
        icon: Icons.person_rounded,
        label: appLocalizations.profile,
        selected: selectedIndex.value == 4,
        onTap: () async {
          selectedIndex.value = 4;
          if (!context.mounted) return;
          context.go(ScreenPaths.profile);
        },
      ),
    ];

    return Scaffold(
      body: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Show the navigaiton rail if screen width >= 640
          if (MediaQuery.of(context).size.width >= 640)
            JfxNavBarLeft(
                items: navButtons,
                selectedIndex: selectedIndex,
                appLocalizations: appLocalizations,
                ref: ref,
                showOfflineSnackbar: showOfflineSnackbar),
          // Main content
          // This part is always shown
          // You will see it on both small and wide screen
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: screenWidth < 640
          ? JfxNavBarBottom(
              items: navButtons,
              selectedIndex: selectedIndex,
              appLocalizations: appLocalizations,
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
  final List<Widget> items;

  const JfxNavBarLeft({
    super.key,
    required this.selectedIndex,
    required this.appLocalizations,
    required this.ref,
    required this.showOfflineSnackbar,
    required this.items,
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
          children: items,
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
  final List<Widget> items;

  const JfxNavBarBottom({
    super.key,
    required this.selectedIndex,
    required this.appLocalizations,
    required this.ref,
    required this.showOfflineSnackbar,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
        child: Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items,
    ));
  }
}
