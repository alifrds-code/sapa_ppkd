import 'training_model.dart';

// Model buat data batch (di dalamnya ada list training)
class BatchModel {
  final int id;
  final String batchKe;
  final List<TrainingModel> trainings;

  BatchModel({
    required this.id,
    required this.batchKe,
    required this.trainings,
  });

  factory BatchModel.fromJson(Map<String, dynamic> json) {
    // Ambil list training dari dalam data batch
    var list = json['trainings'] as List? ?? [];
    var trainingList = list.map((i) => TrainingModel.fromJson(i)).toList();

    return BatchModel(
      id: json['id'],
      batchKe: json['batch_ke'],
      trainings: trainingList,
    );
  }
}
