/* Parent component for all responsive navigation bar subcomponents */
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/jfx_layout.dart';
import 'package:jellyflix/components/jfx_nav_bar/jfx_nav_bar_bottom.dart';
import 'package:jellyflix/components/jfx_nav_bar/jfx_nav_bar_left_full.dart';
import 'package:jellyflix/components/jfx_nav_bar/jfx_nav_bar_left_narrow.dart';
import 'package:jellyflix/models/auth_state.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:jellyflix/providers/auth_provider.dart';

class JfxNavBar extends HookConsumerWidget {
  final Widget body;

  const JfxNavBar({Key? key, required this.body}) : super(key: key);

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
            JfxNavBarLeftNarrow(
                selectedIndex: selectedIndex,
                appLocalizations: AppLocalizations.of(context)!,
                ref: ref,
                showOfflineSnackbar: showOfflineSnackbar,
                layout: layout),

          if (MediaQuery.of(context).size.width >= 1100)
            JfxNavBarLeftFull(
              selectedIndex: selectedIndex,
              appLocalizations: AppLocalizations.of(context)!,
              ref: ref,
              showOfflineSnackbar: showOfflineSnackbar,
            ),
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
