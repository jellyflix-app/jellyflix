import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:jellyflix/models/download_metadata.dart';
import 'package:jellyflix/navigation/app_router.dart';
import 'package:jellyflix/providers/scaffold_key.dart';
import 'package:jellyflix/services/api_service.dart';
import 'package:openapi/openapi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:async/async.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DownloadService {
  static final Map<String, DownloadService> _instances = {};

  final ApiService _api;
  late CancelableOperation<void> _download;
  late final String itemId;
  late Dio _dio;

  bool isDownloading = false;
  CancelToken cancelToken = CancelToken();
  List<String> downloadTaskIds = [];

  factory DownloadService(
    api, {
    required String itemId,
  }) {
    if (_instances.containsKey(itemId)) {
      return _instances[itemId]!;
    } else {
      final instance = DownloadService._internal(api, itemId: itemId);
      _instances[itemId] = instance;
      return instance;
    }
  }

  DownloadService._internal(
    this._api, {
    required this.itemId,
  }) {
    _dio = Dio(
      BaseOptions(
        headers: _api.headers,
        baseUrl: _api.currentUser!.serverAdress!,
      ),
    );
  }

  static Future<List<String>> getDownloadedItems() async {
    var downloadDir = await getDownloadDirectory();

    // get all folders in downloadDir
    var contents = await Directory(downloadDir)
        .list()
        .where((event) => event is Directory)
        .map((event) => event.path.split("/").last)
        .toList();
    return contents;
  }

  Future<String> getDownloadedItemPath() async {
    var downloadDir = await getDownloadDirectory();
    return "$downloadDir/$itemId/main.m3u8";
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
      },
    )..value.whenComplete(() {}).onError((error, stackTrace) {
        isDownloading = false;
      });
  }

  Future<void> _downloadItem(
      {int? audioStreamIndex,
      int? subtitleStreamIndex,
      required int downloadBitrate}) async {
    // create download directory if it doesn't exist
    var downloadDirectory = await getDownloadDirectory();
    if (!await Directory(downloadDirectory).exists()) {
      await Directory(downloadDirectory).create();
    }
    isDownloading = true;
    var response = await _api.getStreamUrlAndPlaybackInfo(
        itemId: itemId,
        maxStreamingBitrate: downloadBitrate,
        audioStreamIndex: audioStreamIndex,
        subtitleStreamIndex: subtitleStreamIndex);
    PlaybackInfoResponse playbackInfo = response.$2;

    await writeMetadataToFile(playbackInfo, response.$1);

    if (playbackInfo.mediaSources![0].transcodingUrl == null) {
      await downloadDirectStream(response.$1);
    } else {
      await downloadTranscodedStream(
          playbackInfo.mediaSources![0].transcodingUrl!);
    }
  }

  Future<void> writeMetadataToFile(
      PlaybackInfoResponse playbackInfo, String streamUrl) async {
    var downloadDirectory = await getDownloadDirectory();
    var downloadPath = "$downloadDirectory/$itemId";

    BaseItemDto itemDetails = await _api.getItemDetails(itemId);

    // create download directory if it doesn't exist
    if (!await Directory(downloadPath).exists()) {
      await Directory(downloadPath).create();
    }

    int? downloadSize;
    if (playbackInfo.mediaSources![0].transcodingUrl == null) {
      downloadSize = int.parse(
          (await _dio.head(streamUrl)).headers.value("content-length")!);
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
            path: "$downloadPath/main.m3u8",
            downloadSize: downloadSize)
        .toJson();

    // write metadata to file
    await File("$downloadPath/metadata.json")
        .writeAsString(jsonEncode(metadata));

    // download backdrop image
    try {
      var imageUrl = _api.getImageUrl(itemId, ImageType.backdrop);
      await _dio.download(imageUrl, "$downloadPath/image.jpg");
    } on DioException catch (e) {
      if (e.response!.statusCode == 404) {
        var imageUrl = _api.getImageUrl(itemId, ImageType.primary);
        await _dio.download(imageUrl, "$downloadPath/image.jpg");
      }
    }
  }

  Future<String> getMetadataImagePath() async {
    var downloadDirectory = await getDownloadDirectory();
    var downloadPath = "$downloadDirectory/$itemId";
    return "$downloadPath/image.jpg";
  }

  Future<DownloadMetadata> getMetadata() async {
    var downloadDirectory = await getDownloadDirectory();
    var downloadPath = "$downloadDirectory/$itemId";

    // check if file exists
    if (!await File("$downloadPath/metadata.json").exists()) {
      throw Exception("Metadata file not found");
    }

    var metadata = await File("$downloadPath/metadata.json").readAsString();

    return DownloadMetadata.fromJson(json.decode(metadata));
  }

  Future<void> resumeDownload() async {
    // Resume download
    bool masterM3UExists =
        await File("${await getDownloadDirectory()}/$itemId/master.m3u8")
            .exists();
    bool mainM3UExists =
        await File("${await getDownloadDirectory()}/$itemId/main.m3u8")
            .exists();
    if (Platform.isAndroid || Platform.isIOS) {
      var tasks = await FlutterDownloader.loadTasksWithRawQuery(
          query:
              "SELECT * FROM task WHERE saved_dir LIKE '%downloads/$itemId%'");
      if (tasks != null && tasks.isNotEmpty) {
        isDownloading = true;
        var failedTasks = tasks
            .where((element) =>
                element.status == DownloadTaskStatus.failed ||
                element.status == DownloadTaskStatus.canceled)
            .toList();
        if (failedTasks.isNotEmpty) {
          for (var task in failedTasks) {
            await FlutterDownloader.retry(taskId: task.taskId);
          }
        }
      } else {
        await removeDownload();
        rootScaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(navigatorKey.currentContext!)!
                .couldNotResumeDownload)));
      }
    } else if (masterM3UExists && mainM3UExists) {
      isDownloading = true;
      _download = CancelableOperation.fromFuture(
        _resumeTranscodedDownload(),
        onCancel: () {
          isDownloading = false;
        },
      )..value.whenComplete(() {}).onError((error, stackTrace) {
          isDownloading = false;
        });
    } else if (await File(
            "${await getDownloadDirectory()}/$itemId/temp_download_data")
        .exists()) {
      isDownloading = true;
      _download = CancelableOperation.fromFuture(
        _resumeDirectStreamDownload(),
        onCancel: () {
          isDownloading = false;
        },
      )..value.whenComplete(() {}).onError((error, stackTrace) {
          isDownloading = false;
        });
    } else {
      await removeDownload();
      rootScaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(navigatorKey.currentContext!)!
              .couldNotResumeDownload)));
    }
  }

  _resumeTranscodedDownload() async {
    // open main.m3u8
    var downloadDirectory = await getDownloadDirectory();
    var downloadPath = "$downloadDirectory/$itemId";
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
        await _dio.download(prefix + line, "$downloadPath/$fileName",
            cancelToken: cancelToken);
        mainM3U = mainM3U.replaceAll(line, "file://$downloadPath/$fileName");
        await File("$downloadPath/main.m3u8").writeAsString(mainM3U);
      } else {}
    }
  }

  _resumeDirectStreamDownload() async {
    var downloadDirectory = await getDownloadDirectory();
    var downloadPath = "$downloadDirectory/$itemId";

    if (await File("$downloadPath/temp_download_data").exists() &&
        await File("$downloadPath/temp_chunk0").exists()) {
      // load temp_download_data
      var tempDownloadData =
          await File("$downloadPath/temp_download_data").readAsString();
      var tempData = tempDownloadData.split("\n");
      var streamUrl = tempData[0];
      var contentLength = int.parse(tempData[1]);
      var localFilePath = tempData[2];

      // check if temp_chunk files exist
      var list = await Directory(downloadPath).list().toList();
      List<FileSystemEntity> chunks = list
          .where((element) =>
              element.path.split("/").last.startsWith("temp_chunk"))
          .toList();
      // get size of all chunks
      var downloadedSize = 0;
      for (var chunk in chunks) {
        var stats = await chunk.stat();
        downloadedSize += stats.size;
      }
      if (downloadedSize < contentLength) {
        // download remaining data
        var tempFile = File("$downloadPath/temp_chunk${chunks.length}");
        Options options = Options(
          headers: {
            "Range": "bytes=$downloadedSize-",
          },
        );
        await _dio.download(
          streamUrl,
          tempFile.path,
          options: options,
          cancelToken: cancelToken,
        );
        for (int i = 0; i <= chunks.length; i++) {
          var chunk = File("$downloadPath/temp_chunk$i");
          var bytes = await chunk.readAsBytes();
          await File(localFilePath).writeAsBytes(bytes, mode: FileMode.append);
          await chunk.delete();
        }
      } else {
        for (int i = 0; i < chunks.length; i++) {
          var chunk = File("$downloadPath/temp_chunk$i");
          var bytes = await chunk.readAsBytes();
          await File(localFilePath).writeAsBytes(bytes, mode: FileMode.append);
          await chunk.delete();
        }
      }
      // delete temp_download_data
      await File("$downloadPath/temp_download_data").delete();
    } else {
      await removeDownload();
    }
  }

  Future<void> removeDownload() async {
    // Remove downloaded file
    var downloadDirectory = await getDownloadDirectory();
    var downloadPath = "$downloadDirectory/$itemId";

    // Remove downloaded files
    if (await Directory(downloadPath).exists()) {
      await Directory(downloadPath).delete(recursive: true);
    }
  }

  static Future<String> getDownloadDirectory() async {
    // Get download directory
    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    return "${appDocumentsDir.path}/downloads";
  }

  Future<void> downloadTranscodedStream(String streamUrl) async {
    var downloadDirectory = await getDownloadDirectory();
    var downloadPath = "$downloadDirectory/$itemId";

    // create download directory if it doesn't exist
    if (!await Directory(downloadPath).exists()) {
      await Directory(downloadPath).create();
    }
    var masterM3U = await _dio.get(streamUrl, cancelToken: cancelToken);
    await File("$downloadPath/master.m3u8").writeAsString(masterM3U.data);
    var prefix =
        "${streamUrl.split("/").sublist(0, streamUrl.split("/").length - 1).join("/")}/";
    var mainM3U = await _dio.get(prefix + masterM3U.data.split("\n")[2],
        cancelToken: cancelToken);

    // write original mainM3U to file
    await File("$downloadPath/main.m3u8").writeAsString(mainM3U.data);
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
          await _dio.download(prefix + line, "$downloadPath/$fileName",
              cancelToken: cancelToken);
        }
        mainM3U.data =
            mainM3U.data.replaceAll(line, "file://$downloadPath/$fileName");
        await File("$downloadPath/main.m3u8").writeAsString(mainM3U.data);
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
    var downloadPath = "$downloadDirectory/$itemId";
    var fileExtension =
        streamUrl.split("/").last.split("?").first.split(".").last;

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
      var downloadInfo = await _dio.head(streamUrl);

      var contentLength =
          int.parse(downloadInfo.headers.value("content-length")!);

      var localFilePath = "$downloadPath/$itemId.$fileExtension";
      var localFile = File(localFilePath);

      // write temp_download_data to file
      await File("$downloadPath/temp_download_data")
          .writeAsString("$streamUrl\n$contentLength\n${localFile.path}");

      var tempFile = File("$downloadPath/temp_chunk0");

      await _dio.download(
        streamUrl,
        tempFile.path,
        cancelToken: cancelToken,
      );

      // rename file
      await tempFile.rename(localFilePath);
      // remove temp_download_data
      await File("$downloadPath/temp_download_data").delete();
    }
  }

  Stream<int?> downloadProgess(int interval) async* {
    yield await calculateProgress();

    await for (var _ in Stream.periodic(Duration(seconds: interval))) {
      yield await calculateProgress();
    }
  }

  Future<int?> calculateProgress() async {
    var downloadDirectory = await getDownloadDirectory();
    // check if folder exists in downloadDirectory
    if (await Directory("$downloadDirectory/$itemId").exists() &&
        await File("$downloadDirectory/$itemId/main.m3u8").exists()) {
      // read mainm3u file
      var mainM3U =
          await File("$downloadDirectory/$itemId/main.m3u8").readAsString();

      var totalChunks = mainM3U
          .split("\n")
          .where((element) => element.startsWith("#EXTINF:"))
          .length;

      // get all files in folder
      var contents =
          await Directory("$downloadDirectory/$itemId").list().toList();
      // get all files with .ts extension
      var downloadedChunks =
          contents.where((element) => element.path.endsWith(".ts")).length;
      if (totalChunks == 0) {
        return 0;
      } else {
        int progress = (downloadedChunks / totalChunks * 100).toInt();
        if (progress == 100) {
          await completeDownload();
        }
        return progress;
      }
    } else if (await File("$downloadDirectory/$itemId/metadata.json")
        .exists()) {
      // read metadata file
      DownloadMetadata metadata = await getMetadata();
      if (metadata.downloadSize != null &&
          !await File("$downloadDirectory/$itemId/main.m3u8").exists()) {
        // check if chunks exist
        var contents =
            await Directory("$downloadDirectory/$itemId").list().toList();

        if (Platform.isAndroid || Platform.isIOS) {
          var tasks = await FlutterDownloader.loadTasksWithRawQuery(
            query: "SELECT * FROM task WHERE file_name LIKE '$itemId.%'",
          );
          if (tasks == null || tasks.isEmpty) {
            contents.where(
                (element) => element.path.split("/").last.startsWith(itemId));
            if (contents.isNotEmpty) {
              return 100;
            }
            return null;
          } else {
            tasks.sort((a, b) => a.timeCreated.compareTo(b.timeCreated));
            return tasks.last.progress;
          }
        } else {
          // check if chunks exist
          contents.where((element) =>
              element.path.split("/").last.startsWith("temp_chunk"));
          if (contents.isNotEmpty) {
            int downloadedSize = 0;
            for (var chunk in contents) {
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
