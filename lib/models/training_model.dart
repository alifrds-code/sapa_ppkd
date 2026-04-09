// Model buat data pelatihan
class TrainingModel {
  final int id;
  final String title;

  TrainingModel({required this.id, required this.title});

  factory TrainingModel.fromJson(Map<String, dynamic> json) {
    return TrainingModel(id: json['id'], title: json['title']);
  }
}
