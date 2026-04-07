import 'training_model.dart';

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
    // Ini buat nangkep list training yang ada di dalam batch
    var list = json['trainings'] as List? ?? [];
    List<TrainingModel> trainingList = list
        .map((i) => TrainingModel.fromJson(i))
        .toList();

    return BatchModel(
      id: json['id'],
      batchKe: json['batch_ke'],
      trainings: trainingList,
    );
  }
}
