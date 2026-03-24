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

  final String currency;
  final String? profilePicture;

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

    required this.currency,
    this.profilePicture,
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

      currency: json['currency'],
      profilePicture: json['profile_picture'],
    );
  }

  ProfileModel copyWith({String? username, String? profilePicture}) {
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

      currency: currency,
      profilePicture: profilePicture ?? this.profilePicture,
    );
  }
}
