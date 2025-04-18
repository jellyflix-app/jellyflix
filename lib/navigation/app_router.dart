import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/models/auth_state.dart';

import 'package:jellyflix/components/responsive_navigation_bar.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:jellyflix/providers/auth_provider.dart';
import 'package:jellyflix/providers/connectivity_provider.dart';
import 'package:jellyflix/screens/detail_screen.dart';
import 'package:jellyflix/screens/download_screen.dart';
import 'package:jellyflix/screens/home_screen.dart';
import 'package:jellyflix/screens/library_screen.dart';
import 'package:jellyflix/screens/loading_screen.dart';
import 'package:jellyflix/screens/login_password_screen.dart';
import 'package:jellyflix/screens/login_quickconnect_screen.dart';
import 'package:jellyflix/screens/login_wrapper_screen.dart';
import 'package:jellyflix/screens/profile_screen.dart';
import 'package:jellyflix/screens/search_screen.dart';
import 'package:jellyflix/screens/player_screen.dart';
import 'package:jellyflix/services/player_helper.dart';

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
                child: LibraryScreen(
                  filterTypeParam: state.uri.queryParameters['filterType'],
                  genreFilterParam: state.uri.queryParameters['genreFilter'],
                  pageNumberParam: state.uri.queryParameters['pageNumber'],
                  sortOrderParam: state.uri.queryParameters['sortOrder'],
                  sortTypeParam: state.uri.queryParameters['sortType'],
                  libraryParam: state.uri.queryParameters['library'],
                ),
              ),
            ),
            GoRoute(
              path: ScreenPaths.detail,
              pageBuilder: (context, state) => CupertinoPage(
                child: DetailScreen(
                  itemId: state.uri.queryParameters['id']!,
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
            GoRoute(
              path: ScreenPaths.downloads,
              pageBuilder: (context, state) => buildPageWithDefaultTransition(
                context: context,
                state: state,
                child: const DownloadScreen(),
              ),
            ),
            GoRoute(
                path: ScreenPaths.loading,
                pageBuilder: (context, state) => buildPageWithDefaultTransition(
                    context: context,
                    state: state,
                    child: const LoadingScreen())),
          ]),
      GoRoute(
        path: ScreenPaths.player,
        pageBuilder: (context, state) => buildPageWithDefaultTransition(
          context: context,
          state: state,
          child: PlayerScreen(
              startTimeTicks:
                  int.parse(state.uri.queryParameters['startTimeTicks'] ?? "0"),
              playerHelper: state.extra as PlayerHelper,
              title: state.uri.queryParameters['title'] ?? ""),
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
      GoRoute(
        path: '${ScreenPaths.login}/:server/${LoginRouteNames.password}',
        name: LoginRouteNames.password,
        pageBuilder: (context, state) => buildPageWithDefaultTransition(
          context: context,
          state: state,
          maintainState: false,
          child: LoginPasswordScreen(
              serverAddress: state.pathParameters['server']!),
        ),
      ),
      GoRoute(
        path: '${ScreenPaths.login}/:server/${LoginRouteNames.quickConnect}',
        name: LoginRouteNames.quickConnect,
        pageBuilder: (context, state) => buildPageWithDefaultTransition(
          context: context,
          state: state,
          maintainState: false,
          child: LoginQuickConnectScreen(
              serverAddress: state.pathParameters['server']!),
        ),
      ),
    ],
    errorBuilder: (context, state) {
      //TODO Add 404 screen
      return const LoadingScreen();
    },
    redirect: (context, state) async {
      final isGoingToOfflinePlayer =
          state.matchedLocation == ScreenPaths.player;
      final isGoingToDownloads = state.matchedLocation == ScreenPaths.downloads;
      final isGoingToLogin = state.matchedLocation == ScreenPaths.login;
      final isGoingToProfile = state.matchedLocation == ScreenPaths.profile;
      final isConnected =
          await _ref.read(connectivityProvider).checkConnectivityOnce();

      // start connection check
      _ref.read(updateServerReachableProvider);

      // bool? serverIsReachable;
      // bool loggedIn = false;

      // if (isConnected) {
      //   serverIsReachable =
      //       await _ref.read(authProvider).checkServerReachable();
      // }

      // if (serverIsReachable == true) {
      //   loggedIn = await _ref.watch(authProvider).checkAuthentication();
      // }

      // if (isConnected && serverIsReachable != false) {
      //   if (isGoingToLogin && loggedIn) {
      //     return ScreenPaths.home;
      //   } else if (!isGoingToLogin && !loggedIn) {
      //     return ScreenPaths.login;
      //   }
      //   return null;
      // } else {
      //   if (!isGoingToDownloads &&
      //       !isGoingToOfflinePlayer &&
      //       !isGoingToProfile &&
      //       !isGoingToLogin) {
      //     return ScreenPaths.downloads;
      //   }
      //   return null;
      // }
      if (isConnected &&
          (_ref.read(authStateProvider.notifier).state == AuthState.loggedIn ||
              _ref.read(authStateProvider.notifier).state ==
                  AuthState.loggedOut ||
              _ref.read(authStateProvider.notifier).state ==
                  AuthState.unknown)) {
        if (isGoingToLogin &&
            _ref.read(authStateProvider.notifier).state == AuthState.loggedIn) {
          return ScreenPaths.home;
        } else if (!isGoingToLogin &&
            _ref.read(authStateProvider.notifier).state ==
                AuthState.loggedOut) {
          return ScreenPaths.login;
        }
        return null;
      } else {
        if (!isGoingToDownloads &&
            !isGoingToOfflinePlayer &&
            !isGoingToProfile &&
            !isGoingToLogin) {
          return ScreenPaths.downloads;
        }
        return null;
      }
    },
    refreshListenable: GoRouterRefreshStream(_ref),
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
  GoRouterRefreshStream(this._ref) {
    _ref.watch(authStateStreamControllerProvider).stream.listen((event) {
      notifyListeners();
    });
  }
}
