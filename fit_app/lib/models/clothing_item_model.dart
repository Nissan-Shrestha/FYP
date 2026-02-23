class ClothingItemModel {
  final int id;
  final int owner;
  final String name;
  final String category;
  final String season;
  final String occasion;
  final String size;
  final String material;
  final String brand;
  final String? image;
  final DateTime createdAt;

  const ClothingItemModel({
    required this.id,
    required this.owner,
    required this.name,
    required this.category,
    required this.season,
    required this.occasion,
    required this.size,
    required this.material,
    required this.brand,
    required this.image,
    required this.createdAt,
  });

  factory ClothingItemModel.fromJson(Map<String, dynamic> json) {
    return ClothingItemModel(
      id: json["id"] as int,
      owner: json["owner"] as int,
      name: json["name"] as String,
      category: (json["category"] as String?) ?? "",
      season: (json["season"] as String?) ?? "",
      occasion: (json["occasion"] as String?) ?? "",
      size: (json["size"] as String?) ?? "",
      material: (json["material"] as String?) ?? "",
      brand: (json["brand"] as String?) ?? "",
      image: json["image"] as String?,
      createdAt: DateTime.parse(json["created_at"] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "owner": owner,
      "name": name,
      "category": category,
      "season": season,
      "occasion": occasion,
      "size": size,
      "material": material,
      "brand": brand,
      "image": image,
      "created_at": createdAt.toIso8601String(),
    };
  }
}
