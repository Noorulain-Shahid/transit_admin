import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:transit_core/transit_core.dart';

/// A failed account action, with a message safe to show the admin.
class AccountActionException implements Exception {
  final String message;
  const AccountActionException(this.message);

  @override
  String toString() => message;
}

/// The one thing the admin app cannot do with the client SDK: delete
/// someone else's Firebase sign-in. That needs the Admin SDK's credential,
/// which lives only in the Worker (`push_worker`, the same one that sends
/// push notifications), behind:
///
/// ```text
/// POST {pushWorkerUrl}/admin/delete-account
/// Authorization: Bearer <this admin's Firebase ID token>
/// { "uid": "<account to delete>" }
/// ```
///
/// The Worker checks the caller is an admin (`users/{uid}.role`), refuses
/// admin accounts and the caller's own, and treats an already-missing
/// sign-in as success, so a retry after a half-finished delete is safe.
class AccountAdminClient {
  AccountAdminClient._();
  static final AccountAdminClient instance = AccountAdminClient._();

  static const _timeout = Duration(seconds: 30);

  /// Deletes [uid]'s Firebase sign-in. Throws [AccountActionException]
  /// with the reason when it did not happen.
  Future<void> deleteSignIn(String uid) async {
    final base = AppConfig.pushWorkerUrl;
    if (base.isEmpty) {
      throw const AccountActionException(
        'Permanent delete is not set up: no server URL is configured.',
      );
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const AccountActionException('You are signed out. Sign in again.');
    }

    final http.Response response;
    try {
      final token = await user.getIdToken();
      response = await http
          .post(
            Uri.parse('$base/admin/delete-account'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'uid': uid}),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw const AccountActionException(
        'The server took too long to answer. Nothing was deleted — try again.',
      );
    } catch (_) {
      throw const AccountActionException(
        'Could not reach the server. Check the connection — nothing was '
        'deleted.',
      );
    }
    if (response.statusCode == 200) return;
    throw AccountActionException(
      deleteFailureMessage(response.statusCode, response.body),
    );
  }
}

/// The admin-facing reason for a failed `/admin/delete-account` call.
String deleteFailureMessage(int status, String body) {
  var serverText = '';
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map && decoded['error'] is String) {
      serverText = decoded['error'] as String;
    }
  } catch (_) {
    // Not JSON — fall through to the status-based wording.
  }
  final reason = switch (status) {
    401 => 'Your sign-in could not be verified. Sign out and in again.',
    403 =>
      serverText.isNotEmpty
          ? serverText
          : 'This account cannot be deleted by you.',
    // The Worker's own unknown-route answer is "Not found." — an older
    // deployment without this endpoint.
    404 =>
      serverText.isNotEmpty && serverText != 'Not found.'
          ? serverText
          : 'The server does not have this feature yet (deploy the Worker).',
    _ =>
      serverText.isNotEmpty
          ? 'Server error ($status): $serverText'
          : 'Server error ($status).',
  };
  return '$reason Nothing was deleted.';
}
