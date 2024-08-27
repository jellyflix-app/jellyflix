import 'package:dio/dio.dart';
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
                          final missingFields = formatMissingFields(
                            context,
                            userName.text,
                            password.text,
                            serverAddress.text,
                          );
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
                        } on DioException catch (e) {
                          if (!context.mounted) return;
                          await showInfoDialog(
                            context,
                            Text(
                              AppLocalizations.of(context)!
                                  .errorConnectingToServer,
                            ),
                            content: e.response?.statusCode == null
                                ? Text(e.toString())
                                : Text(formatHttpErrorCode(e.response)),
                          );
                          return;
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

  String formatMissingFields(BuildContext context, String username,
      String password, String serverAddress) {
    var missingFields = '';
    if (username.isEmpty) {
      missingFields += '${AppLocalizations.of(context)!.emptyUsername}\n\n';
    }
    if (password.isEmpty) {
      missingFields += '${AppLocalizations.of(context)!.emptyPassword}\n\n';
    }
    if (serverAddress.isEmpty) {
      missingFields += '${AppLocalizations.of(context)!.emptyAddress}\n\n';
    }

    return missingFields;
  }

  String formatHttpErrorCode(Response? resp) {
    var message = '';
    switch (resp!.statusCode) {
      case 400:
        message =
            'Something went wrong while making the request, this is probably a issue within Jellyflix, please open a github issue';
      case 401:
        message = 'Your username or password may be incorrect';
      case 403:
        message =
            'The Server has probably banned this IP, please contact your admin to resolve this issue';
      default:
        message = '';
    }

    return '$message\n\n'
            'Http Code: ${resp.statusCode ?? 'Unknown'}\n\n'
            'Http Response: ${resp.statusMessage ?? 'Unknown'}\n\n'
        .trim();
  }
}
