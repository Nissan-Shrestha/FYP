class ProfileModel {
  final int id;
  final String firebaseUid;
  final String username;
  final String email;
  final String plan;
  final int wardrobeCount;
  final int outfitsCount;

  final String? profilePicture;
  final String? bio;
  final Map<String, dynamic>? socialLinks;
  final bool isFeatured;
  final bool isAdmin;
  final bool isPremium;
  final String? premiumUntil;
  final bool canUseStylist;
  final String? stylistAvailableIn;
  final bool canUseAnalysis;
  final String? analysisAvailableIn;
  final String? fcmToken;

  String? get fullProfilePictureUrl {
    if (profilePicture == null) return null;
    if (profilePicture!.startsWith("http")) {
      // Intelligently replace localhost/127.0.0.1 with our server IP for mobile testing
      return profilePicture!
          .replaceAll("localhost", "192.168.1.67")
          .replaceAll("127.0.0.1", "192.168.1.67");
    }
    return "http://192.168.1.67:8000$profilePicture";
  }

  String get socialHandle {
    if (socialLinks == null) return "";
    if (socialLinks!.containsKey('instagram')) return socialLinks!['instagram'];
    if (socialLinks!.containsKey('tiktok')) return socialLinks!['tiktok'];
    return "";
  }

  ProfileModel({
    required this.id,
    required this.firebaseUid,
    required this.username,
    required this.email,
    required this.plan,
    required this.wardrobeCount,
    required this.outfitsCount,

    this.profilePicture,
    this.bio,
    this.socialLinks,
    this.isFeatured = false,
    this.isAdmin = false,
    this.isPremium = false,
    this.premiumUntil,
    this.canUseStylist = true,
    this.stylistAvailableIn,
    this.canUseAnalysis = true,
    this.analysisAvailableIn,
    this.fcmToken,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'],
      firebaseUid: json['firebase_uid'],
      username: json['username'],
      email: json['email'],
      plan: json['plan'],
      wardrobeCount: json['wardrobe_count_live'] ?? 0,
      outfitsCount: json['outfits_count_live'] ?? 0,

      profilePicture: json['profile_picture'],
      bio: json['bio'],
      socialLinks: json['social_links'] as Map<String, dynamic>?,
      isFeatured: json['is_featured'] ?? false,
      isAdmin: json['is_admin'] ?? false,
      isPremium: json['is_premium'] ?? false,
      premiumUntil: json['premium_until'],
      canUseStylist: json['can_use_stylist'] ?? true,
      stylistAvailableIn: json['stylist_available_in'],
      canUseAnalysis: json['can_use_analysis'] ?? true,
      analysisAvailableIn: json['analysis_available_in'],
      fcmToken: json['fcm_token'],
    );
  }

  ProfileModel copyWith({
    String? username,
    String? profilePicture,
    String? bio,
    Map<String, dynamic>? socialLinks,
    bool? isFeatured,
    bool? isAdmin,
    bool? isPremium,
    String? premiumUntil,
    bool? canUseStylist,
    String? stylistAvailableIn,
  }) {
    return ProfileModel(
      id: id,
      firebaseUid: firebaseUid,
      username: username ?? this.username,
      email: email,
      plan: plan,
      wardrobeCount: wardrobeCount,
      outfitsCount: outfitsCount,

      profilePicture: profilePicture ?? this.profilePicture,
      bio: bio ?? this.bio,
      socialLinks: socialLinks ?? this.socialLinks,
      isFeatured: isFeatured ?? this.isFeatured,
      isAdmin: isAdmin ?? this.isAdmin,
      isPremium: isPremium ?? this.isPremium,
      premiumUntil: premiumUntil ?? this.premiumUntil,
      canUseStylist: canUseStylist ?? this.canUseStylist,
      stylistAvailableIn: stylistAvailableIn ?? this.stylistAvailableIn,
    );
  }
}
