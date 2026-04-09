// Model buat nampung data profil user dari API
class ProfileModel {
  final int id;
  final String name;
  final String email;
  final String? batchKe;
  final String? trainingTitle;
  final String? jenisKelamin;
  final String? profilePhotoUrl;

  ProfileModel({
    required this.id,
    required this.name,
    required this.email,
    this.batchKe,
    this.trainingTitle,
    this.jenisKelamin,
    this.profilePhotoUrl,
  });

  // Ubah data JSON dari API jadi object ProfileModel
  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Tanpa Nama',
      email: json['email'] ?? '',
      batchKe: json['batch_ke'],
      trainingTitle: json['training_title'],
      jenisKelamin: json['jenis_kelamin'],
      profilePhotoUrl: json['profile_photo_url'],
    );
  }
}
