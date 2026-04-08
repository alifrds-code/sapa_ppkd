class AbsenStatsModel {
  final int totalAbsen;
  final int totalMasuk;
  final int totalIzin;
  final bool sudahAbsenHariIni;

  AbsenStatsModel({
    required this.totalAbsen,
    required this.totalMasuk,
    required this.totalIzin,
    required this.sudahAbsenHariIni,
  });

  factory AbsenStatsModel.fromJson(Map<String, dynamic> json) {
    return AbsenStatsModel(
      totalAbsen: json['total_absen'] ?? 0,
      totalMasuk: json['total_masuk'] ?? 0,
      totalIzin: json['total_izin'] ?? 0,
      sudahAbsenHariIni: json['sudah_absen_hari_ini'] ?? false,
    );
  }
}
