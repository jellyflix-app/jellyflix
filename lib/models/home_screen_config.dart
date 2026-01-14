import 'dart:convert';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/providers/database_provider.dart';

class HomeScreenConfig {
  final String version;
  final List<SectionConfig> sections;

  HomeScreenConfig({required this.version, required this.sections});

  factory HomeScreenConfig.fromJson(Map<String, dynamic> json) {
    try {
      final version = json['version'] as String? ?? '1.0';
      final sectionsJson = json['sections'] as List;
      final sections = sectionsJson
          .map((s) => SectionConfig.fromJson(s as Map<String, dynamic>))
          .toList();
      return HomeScreenConfig(version: version, sections: sections);
    } catch (e) {
      return HomeScreenConfig.getDefault();
    }
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'sections': sections.map((s) => s.toJson()).toList(),
      };

  String toJsonString() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }

  static HomeScreenConfig getDefault() {
    return HomeScreenConfig(
      version: '1.0',
      sections: [
        SectionConfig(
          id: 'header',
          type: SectionType.imageBanner,
          enabled: true,
          config: {
            'dataSource': 'getFilterItems',
            'maxItems': 7,
            'height': 500,
            'scrollInterval': 5,
            'parameters': {
              'sortBy': ['random'],
              'includeItemTypes': ['movie', 'series']
            }
          },
        ),
        SectionConfig(
          id: 'continue_watching',
          type: SectionType.futureCarousel,
          enabled: true,
          title: 'continueWatching',
          config: {
            'dataSource': 'continueWatchingAndNextUp',
            'posterType': 'horizontal',
            'overlay': 'progress'
          },
        ),
        SectionConfig(
          id: 'recent_shows',
          type: SectionType.paginatedCarousel,
          enabled: true,
          title: 'recentlyAddedShows',
          config: {
            'dataSource': 'getFilterItems',
            'pageSize': 20,
            'posterType': 'vertical',
            'parameters': {
              'sortBy': ['dateLastContentAdded'],
              'sortOrder': ['descending'],
              'includeItemTypes': ['series']
            }
          },
        ),
        SectionConfig(
          id: 'genres',
          type: SectionType.genreBanner,
          enabled: true,
          config: {},
        ),
        SectionConfig(
          id: 'playlists',
          type: SectionType.playlistCarousel,
          enabled: true,
          config: {
            'allPlaylists': true,
            'shuffle': true
          },
        ),
        SectionConfig(
          id: 'watchlist',
          type: SectionType.paginatedCarousel,
          enabled: true,
          title: 'yourWatchlist',
          config: {
            'dataSource': 'getWatchlist',
            'pageSize': 20,
            'posterType': 'vertical'
          },
          condition: SectionCondition(
            type: 'setting',
            key: 'disableWatchlist',
            negate: true,
          ),
        ),
        SectionConfig(
          id: 'highest_rated_shows',
          type: SectionType.paginatedCarousel,
          enabled: true,
          title: 'highestRatedShows',
          config: {
            'dataSource': 'getFilterItems',
            'pageSize': 20,
            'posterType': 'vertical',
            'parameters': {
              'sortBy': ['random'],
              'minCommunityRating': 7.5,
              'includeItemTypes': ['series']
            }
          },
        ),
        SectionConfig(
          id: 'movies_maybe_missed',
          type: SectionType.paginatedCarousel,
          enabled: true,
          title: 'moviesMaybeMissed',
          config: {
            'dataSource': 'getFilterItems',
            'pageSize': 20,
            'posterType': 'vertical',
            'parameters': {
              'sortBy': ['random'],
              'sortOrder': ['descending'],
              'includeItemTypes': ['movie'],
              'filters': ['isUnplayed']
            }
          },
        ),
        SectionConfig(
          id: 'shows_maybe_missed',
          type: SectionType.paginatedCarousel,
          enabled: true,
          title: 'showsMaybeMissed',
          config: {
            'dataSource': 'getFilterItems',
            'pageSize': 20,
            'posterType': 'vertical',
            'parameters': {
              'sortBy': ['random'],
              'sortOrder': ['descending'],
              'includeItemTypes': ['series'],
              'filters': ['isUnplayed']
            }
          },
        ),
        SectionConfig(
          id: 'recommendations',
          type: SectionType.recommendations,
          enabled: true,
          config: {},
        ),
        SectionConfig(
          id: 'recent_movies',
          type: SectionType.paginatedCarousel,
          enabled: true,
          title: 'recentlyAddedMovies',
          config: {
            'dataSource': 'getFilterItems',
            'pageSize': 20,
            'posterType': 'vertical',
            'parameters': {
              'sortBy': ['dateCreated'],
              'sortOrder': ['descending'],
              'includeItemTypes': ['movie']
            }
          },
        ),
      ],
    );
  }

  static ValidationResult validate(String jsonString) {
    try {
      final json = jsonDecode(jsonString);
      if (json is! Map) {
        return ValidationResult(
            isValid: false, error: 'Root must be an object');
      }
      if (!json.containsKey('sections')) {
        return ValidationResult(
            isValid: false, error: 'Missing "sections" field');
      }
      HomeScreenConfig.fromJson(json as Map<String, dynamic>);
      return ValidationResult(isValid: true);
    } catch (e) {
      return ValidationResult(isValid: false, error: e.toString());
    }
  }
}

class SectionConfig {
  final String id;
  final SectionType type;
  final bool enabled;
  final String? title;
  final Map<String, dynamic> config;
  final SectionCondition? condition;

  SectionConfig({
    required this.id,
    required this.type,
    required this.enabled,
    this.title,
    required this.config,
    this.condition,
  });

  factory SectionConfig.fromJson(Map<String, dynamic> json) {
    return SectionConfig(
      id: json['id'] as String,
      type: SectionType.values.byName(json['type'] as String),
      enabled: json['enabled'] as bool? ?? true,
      title: json['title'] as String?,
      config: json['config'] as Map<String, dynamic>? ?? {},
      condition: json['condition'] != null
          ? SectionCondition.fromJson(
              json['condition'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'enabled': enabled,
        if (title != null) 'title': title,
        'config': config,
        if (condition != null) 'condition': condition!.toJson(),
      };
}

class SectionCondition {
  final String type;
  final String key;
  final bool negate;

  SectionCondition({
    required this.type,
    required this.key,
    this.negate = false,
  });

  factory SectionCondition.fromJson(Map<String, dynamic> json) {
    return SectionCondition(
      type: json['type'] as String,
      key: json['key'] as String,
      negate: json['negate'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'key': key,
        'negate': negate,
      };

  bool evaluate(WidgetRef ref) {
    if (type == 'setting') {
      final value = ref.read(databaseProvider('settings')).get(key);
      final result = value == true;
      return negate ? !result : result;
    }
    return true;
  }
}

enum SectionType {
  imageBanner,
  futureCarousel,
  paginatedCarousel,
  playlistCarousel,
  genreBanner,
  recommendations
}

class ValidationResult {
  final bool isValid;
  final String? error;

  ValidationResult({required this.isValid, this.error});
}
