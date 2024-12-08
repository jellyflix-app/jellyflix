import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:jellyflix/models/user.dart';
import 'package:jellyflix/providers/auth_provider.dart';
import 'package:jellyflix/components/login_messages.dart';

class LoginPasswordScreen extends HookConsumerWidget {
  final String serverAddress;
  const LoginPasswordScreen({super.key, required this.serverAddress});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = useTextEditingController();
    final password = useTextEditingController();

    final loadingListenable = useValueNotifier<bool>(false);

    return Scaffold(
      appBar: AppBar(),
      body: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.enter): () async {
            await login(
              context,
              ref,
              loadingListenable,
              username: userName.text,
              serverAddress: serverAddress,
              password: password.text,
            );
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
                          child: Text(
                            serverAddress,
                            textAlign: TextAlign.left,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: TextField(
                            controller: userName,
                            autofillHints: const [AutofillHints.username],
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
                            autofillHints: const [AutofillHints.password],
                            textInputAction: TextInputAction.go,
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
                              child: ValueListenableBuilder(
                                  valueListenable: loadingListenable,
                                  builder: (context, isLoading, _) {
                                    return isLoading
                                        ? const Center(
                                            child: CircularProgressIndicator())
                                        : FilledButton(
                                            onPressed: () async => await login(
                                              context,
                                              ref,
                                              loadingListenable,
                                              username: userName.text,
                                              serverAddress: serverAddress,
                                              password: password.text,
                                            ),
                                            child: Text(
                                              AppLocalizations.of(context)!
                                                  .login,
                                            ),
                                          );
                                  }),
                            )),
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

  Future<void> login(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> loadingListenable, {
    required String serverAddress,
    required String username,
    required String password,
  }) async {
    loadingListenable.value = true;
    try {
      final missingFields = formatMissingFields(
        context,
        username,
        serverAddress,
      );
      if (missingFields.isNotEmpty) {
        loadingListenable.value = false;
        await LoginMessages.showInfoDialog(
          context,
          Text(
            AppLocalizations.of(context)!.emptyFields,
          ),
          content: Text(missingFields),
        );

        return;
      }

      User user = User(
        name: username,
        password: password,
        serverAdress: serverAddress,
      );
      await ref.read(authProvider).login(user);
      loadingListenable.value = false;
      if (context.mounted) {
        context.go(ScreenPaths.home);
      }
    } on DioException catch (e) {
      if (!context.mounted) return;
      loadingListenable.value = false;
      await LoginMessages.showHttpErrorDialog(context, e);
      return;
    } catch (e) {
      if (!context.mounted) return;
      loadingListenable.value = false;
      await LoginMessages.showErrorDialog(context, e);
      return;
    }
    loadingListenable.value = false;
  }
}

String formatMissingFields(
  BuildContext context,
  String username,
  String serverAddress,
) {
  var missingFields = '';
  if (username.isEmpty) {
    missingFields += '${AppLocalizations.of(context)!.emptyUsername}\n\n';
  }
  if (serverAddress.isEmpty) {
    missingFields += '${AppLocalizations.of(context)!.emptyAddress}\n\n';
  }

  return missingFields;
}
