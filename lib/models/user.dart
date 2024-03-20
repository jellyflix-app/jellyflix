import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 0)
class User {
  @HiveField(0)
  String? id;
  @HiveField(1)
  String? name;
  @HiveField(2)
  String? serverAdress;
  @HiveField(3)
  String? password;
  int? profileIndex;
  @HiveField(4)
  String? token;

  User(
      {this.id,
      this.name,
      this.serverAdress,
      this.password,
      this.profileIndex,
      this.token});
}
