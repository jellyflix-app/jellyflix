import 'package:hive/hive.dart';
import 'package:tentacle/tentacle.dart';

class BaseItemDtoAdapter extends TypeAdapter<BaseItemDto> {
  @override
  final int typeId = 1;

  @override
  BaseItemDto read(BinaryReader reader) {
    return $BaseItemDto((p0) {
      p0.id = reader.read();
      p0.name = reader.read();
      p0.productionYear = reader.read();
    });
  }

  @override
  void write(BinaryWriter writer, BaseItemDto obj) {
    writer
      ..write(obj.id)
      ..write(obj.name)
      ..write(obj.productionYear);
  }
}
