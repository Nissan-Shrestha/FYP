class ClothingOptionModel {
  final int id;
  final String type;
  final String name;
  final String? itemType;
  final int layerLevel;

  const ClothingOptionModel({
    required this.id,
    required this.type,
    required this.name,
    this.itemType,
    this.layerLevel = 0,
  });

  factory ClothingOptionModel.fromJson(Map<String, dynamic> json) {
    return ClothingOptionModel(
      id: json["id"] as int,
      type: (json["type"] as String?) ?? "",
      name: (json["name"] as String?) ?? "",
      itemType: json["item_type"] as String?,
      layerLevel: json["layer_level"] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "type": type,
      "name": name,
      "item_type": itemType,
      "layer_level": layerLevel,
    };
  }
}
