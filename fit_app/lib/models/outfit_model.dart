import 'package:fit_app/models/clothing_item_model.dart';

class OutfitModel {
  final int id;
  final String name;
  final String occasion;
  final bool isPublic;
  final String? ownerUsername;
  final String? ownerFirebaseUid;
  final String? ownerProfilePicture;
  final List<ClothingItemModel> items;
  final bool ownerIsFeatured;
  final Map<String, dynamic>? ownerSocialLinks;
  final String? ownerBio;
  final int savesCount;
  final bool isSaved;
  final DateTime createdAt;

  const OutfitModel({
    required this.id,
    required this.name,
    required this.occasion,
    required this.isPublic,
    this.ownerUsername,
    this.ownerFirebaseUid,
    this.ownerProfilePicture,
    required this.items,
    this.savesCount = 0,
    this.isSaved = false,
    this.ownerIsFeatured = false,
    this.ownerSocialLinks,
    this.ownerBio,
    required this.createdAt,
  });

  factory OutfitModel.fromJson(Map<String, dynamic> json) {
    return OutfitModel(
      id: json["id"] as int,
      name: json["name"] as String,
      occasion: json["occasion"] as String? ?? 'General',
      isPublic: json["is_public"] as bool? ?? false,
      ownerUsername: json["owner_username"] as String?,
      ownerFirebaseUid: json["owner_firebase_uid"] as String?,
      ownerProfilePicture: json["owner_profile_picture"] as String?,
      items: (json["items"] as List<dynamic>?)
              ?.map((item) =>
                  ClothingItemModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      savesCount: json["saves_count"] as int? ?? 0,
      isSaved: json["is_saved"] as bool? ?? false,
      ownerIsFeatured: json["owner_is_featured"] as bool? ?? false,
      ownerSocialLinks: json["owner_social_links"] as Map<String, dynamic>?,
      ownerBio: json["owner_bio"] as String?,
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
      if (ownerFirebaseUid != null) "owner_firebase_uid": ownerFirebaseUid,
      "items": items.map((item) => item.toJson()).toList(),
      if (ownerSocialLinks != null) "owner_social_links": ownerSocialLinks,
      "created_at": createdAt.toIso8601String(),
    };
  }

  OutfitModel copyWith({
    int? id,
    String? name,
    String? occasion,
    bool? isPublic,
    String? ownerUsername,
    String? ownerFirebaseUid,
    String? ownerProfilePicture,
    List<ClothingItemModel>? items,
    int? savesCount,
    bool? isSaved,
    bool? ownerIsFeatured,
    Map<String, dynamic>? ownerSocialLinks,
    String? ownerBio,
    DateTime? createdAt,
  }) {
    return OutfitModel(
      id: id ?? this.id,
      name: name ?? this.name,
      occasion: occasion ?? this.occasion,
      isPublic: isPublic ?? this.isPublic,
      ownerUsername: ownerUsername ?? this.ownerUsername,
      ownerFirebaseUid: ownerFirebaseUid ?? this.ownerFirebaseUid,
      ownerProfilePicture: ownerProfilePicture ?? this.ownerProfilePicture,
      items: items ?? this.items,
      savesCount: savesCount ?? this.savesCount,
      isSaved: isSaved ?? this.isSaved,
      ownerIsFeatured: ownerIsFeatured ?? this.ownerIsFeatured,
      ownerSocialLinks: ownerSocialLinks ?? this.ownerSocialLinks,
      ownerBio: ownerBio ?? this.ownerBio,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

