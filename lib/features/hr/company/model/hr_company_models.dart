class HrCompanyInfo {
  final int id;
  final String erpnextDocName;
  final String name;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HrCompanyInfo({
    required this.id,
    required this.erpnextDocName,
    required this.name,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HrCompanyInfo.fromJson(Map<String, dynamic> json) {
    return HrCompanyInfo(
      id:             json['id']               as int,
      erpnextDocName: json['erpnext_doc_name'] as String,
      name:           json['name']             as String,
      isActive:       json['is_active']        as bool,
      createdAt:      DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt:      DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }
}

class HrGeofenceSite {
  final String wifiSsid;
  final String wifiBssid;
  final int rssiThreshold;
  final bool enforce5ghz;
  final double latitude;
  final double longitude;
  final int radiusMetres;

  const HrGeofenceSite({
    required this.wifiSsid,
    required this.wifiBssid,
    required this.rssiThreshold,
    required this.enforce5ghz,
    required this.latitude,
    required this.longitude,
    required this.radiusMetres,
  });

  factory HrGeofenceSite.fromJson(Map<String, dynamic> json) {
    return HrGeofenceSite(
      wifiSsid:      json['wifi_ssid']      as String,
      wifiBssid:     json['wifi_bssid']     as String,
      rssiThreshold: json['rssi_threshold'] as int,
      enforce5ghz:   json['enforce_5ghz']   as bool,
      latitude:      double.parse(json['latitude']  as String),
      longitude:     double.parse(json['longitude'] as String),
      radiusMetres:  json['radius_metres']  as int,
    );
  }
}

class HrCompanySettings {
  final HrCompanyInfo info;
  final HrGeofenceSite geofence;

  const HrCompanySettings({
    required this.info,
    required this.geofence,
  });
}
