import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/responsive_navigation_bar.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:jellyflix/providers/auth_provider.dart';

class ProfileScreen extends HookConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveNavigationBar(
      selectedIndex: 3,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: () async {
                  await ref.read(authProvider).logout();
                  if (context.mounted) {
                    context.go(ScreenPaths.login);
                  }
                },
                child: const Text("Logout")),
          ],
        ),
      ),
    );
  }
}
