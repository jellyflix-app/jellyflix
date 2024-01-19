import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/responsive_navigation_bar.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:jellyflix/providers/auth_provider.dart';
import 'package:jellyflix/screens/detail_screen.dart';
import 'package:jellyflix/screens/home_screen.dart';
import 'package:jellyflix/screens/library_screen.dart';
import 'package:jellyflix/screens/loading_screen.dart';
import 'package:jellyflix/screens/login_wrapper_screen.dart';
import 'package:jellyflix/screens/profile_screen.dart';
import 'package:jellyflix/screens/search_screen.dart';
import 'package:jellyflix/screens/player_screen.dart';
import 'package:openapi/openapi.dart';

final navigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  GoRouter get router => _goRouter;

  late Ref _ref;

  AppRouter(Ref ref) {
    _ref = ref;
  }

  late final GoRouter _goRouter = GoRouter(
    debugLogDiagnostics: true,
    initialLocation: ScreenPaths.login,
    routes: [
      ShellRoute(
          navigatorKey: shellNavigatorKey,
          pageBuilder: (context, state, child) {
            //print(state.location);
            return NoTransitionPage(
                child: ResponsiveNavigationBar(
              body: child,
            ));
          },
          routes: [
            GoRoute(
              path: ScreenPaths.home,
              pageBuilder: (context, state) => buildPageWithDefaultTransition(
                context: context,
                state: state,
                child: const HomeScreen(),
              ),
            ),
            GoRoute(
              path: ScreenPaths.library,
              pageBuilder: (context, state) => buildPageWithDefaultTransition(
                context: context,
                state: state,
                child: const LibraryScreen(),
              ),
            ),
            GoRoute(
              path: ScreenPaths.detail,
              pageBuilder: (context, state) => CupertinoPage(
                child: DetailScreen(
                  itemId: state.uri.queryParameters['id']!,
                  selectedIndex:
                      int.parse(state.uri.queryParameters['selectedIndex']!),
                ),
              ),
            ),
            GoRoute(
              path: ScreenPaths.search,
              pageBuilder: (context, state) => buildPageWithDefaultTransition(
                context: context,
                state: state,
                child: const SearchScreen(),
              ),
            ),
            GoRoute(
              path: ScreenPaths.profile,
              pageBuilder: (context, state) => buildPageWithDefaultTransition(
                context: context,
                state: state,
                child: const ProfileScreen(),
              ),
            ),
          ]),
      GoRoute(
        path: ScreenPaths.player,
        pageBuilder: (context, state) => buildPageWithDefaultTransition(
          context: context,
          state: state,
          child: PlayerScreen(
              startTimeTicks:
                  int.parse(state.uri.queryParameters['startTimeTicks'] ?? "0"),
              streamUrlAndPlaybackInfo:
                  state.extra as (String, PlaybackInfoResponse)),
        ),
      ),
      GoRoute(
        path: ScreenPaths.login,
        pageBuilder: (context, state) => buildPageWithDefaultTransition(
          context: context,
          state: state,
          maintainState: false,
          child: const LoginWrapperScreen(),
        ),
      ),
    ],
    errorBuilder: (context, state) {
      //TODO Add 404 screen
      return const LoadingScreen();
    },
    redirect: (context, state) async {
      final isGoingToLogin = state.matchedLocation == ScreenPaths.login;
      final loggedIn = await _ref.watch(authProvider).checkAuthentication();
      if (isGoingToLogin && loggedIn) {
        return ScreenPaths.home;
      } else if (!isGoingToLogin && !loggedIn) {
        return ScreenPaths.login;
      }
      return null;
    },
    //refreshListenable: GoRouterRefreshStream(_ref),
    navigatorKey: navigatorKey,
  );

  CustomTransitionPage buildPageWithDefaultTransition<T>({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
    bool maintainState = true,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      maintainState: maintainState,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  final Ref _ref;
  late final Stream<bool> authState;
  GoRouterRefreshStream(this._ref) {
    notifyListeners();
    authState = _ref.read(authProvider).authStateChange;
    authState.listen((event) {
      notifyListeners();
    });
  }
}
