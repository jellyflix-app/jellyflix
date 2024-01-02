import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:jellyflix/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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
                Text("Jellyflix",
                    style: Theme.of(context).textTheme.displaySmall),
                const Text(
                  "Another Jellyfin Client",
                ),
                const SizedBox(
                  height: 20,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: TextField(
                    controller: serverAddress,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Server Address',
                        hintText: 'http://'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: TextField(
                    controller: userName,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'User Name',
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: TextField(
                    obscureText: true,
                    controller: password,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Password',
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
                      child: const Text("Login"),
                    ),
                  ),
                ),
                kIsWeb
                    ? const Text(
                        "This is a demo version of Jellyflix. To use it, you can use the following credentials: \n\nServer Address: https://demo.jellyfin.org/stable \nUser Name: demo \nand empty password \n\n")
                    : const SizedBox(),
              ],
            ),
          ),
        ),
      )),
    );
  }
}
