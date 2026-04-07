class AbsenTodayModel {
  final String? attendanceDate;
  final String? checkInTime;
  final String? checkOutTime;
  final String? checkInAddress;
  final String? checkOutAddress;
  final String? status;

  AbsenTodayModel({
    this.attendanceDate,
    this.checkInTime,
    this.checkOutTime,
    this.checkInAddress,
    this.checkOutAddress,
    this.status,
  });

  factory AbsenTodayModel.fromJson(Map<String, dynamic> json) {
    return AbsenTodayModel(
      attendanceDate: json['attendance_date'],
      checkInTime: json['check_in_time'],
      checkOutTime: json['check_out_time'],
      checkInAddress: json['check_in_address'],
      checkOutAddress: json['check_out_address'],
      status: json['status'],
    );
  }
}
