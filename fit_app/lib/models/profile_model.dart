class ProfileModel {
  final int id;
  final String firebaseUid;
  final String username;
  final String email;
  final String plan;
  final int wardrobeCount;
  final int wardrobeLimit;
  final int outfitsCount;
  final int outfitsLimit;

  final String? profilePicture;
  final String? bio;
  final Map<String, dynamic>? socialLinks;
  final bool isFeatured;
  final bool isAdmin;

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
    required this.wardrobeLimit,
    required this.outfitsCount,
    required this.outfitsLimit,

    this.profilePicture,
    this.bio,
    this.socialLinks,
    this.isFeatured = false,
    this.isAdmin = false,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'],
      firebaseUid: json['firebase_uid'],
      username: json['username'],
      email: json['email'],
      plan: json['plan'],
      wardrobeCount: json['wardrobe_count'],
      wardrobeLimit: json['wardrobe_limit'],
      outfitsCount: json['outfits_count'],
      outfitsLimit: json['outfits_limit'],

      profilePicture: json['profile_picture'],
      bio: json['bio'],
      socialLinks: json['social_links'] as Map<String, dynamic>?,
      isFeatured: json['is_featured'] ?? false,
      isAdmin: json['is_admin'] ?? false,
    );
  }

  ProfileModel copyWith({
    String? username,
    String? profilePicture,
    String? bio,
    Map<String, dynamic>? socialLinks,
    bool? isFeatured,
    bool? isAdmin,
  }) {
    return ProfileModel(
      id: id,
      firebaseUid: firebaseUid,
      username: username ?? this.username,
      email: email,
      plan: plan,
      wardrobeCount: wardrobeCount,
      wardrobeLimit: wardrobeLimit,
      outfitsCount: outfitsCount,
      outfitsLimit: outfitsLimit,

      profilePicture: profilePicture ?? this.profilePicture,
      bio: bio ?? this.bio,
      socialLinks: socialLinks ?? this.socialLinks,
      isFeatured: isFeatured ?? this.isFeatured,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}
