class WardrobeModel {
  final int id;
  final int owner;
  final String name;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WardrobeModel({
    required this.id,
    required this.owner,
    required this.name,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WardrobeModel.fromJson(Map<String, dynamic> json) {
    return WardrobeModel(
      id: json["id"] as int,
      owner: json["owner"] as int,
      name: json["name"] as String,
      isDefault: json["is_default"] as bool? ?? false,
      createdAt: DateTime.parse(json["created_at"] as String),
      updatedAt: DateTime.parse(json["updated_at"] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "owner": owner,
      "name": name,
      "is_default": isDefault,
      "created_at": createdAt.toIso8601String(),
      "updated_at": updatedAt.toIso8601String(),
    };
  }
}
