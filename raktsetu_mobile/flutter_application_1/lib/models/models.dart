// ── Blood type helpers ────────────────────────────────────────────────────────
class BloodTypeHelper {
  // Display label → Firestore key
  static const Map<String, String> toKey = {
    'O+': 'O_pos', 'O-': 'O_neg',
    'A+': 'A_pos', 'A-': 'A_neg',
    'B+': 'B_pos', 'B-': 'B_neg',
    'AB+': 'AB_pos', 'AB-': 'AB_neg',
  };
 
  // Firestore key → Display label
  static const Map<String, String> toDisplay = {
    'O_pos': 'O+', 'O_neg': 'O-',
    'A_pos': 'A+', 'A_neg': 'A-',
    'B_pos': 'B+', 'B_neg': 'B-',
    'AB_pos': 'AB+', 'AB_neg': 'AB-',
  };
 
  static const List<String> allDisplay = [
    'O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'
  ];
 
  static String display(String key) => toDisplay[key] ?? key;
  static String key(String display) => toKey[display] ?? display;
}
 
// ── Blood Bank model ──────────────────────────────────────────────────────────
class BloodBank {
  final String id;
  final String name;
  final String address;
  final String phone;
  final double lat;
  final double lng;
  final Map<String, int> inventory; // {O_pos: 12, B_neg: 4}
 
  // Populated by matching engine
  final String? travelTime;   // "14 mins"
  final int? travelSeconds;   // 840
  final String? distance;     // "6.2 km"
 
  const BloodBank({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.lat,
    required this.lng,
    required this.inventory,
    this.travelTime,
    this.travelSeconds,
    this.distance,
  });
 
  // Parse from P1's find_matches response
  factory BloodBank.fromMatchJson(Map<String, dynamic> json) {
    return BloodBank(
      id:            json['id']          as String? ?? '',
      name:          json['name']        as String? ?? 'Unknown',
      address:       json['address']     as String? ?? '',
      phone:         json['phone']       as String? ?? '',
      lat:           (json['lat']        as num?)?.toDouble() ?? 0.0,
      lng:           (json['lng']        as num?)?.toDouble() ?? 0.0,
      inventory:     {},
      travelTime:    json['travelTime']  as String?,
      travelSeconds: json['travelSeconds'] as int?,
      distance:      json['distance']    as String?,
    );
  }
 
  // Parse from Firestore inventory document
  factory BloodBank.fromFirestore(String docId, Map<String, dynamic> data) {
    final bgRaw = data['blood_groups'] as Map<String, dynamic>? ?? {};
    final inventory = <String, int>{};
    bgRaw.forEach((key, val) {
      if (val is Map) {
        inventory[key] = (val['units'] as num?)?.toInt() ?? 0;
      }
    });
 
    final loc = data['location'] as Map<String, dynamic>? ?? {};
    return BloodBank(
      id:        docId,
      name:      data['name']    as String? ?? 'Unknown',
      address:   data['address'] as String? ?? '',
      phone:     data['phone']   as String? ?? '',
      lat:       (loc['lat']     as num?)?.toDouble() ?? 0.0,
      lng:       (loc['lng']     as num?)?.toDouble() ?? 0.0,
      inventory: inventory,
    );
  }
 
  int unitsOf(String bloodTypeKey) => inventory[bloodTypeKey] ?? 0;
}
 
// ── Request Status enum ───────────────────────────────────────────────────────
enum RequestStatus {
  pending,
  confirmed,
  dispatched,
  completed,
  rejected;
 
  static RequestStatus fromString(String? s) {
    switch (s) {
      case 'confirmed':  return confirmed;
      case 'dispatched': return dispatched;
      case 'completed':  return completed;
      case 'rejected':   return rejected;
      default:           return pending;
    }
  }
 
  String get displayLabel {
    switch (this) {
      case pending:    return 'Waiting for confirmation';
      case confirmed:  return 'Blood bank confirmed';
      case dispatched: return 'Blood dispatched';
      case completed:  return 'Delivered';
      case rejected:   return 'Rejected';
    }
  }
 
  String get displayLabelMr {
    switch (this) {
      case pending:    return 'पुष्टीची वाट';
      case confirmed:  return 'रक्तपेढीने पुष्टी केली';
      case dispatched: return 'रक्त पाठवले';
      case completed:  return 'वितरित केले';
      case rejected:   return 'नाकारले';
    }
  }
}
 
// ── Blood Request model ───────────────────────────────────────────────────────
class BloodRequest {
  final String id;
  final String bloodTypeKey;     // "O_pos"
  final String bloodTypeDisplay; // "O+"
  final int unitsNeeded;
  final String hospitalId;
  final double hospitalLat;
  final double hospitalLng;
  final List<String> matchedBanks;
  final RequestStatus status;
  final String? eta;             // "18 mins"
  final String? dispatchedFrom;  // blood bank name
  final DateTime? createdAt;
 
  const BloodRequest({
    required this.id,
    required this.bloodTypeKey,
    required this.bloodTypeDisplay,
    required this.unitsNeeded,
    required this.hospitalId,
    required this.hospitalLat,
    required this.hospitalLng,
    required this.matchedBanks,
    required this.status,
    this.eta,
    this.dispatchedFrom,
    this.createdAt,
  });
 
  factory BloodRequest.fromFirestore(String docId, Map<String, dynamic> data) {
    return BloodRequest(
      id:               docId,
      bloodTypeKey:     data['bloodType']    as String? ?? 'O_pos',
      bloodTypeDisplay: data['bloodTypeRaw'] as String? ?? 'O+',
      unitsNeeded:      (data['unitsNeeded'] as num?)?.toInt() ?? 1,
      hospitalId:       data['hospitalId']   as String? ?? '',
      hospitalLat:      (data['hospitalLat'] as num?)?.toDouble() ?? 0.0,
      hospitalLng:      (data['hospitalLng'] as num?)?.toDouble() ?? 0.0,
      matchedBanks:     List<String>.from(data['matchedBanks'] ?? []),
      status:           RequestStatus.fromString(data['status'] as String?),
      eta:              data['eta']             as String?,
      dispatchedFrom:   data['dispatchedFrom']  as String?,
      createdAt:        (data['createdAt'] as dynamic)?.toDate(),
    );
  }
}