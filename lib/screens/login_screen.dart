import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/models/screen_paths.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverAddress = useTextEditingController();

    final loadingListenable = useValueNotifier<bool>(false);

    return Scaffold(
      appBar: AppBar(),
      body: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.enter): () async {
            loginToServer(
                context, serverAddress.text, LoginRouteNames.password);
          }
        },
        child: FocusScope(
          // needed for enter shortcut to work
          autofocus: true,
          child: Center(
            child: SingleChildScrollView(
              child: SizedBox(
                width: 400,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: AutofillGroup(
                    child: Column(
                      children: [
                        Text(AppLocalizations.of(context)!.appName,
                            style: Theme.of(context).textTheme.displaySmall),
                        Text(
                          AppLocalizations.of(context)!.appSubtitle,
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: TextField(
                            controller: serverAddress,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText:
                                  AppLocalizations.of(context)!.serverAddress,
                              hintText: 'https://',
                            ),
                          ),
                        ),
                        Center(
                          child: Wrap(spacing: 8.0, runSpacing: 4.0, children: [
                            SizedBox(
                              height: 45,
                              width: 170,
                              child: ValueListenableBuilder(
                                  valueListenable: loadingListenable,
                                  builder: (context, isLoading, _) {
                                    return isLoading
                                        ? const Center(
                                            child: CircularProgressIndicator())
                                        : FilledButton(
                                            onPressed: () => loginToServer(
                                                context,
                                                serverAddress.text,
                                                LoginRouteNames.password),
                                            child: Text(
                                              AppLocalizations.of(context)!
                                                  .loginWithPassword,
                                            ),
                                          );
                                  }),
                            ),
                            SizedBox(
                              height: 45,
                              width: 170,
                              child: ValueListenableBuilder(
                                  valueListenable: loadingListenable,
                                  builder: (context, isLoading, _) {
                                    return isLoading
                                        ? const Center(
                                            child: CircularProgressIndicator())
                                        : FilledButton(
                                            onPressed: () => loginToServer(
                                                context,
                                                serverAddress.text,
                                                LoginRouteNames.quickConnect),
                                            child: Text(
                                              AppLocalizations.of(context)!
                                                  .loginWithQuickConnect,
                                            ),
                                          );
                                  }),
                            ),
                          ]),
                        ),
                        kIsWeb
                            ? Text(AppLocalizations.of(context)!.webDemoNote)
                            : const SizedBox(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void loginToServer(
      BuildContext context, final String serverAddress, String routeName) {
    if (serverAddress.isNotEmpty) {
      context.pushNamed(routeName, pathParameters: {'server': serverAddress});
    }
  }
}
