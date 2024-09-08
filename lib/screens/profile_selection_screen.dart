import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/profile_card.dart';
import 'package:jellyflix/components/profile_image.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:jellyflix/providers/auth_provider.dart';
import 'package:jellyflix/screens/login_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProfileSelectionScreen extends HookConsumerWidget {
  const ProfileSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allProfiles = ref.watch(allProfilesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.selectProfile)),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: allProfiles.when(
          data: (data) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 750),
              child: Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.start,
                children: List.generate(data.length + 1, (index) {
                  if (index == data.length) {
                    return ProfileCard(
                      title: AppLocalizations.of(context)!.addProfile,
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
                    title: data[index].name!,
                    subtitle: data[index].serverAdress!,
                    id: data[index].id!,
                    image: SizedBox(
                      width: 100,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: ProfileImage(user: data[index]),
                      ),
                    ),
                    showDelButton: true,
                    onTap: () {
                      ref.read(authProvider).logout();
                      ref.read(authProvider).updateCurrentProfileId(
                          data[index].id! + data[index].serverAdress!);
                      context.push(ScreenPaths.loading);
                    },
                  );
                }),
              ),
            ),
          ),
          error: (error, stackTrace) => Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                'Error fetching profiles',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Text(error.toString()),
              IconButton(
                onPressed: () => ref.invalidate(allProfilesProvider),
                icon: const Icon(Icons.refresh),
              )
            ],
          ),
          loading: () => const CircularProgressIndicator(),
        ),
      ),
    );
  }
}
