class FlaggedRecord {
  final int id;
  final int employeeId;
  final String employeeName;
  final String erpnextEmployeeId;
  final String flagType;   // INCOMPLETE | MISSING_CHECKOUT | SUSPICIOUS
  final String date;
  final String? notes;
  final bool resolved;

  const FlaggedRecord({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.erpnextEmployeeId,
    required this.flagType,
    required this.date,
    this.notes,
    required this.resolved,
  });

  factory FlaggedRecord.fromJson(Map<String, dynamic> json) {
    return FlaggedRecord(
      id:                 json['id']                   as int,
      employeeId:         json['employee_id']          as int,
      employeeName:       json['employee_name']        as String,
      erpnextEmployeeId:  json['erpnext_employee_id']  as String,
      flagType:           json['flag_reason']          as String? ?? 'UNKNOWN',
      date:               json['timestamp_gps']        as String,
      notes:              json['review_note']          as String?,
      resolved:           (json['is_approved'] == true) || (json['is_rejected'] == true),
    );
  }

  FlaggedRecord copyWith({bool? resolved}) => FlaggedRecord(
        id:                id,
        employeeId:        employeeId,
        employeeName:      employeeName,
        erpnextEmployeeId: erpnextEmployeeId,
        flagType:          flagType,
        date:              date,
        notes:             notes,
        resolved:          resolved ?? this.resolved,
      );

  Map<String, dynamic> toJson() => {
        'id':                   id,
        'employee_id':          employeeId,
        'employee_name':        employeeName,
        'erpnext_employee_id':  erpnextEmployeeId,
        'flag_reason':          flagType,
        'timestamp_gps':        date,
        'review_note':          notes,
        'is_approved':          resolved,
      };
}
