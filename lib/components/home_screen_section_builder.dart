import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/future_item_carousel.dart';
import 'package:jellyflix/components/genre_banner.dart';
import 'package:jellyflix/components/image_banner.dart';
import 'package:jellyflix/components/jfx_text_theme.dart';
import 'package:jellyflix/components/paginated_item_carousel.dart';
import 'package:jellyflix/components/playback_progress_overlay.dart';
import 'package:jellyflix/components/recommendation_carousels.dart';
import 'package:jellyflix/l10n/generated/app_localizations.dart';
import 'package:jellyflix/models/home_screen_config.dart';
import 'package:jellyflix/models/poster_type.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:jellyflix/providers/database_provider.dart';
import 'package:tentacle/tentacle.dart';

class HomeScreenSectionBuilder {
  static Widget? build(
      SectionConfig section, BuildContext context, WidgetRef ref) {
    try {
      if (section.condition != null && !section.condition!.evaluate(ref)) {
        return null;
      }

      if (!section.enabled) {
        return null;
      }

      switch (section.type) {
        case SectionType.imageBanner:
          return _buildImageBanner(section, context, ref);
        case SectionType.futureCarousel:
          return _buildFutureCarousel(section, context, ref);
        case SectionType.paginatedCarousel:
          return _buildPaginatedCarousel(section, context, ref);
        case SectionType.playlistCarousel:
          return _buildPlaylistCarousel(section, context, ref);
        case SectionType.genreBanner:
          return const GenreBanner();
        case SectionType.recommendations:
          return const RecommendationCarousels();
      }
    } catch (e) {
      print('Error building section ${section.id}: $e');
      return null;
    }
  }

  static Widget _buildImageBanner(
      SectionConfig section, BuildContext context, WidgetRef ref) {
    final config = section.config;
    final height = (config['height'] as num?)?.toDouble() ?? 500.0;
    final dataSource =
        config['dataSource'] as String? ?? 'getHeaderRecommendation';
    final maxItems = (config['maxItems'] as num?)?.toInt();

    Future<List<BaseItemDto>> future;
    switch (dataSource) {
      case 'getHeaderRecommendation':
        future = ref.read(apiProvider).getHeaderRecommendation();
        break;
      case 'getFilterItems':
        final params = config['parameters'] as Map<String, dynamic>?;
        future = ref.read(apiProvider).getFilterItems(
              sortBy: _parseItemSortByList(params?['sortBy']),
              sortOrder: _parseSortOrderList(params?['sortOrder']),
              includeItemTypes:
                  _parseBaseItemKindList(params?['includeItemTypes']),
              filters: _parseItemFilterList(params?['filters']),
              minCommunityRating:
                  (params?['minCommunityRating'] as num?)?.toDouble(),
              limit: maxItems,
            );
        break;
      default:
        throw Exception('Unknown data source: $dataSource');
    }

    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(
            height: height,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        var items = snapshot.data!;
        if (maxItems != null && items.length > maxItems) {
          items = items.sublist(0, maxItems);
        }
        return ImageBanner(
          items: items,
          parentPath: ScreenPaths.home,
          height: height,
        );
      },
    );
  }

  static Widget _buildFutureCarousel(
      SectionConfig section, BuildContext context, WidgetRef ref) {
    final config = section.config;
    final dataSource = config['dataSource'] as String;
    final posterType = config['posterType'] as String? ?? 'vertical';
    final overlayType = config['overlay'] as String?;

    Future<List<BaseItemDto>> future;
    switch (dataSource) {
      case 'continueWatchingAndNextUp':
        future = ref.read(apiProvider).continueWatchingAndNextUp();
        break;
      case 'similarItemsByLastWatched':
        future = ref.read(apiProvider).similarItemsByLastWatched();
        break;
      case 'getTopTenPopular':
        future = ref.read(apiProvider).getTopTenPopular();
        break;
      default:
        throw Exception('Unknown data source: $dataSource');
    }

    Widget Function(int, BaseItemDto)? overlay;
    if (overlayType == 'progress') {
      overlay = (index, item) => PlaybackProgressOverlay(
            progress: item.userData?.playedPercentage != null
                ? item.userData!.playedPercentage! / 100
                : null,
          );
    } else if (overlayType == 'ranking') {
      overlay = (index, element) => Positioned(
            top: 0,
            left: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  AppLocalizations.of(context)!.top10(index + 1),
                  style: JfxTextTheme.scalingTheme(context)
                      .headlineMedium!
                      .copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
          );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: FutureItemCarousel(
        future: future,
        title: section.title != null
            ? _getLocalizedString(context, section.title!)
            : '',
        posterType: _parsePosterType(posterType),
        overlay: overlay,
        titleMapping: (e) => e.name!,
        imageMapping: (e) {
          if (e.type == BaseItemKind.episode &&
              ref.read(databaseProvider('settings')).get('showPrimaryForEpisodes') !=
                  true) {
            return e.seriesId!;
          }
          return e.id!;
        },
        subtitleMapping: (e) =>
            e.productionYear == null ? "" : e.productionYear.toString(),
        blurHashMapping: (e) => e.imageBlurHashes?.primary?.values.first,
        onTap: (index, id) {
          context.pushNamed(ScreenPaths.home + ScreenPaths.detail,
              queryParameters: {"id": id});
        },
      ),
    );
  }

  static Widget _buildPaginatedCarousel(
      SectionConfig section, BuildContext context, WidgetRef ref) {
    final config = section.config;
    final dataSource = config['dataSource'] as String;
    final posterType = config['posterType'] as String? ?? 'vertical';
    final pageSize = (config['pageSize'] as num?)?.toInt() ?? 20;

    Future<List<BaseItemDto>> Function(int startIndex, int limit) futureFunc;

    switch (dataSource) {
      case 'getFilterItems':
        final params = config['parameters'] as Map<String, dynamic>?;
        futureFunc = (startIndex, limit) {
          return ref.read(apiProvider).getFilterItems(
                sortBy: _parseItemSortByList(params?['sortBy']),
                sortOrder: _parseSortOrderList(params?['sortOrder']),
                includeItemTypes:
                    _parseBaseItemKindList(params?['includeItemTypes']),
                filters: _parseItemFilterList(params?['filters']),
                minCommunityRating:
                    (params?['minCommunityRating'] as num?)?.toDouble(),
                startIndex: startIndex,
                limit: limit,
              );
        };
        break;
      case 'getWatchlist':
        futureFunc = (startIndex, limit) =>
            ref.read(apiProvider).getWatchlist();
        break;
      default:
        throw Exception('Unknown data source: $dataSource');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: PaginatedItemCarousel(
        future: futureFunc,
        pageSize: pageSize,
        title: section.title != null
            ? _getLocalizedString(context, section.title!)
            : '',
        posterType: _parsePosterType(posterType),
        titleMapping: (e) => e.name!,
        imageMapping: (e) => e.id!,
        subtitleMapping: (e) =>
            e.productionYear == null ? "" : e.productionYear.toString(),
        blurHashMapping: (e) => e.imageBlurHashes?.primary?.values.first,
        onTap: (index, id) {
          context.pushNamed(ScreenPaths.home + ScreenPaths.detail,
              queryParameters: {"id": id});
        },
      ),
    );
  }

  static Widget _buildPlaylistCarousel(
      SectionConfig section, BuildContext context, WidgetRef ref) {
    final config = section.config;
    final playlistName = config['playlistName'] as String?;
    final allPlaylists = config['allPlaylists'] as bool? ?? false;

    // If allPlaylists is true, build multiple carousels
    if (allPlaylists && playlistName == null) {
      return FutureBuilder<List<BaseItemDto>>(
        future: ref.read(apiProvider).getAllPlaylists(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const SizedBox.shrink();
          }

          return Column(
            children: snapshot.data!.map((playlist) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: FutureItemCarousel(
                  future: ref.read(apiProvider).getRandomPlaylistItems(
                      playlistName: playlist.name),
                  title: playlist.name ?? '',
                  posterType: PosterType.horizontal,
                  titleMapping: (e) => e.name!,
                  imageMapping: (e) => e.id!,
                  subtitleMapping: (e) => e.productionYear == null
                      ? ""
                      : e.productionYear.toString(),
                  blurHashMapping: (e) =>
                      e.imageBlurHashes?.primary?.values.first,
                  onTap: (index, id) {
                    context.pushNamed(ScreenPaths.home + ScreenPaths.detail,
                        queryParameters: {"id": id});
                  },
                ),
              );
            }).toList(),
          );
        },
      );
    }

    // Build single carousel for specific playlist
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: FutureItemCarousel(
        future: ref
            .read(apiProvider)
            .getRandomPlaylistItems(playlistName: playlistName),
        title: section.title != null
            ? _getLocalizedString(context, section.title!)
            : playlistName ?? '',
        posterType: PosterType.horizontal,
        titleMapping: (e) => e.name!,
        imageMapping: (e) => e.id!,
        subtitleMapping: (e) =>
            e.productionYear == null ? "" : e.productionYear.toString(),
        blurHashMapping: (e) => e.imageBlurHashes?.primary?.values.first,
        onTap: (index, id) {
          context.pushNamed(ScreenPaths.home + ScreenPaths.detail,
              queryParameters: {"id": id});
        },
      ),
    );
  }

  static PosterType _parsePosterType(String type) {
    switch (type) {
      case 'horizontal':
        return PosterType.horizontal;
      case 'square':
        return PosterType.square;
      case 'vertical':
      default:
        return PosterType.vertical;
    }
  }

  static List<ItemSortBy>? _parseItemSortByList(dynamic value) {
    if (value == null) return null;
    if (value is! List) return null;
    return value.map((v) => _parseItemSortBy(v.toString())).toList();
  }

  static ItemSortBy _parseItemSortBy(String value) {
    switch (value) {
      case 'dateCreated':
        return ItemSortBy.dateCreated;
      case 'dateLastContentAdded':
        return ItemSortBy.dateLastContentAdded;
      case 'random':
        return ItemSortBy.random;
      case 'sortName':
        return ItemSortBy.sortName;
      default:
        return ItemSortBy.sortName;
    }
  }

  static List<SortOrder>? _parseSortOrderList(dynamic value) {
    if (value == null) return null;
    if (value is! List) return null;
    return value.map((v) => _parseSortOrder(v.toString())).toList();
  }

  static SortOrder _parseSortOrder(String value) {
    switch (value) {
      case 'ascending':
        return SortOrder.ascending;
      case 'descending':
        return SortOrder.descending;
      default:
        return SortOrder.ascending;
    }
  }

  static List<BaseItemKind>? _parseBaseItemKindList(dynamic value) {
    if (value == null) return null;
    if (value is! List) return null;
    return value.map((v) => _parseBaseItemKind(v.toString())).toList();
  }

  static BaseItemKind _parseBaseItemKind(String value) {
    switch (value) {
      case 'movie':
        return BaseItemKind.movie;
      case 'series':
        return BaseItemKind.series;
      case 'episode':
        return BaseItemKind.episode;
      case 'boxSet':
        return BaseItemKind.boxSet;
      default:
        return BaseItemKind.movie;
    }
  }

  static List<ItemFilter>? _parseItemFilterList(dynamic value) {
    if (value == null) return null;
    if (value is! List) return null;
    return value.map((v) => _parseItemFilter(v.toString())).toList();
  }

  static ItemFilter _parseItemFilter(String value) {
    switch (value) {
      case 'isUnplayed':
        return ItemFilter.isUnplayed;
      case 'isPlayed':
        return ItemFilter.isPlayed;
      case 'isFavorite':
        return ItemFilter.isFavorite;
      default:
        return ItemFilter.isUnplayed;
    }
  }

  static String _getLocalizedString(BuildContext context, String key) {
    final localizations = AppLocalizations.of(context)!;
    switch (key) {
      case 'continueWatching':
        return localizations.continueWatching;
      case 'recentlyAddedMovies':
        return localizations.recentlyAddedMovies;
      case 'recentlyAddedShows':
        return localizations.recentlyAddedShows;
      case 'yourWatchlist':
        return localizations.yourWatchlist;
      case 'top10inYourLibrary':
        return localizations.top10inYourLibrary;
      case 'highesRatedMovies':
        return localizations.highesRatedMovies;
      case 'highestRatedShows':
        return localizations.highestRatedShows;
      case 'moviesMaybeMissed':
        return localizations.moviesMaybeMissed;
      case 'showsMaybeMissed':
        return localizations.showsMaybeMissed;
      default:
        return key;
    }
  }
}
