import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:jellyflix/components/profile_placeholder_image.dart';
import 'package:jellyflix/models/user.dart';
import 'package:flutter/material.dart';
import 'package:openapi/openapi.dart';
import 'package:built_collection/built_collection.dart';

class ApiService {
  Openapi? _jellyfinApi;
  User? _user;
  Map<String, String> headers = {
    "Accept": "application/json",
    "Accept-Language": "en-US,en;q=0.5",
    "Accept-Encoding": "gzip, deflate",
    "Authorization":
        "MediaBrowser Client=\"AnotherJellyfinClient\", Device=\"notset\", DeviceId=\"Unknown Device Id\", Version=\"10.8.11\"",
    "Content-Type": "application/json",
    "Connection": "keep-alive",
  };

  PlaybackInfoResponse? playbackInfo;

  User? get currentUser => _user;

  build() {
    return ApiService();
  }

  Future<User> login(String baseUrl, String username, String pw) async {
    // TODO add error handling
    _jellyfinApi = Openapi(basePathOverride: baseUrl);
    var response = await _jellyfinApi!.getUserApi().authenticateUserByName(
        authenticateUserByName: AuthenticateUserByName((b) => b
          ..username = username
          ..pw = pw),
        headers: headers);

    headers["Authorization"] =
        "${headers["Authorization"]!}, Token=\"${response.data!.accessToken!}\"";
    headers["Origin"] = baseUrl;
    _user = User(
      id: response.data!.user!.id,
      name: response.data!.user!.name,
      serverAdress: baseUrl,
    );
    return _user!;
  }

  Future<BaseItemDto> getItemDetails(String id) async {
    var response = await _jellyfinApi!.getUserLibraryApi().getItem(
          userId: _user!.id!,
          itemId: id,
          headers: headers,
        );
    return response.data!;
  }

  CachedNetworkImage getImage(
      {required String id,
      required ImageType type,
      String? blurHash,
      BorderRadius? borderRadius}) {
    String url = "${_user!.serverAdress}/Items/$id/Images/${type.name}";

    return CachedNetworkImage(
      width: double.infinity,
      imageUrl: url,
      httpHeaders: headers,
      fit: BoxFit.cover,
      imageBuilder: (context, imageProvider) => Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius ?? BorderRadius.circular(10.0),
          image: DecorationImage(
            image: imageProvider,
            fit: BoxFit.cover,
          ),
        ),
      ),
      placeholder: blurHash == null
          ? null
          : (context, url) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: BlurHash(
                  hash: blurHash,
                  imageFit: BoxFit.cover,
                ),
              );
            },
      errorWidget: (context, url, error) {
        return const SizedBox();
      },
      errorListener: (value) {
        //! Errors can't be caught right now
        //! There is a pr to fix this: https://github.com/Baseflow/flutter_cached_network_image/pull/777
      },
    );
  }

  CachedNetworkImage getProfileImage({User? user}) {
    user ??= _user!;
    return CachedNetworkImage(
      width: double.infinity,
      fit: BoxFit.cover,
      imageUrl: "${user.serverAdress}/Users/${user.id}/Images/Profile",
      placeholder: (context, url) {
        return const ProfilePlaceholderImage();
      },
      errorWidget: (context, url, error) {
        return const ProfilePlaceholderImage();
      },
      errorListener: (value) {
        //! Errors can't be caught right now
        //! There is a pr to fix this
      },
    );
  }

  Future<List<BaseItemDto>> getContinueWatching() async {
    var response = await _jellyfinApi!
        .getItemsApi()
        .getResumeItems(userId: _user!.id!, headers: headers);
    return response.data!.items!.toList();
  }

  Future<List<BaseItemDto>> getLatestItems(String collectionType) async {
    List<BaseItemDto> items = [];
    var folders = await getMediaFolders();
    // get all movie collections and their ids
    var movieCollections = folders.where((element) {
      return element.collectionType == collectionType;
    }).toList();
    var movieCollectionIds = movieCollections.map((e) {
      return e.id!;
    }).toList();

    for (var id in movieCollectionIds) {
      var response = await _jellyfinApi!.getUserLibraryApi().getLatestMedia(
          userId: _user!.id!,
          parentId: id,
          headers: headers,
          fields: BuiltList<ItemFields>(ItemFields.values));

      // add response to list
      items.addAll(response.data!);
    }
    return items;
  }

  Future<List<BaseItemDto>> getMediaFolders() async {
    var response = await _jellyfinApi!
        .getUserViewsApi()
        .getUserViews(userId: _user!.id!, headers: headers);
    //keep only video folders
    var folders = response.data!.items!.where((element) {
      return element.collectionType == "movies" ||
          element.collectionType == "tvshows";
    }).toList();
    return folders;
    //return response.data!;
  }

  Future getEpisodes(String id) async {
    var response = await _jellyfinApi!
        .getTvShowsApi()
        .getEpisodes(userId: _user!.id!, seriesId: id, headers: headers);
    return response.data!;
  }

  Future<List<BaseItemDto>> getFilterItems(
      {List<BaseItemDto>? genreIds, String? searchTerm}) async {
    var folders = await getMediaFolders();
    var ids = genreIds == null
        ? null
        : BuiltList<String>.from(genreIds.map((e) => e.id!));
    List<BaseItemDto> items = [];
    for (var folder in folders) {
      var response = await _jellyfinApi!.getItemsApi().getItems(
            userId: _user!.id!,
            headers: headers,
            parentId: folder.id,
            genreIds: ids,
            searchTerm: searchTerm,
            recursive: true,
            includeItemTypes: BuiltList<BaseItemKind>([
              BaseItemKind.movie,
              BaseItemKind.series,
              BaseItemKind.episode,
              BaseItemKind.boxSet
            ]),
            fields: BuiltList<ItemFields>(ItemFields.values),
          );
      items.addAll(response.data!.items!);
    }
    return items;
  }

  Future<List<BaseItemDto>> getGenres() async {
    List<BaseItemDto> genres = [];
    var folders = await getMediaFolders();
    for (var folder in folders) {
      var response = await _jellyfinApi!
          .getGenresApi()
          .getGenres(userId: _user!.id!, headers: headers, parentId: folder.id);
      genres.addAll(response.data!.items!);
    }
    // keep only unique genres
    genres = genres.toSet().toList();
    return genres;
  }

  /// Retrieves the stream URL and playback information for a video.
  ///
  /// Returns a [Future] that completes with a tuple containing the stream URL
  /// and the [PlaybackInfoResponse] object.
  ///
  /// The [streamUrl] is a [String] representing the URL of the video stream.
  /// The [playbackInfo] is a [PlaybackInfoResponse] object containing information
  /// about the playback, such as duration, bitrate, and video format.
  ///
  /// maxStreamingBitrate is the default bitrate set in the settings if null
  /// audioStreamIndex is the default audioStreamIndex set by jellyfin if null
  /// subtitleStreamIndex is the default subtitleStreamIndex set by jellyfin if null
  Future<(String, PlaybackInfoResponse)> getStreamUrlAndPlaybackInfo(
      {required String itemId,
      int? audioStreamIndex,
      int? subtitleStreamIndex,
      int? maxStreaminBitrate,
      int? startTimeTicks}) async {
    Response<PlaybackInfoResponse> response = await postPlaybackInfoRequest(
        itemId,
        maxStreaminBitrate,
        audioStreamIndex,
        subtitleStreamIndex,
        startTimeTicks,
        false);

    var canUseStatic = response.data!.mediaSources!.first.mediaStreams!
                .where((p0) => p0.type == MediaStreamType.audio)
                .toList()
                .length ==
            1 ||
        response.data!.mediaSources!.first.defaultAudioStreamIndex! == 1;

    String? url;
    //TODO use only directplay if static is available or is forced in settings
    if (canUseStatic) {
      if (response.data!.mediaSources!.toList().first.supportsDirectPlay ==
          true) {
        url =
            "${_user!.serverAdress}/Videos/$itemId/stream?mediaSourceId=$itemId&AudioStreamIndex=${audioStreamIndex ?? response.data!.mediaSources!.first.defaultAudioStreamIndex!}";
        if (canUseStatic) {
          url += "&Static=true";
        }
      }
      if (response.data!.mediaSources!.toList().first.supportsDirectStream ==
          true) {
        url =
            "${_user!.serverAdress}/Videos/$itemId/stream.${response.data!.mediaSources!.first.container}?mediaSourceId=$itemId&AudioStreamIndex=${audioStreamIndex ?? response.data!.mediaSources!.first.defaultAudioStreamIndex!}";
        if (canUseStatic) {
          url += "&Static=true";
        }
      }
    }
    if (response.data!.mediaSources!.first.supportsTranscoding == true) {
      if (response.data!.mediaSources!.first.transcodingUrl == null) {
        response = await postPlaybackInfoRequest(itemId, maxStreaminBitrate,
            audioStreamIndex, subtitleStreamIndex, startTimeTicks, true);
      }
      url =
          "${_user!.serverAdress}${response.data!.mediaSources!.first.transcodingUrl}";
    }

    if (url != null) {
      playbackInfo = response.data!;
      return (url, response.data!);
    }

    throw Exception("Couldn't get stream url");
  }

  Future<Response<PlaybackInfoResponse>> postPlaybackInfoRequest(
      String itemId,
      int? maxStreaminBitrate,
      int? audioStreamIndex,
      int? subtitleStreamIndex,
      int? startTimeTicks,
      bool forceTranscoding) async {
    var deviceProfile = ClientCapabilitiesDeviceProfileBuilder();
    deviceProfile.directPlayProfiles = ListBuilder([
      DirectPlayProfile((b) => b..type = DlnaProfileType.video),
    ]);
    deviceProfile.transcodingProfiles = ListBuilder<TranscodingProfile>([
      TranscodingProfile(
        (b) => b
          ..container = "ts"
          ..type = DlnaProfileType.video
          ..audioCodec = "aac,ac3,eac3"
          ..videoCodec = "h264,hevc"
          ..protocol = "hls",
      )
    ]);

    deviceProfile.containerProfiles = ListBuilder<ContainerProfile>([]);
    deviceProfile.subtitleProfiles = ListBuilder<SubtitleProfile>([
      SubtitleProfile((b) => b
        ..format = "vtt"
        ..method = SubtitleDeliveryMethod.external_),
      SubtitleProfile((b) => b
        ..format = "ssa"
        ..method = SubtitleDeliveryMethod.external_),
      SubtitleProfile((b) => b
        ..format = "ass"
        ..method = SubtitleDeliveryMethod.external_),
    ]);
    var response = await _jellyfinApi!.getMediaInfoApi().getPostedPlaybackInfo(
          itemId: itemId,
          headers: headers,
          playbackInfoDto: PlaybackInfoDto((b) => b
            ..userId = _user!.id!
            ..mediaSourceId = itemId
            ..autoOpenLiveStream = true
            ..enableDirectPlay = !forceTranscoding
            ..enableDirectStream = !forceTranscoding
            ..startTimeTicks = startTimeTicks
            ..maxStreamingBitrate =
                maxStreaminBitrate ?? 1000000000 // TODO set in settings
            ..audioStreamIndex =
                audioStreamIndex // should use the default audioStream determined by jellyfin if null
            ..subtitleStreamIndex = subtitleStreamIndex
            ..deviceProfile = deviceProfile),
        );

    playbackInfo = response.data;
    return response;
  }

  Future<int> authorizeQuickConnect(String secret) async {
    try {
      var response = await _jellyfinApi!.getQuickConnectApi().authorize(
            code: secret,
            headers: headers,
          );
      if (response.data! == true) {
        return 200;
      } else {
        return 400;
      }
    } on DioException catch (_) {
      return _.response!.statusCode ?? 400;
    }
  }

  Future<List<BaseItemDto>> getTopTenPopular() async {
    // TODO depending on locale
    // TODO cache to increase performance
    // get top 10000 from url
    var responseMovie = await Dio().get(
        "https://raw.githubusercontent.com/jdk-21/popular-movies-data/main/US-popular-movie.json");
    var responseTv = await Dio().get(
        "https://raw.githubusercontent.com/jdk-21/popular-movies-data/main/US-popular-tv.json");

    List movieJson = jsonDecode(responseMovie.data);
    List tvJson = jsonDecode(responseTv.data);

    List<BaseItemDto> library = await getFilterItems();
    List<BaseItemDto> movieLibrary = library.where((element) {
      return element.type == BaseItemKind.movie;
    }).toList();
    List<BaseItemDto> tvLibrary = library.where((element) {
      return element.type == BaseItemKind.series;
    }).toList();
    library = movieLibrary + tvLibrary;

    List<dynamic> popular = matchItemWithPopularity(movieLibrary, movieJson);
    List<dynamic> popularTv = matchItemWithPopularity(tvLibrary, tvJson);

    popular.addAll(popularTv);

    // sort by popularity
    popular.sort((a, b) {
      return b["p"].compareTo(a["p"]);
    });

    // find the top then in library
    List<BaseItemDto> top10 = [];
    for (var i = 0; i < popular.length; i++) {
      var movie = popular[i];
      int movieId = movie["i"];
      for (var element in library) {
        if (element.providerIds == null) continue;
        if (element.providerIds!["Tmdb"] == null) continue;
        if (int.parse(element.providerIds!["Tmdb"]!) == movieId) {
          top10.add(element);
          break;
        }
      }

      if (top10.length == 10) {
        break;
      }
    }

    return top10;
  }

  List<dynamic> matchItemWithPopularity(
      List<BaseItemDto> library, List<dynamic> movieJson) {
    var popular = [];
    // check if providerId in library is in json file and return the movieJson entry
    for (var movie in library) {
      if (movie.providerIds == null) continue;
      var movieId = movie.providerIds!["Tmdb"];
      if (movieId != null) {
        var movieEntry = movieJson.firstWhere((element) {
          return element["i"] == int.parse(movieId);
        }, orElse: () => null);
        if (movieEntry != null) {
          popular.add(movieEntry);
        }
      }
    }

    // sort by popularity
    popular.sort((a, b) {
      return b["p"].compareTo(a["p"]);
    });
    return popular;
  }

  reportStartPlayback(int positionTicks) async {
    await _jellyfinApi!.getPlaystateApi().reportPlaybackStart(
        headers: headers,
        playbackStartInfo: PlaybackStartInfo((b) => b
          ..itemId = playbackInfo!.mediaSources!.first.id!
          ..mediaSourceId = playbackInfo!.mediaSources!.first.id!
          ..playbackStartTimeTicks =
              DateTime.now().millisecondsSinceEpoch * 10000
          ..positionTicks = positionTicks
          ..playSessionId = playbackInfo!.playSessionId
          ..audioStreamIndex =
              playbackInfo!.mediaSources!.first.defaultAudioStreamIndex
          ..subtitleStreamIndex =
              playbackInfo!.mediaSources!.first.defaultSubtitleStreamIndex));
  }

  reportPlaybackProgress(int positionTicks) async {
    await _jellyfinApi!.getPlaystateApi().reportPlaybackProgress(
        headers: headers,
        playbackProgressInfo: PlaybackProgressInfo((b) => b
          ..itemId = playbackInfo!.mediaSources!.first.id!
          ..mediaSourceId = playbackInfo!.mediaSources!.first.id!
          ..positionTicks = positionTicks
          ..playSessionId = playbackInfo!.playSessionId
          ..audioStreamIndex =
              playbackInfo!.mediaSources!.first.defaultAudioStreamIndex
          ..subtitleStreamIndex =
              playbackInfo!.mediaSources!.first.defaultSubtitleStreamIndex));
  }

  reportStopPlayback(int positionTicks) async {
    await _jellyfinApi!.getPlaystateApi().reportPlaybackStopped(
        headers: headers,
        playbackStopInfo: PlaybackStopInfo((b) => b
          ..itemId = playbackInfo!.mediaSources!.first.id!
          ..mediaSourceId = playbackInfo!.mediaSources!.first.id!
          ..positionTicks = positionTicks
          ..playSessionId = playbackInfo!.playSessionId));
  }
}
