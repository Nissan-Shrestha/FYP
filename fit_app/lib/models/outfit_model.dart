import 'package:fit_app/models/clothing_item_model.dart';

class OutfitModel {
  final int id;
  final String name;
  final String? occasion;
  final List<ClothingItemModel> items;
  final DateTime createdAt;

  const OutfitModel({
    required this.id,
    required this.name,
    this.occasion,
    required this.items,
    required this.createdAt,
  });

  factory OutfitModel.fromJson(Map<String, dynamic> json) {
    return OutfitModel(
      id: json["id"] as int,
      name: json["name"] as String,
      occasion: json["occasion"] as String?,
      items: (json["items"] as List<dynamic>?)
              ?.map((item) =>
                  ClothingItemModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json["created_at"] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "occasion": occasion,
      "items": items.map((item) => item.toJson()).toList(),
      "created_at": createdAt.toIso8601String(),
    };
  }
}
