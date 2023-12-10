import 'package:jellyflix/providers/auth_provider.dart';
import 'package:jellyflix/screens/home_screen.dart';
import 'package:jellyflix/screens/loading_screen.dart';
import 'package:jellyflix/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:media_kit/media_kit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Necessary initialization for package:media_kit.
  MediaKit.ensureInitialized();
  runApp(const ProviderScope(
    child: MyApp(),
  ));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Another Jellyfin Client',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: FutureBuilder(
        future: ref.read(authProvider).checkAuthentication(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!) {
              return const HomeScreen();
            } else {
              return const LoginScreen();
            }
          } else {
            return const LoadingScreen();
          }
        },
      ),
    );
  }
}
