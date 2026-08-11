import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Derived (client-side) risk classification for late-arrival entries.
/// NOT a backend field — LateArrivalEntry has no risk concept server-side.
/// Thresholds are a product/UX decision, not sourced from any spec:
///   CRITICAL >= 20 min avg late
///   ELEVATED >= 10 and < 20 min avg late
///   LOW      <  10 min avg late
enum AnalyticsRiskLevel { critical, elevated, low }

AnalyticsRiskLevel riskLevelFor(double avgMinutesLate) {
  if (avgMinutesLate >= 20) return AnalyticsRiskLevel.critical;
  if (avgMinutesLate >= 10) return AnalyticsRiskLevel.elevated;
  return AnalyticsRiskLevel.low;
}

extension AnalyticsRiskLevelX on AnalyticsRiskLevel {
  String get label => switch (this) {
        AnalyticsRiskLevel.critical => 'CRITICAL',
        AnalyticsRiskLevel.elevated => 'ELEVATED',
        AnalyticsRiskLevel.low => 'LOW',
      };

  Color get color => switch (this) {
        AnalyticsRiskLevel.critical => AppColors.securityError,
        AnalyticsRiskLevel.elevated => AppColors.securityWarning,
        AnalyticsRiskLevel.low => AppColors.securitySuccess,
      };
}
