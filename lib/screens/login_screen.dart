import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:jellyflix/models/user.dart';
import 'package:jellyflix/providers/auth_provider.dart';

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
                    autofillHints: const [AutofillHints.url],
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: AppLocalizations.of(context)!.serverAddress,
                      hintText: 'http://',
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: TextField(
                    autofillHints: const [AutofillHints.username],
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
                    autofillHints: const [AutofillHints.password],
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
                          var missingFields = '';
                          if (userName.text.isEmpty) {
                            missingFields +=
                                '${AppLocalizations.of(context)!.emptyUsername}\n\n';
                          }
                          if (password.text.isEmpty) {
                            missingFields +=
                                '${AppLocalizations.of(context)!.emptyPassword}\n\n';
                          }
                          if (serverAddress.text.isEmpty) {
                            missingFields +=
                                '${AppLocalizations.of(context)!.emptyAddress}\n\n';
                          }

                          if (missingFields.isNotEmpty) {
                            await showInfoDialog(
                              context,
                              Text(
                                AppLocalizations.of(context)!.emptyFields,
                              ),
                              content: Text(missingFields),
                            );
                            return;
                          }

                          User user = User(
                            name: userName.text,
                            password: password.text,
                            serverAdress: serverAddress.text,
                          );
                          await ref.read(authProvider).login(user);
                          if (context.mounted) {
                            context.go(ScreenPaths.home);
                          }
                        } catch (e) {
                          if (!context.mounted) return;
                          await showInfoDialog(
                            context,
                            Text(AppLocalizations.of(context)!
                                .errorConnectingToServer),
                            content: Text(e.toString()),
                          );
                          return;
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

  Future<void> showInfoDialog(
    BuildContext context,
    Widget title, {
    Widget? content,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: title,
        content: content,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Ok'),
          )
        ],
      ),
    );
  }
}
