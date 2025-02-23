import 'package:tentacle/tentacle.dart';
import 'dart:convert';

class PlaybackInfoResponseSerializer {
  /// Converts a PlaybackInfoResponse object to a JSON string.
  static String toJson(PlaybackInfoResponse response) {
    final serialized =
        serializers.serializeWith(PlaybackInfoResponse.serializer, response);
    return json.encode(serialized);
  }

  /// Converts a JSON string to a PlaybackInfoResponse object.
  static PlaybackInfoResponse fromJson(String jsonString) {
    final decodedJson = json.decode(jsonString);
    return serializers.deserializeWith(
        PlaybackInfoResponse.serializer, decodedJson)!;
  }
}
