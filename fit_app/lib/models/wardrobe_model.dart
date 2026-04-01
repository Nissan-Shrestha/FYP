class WardrobeModel {
  final int id;
  final int owner;
  final String name;
  final bool isDefault;
  final int itemCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WardrobeModel({
    required this.id,
    required this.owner,
    required this.name,
    required this.isDefault,
    required this.itemCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WardrobeModel.fromJson(Map<String, dynamic> json) {
    return WardrobeModel(
      id: _asInt(json["id"]),
      owner: _asInt(json["owner"]),
      name: (json["name"] as String?) ?? "",
      isDefault: json["is_default"] as bool? ?? false,
      itemCount: _asInt(json["item_count"], fallback: 0),
      createdAt:
          DateTime.tryParse((json["created_at"] as String?) ?? "") ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse((json["updated_at"] as String?) ?? "") ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "owner": owner,
      "name": name,
      "is_default": isDefault,
      "item_count": itemCount,
      "created_at": createdAt.toIso8601String(),
      "updated_at": updatedAt.toIso8601String(),
    };
  }
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}
