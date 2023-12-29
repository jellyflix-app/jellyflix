import 'package:openapi/openapi.dart';

class PlaybackHelperService {
  final PlaybackInfoResponse item;

  Map<int, String> bitrateMap = {
    120000000: "2160p 120 Mb/s",
    60000000: "1080p 60 Mb/s",
    8000000: "720p 8 Mb/s",
    4000000: "480p 4 Mb/s",
    420000: "360p 420 Kb/s",
  };

  PlaybackHelperService({required this.item});

  Map<int, String> getBitrateMap() {
    // add orignal bitrate at the beginning
    bitrateMap[item.mediaSources![0].bitrate ?? 0] =
        "Original ${item.mediaSources![0].bitrate! ~/ 1000000} Mb/s";
    // add original bitrate at the beginning and sort the rest descending
    bitrateMap = Map.fromEntries(
      bitrateMap.entries.toList()..sort((e1, e2) => e2.key.compareTo(e1.key)),
    );
    // remove bitrates that are higher than the original
    bitrateMap
        .removeWhere((key, value) => key > item.mediaSources![0].bitrate!);

    return bitrateMap;
  }

  int getDefaultBitrate() {
    return item.mediaSources![0].bitrate ?? 0;
  }

  int getDefaultSubtitleIndex() {
    return item.mediaSources![0].defaultSubtitleStreamIndex ?? -1;
  }

  int getDefaultAudioIndex() {
    return item.mediaSources![0].defaultAudioStreamIndex ?? -1;
  }

  List<MediaStream> getSubtitleList() {
    return item.mediaSources![0].mediaStreams!
        .where((element) => element.type == MediaStreamType.subtitle)
        .toList();
  }

  List<MediaStream> getAudioList() {
    return item.mediaSources![0].mediaStreams!
        .where((element) => element.type == MediaStreamType.audio)
        .toList();
  }

  bool subtitleListIsEmpty() {
    return getSubtitleList().isEmpty;
  }
}
