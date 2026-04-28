// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  // ── REPLACE THIS with P1's deployed Cloud Function URL after Apr 19 ────────
  static const String _baseUrl =
      // lib/services/api_service.dart
 'https://us-central1-raktsetu-prod.cloudfunctions.net';

  // ── Find matching blood banks ─────────────────────────────────────────────
  /// Calls P1's find_matches endpoint.
  /// Returns list of matched BloodBank objects with travel times.
  static Future<MatchResult> findMatches({
    required String bloodType,      // display format: "O+"
    required int unitsNeeded,
    required double hospitalLat,
    required double hospitalLng,
    required String hospitalId,
  }) async {
    final url = Uri.parse('$_baseUrl/find_matches');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'bloodType':   bloodType,   // P1 normalises O+ → O_pos internally
          'unitsNeeded': unitsNeeded,
          'hospitalLat': hospitalLat,
          'hospitalLng': hospitalLng,
          'hospitalId':  hospitalId,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return MatchResult.error('Server error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['status'] == 'no_match') {
        return MatchResult.noMatch();
      }

      final matchesJson = data['matches'] as List<dynamic>;
      final banks = matchesJson
          .map((m) => BloodBank.fromMatchJson(m as Map<String, dynamic>))
          .toList();

      return MatchResult.success(
        requestId: data['requestId'] as String,
        banks: banks,
      );
    } on Exception catch (e) {
      return MatchResult.error(e.toString());
    }
  }
}

// ── Result wrapper ────────────────────────────────────────────────────────────
class MatchResult {
  final bool isSuccess;
  final bool isNoMatch;
  final String? error;
  final String? requestId;
  final List<BloodBank> banks;

  const MatchResult._({
    required this.isSuccess,
    required this.isNoMatch,
    this.error,
    this.requestId,
    this.banks = const [],
  });

  factory MatchResult.success({
    required String requestId,
    required List<BloodBank> banks,
  }) => MatchResult._(isSuccess: true, isNoMatch: false,
        requestId: requestId, banks: banks);

  factory MatchResult.noMatch() =>
      const MatchResult._(isSuccess: false, isNoMatch: true);

  factory MatchResult.error(String msg) =>
      MatchResult._(isSuccess: false, isNoMatch: false, error: msg);
}