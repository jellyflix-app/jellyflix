import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/profile_card.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:jellyflix/providers/auth_provider.dart';
import 'package:jellyflix/screens/login_screen.dart';

class ProfileSelectionScreen extends HookConsumerWidget {
  const ProfileSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
        appBar: AppBar(title: const Text("Select Profile")),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60.0),
          child: FutureBuilder(
            future: ref.read(authProvider).getAllProfiles(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 750),
                    child: Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      alignment: WrapAlignment.start,
                      children:
                          List.generate(snapshot.data!.length + 1, (index) {
                        if (index == snapshot.data!.length) {
                          return ProfileCard(
                            title: "Add Profile",
                            subtitle: "",
                            image: const Icon(
                              Icons.add,
                              size: 50,
                            ),
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => const LoginScreen()));
                            },
                          );
                        }

                        return ProfileCard(
                            title: snapshot.data![index].name!,
                            subtitle: snapshot.data![index].serverAdress!,
                            image: SizedBox(
                              width: 100,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(100),
                                child: ref
                                    .read(apiProvider)
                                    .getProfileImage(snapshot.data![index]),
                              ),
                            ),
                            onTap: () async {
                              await ref
                                  .read(authProvider)
                                  .updateCurrentProfileIndex(
                                      snapshot.data![index].profileIndex!);
                              if (context.mounted) {
                                context.push(ScreenPaths.home);
                              }
                            });
                      }),
                    ),
                  ),
                );
              }
              return const Center(
                child: Text("Bla"),
              );
            },
          ),
        ));
  }
}
