import 'package:jellyflix/models/bitrates.dart';
import 'package:tentacle/tentacle.dart';

class PlaybackHelperService {
  final PlaybackInfoResponse item;
  Map<int, String> bitrateMap = BitRates().map;

  late final List<MediaStream> subtitles;
  late final List<MediaStream> audioStreams;

  PlaybackHelperService({required this.item}) {
    audioStreams = item.mediaSources![0].mediaStreams!
        .where((element) => element.type == MediaStreamType.audio)
        .toList();
    subtitles = [
      MediaStream(
        (b) {
          b.displayTitle = "None";
          b.index = -1;
        },
      ),
      ...item.mediaSources![0].mediaStreams!
          .where((element) => element.type == MediaStreamType.subtitle)
          .toList()
    ];
  }

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

  Map<MediaStream, int?> getSubtitleList() {
    var subtitleStreams = item.mediaSources![0].mediaStreams!
        .where((element) => element.type == MediaStreamType.subtitle)
        .toList();
    int index = 2;
    // map the subtitle streams to the index
    Map<MediaStream, int?> subtitleMap = {
      MediaStream(
        (b) {
          b.displayTitle = "None";
          b.index = -1;
        },
      ): 1, // should this be 0 or 1 auto / none
    };
    for (var stream in subtitleStreams) {
      if (stream.isExternal!) {
        subtitleMap.addAll({stream: null});
      } else {
        subtitleMap.addAll({stream: index});
        index++;
      }
    }
    return subtitleMap;
  }

  Map<MediaStream, int?> getAudioList() {
    var audioStreams = item.mediaSources![0].mediaStreams!
        .where((element) => element.type == MediaStreamType.audio)
        .toList();
    int index = 2;
    // map the audio streams to the index
    Map<MediaStream, int?> audioMap = {};
    for (var stream in audioStreams) {
      audioMap.addAll({stream: index});
      index++;
    }

    return audioMap;
  }

  bool subtitleListIsEmpty() {
    return getSubtitleList().isEmpty;
  }
}
