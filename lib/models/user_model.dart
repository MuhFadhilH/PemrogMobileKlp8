class UserModel {
  final String id;
  final String displayName;
  final String email;
  final String photoUrl;
  final String bio;

  UserModel({
    required this.id,
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.bio,
  });

factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      id: uid,
      // LOGIKA BARU:
      // 1. Cek apakah ada displayName & tidak kosong? Pakai itu.
      // 2. Jika tidak, cek apakah ada username? Pakai itu.
      // 3. Jika tidak ada keduanya, baru pakai 'No Name'.
      displayName: (data['displayName'] != null &&
              data['displayName'].toString().isNotEmpty)
          ? data['displayName']
          : (data['username'] ?? 'No Name'),

      email: data['email'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      // Default bio jika kosong
      bio: (data['bio'] != null && data['bio'].toString().isNotEmpty)
          ? data['bio']
          : 'Bibliomate User',
    );
  }
}
