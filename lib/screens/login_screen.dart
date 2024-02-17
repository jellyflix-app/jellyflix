import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:jellyflix/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = useTextEditingController();
    final password = useTextEditingController();
    final serverAddress = useTextEditingController();
    return Scaffold(
      appBar: AppBar(),
      body: Center(
          child: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Text(AppLocalizations.of(context)!.appName,
                    style: Theme.of(context).textTheme.displaySmall),
                Text(
                  AppLocalizations.of(context)!.appSubtitle,
                ),
                const SizedBox(
                  height: 20,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: TextField(
                    controller: serverAddress,
                    decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: AppLocalizations.of(context)!.serverAddress,
                        hintText: 'http://'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: TextField(
                    controller: userName,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: AppLocalizations.of(context)!.username,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: TextField(
                    obscureText: true,
                    controller: password,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: AppLocalizations.of(context)!.password,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: SizedBox(
                    height: 45,
                    width: 100,
                    child: FilledButton(
                      onPressed: () async {
                        try {
                          await ref.read(authProvider).login(
                              serverAddress.text, userName.text, password.text);
                          if (context.mounted) {
                            context.go(ScreenPaths.home);
                          }
                        } catch (e) {
                          // TODO: show error message to user
                          //print(e);
                        }
                      },
                      child: Text(AppLocalizations.of(context)!.login),
                    ),
                  ),
                ),
                kIsWeb
                    ? Text(AppLocalizations.of(context)!.webDemoNote)
                    : const SizedBox(),
              ],
            ),
          ),
        ),
      )),
    );
  }
}
