import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  final String uid;
  final String email;
  //will be using firebase display name for now b4 implementing postgres
  final String username; 

  UserModel({required this.uid, required this.email, required this.username});

  // Factory constructor to convert Firebase User to our UserModel
  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      username: user.displayName ?? '',
    );
  }
}
