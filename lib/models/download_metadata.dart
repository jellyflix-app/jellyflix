import 'package:tentacle/tentacle.dart';

class DownloadMetadata {
  final String id;
  final String name;
  final BaseItemKind type;
  final int runTimeTicks;
  final String? seriesName;
  final String? seriesId;
  final int? indexNumber;
  final int? parentIndexNumber;
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
}
