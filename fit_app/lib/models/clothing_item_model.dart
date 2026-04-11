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
  final double? purchasePrice;
  final String? image;
  final String itemType;
  final String color;
  final int layerLevel;
  final String? purchaseLink;
  final int wearCount;
  final DateTime createdAt;
  final bool isLocked;

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
    required this.purchasePrice,
    required this.image,
    required this.itemType,
    required this.color,
    required this.layerLevel,
    this.purchaseLink,
    this.wearCount = 0,
    required this.createdAt,
    this.isLocked = false,
  });

  factory ClothingItemModel.fromJson(Map<String, dynamic> json) {
    return ClothingItemModel(
      id: json["id"] as int,
      owner: json["owner"] as int,
      name: (json["name"] as String?) ?? "",
      itemType: (json["item_type"] as String?) ?? "Top",
      category: (json["category"] as String?) ?? "",
      season: (json["season"] as String?) ?? "",
      occasion: (json["occasion"] as String?) ?? "",
      size: (json["size"] as String?) ?? "",
      material: (json["material"] as String?) ?? "",
      brand: (json["brand"] as String?) ?? "",
      purchasePrice: _parsePurchasePrice(json["purchase_price"]),
      image: json["image"] as String?,
      color: json["color"] as String? ?? "Black",
      layerLevel: json["layer_level"] as int? ?? 0,
      purchaseLink: json["purchase_link"] as String?,
      wearCount: (json["wear_count"] as int?) ?? 0,
      createdAt: DateTime.parse(json["created_at"] as String),
      isLocked: json["is_locked"] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "owner": owner,
      "name": name,
      "item_type": itemType,
      "category": category,
      "season": season,
      "occasion": occasion,
      "size": size,
      "material": material,
      "brand": brand,
      "purchase_price": purchasePrice,
      "image": image,
      "color": color,
      "layer_level": layerLevel,
      "purchase_link": purchaseLink,
      "wear_count": wearCount,
      "created_at": createdAt.toIso8601String(),
      "is_locked": isLocked,
    };
  }

  static double? _parsePurchasePrice(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

