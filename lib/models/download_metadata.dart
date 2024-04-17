import 'package:built_collection/built_collection.dart';
import 'package:tentacle/tentacle.dart';

class DownloadMetadata extends BaseItemDto {
  @override
  final String id;
  @override
  final String name;
  @override
  final BaseItemKind type;
  @override
  final int runTimeTicks;
  @override
  final String? seriesName;
  @override
  final String? seriesId;
  @override
  final int? indexNumber;
  @override
  final int? parentIndexNumber;
  @override
  final String? path;
  final int? downloadSize;

  DownloadMetadata({
    required this.id,
    required this.name,
    required this.type,
    required this.runTimeTicks,
    required this.seriesName,
    required this.seriesId,
    required this.indexNumber,
    required this.parentIndexNumber,
    required this.path,
    this.downloadSize,
  });

  Map<String, dynamic> toJson() {
    return {
      "Id": id,
      "Name": name,
      "Type": type.name,
      "RunTimeTicks": runTimeTicks,
      "SeriesName": seriesName,
      "SeriesId": seriesId,
      "IndexNumber": indexNumber,
      "ParentIndexNumber": parentIndexNumber,
      "Path": path,
      "DownloadSize": downloadSize,
    };
  }

  static DownloadMetadata fromJson(Map<String, dynamic> json) {
    return DownloadMetadata(
      id: json["Id"],
      name: json["Name"],
      type: BaseItemKind.values.firstWhere((p0) => p0.name == json["Type"]),
      runTimeTicks: json["RunTimeTicks"],
      seriesName: json["SeriesName"],
      seriesId: json["SeriesId"],
      indexNumber: json["IndexNumber"],
      parentIndexNumber: json["ParentIndexNumber"],
      path: json["Path"],
      downloadSize: json["DownloadSize"],
    );
  }

  @override
  BuiltList<DayOfWeek>? get airDays => null;

  @override
  String? get airTime => null;

  @override
  int? get airsAfterSeasonNumber => null;

  @override
  int? get airsBeforeEpisodeNumber => null;

  @override
  int? get airsBeforeSeasonNumber => null;

  @override
  String? get album => null;

  @override
  String? get albumArtist => null;

  @override
  BuiltList<NameGuidPair>? get albumArtists => null;

  @override
  int? get albumCount => null;

  @override
  String? get albumId => null;

  @override
  String? get albumPrimaryImageTag => null;

  @override
  double? get altitude => null;

  @override
  double? get aperture => null;

  @override
  int? get artistCount => null;

  @override
  BuiltList<NameGuidPair>? get artistItems => null;

  @override
  BuiltList<String>? get artists => null;

  @override
  String? get aspectRatio => null;

  @override
  ProgramAudio? get audio => null;

  @override
  BuiltList<String>? get backdropImageTags => null;

  @override
  String? get cameraMake => null;

  @override
  String? get cameraModel => null;

  @override
  bool? get canDelete => null;

  @override
  bool? get canDownload => null;

  @override
  String? get channelId => null;

  @override
  String? get channelName => null;

  @override
  String? get channelNumber => null;

  @override
  String? get channelPrimaryImageTag => null;

  @override
  ChannelType? get channelType => null;

  @override
  BuiltList<ChapterInfo>? get chapters => null;

  @override
  int? get childCount => null;

  @override
  String? get collectionType => null;

  @override
  double? get communityRating => null;

  @override
  double? get completionPercentage => null;

  @override
  String? get container => null;

  @override
  double? get criticRating => null;

  @override
  int? get cumulativeRunTimeTicks => null;

  @override
  BaseItemDtoCurrentProgram? get currentProgram => null;

  @override
  String? get customRating => null;

  @override
  DateTime? get dateCreated => null;

  @override
  DateTime? get dateLastMediaAdded => null;

  @override
  String? get displayOrder => null;

  @override
  String? get displayPreferencesId => null;

  @override
  bool? get enableMediaSourceDisplay => null;

  @override
  DateTime? get endDate => null;

  @override
  int? get episodeCount => null;

  @override
  String? get episodeTitle => null;

  @override
  String? get etag => null;

  @override
  double? get exposureTime => null;

  @override
  BuiltList<ExternalUrl>? get externalUrls => null;

  @override
  String? get extraType => null;

  @override
  double? get focalLength => null;

  @override
  String? get forcedSortName => null;

  @override
  BuiltList<NameGuidPair>? get genreItems => null;

  @override
  BuiltList<String>? get genres => null;

  @override
  bool? get hasSubtitles => null;

  @override
  int? get height => null;

  @override
  BaseItemDtoImageBlurHashes? get imageBlurHashes => null;

  @override
  ImageOrientation? get imageOrientation => null;

  @override
  BuiltMap<String, String>? get imageTags => null;

  @override
  int? get indexNumberEnd => null;

  @override
  bool? get isFolder => null;

  @override
  bool? get isHD => null;

  @override
  bool? get isKids => null;

  @override
  bool? get isLive => null;

  @override
  bool? get isMovie => null;

  @override
  bool? get isNews => null;

  @override
  bool? get isPlaceHolder => null;

  @override
  bool? get isPremiere => null;

  @override
  bool? get isRepeat => null;

  @override
  bool? get isSeries => null;

  @override
  bool? get isSports => null;

  @override
  int? get isoSpeedRating => null;

  @override
  IsoType? get isoType => null;

  @override
  double? get latitude => null;

  @override
  int? get localTrailerCount => null;

  @override
  LocationType? get locationType => null;

  @override
  bool? get lockData => null;

  @override
  BuiltList<MetadataField>? get lockedFields => null;

  @override
  double? get longitude => null;

  @override
  int? get mediaSourceCount => null;

  @override
  BuiltList<MediaSourceInfo>? get mediaSources => null;

  @override
  BuiltList<MediaStream>? get mediaStreams => null;

  @override
  String? get mediaType => null;

  @override
  int? get movieCount => null;

  @override
  int? get musicVideoCount => null;

  @override
  String? get number => null;

  @override
  String? get officialRating => null;

  @override
  String? get originalTitle => null;

  @override
  String? get overview => null;

  @override
  String? get parentArtImageTag => null;

  @override
  String? get parentArtItemId => null;

  @override
  BuiltList<String>? get parentBackdropImageTags => null;

  @override
  String? get parentBackdropItemId => null;

  @override
  String? get parentId => null;

  @override
  String? get parentLogoImageTag => null;

  @override
  String? get parentLogoItemId => null;

  @override
  String? get parentPrimaryImageItemId => null;

  @override
  String? get parentPrimaryImageTag => null;

  @override
  String? get parentThumbImageTag => null;

  @override
  String? get parentThumbItemId => null;

  @override
  int? get partCount => null;

  @override
  BuiltList<BaseItemPerson>? get people => null;

  @override
  PlayAccess? get playAccess => null;

  @override
  String? get playlistItemId => null;

  @override
  String? get preferredMetadataCountryCode => null;

  @override
  String? get preferredMetadataLanguage => null;

  @override
  DateTime? get premiereDate => null;

  @override
  double? get primaryImageAspectRatio => null;

  @override
  BuiltList<String>? get productionLocations => null;

  @override
  int? get productionYear => null;

  @override
  int? get programCount => null;

  @override
  String? get programId => null;

  @override
  BuiltMap<String, String?>? get providerIds => null;

  @override
  int? get recursiveItemCount => null;

  @override
  BuiltList<MediaUrl>? get remoteTrailers => null;

  @override
  BuiltList<String>? get screenshotImageTags => null;

  @override
  String? get seasonId => null;

  @override
  String? get seasonName => null;

  @override
  int? get seriesCount => null;

  @override
  String? get seriesPrimaryImageTag => null;

  @override
  String? get seriesStudio => null;

  @override
  String? get seriesThumbImageTag => null;

  @override
  String? get seriesTimerId => null;

  @override
  String? get serverId => null;

  @override
  double? get shutterSpeed => null;

  @override
  String? get software => null;

  @override
  int? get songCount => null;

  @override
  String? get sortName => null;

  @override
  String? get sourceType => null;

  @override
  int? get specialFeatureCount => null;

  @override
  DateTime? get startDate => null;

  @override
  String? get status => null;

  @override
  BuiltList<NameGuidPair>? get studios => null;

  @override
  bool? get supportsSync => null;

  @override
  BuiltList<String>? get taglines => null;

  @override
  BuiltList<String>? get tags => null;

  @override
  String? get timerId => null;

  @override
  int? get trailerCount => null;

  @override
  BaseItemDtoUserData? get userData => null;

  @override
  Video3DFormat? get video3DFormat => null;

  @override
  VideoType? get videoType => null;

  @override
  int? get width => null;
}
