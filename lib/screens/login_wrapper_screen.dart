import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/providers/auth_provider.dart';
import 'package:jellyflix/screens/loading_screen.dart';
import 'package:jellyflix/screens/login_screen.dart';
import 'package:jellyflix/screens/profile_selection_screen.dart';

class LoginWrapperScreen extends HookConsumerWidget {
  const LoginWrapperScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
        future: ref.read(authProvider).getAllProfiles(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.isEmpty) {
              return const LoginScreen();
            } else {
              return const ProfileSelectionScreen();
            }
          } else {
            return const LoadingScreen();
          }
        });
  }
}
