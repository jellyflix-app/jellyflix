import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/quick_connect_dialog.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:jellyflix/providers/auth_provider.dart';

class ProfileScreen extends HookConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 750),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(100),
                                  child:
                                      ref.read(apiProvider).getProfileImage(),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ref
                                        .read(authProvider)
                                        .currentProfile!
                                        .name!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall,
                                  ),
                                  Text(
                                    ref
                                        .read(authProvider)
                                        .currentProfile!
                                        .serverAdress!,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        ListTile(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          leading: const Icon(Icons.group_rounded),
                          title: const Text("Change Profile"),
                          onTap: () async {
                            await ref
                                .read(authProvider)
                                .updateCurrentProfileIndex(null);
                            if (context.mounted) {
                              context.go(ScreenPaths.profileSelection);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          leading: const Icon(Icons.connected_tv_rounded),
                          title: const Text("Quick Connect"),
                          onTap: () {
                            showDialog(
                                context: context,
                                builder: (context) =>
                                    const QuickConnectDialog());
                          },
                        ),
                        ListTile(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          leading: const Icon(Icons.qr_code_rounded),
                          title: const Text("Scan library"),
                          onTap: () async {
                            await ref.read(apiProvider).startLibraryScan();
                            // show snack bar
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Scan started"),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                    ),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      leading: const Icon(Icons.info_rounded),
                      title: const Text("About"),
                      onTap: () {
                        showLicensePage(context: context);
                      },
                    ),
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                    ),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      leading: Icon(Icons.logout,
                          color: Theme.of(context).colorScheme.error),
                      title: const Text("Logout"),
                      onTap: () async {
                        await ref.read(authProvider).logout();

                        if (context.mounted) {
                          context.go(ScreenPaths.login);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
