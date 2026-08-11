class HrDashboardStats {
  final int presentToday;
  final int absentToday;
  final int flaggedPending;
  final int notOnboarded;
  final int totalActiveEmployees;
  final bool isFromCache;

  const HrDashboardStats({
    required this.presentToday,
    required this.absentToday,
    required this.flaggedPending,
    required this.notOnboarded,
    required this.totalActiveEmployees,
    this.isFromCache = false,
  });

  factory HrDashboardStats.fromJson(
    Map<String, dynamic> json, {
    bool isFromCache = false,
  }) {
    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return HrDashboardStats(
      presentToday:          parseInt(json['present_today']),
      absentToday:           parseInt(json['absent_today']),
      flaggedPending:        parseInt(json['flagged_pending']),
      notOnboarded:          parseInt(json['not_onboarded']),
      totalActiveEmployees:  parseInt(json['total_active_employees']),
      isFromCache: isFromCache,
    );
  }
}
