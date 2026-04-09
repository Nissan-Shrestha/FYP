import 'package:fit_app/models/clothing_item_model.dart';
import 'package:fit_app/models/wardrobe_model.dart';
import 'package:fit_app/models/profile_model.dart';

class FeaturedWardrobeModel {
  final int id;
  final int requester;
  final int wardrobe;
  final String status; // 'pending', 'approved', 'rejected'
  final String? adminFeedback;
  final String? wardrobeName;
  final String? requesterUsername;
  final DateTime createdAt;
  final DateTime updatedAt;

  FeaturedWardrobeModel({
    required this.id,
    required this.requester,
    required this.wardrobe,
    required this.status,
    this.adminFeedback,
    this.wardrobeName,
    this.requesterUsername,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FeaturedWardrobeModel.fromJson(Map<String, dynamic> json) {
    return FeaturedWardrobeModel(
      id: json['id'],
      requester: json['requester'],
      wardrobe: json['wardrobe'],
      status: json['status'],
      adminFeedback: json['admin_feedback'],
      wardrobeName: json['wardrobe_name'],
      requesterUsername: json['requester_username'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class CommunityFeaturedWardrobeModel {
  final int requestId;
  final WardrobeModel wardrobe;
  final String? adminFeedback;
  final ProfileModel owner;
  final List<ClothingItemModel>? previewItems;

  // Clean accessors for the UI
  String get title => wardrobe.name;
  String? get coverImage => wardrobe.thumbnail;
  String get ownerUsername => owner.username;
  String? get ownerPicture => owner.profilePicture;

  CommunityFeaturedWardrobeModel({
    required this.requestId,
    required this.wardrobe,
    this.adminFeedback,
    required this.owner,
    this.previewItems,
  });

  factory CommunityFeaturedWardrobeModel.fromJson(Map<String, dynamic> json) {
    // Robustly handle nested JSON objects to avoid subtype errors
    final Map<String, dynamic> wardrobeJson =
        (json['wardrobe'] as Map?)?.cast<String, dynamic>() ?? {};
    final Map<String, dynamic> ownerJson =
        (json['owner'] as Map?)?.cast<String, dynamic>() ?? {};

    return CommunityFeaturedWardrobeModel(
      requestId: json['request_id'] as int? ?? 0,
      wardrobe: WardrobeModel.fromJson(wardrobeJson),
      adminFeedback: json['admin_feedback'] as String?,
      owner: ProfileModel.fromJson(ownerJson),
      previewItems: json['preview_items'] != null
          ? (json['preview_items'] as List)
                .map(
                  (i) => ClothingItemModel.fromJson(
                    (i as Map).cast<String, dynamic>(),
                  ),
                )
                .toList()
          : null,
    );
  }
}
