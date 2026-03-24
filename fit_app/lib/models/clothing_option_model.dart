class ClothingOptionModel {
  final int id;
  final String type;
  final String name;

  const ClothingOptionModel({
    required this.id,
    required this.type,
    required this.name,
  });

  factory ClothingOptionModel.fromJson(Map<String, dynamic> json) {
    return ClothingOptionModel(
      id: json["id"] as int,
      type: json["type"] as String,
      name: json["name"] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "type": type,
      "name": name,
    };
  }
}
