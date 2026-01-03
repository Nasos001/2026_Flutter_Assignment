// Imports --------------------------------------------------------------------------------
import 'package:cloud_firestore/cloud_firestore.dart';

// Define UserModel
class UserModel {
  final String uid;
  final String name;
  final String surname;
  final String? phone;
  final DateTime birthday;
  final String email;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.surname,
    required this.phone,
    required this.birthday,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    // Safe Date Conversion
    DateTime parsedBirthday = (data['birthday'] as Timestamp).toDate();

    return UserModel(
      uid: uid,
      name: data['name']?.toString() ?? '',
      surname: data['surname']?.toString() ?? '',
      phone: data['phone']?.toString(),
      email: data['email']?.toString() ?? '',
      birthday: parsedBirthday,
    );
  }
}
