import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:transit_core/transit_core.dart';

import '../firebase_options.dart';

/// Reads a van's live position from the Realtime Database over REST.
///
/// The driver app publishes `liveLocations/{busId}` to the Realtime
/// Database, not Firestore (see `LiveLocation`). The admin app has no
/// `firebase_database` plugin — and must also build for Windows, where that
/// plugin has no implementation — so it reads the node with a plain
/// authenticated GET instead. Any signed-in user may read it
/// (`database.rules.json`), so the admin's own ID token is enough.
class LiveLocationClient {
  LiveLocationClient._();
  static final LiveLocationClient instance = LiveLocationClient._();

  /// From the mobile app's `google-services.json`. `firebase_options.dart`
  /// here was generated without a `databaseURL`, so this is the fallback.
  static const fallbackDatabaseUrl =
      'https://transitpro-db-default-rtdb.asia-southeast1.firebasedatabase.app';

  static String get databaseUrl {
    String? configured;
    try {
      configured = DefaultFirebaseOptions.currentPlatform.databaseURL;
    } catch (_) {
      // A platform with no generated options (Linux) — use the fallback.
    }
    final url = (configured == null || configured.isEmpty)
        ? fallbackDatabaseUrl
        : configured;
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  /// The node at `liveLocations/{key}`, or null when nothing is published
  /// there (the driver isn't sharing). Throws on a network/auth failure so
  /// the caller can say "couldn't reach" rather than "not sharing".
  Future<LiveLocation?> fetch(String key) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || key.isEmpty) return null;
    final token = await user.getIdToken();
    final uri = Uri.parse(
      '$databaseUrl/liveLocations/${Uri.encodeComponent(key)}.json',
    ).replace(queryParameters: {'auth': token ?? ''});
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw LiveLocationException(
        'Realtime Database returned ${res.statusCode}',
      );
    }
    final body = jsonDecode(res.body);
    if (body is! Map) return null;
    final map = Map<String, dynamic>.from(body);
    if (map['lat'] == null || map['lng'] == null) return null;
    return LiveLocation.fromMap(key, map);
  }

  /// Tries each of [keys] in order and returns the first published
  /// position that belongs to [driverId] (a node published by a different
  /// driver on a shared bus is not this driver's location).
  ///
  /// A self-signed-up driver with no admin-assigned bus publishes under
  /// their own uid, so callers pass the trip's bus, the driver's bus and
  /// the driver's uid.
  Future<LiveLocation?> fetchFirst(
    Iterable<String?> keys, {
    required String driverId,
  }) async {
    final seen = <String>{};
    Object? lastError;
    for (final raw in keys) {
      final key = raw?.trim() ?? '';
      if (key.isEmpty || !seen.add(key)) continue;
      try {
        final loc = await fetch(key);
        if (loc == null) continue;
        final owner = loc.driverId ?? '';
        if (owner.isNotEmpty && owner != driverId) continue;
        return loc;
      } catch (e) {
        lastError = e;
      }
    }
    if (lastError != null) throw lastError;
    return null;
  }
}

class LiveLocationException implements Exception {
  final String message;
  const LiveLocationException(this.message);
  @override
  String toString() => message;
}
