import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:jellyflix/models/playback_info_response_serializer.dart';
import 'package:jellyflix/services/jfx_logger.dart';
import 'package:jellyflix/services/player_helper.dart';
import 'package:universal_io/io.dart';
import 'package:tentacle/tentacle.dart';
import 'package:path_provider/path_provider.dart';
import 'package:async/async.dart';
import 'package:jellyflix/l10n/generated/app_localizations.dart';

import 'package:jellyflix/models/download_metadata.dart';
import 'package:jellyflix/navigation/app_router.dart';
import 'package:jellyflix/providers/scaffold_key.dart';
import 'package:jellyflix/services/api_service.dart';
import 'package:jellyflix/services/connectivity_service.dart';

class DownloadService {
  static final Map<String, DownloadService> _instances = {};

  final ApiService _api;
  late CancelableOperation<void> _download;
  late final String itemId;
  late final ConnectivityService connectivityService;
  late final JfxLogger logger;
  Dio? _dio;

  bool isDownloading = false;
  CancelToken cancelToken = CancelToken();
  List<String> downloadTaskIds = [];
  int? totalChunks;

  factory DownloadService(
    api, {
    required String itemId,
    required ConnectivityService connectivityService,
    required JfxLogger logger,
  }) {
    if (_instances.containsKey(itemId)) {
      return _instances[itemId]!;
    } else {
      final instance = DownloadService._internal(api,
          itemId: itemId,
          connectivityService: connectivityService,
          logger: logger);
      _instances[itemId] = instance;
      return instance;
    }
  }

  DownloadService._internal(
    this._api, {
    required this.itemId,
    required this.connectivityService,
    required this.logger,
  }) {
    if (_api.currentUser != null) {
      _dio = Dio(
        BaseOptions(
          headers: _api.headers,
          baseUrl: _api.currentUser!.serverAdress!,
        ),
      );
    }
    connectivityService.connectionStatusStream.listen((isConnected) {
      if (isConnected && _api.currentUser?.serverAdress != null) {
        _dio = Dio(
          BaseOptions(
            headers: _api.headers,
            baseUrl: _api.currentUser!.serverAdress!,
          ),
        );
      } else {
        _dio = null;
      }
    });
  }

  static Future<List<String>> getDownloadedItems() async {
    var downloadDir = await getDownloadDirectory();

    // get all folders in downloadDir
    var contents = await Directory(downloadDir)
        .list()
        .where((event) => event is Directory)
        .map((event) => event.path.split(Platform.pathSeparator).last)
        .toList();
    return contents;
  }

  Future<String> getDownloadedItemPath() async {
    var downloadDir = await getDownloadDirectory();
    return "$downloadDir${Platform.pathSeparator}$itemId${Platform.pathSeparator}main.m3u8";
  }

  Future<PlaybackInfoResponse> getDownloadInfo(
      {int? audioStreamIndex,
      int? subtitleStreamIndex,
      required int downloadBitrate}) async {
    return (await _api.getPlaybackInfo(
        itemId: itemId,
        maxStreamingBitrate: downloadBitrate,
        audioStreamIndex: audioStreamIndex,
        subtitleStreamIndex: subtitleStreamIndex));
  }

  void downloadItem(
      {int? audioStreamIndex,
      int? subtitleStreamIndex,
      required int downloadBitrate}) {
    _download = CancelableOperation.fromFuture(
      _downloadItem(
        audioStreamIndex: audioStreamIndex,
        subtitleStreamIndex: subtitleStreamIndex,
        downloadBitrate: downloadBitrate,
      ),
      onCancel: () {
        isDownloading = false;
        logger.warning("Downloads: Download canceled");
      },
    )..value.whenComplete(() {}).onError((error, stackTrace) {
        isDownloading = false;
        logger.error("Downloads: Error downloading item: $itemId: $stackTrace",
            error: error);
      });
    logger.verbose("Downloads: Downloading item: $itemId");
  }

  Future<void> _downloadItem(
      {int? audioStreamIndex,
      int? subtitleStreamIndex,
      required int downloadBitrate}) async {
    isDownloading = true;
    PlaybackInfoResponse playbackInfo = await _api.getPlaybackInfo(
        itemId: itemId,
        maxStreamingBitrate: downloadBitrate,
        audioStreamIndex: audioStreamIndex,
        subtitleStreamIndex: subtitleStreamIndex);
    logger.verbose("Downloads: PlaybackInfo: $playbackInfo");

    String streamUrl = _api.getStreamUrl(playbackInfo);
    await writeMetadataToFile(playbackInfo, streamUrl);

    logger.verbose("Downloads: Stream URL: $streamUrl");

    MediaStream? subtitle;
    String? subtitlePath;

    if (subtitleStreamIndex != null && subtitleStreamIndex != -1) {
      PlayerHelper helper =
          PlayerHelper(playbackInfo: playbackInfo, logger: logger);

      subtitle = helper.subtitles
          .firstWhere((element) => element.index == subtitleStreamIndex);
      subtitlePath = await downloadSubtitle(subtitle);
    }

    logger.verbose("Downloads: Subtitle downloaded to path: $subtitlePath");

    if (playbackInfo.mediaSources![0].transcodingUrl == null) {
      await writePlaybackInfoToFile(playbackInfo,
          subtitle: subtitle, subtitlePath: subtitlePath);
      await downloadDirectStream(streamUrl);
    } else {
      await writePlaybackInfoToFile(playbackInfo,
          subtitle: subtitle,
          subtitlePath: subtitlePath,
          audioStreamIndex: audioStreamIndex);
      await downloadTranscodedStream(
          playbackInfo.mediaSources![0].transcodingUrl!);
    }
  }

  Future<String> downloadSubtitle(MediaStream subtitle) async {
    // create download directory if it doesn't exist
    var downloadDirectory = await getDownloadDirectory();
    logger.verbose("Downloads: Download directory: $downloadDirectory");
    if (!await Directory(downloadDirectory).exists()) {
      await Directory(downloadDirectory).create(recursive: true);
    }

    if (subtitle.deliveryMethod == SubtitleDeliveryMethod.external_) {
      logger.verbose("Downloads: Download external subtitle: $subtitle");
      // download external subtitle
      var externalSubtitle =
          await _api.getExternalSubtitle(deliveryUrl: subtitle.deliveryUrl!);
      String fileName = subtitle.deliveryUrl!.split("?")[0].split("/").last;
      String downloadPath =
          "$downloadDirectory${Platform.pathSeparator}$itemId";
      // create download directory if it doesn't exist
      if (!await Directory(downloadPath).exists()) {
        await Directory(downloadPath).create(recursive: true);
      }
      await File(downloadPath + Platform.pathSeparator + fileName)
          .writeAsBytes(externalSubtitle);
      logger.verbose(
          "Downloads: External subtitle downloaded: $downloadPath/$fileName");
      return downloadPath + Platform.pathSeparator + fileName;
    } else {
      throw Exception("Subtitle is not external");
    }
  }

  Future<void> writeMetadataToFile(
    PlaybackInfoResponse playbackInfo,
    String streamUrl,
  ) async {
    var downloadDirectory = await getDownloadDirectory();
    var downloadPath = "$downloadDirectory${Platform.pathSeparator}$itemId";

    BaseItemDto itemDetails = await _api.getItemDetails(itemId);

    // create download directory if it doesn't exist
    if (!await Directory(downloadPath).exists()) {
      await Directory(downloadPath).create(recursive: true);
    }

    int? downloadSize;
    MediaSourceInfo sourceInfo = playbackInfo.mediaSources![0];
    String path = "$downloadPath${Platform.pathSeparator}main.m3u8";
    if (sourceInfo.transcodingUrl == null) {
      downloadSize = int.parse(
          (await _dio!.head(streamUrl)).headers.value("content-length")!);
      path =
          "$downloadPath${Platform.pathSeparator}${sourceInfo.id}.${sourceInfo.container}";
    }

    var metadata = DownloadMetadata(
            id: itemId,
            name: itemDetails.name!,
            type: itemDetails.type!,
            runTimeTicks: itemDetails.runTimeTicks!,
            seriesName: itemDetails.seriesName ?? "",
            seriesId: itemDetails.seriesId ?? "",
            indexNumber: itemDetails.indexNumber ?? 0,
            parentIndexNumber: itemDetails.parentIndexNumber ?? 0,
            path: path,
            downloadSize: downloadSize)
        .toJson();

    // write metadata to file
    await File("$downloadPath${Platform.pathSeparator}metadata.json")
        .writeAsString(jsonEncode(metadata));

    // download backdrop image
    try {
      var imageUrl = _api.getImageUrl(itemId, ImageType.backdrop);
      await _dio!.download(
          imageUrl, "$downloadPath${Platform.pathSeparator}image.jpg");
    } on DioException catch (e) {
      if (e.response!.statusCode == 404) {
        var imageUrl = _api.getImageUrl(itemId, ImageType.primary);
        await _dio!.download(
            imageUrl, "$downloadPath${Platform.pathSeparator}image.jpg");
      }
    }
  }

  Future<void> writePlaybackInfoToFile(PlaybackInfoResponse playbackInfo,
      {MediaStream? subtitle,
      String? subtitlePath,
      int? audioStreamIndex}) async {
    var downloadDirectory = await getDownloadDirectory();
    var downloadPath = "$downloadDirectory${Platform.pathSeparator}$itemId";

    // create download directory if it doesn't exist
    if (!await Directory(downloadPath).exists()) {
      await Directory(downloadPath).create(recursive: true);
    }

    List<MediaStream> streamsToKeep = [];

    for (var stream in playbackInfo.mediaSources![0].mediaStreams!) {
      if ((stream.type == MediaStreamType.audio &&
              stream.index! == audioStreamIndex) ||
          (stream.type == MediaStreamType.audio &&
              stream.deliveryMethod == null &&
              playbackInfo.mediaSources![0].transcodingUrl == null) ||
          stream.type == MediaStreamType.video ||
          (stream.type == MediaStreamType.subtitle &&
              stream.deliveryMethod == SubtitleDeliveryMethod.embed)) {
        streamsToKeep.add(stream);
      }
    }

    if (subtitle != null && subtitlePath != null) {
      MediaStream updatedSubtitle =
          subtitle.rebuild((b) => b..deliveryUrl = subtitlePath);
      streamsToKeep.add(updatedSubtitle);
    } else if (subtitle != null || subtitlePath != null) {
      throw Exception(
          "Subtitle and subtitlePath must be either both null or both not null");
    }

    PlaybackInfoResponse updatedInfo = playbackInfo.rebuild((b) {
      if (b.mediaSources.isNotEmpty) {
        // Update only the first media source
        b.mediaSources[0] = b.mediaSources[0].rebuild((ms) {
          ms.mediaStreams.replace(streamsToKeep);
        });
      }
    });

    // write playback info to file
    await File("$downloadPath${Platform.pathSeparator}playback_info.json")
        .writeAsString(PlaybackInfoResponseSerializer.toJson(updatedInfo));
  }

  Future<PlaybackInfoResponse> getPlaybackInfoFromFile() async {
    var downloadDirectory = await getDownloadDirectory();
    var downloadPath = "$downloadDirectory${Platform.pathSeparator}$itemId";

    return PlaybackInfoResponseSerializer.fromJson(
        await File("$downloadPath${Platform.pathSeparator}playback_info.json")
            .readAsString());
  }

  Future<String> getMetadataImagePath() async {
    var downloadDirectory = await getDownloadDirectory();
    var downloadPath = "$downloadDirectory${Platform.pathSeparator}$itemId";
    return "$downloadPath${Platform.pathSeparator}image.jpg";
  }

  Future<DownloadMetadata> getMetadata() async {
    var downloadDirectory = await getDownloadDirectory();
    var downloadPath = "$downloadDirectory${Platform.pathSeparator}$itemId";

    // check if file exists
    if (!await File("$downloadPath${Platform.pathSeparator}metadata.json")
        .exists()) {
      throw Exception("Metadata file not found");
    }

    var metadataString =
        await File("$downloadPath${Platform.pathSeparator}metadata.json")
            .readAsString();

    var metadata = DownloadMetadata.fromJson(json.decode(metadataString));

    return metadata;
  }

  Future<void> resumeDownload() async {
    // Resume download
    bool masterM3UExists = await File(
            "${await getDownloadDirectory()}${Platform.pathSeparator}$itemId${Platform.pathSeparator}master.m3u8")
        .exists();
    bool mainM3UExists = await File(
            "${await getDownloadDirectory()}${Platform.pathSeparator}$itemId${Platform.pathSeparator}main.m3u8")
        .exists();
    if (Platform.isAndroid || Platform.isIOS) {
      isDownloading = true;
      _download = CancelableOperation.fromFuture(
        _resumeMobileDownload(),
        onCancel: () {
          isDownloading = false;
          logger.warning("Downloads: Download canceled");
        },
      )..value.whenComplete(() {}).onError((error, stackTrace) {
          isDownloading = false;
          logger.error(
              "Downloads: Error resuming download: $itemId: $stackTrace",
              error: error);
        });
    } else if (masterM3UExists && mainM3UExists) {
      isDownloading = true;
      _download = CancelableOperation.fromFuture(
        _resumeTranscodedDownload(),
        onCancel: () {
          isDownloading = false;
          logger.warning("Downloads: Download canceled");
        },
      )..value.whenComplete(() {}).onError((error, stackTrace) {
          isDownloading = false;
          logger.error(
              "Downloads: Error resuming download: $itemId: $stackTrace",
              error: error);
        });
    } else if (await File(
            "${await getDownloadDirectory()}${Platform.pathSeparator}$itemId${Platform.pathSeparator}temp_download_data")
        .exists()) {
      isDownloading = true;
      _download = CancelableOperation.fromFuture(
        _resumeDirectStreamDownload(),
        onCancel: () {
          isDownloading = false;
          logger.warning("Downloads: Download canceled");
        },
      )..value.whenComplete(() {}).onError((error, stackTrace) {
          isDownloading = false;
          logger.error(
              "Downloads: Error resuming download: $itemId: $stackTrace",
              error: error);
        });
    } else {
      await removeDownload();
      rootScaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(navigatorKey.currentContext!)!
              .couldNotResumeDownload)));
    }
  }

  _resumeMobileDownload() async {
    var tasks = await FlutterDownloader.loadTasksWithRawQuery(
        query:
            "SELECT * FROM task WHERE saved_dir LIKE '%downloads${Platform.pathSeparator}$itemId%'");
    if (tasks != null && tasks.isNotEmpty) {
      List removeTasks = [];
      // check if file already exists
      for (var task in tasks) {
        if (await File(task.savedDir + Platform.pathSeparator + task.filename!)
            .exists()) {
          await FlutterDownloader.remove(taskId: task.taskId);
          logger.verbose(
              "Downloads: File already exists, removing task: ${task.taskId} (${task.filename})");
          // remove task from list
          removeTasks.add(task);
        }
      }
      for (var task in removeTasks) {
        tasks.remove(task);
      }
    }
    if (tasks != null && tasks.isNotEmpty) {
      var failedTasks = tasks
          .where((element) => element.status != DownloadTaskStatus.complete)
          .toList();
      if (failedTasks.isNotEmpty) {
        for (var task in failedTasks) {
          logger.verbose(
              "Downloads: Restarting download for task: ${task.taskId} (${task.filename})");
          await _enqueueUpdatedDownloadUrl(task);
          await FlutterDownloader.remove(taskId: task.taskId);
        }
      }
      tasks = await FlutterDownloader.loadTasksWithRawQuery(
          query:
              "SELECT * FROM task WHERE saved_dir LIKE '%downloads${Platform.pathSeparator}$itemId%'");
      logger.verbose("Downloads: Tasks after resuming: ${tasks?.length}");
    }
    // tasks can be empty if all tasks were removed and they haven't been reported correctly by FlutterDownloader
  }

  _enqueueUpdatedDownloadUrl(DownloadTask task) async {
    // Replace the api_key parameter value in the URL with the current user's token, until the next '&'
    String newUrl = task.url.replaceFirst(
      RegExp(r'api_key=[a-zA-Z0-9]+(?=&)'),
      'api_key=${_api.currentUser!.token}',
    );
    await FlutterDownloader.enqueue(
      url: newUrl,
      savedDir: task.savedDir,
      fileName: task.filename,
      showNotification: false,
      openFileFromNotification: false,
    );
  }

  _resumeTranscodedDownload() async {
    // open main.m3u8
    var downloadDirectory = await getDownloadDirectory();
    var downloadPath = "$downloadDirectory${Platform.pathSeparator}$itemId";
    var mainM3U =
        await File("$downloadDirectory/$itemId/main.m3u8").readAsString();

    var prefix = "${_api.currentUser!.serverAdress}/Videos/$itemId/";

    for (var line in mainM3U.split("\n")) {
      if (line.startsWith("hls1/main")) {
        var fileName = line.split("/").last.split("?").first;
        var pattern = line
            .split("&")
            .firstWhere((element) => element.startsWith("api_key"));
        line = line.replaceAll(pattern, "api_key=${_api.currentUser!.token}");
        await _dio!.download(
            prefix + line, "$downloadPath${Platform.pathSeparator}$fileName",
            cancelToken: cancelToken);
        mainM3U = mainM3U.replaceAll(line, fileName);
        await File("$downloadPath${Platform.pathSeparator}main.m3u8")
            .writeAsString(mainM3U);
      } else {}
    }
  }

  _resumeDirectStreamDownload() async {
    var downloadDirectory = await getDownloadDirectory();
    var downloadPath = "$downloadDirectory${Platform.pathSeparator}$itemId";

    if (await File("$downloadPath${Platform.pathSeparator}temp_download_data")
            .exists() &&
        await File("$downloadPath${Platform.pathSeparator}temp_chunk0")
            .exists()) {
      // load temp_download_data
      var tempDownloadData =
          await File("$downloadPath${Platform.pathSeparator}temp_download_data")
              .readAsString();
      var tempData = tempDownloadData.split("\n");
      var streamUrl = tempData[0];
      var contentLength = int.parse(tempData[1]);
      var localFilePath = tempData[2];

      // check if temp_chunk files exist
      var list = await Directory(downloadPath).list().toList();
      List<FileSystemEntity> chunks = list
          .where((element) => element.path
              .split(Platform.pathSeparator)
              .last
              .startsWith("temp_chunk"))
          .toList();
      // get size of all chunks
      var downloadedSize = 0;
      for (var chunk in chunks) {
        var stats = await chunk.stat();
        downloadedSize += stats.size;
      }
      if (downloadedSize < contentLength) {
        // download remaining data
        var tempFile = File(
            "$downloadPath${Platform.pathSeparator}temp_chunk${chunks.length}");
        Options options = Options(
          headers: {
            "Range": "bytes=$downloadedSize-",
          },
        );
        await _dio!.download(
          streamUrl,
          tempFile.path,
          options: options,
          cancelToken: cancelToken,
        );
        for (int i = 0; i <= chunks.length; i++) {
          var chunk =
              File("$downloadPath${Platform.pathSeparator}temp_chunk$i");
          var bytes = await chunk.readAsBytes();
          await File(localFilePath).writeAsBytes(bytes, mode: FileMode.append);
          await chunk.delete();
        }
      } else {
        for (int i = 0; i < chunks.length; i++) {
          var chunk =
              File("$downloadPath${Platform.pathSeparator}temp_chunk$i");
          var bytes = await chunk.readAsBytes();
          await File(localFilePath).writeAsBytes(bytes, mode: FileMode.append);
          await chunk.delete();
        }
      }
      // delete temp_download_data
      await File("$downloadPath${Platform.pathSeparator}temp_download_data")
          .delete();
    } else {
      await removeDownload();
    }
  }

  Future<void> removeDownload() async {
    // Remove downloaded file
    var downloadDirectory = await getDownloadDirectory();
    var downloadPath = "$downloadDirectory${Platform.pathSeparator}$itemId";

    // Remove downloaded files
    if (await Directory(downloadPath).exists()) {
      await Directory(downloadPath).delete(recursive: true);
    }
  }

  static Future<String> getDownloadDirectory() async {
    // Get download directory
    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    return "${appDocumentsDir.path}${Platform.pathSeparator}jellyflix${Platform.pathSeparator}downloads";
  }

  Future<void> downloadTranscodedStream(String streamUrl) async {
    var downloadDirectory = await getDownloadDirectory();
    var downloadPath = "$downloadDirectory${Platform.pathSeparator}$itemId";

    logger.verbose("Downloads: Download directory: $downloadDirectory");

    // create download directory if it doesn't exist
    if (!await Directory(downloadPath).exists()) {
      await Directory(downloadPath).create(recursive: true);
    }
    var masterM3U = await _dio!.get(streamUrl, cancelToken: cancelToken);
    await File("$downloadPath${Platform.pathSeparator}master.m3u8")
        .writeAsString(masterM3U.data);
    var prefix =
        "${streamUrl.split("/").sublist(0, streamUrl.split("/").length - 1).join("/")}/";
    var mainM3U = await _dio!
        .get(prefix + masterM3U.data.split("\n")[2], cancelToken: cancelToken);

    // write original mainM3U to file
    await File("$downloadPath${Platform.pathSeparator}main.m3u8")
        .writeAsString(mainM3U.data);
    List<String> lines = mainM3U.data.split("\n");

    if (Platform.isAndroid || Platform.isIOS) {
      // get document directory
      for (var line in lines) {
        if (line.startsWith("hls1/main")) {
          var fileName = line.split("/").last.split("?").first;
          var taskId = await FlutterDownloader.enqueue(
            url: _api.currentUser!.serverAdress! + prefix + line,
            savedDir: downloadPath,
            fileName: fileName,
            showNotification: false,
            openFileFromNotification: false,
          );
          downloadTaskIds.add(taskId!);
        }
      }
    }

    for (var line in mainM3U.data.split("\n")) {
      if (line.startsWith("hls1/main")) {
        var fileName = line.split("/").last.split("?").first;
        if (!Platform.isAndroid && !Platform.isIOS) {
          await _dio!.download(
              prefix + line, "$downloadPath${Platform.pathSeparator}$fileName",
              cancelToken: cancelToken);
        }
        mainM3U.data = mainM3U.data.replaceFirst(line, fileName);
        await File("$downloadPath${Platform.pathSeparator}main.m3u8")
            .writeAsString(mainM3U.data);
      }
    }
  }

  downloadDirectStream(String streamUrl) async {
    _download = CancelableOperation.fromFuture(
      _cancelableDownloadDirectStream(streamUrl),
      onCancel: () {
        isDownloading = false;
      },
    )..value.whenComplete(() {}).onError((error, stackTrace) {
        isDownloading = false;
      });
  }

  _cancelableDownloadDirectStream(String streamUrl) async {
    var downloadDirectory = await getDownloadDirectory();
    var downloadPath = "$downloadDirectory${Platform.pathSeparator}$itemId";
    var fileExtension =
        streamUrl.split("/").last.split("?").first.split(".").last;

    logger.verbose("Downloads: Download directory: $downloadPath");

    if (Platform.isAndroid || Platform.isIOS) {
      await FlutterDownloader.enqueue(
        url: streamUrl,
        savedDir: downloadPath,
        fileName: "$itemId.$fileExtension",
        showNotification: false,
        openFileFromNotification: false,
        headers: _api.headers,
      );
    } else {
      // get download info
      var downloadInfo = await _dio!.head(streamUrl);

      var contentLength =
          int.parse(downloadInfo.headers.value("content-length")!);

      var localFilePath =
          "$downloadPath${Platform.pathSeparator}$itemId.$fileExtension";
      var localFile = File(localFilePath);

      // write temp_download_data to file
      await File("$downloadPath${Platform.pathSeparator}temp_download_data")
          .writeAsString("$streamUrl\n$contentLength\n${localFile.path}");

      var tempFile = File("$downloadPath${Platform.pathSeparator}temp_chunk0");

      await _dio!.download(
        streamUrl,
        tempFile.path,
        cancelToken: cancelToken,
      );

      // rename file
      await tempFile.rename(localFilePath);
      // remove temp_download_data
      await File("$downloadPath${Platform.pathSeparator}temp_download_data")
          .delete();
    }
  }

  Stream<int?> downloadProgress(int interval) async* {
    while (true) {
      yield await calculateProgress();
      await Future.delayed(Duration(seconds: interval));
    }
  }

  Future<int?> calculateProgress() async {
    var downloadDirectory = await getDownloadDirectory();
    // check if folder exists in downloadDirectory
    if (await Directory("$downloadDirectory${Platform.pathSeparator}$itemId")
            .exists() &&
        await File(
                "$downloadDirectory${Platform.pathSeparator}$itemId${Platform.pathSeparator}main.m3u8")
            .exists()) {
      if (totalChunks == null) {
        // read mainm3u file
        var mainM3U = await File(
                "$downloadDirectory${Platform.pathSeparator}$itemId${Platform.pathSeparator}main.m3u8")
            .readAsString();

        totalChunks = mainM3U
            .split("\n")
            .where((element) => element.startsWith("#EXTINF:"))
            .length;
      }

      // get all files in folder
      var contents =
          await Directory("$downloadDirectory${Platform.pathSeparator}$itemId")
              .list()
              .toList();
      // get all files with .ts extension
      var downloadedChunks =
          contents.where((element) => element.path.endsWith(".ts")).length;
      if (totalChunks == 0) {
        return 0;
      } else {
        int progress = (downloadedChunks / totalChunks! * 100).toInt();
        if (progress == 100) {
          await completeDownload();
        }
        return progress;
      }
    } else if (await File(
            "$downloadDirectory${Platform.pathSeparator}$itemId${Platform.pathSeparator}metadata.json")
        .exists()) {
      // read metadata file
      DownloadMetadata metadata = await getMetadata();
      // calculate progress for direct stream downloads
      if (metadata.downloadSize != null &&
          !await File(
                  "$downloadDirectory${Platform.pathSeparator}$itemId${Platform.pathSeparator}main.m3u8")
              .exists()) {
        // check if chunks exist
        var contents = await Directory(
                "$downloadDirectory${Platform.pathSeparator}$itemId")
            .list()
            .toList();

        if (Platform.isAndroid || Platform.isIOS) {
          var tasks = await FlutterDownloader.loadTasksWithRawQuery(
            query: "SELECT * FROM task WHERE file_name LIKE '$itemId.%'",
          );
          // it's more reliable to check if the file exists in the download directory than checking the status
          if (contents
              .where((element) => element.path
                  .split(Platform.pathSeparator)
                  .last
                  .startsWith(itemId))
              .isNotEmpty) {
            await completeDownload();
            return 100;
          } else if (tasks != null && tasks.isNotEmpty) {
            tasks.sort((a, b) => a.timeCreated.compareTo(b.timeCreated));
            if (tasks.last.progress == 100) {
              await completeDownload();
            }
            return tasks.last.progress;
          }
        } else {
          // check if chunks exist
          contents.where((element) => element.path
              .split(Platform.pathSeparator)
              .last
              .startsWith("temp_chunk"));
          if (contents.isNotEmpty) {
            int downloadedSize = 0;
            for (var chunk in contents) {
              // skip metadata file and image
              if (chunk.path.endsWith("metadata.json") ||
                  chunk.path.endsWith("image.jpg")) {
                continue;
              }
              var stats = await chunk.stat();
              downloadedSize += stats.size;
            }
            var progress =
                (downloadedSize / metadata.downloadSize! * 100).toInt();
            if (progress == 100) {
              await completeDownload();
            }
            return progress;
          }
        }
      }
    }
    return null;
  }

  Future<void> completeDownload() async {
    isDownloading = false;
    if (Platform.isAndroid || Platform.isIOS) {
      var completedTasks = await FlutterDownloader.loadTasksWithRawQuery(
              query: "SELECT * FROM task WHERE status=3") ??
          [];

      for (var task in completedTasks) {
        if (task.status == DownloadTaskStatus.complete) {
          await FlutterDownloader.remove(taskId: task.taskId);
        }
      }
    }
  }

  Future<void> cancelDownload() async {
    isDownloading = false;
    if (Platform.isAndroid || Platform.isIOS) {
      for (var taskId in downloadTaskIds) {
        await FlutterDownloader.cancel(taskId: taskId);
      }
    }
    // cancel the latest request
    cancelToken.cancel();
    // cancel the future
    await _download.cancel();
    await removeDownload();
    await _api.reportStopPlayback(0, itemId: itemId);
    cancelToken = CancelToken();
  }

  static Future<void> cancelAndDeleteAllDownloads() async {
    if (Platform.isAndroid || Platform.isIOS) {
      var tasks = await FlutterDownloader.loadTasks() ?? [];
      for (var task in tasks) {
        await FlutterDownloader.remove(taskId: task.taskId);
      }
    }
    for (DownloadService instance in _instances.values) {
      await instance.cancelDownload();
    }
    // delete all downloads
    var downloadDir = await getDownloadDirectory();
    if (await Directory(downloadDir).exists()) {
      await Directory(downloadDir).delete(recursive: true);
    }
    // show snackbar
    rootScaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(navigatorKey.currentContext!)!
            .allDownloadsRemoved)));
  }
}
