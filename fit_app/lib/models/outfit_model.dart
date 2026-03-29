import 'package:fit_app/models/clothing_item_model.dart';

class OutfitModel {
  final int id;
  final String name;
  final String occasion;
  final bool isPublic;
  final String? ownerUsername;
  final String? ownerProfilePicture;
  final List<ClothingItemModel> items;
  final int savesCount;
  final bool isSaved;
  final DateTime createdAt;

  const OutfitModel({
    required this.id,
    required this.name,
    required this.occasion,
    required this.isPublic,
    this.ownerUsername,
    this.ownerProfilePicture,
    required this.items,
    this.savesCount = 0,
    this.isSaved = false,
    required this.createdAt,
  });

  factory OutfitModel.fromJson(Map<String, dynamic> json) {
    return OutfitModel(
      id: json["id"] as int,
      name: json["name"] as String,
      occasion: json["occasion"] as String? ?? 'General',
      isPublic: json["is_public"] as bool? ?? false,
      ownerUsername: json["owner_username"] as String?,
      ownerProfilePicture: json["owner_profile_picture"] as String?,
      items: (json["items"] as List<dynamic>?)
              ?.map((item) =>
                  ClothingItemModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      savesCount: json["saves_count"] as int? ?? 0,
      isSaved: json["is_saved"] as bool? ?? false,
      createdAt: DateTime.parse(json["created_at"] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "occasion": occasion,
      "is_public": isPublic,
      if (ownerUsername != null) "owner_username": ownerUsername,
      "items": items.map((item) => item.toJson()).toList(),
      "created_at": createdAt.toIso8601String(),
    };
  }

  OutfitModel copyWith({
    int? id,
    String? name,
    String? occasion,
    bool? isPublic,
    String? ownerUsername,
    String? ownerProfilePicture,
    List<ClothingItemModel>? items,
    int? savesCount,
    bool? isSaved,
    DateTime? createdAt,
  }) {
    return OutfitModel(
      id: id ?? this.id,
      name: name ?? this.name,
      occasion: occasion ?? this.occasion,
      isPublic: isPublic ?? this.isPublic,
      ownerUsername: ownerUsername ?? this.ownerUsername,
      ownerProfilePicture: ownerProfilePicture ?? this.ownerProfilePicture,
      items: items ?? this.items,
      savesCount: savesCount ?? this.savesCount,
      isSaved: isSaved ?? this.isSaved,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
