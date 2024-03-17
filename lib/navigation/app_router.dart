import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:universal_io/io.dart';
import 'package:openapi/openapi.dart';

import 'package:jellyflix/components/responsive_navigation_bar.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:jellyflix/providers/auth_provider.dart';
import 'package:jellyflix/providers/connectivity_provider.dart';
import 'package:jellyflix/screens/detail_screen.dart';
import 'package:jellyflix/screens/download_screen.dart';
import 'package:jellyflix/screens/home_screen.dart';
import 'package:jellyflix/screens/library_screen.dart';
import 'package:jellyflix/screens/loading_screen.dart';
import 'package:jellyflix/screens/login_wrapper_screen.dart';
import 'package:jellyflix/screens/offline_player_screen.dart';
import 'package:jellyflix/screens/profile_screen.dart';
import 'package:jellyflix/screens/search_screen.dart';
import 'package:jellyflix/screens/player_screen.dart';

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
                child: LibraryScreen(
                  filterTypeParam: state.uri.queryParameters['filterType'],
                  genreFilterParam: state.uri.queryParameters['genreFilter'],
                  pageNumberParam: state.uri.queryParameters['pageNumber'],
                  sortOrderParam: state.uri.queryParameters['sortOrder'],
                  sortTypeParam: state.uri.queryParameters['sortType'],
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
        path: ScreenPaths.offlinePlayer,
        pageBuilder: (context, state) => buildPageWithDefaultTransition(
          context: context,
          state: state,
          child: OfflinePlayerScreen(
              startTimeTicks:
                  int.parse(state.uri.queryParameters['startTimeTicks'] ?? "0"),
              streamPath: state.extra as String),
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
      final isGoingToOfflinePlayer =
          state.matchedLocation == ScreenPaths.offlinePlayer;
      final isGoingToDownloads = state.matchedLocation == ScreenPaths.downloads;
      final isGoingToLogin = state.matchedLocation == ScreenPaths.login;
      final isConnected =
          await _ref.read(connectivityProvider).checkConnectivityOnce();
      bool serverIsReachable = true;
      bool loggedIn = false;
      try {
        loggedIn = await _ref.watch(authProvider).checkAuthentication();
      } on SocketException catch (_) {
        serverIsReachable = false;
      }

      if (isConnected && serverIsReachable) {
        if (isGoingToLogin && loggedIn) {
          return ScreenPaths.home;
        } else if (!isGoingToLogin && !loggedIn) {
          return ScreenPaths.login;
        }
        return null;
      } else {
        if (!isGoingToDownloads && !isGoingToOfflinePlayer) {
          return ScreenPaths.downloads;
        }
        return null;
      }
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
