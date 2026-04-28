// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  // ── Inventory ─────────────────────────────────────────────────────────────

  /// Stream of all blood banks — used by blood bank home screen
  static Stream<List<BloodBank>> inventoryStream() {
    return _db.collection('inventory').snapshots().map((snap) =>
      snap.docs.map((d) => BloodBank.fromFirestore(d.id, d.data())).toList()
    );
  }

  /// Single blood bank document stream — for blood bank's own screen
  static Stream<BloodBank?> bankStream(String bankId) {
    return _db.collection('inventory').doc(bankId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return BloodBank.fromFirestore(snap.id, snap.data()!);
    });
  }

  /// Update a blood bank's inventory units for a specific blood type
  /// bloodTypeKey = "O_pos", units = 12
  static Future<void> updateInventoryUnit(
    String bankId,
    String bloodTypeKey,
    int units,
  ) async {
    await _db.collection('inventory').doc(bankId).update({
      'blood_groups.$bloodTypeKey.units': units,
      'blood_groups.$bloodTypeKey.last_updated': FieldValue.serverTimestamp(),
    });
  }

  // ── Requests ─────────────────────────────────────────────────────────────

  /// Stream of a single request — used for real-time status tracking
  static Stream<BloodRequest?> requestStream(String requestId) {
    return _db.collection('requests').doc(requestId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return BloodRequest.fromFirestore(snap.id, snap.data()!);
    });
  }

  /// Stream of pending requests for a blood bank — used by blood bank home
  static Stream<List<BloodRequest>> pendingRequestsForBank(String bankId) {
    return _db
        .collection('requests')
        .where('matchedBanks', arrayContains: bankId)
        .where('status', whereIn: ['pending', 'confirmed'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => BloodRequest.fromFirestore(d.id, d.data()))
            .toList());
  }

  /// Blood bank confirms a request — updates status to confirmed
  static Future<void> confirmRequest(
    String requestId,
    String bankId,
    String bankName,
    String eta,
  ) async {
    await _db.collection('requests').doc(requestId).update({
      'status':         'confirmed',
      'confirmedBankId': bankId,
      'dispatchedFrom': bankName,
      'eta':            eta,
      'confirmedAt':    FieldValue.serverTimestamp(),
    });
  }

  /// Blood bank marks as dispatched
  static Future<void> markDispatched(String requestId) async {
    await _db.collection('requests').doc(requestId).update({
      'status':      'dispatched',
      'dispatchedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Blood bank rejects a request
  static Future<void> rejectRequest(String requestId) async {
    await _db.collection('requests').doc(requestId).update({
      'status':    'rejected',
      'rejectedAt': FieldValue.serverTimestamp(),
    });
  }
}