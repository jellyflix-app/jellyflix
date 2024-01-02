import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/profile_card.dart';
import 'package:jellyflix/models/screen_paths.dart';
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
                    constraints: BoxConstraints(maxWidth: 750),
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
                            title: snapshot.data![index].$2,
                            subtitle: snapshot.data![index].$3,
                            image: CircleAvatar(
                                radius: 50,
                                backgroundImage: NetworkImage(
                                    "https://www.gravatar.com/avatar/205e460b479e2e5b48aec07710c08d50?s=200")),
                            onTap: () async {
                              await ref
                                  .read(authProvider)
                                  .updateCurrentProfileIndex(
                                      snapshot.data![index].$1);
                              context.push(ScreenPaths.home);
                            });
                      }),
                    ),
                  ),
                );
              }
              return Center(
                child: Text("Bla"),
              );
            },
          ),
        ));
  }
}
