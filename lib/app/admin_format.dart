import 'package:transit_core/transit_core.dart';

/// Pure formatting and status rules shared by the admin screens.
///
/// Kept free of widgets and Firebase calls so every rule here — what counts
/// as "Deactivated", when a heartbeat stops meaning "Online", which account a
/// student's subscription lives on — is unit-tested in one place instead of
/// being re-derived slightly differently on each screen.

// ── Account state ────────────────────────────────────────────────────────────

/// An account an admin archived, one the user deleted themselves (a
/// tombstone: `isDeleted`), or one an admin switched off (`!isActive`).
/// The admin panel shows exactly two states: Active or Deactivated.
bool isAccountDeactivated(AppUser user) => user.isDeleted || !user.isActive;

String accountStatusLabel(AppUser user) =>
    isAccountDeactivated(user) ? 'Deactivated' : 'Active';

/// Why a deactivated account is deactivated, for the detail screen.
///
/// [deletedBy] is the raw `users/{uid}.deletedBy` (the mobile app writes the
/// user's own uid there on a self-delete; an admin archive writes nothing).
/// When it's unavailable the deletion is attributed by whether the account
/// blanked its own contact details, which the self-delete tombstone does and
/// an admin archive does not.
String deactivationReason(AppUser user, {String? deletedBy}) {
  if (user.isDeleted) {
    final selfDeleted = (deletedBy != null && deletedBy.isNotEmpty)
        ? deletedBy == user.uid
        : user.email.isEmpty && user.phone.isEmpty;
    final by = selfDeleted ? 'Deleted by the user' : 'Archived by an admin';
    final at = user.deletedAt;
    return at == null ? by : '$by on ${formatExactTime(at)}';
  }
  if (!user.isActive) return 'Deactivated by an admin';
  return '';
}

// ── Presence ─────────────────────────────────────────────────────────────────

/// Online only while the app's heartbeat is fresh — see
/// [AppUser.isOnlineAt]. A deleted account is never online.
bool isUserOnline(AppUser? user, DateTime now) =>
    user != null && !user.isDeleted && user.isOnlineAt(now);

String presenceLabel(AppUser? user, DateTime now) =>
    isUserOnline(user, now) ? 'Online' : 'Offline';

/// "Online now", or "Offline for 2 h 15 m · Last seen 14 Nov, 9:42 PM",
/// or a plain statement that the account has never reported in.
String lastSeenLabel(AppUser? user, DateTime now) {
  if (user == null) return 'No account on record';
  if (isUserOnline(user, now)) return 'Online now';
  final seen = user.lastSeenAt;
  if (seen == null) return 'No app activity recorded yet';
  final gap = now.difference(seen);
  return 'Offline for ${formatDuration(gap)} · '
      'Last seen ${formatExactTime(seen, now: now)}';
}

/// `45 s`, `12 m`, `2 h 15 m`, `3 d 4 h` — the two largest units, so an
/// elapsed time reads at a glance. Negative spans (clock skew) read as 0 s.
String formatDuration(Duration d) {
  if (d.isNegative) d = Duration.zero;
  final days = d.inDays;
  final hours = d.inHours % 24;
  final minutes = d.inMinutes % 60;
  if (days > 0) return hours > 0 ? '$days d $hours h' : '$days d';
  if (d.inHours > 0) {
    return minutes > 0 ? '${d.inHours} h $minutes m' : '${d.inHours} h';
  }
  if (d.inMinutes > 0) return '${d.inMinutes} m';
  return '${d.inSeconds} s';
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// `9:42 PM`.
String formatClock(DateTime t) {
  final local = t.toLocal();
  final h12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final mm = local.minute.toString().padLeft(2, '0');
  return '$h12:$mm ${local.hour < 12 ? 'AM' : 'PM'}';
}

/// `14 Nov, 9:42 PM`, with the year added when it isn't [now]'s year.
String formatExactTime(DateTime t, {DateTime? now}) {
  final local = t.toLocal();
  final ref = (now ?? DateTime.now()).toLocal();
  final year = local.year == ref.year ? '' : ' ${local.year}';
  return '${local.day} ${_months[local.month - 1]}$year, ${formatClock(local)}';
}

/// `14 Nov 2026`.
String formatDate(DateTime t) {
  final local = t.toLocal();
  return '${local.day} ${_months[local.month - 1]} ${local.year}';
}

/// `2026-11-14` (a trip's `dateKey`) → `14 Nov 2026`; anything unparseable
/// is returned as-is.
String formatDateKey(String dateKey) {
  final parts = dateKey.split('-');
  if (parts.length != 3) return dateKey;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null || m < 1 || m > 12) return dateKey;
  return '$d ${_months[m - 1]} $y';
}

/// `2026-11` → `Nov 2026`.
String formatMonthKey(String monthKey) {
  final parts = monthKey.split('-');
  if (parts.length != 2) return monthKey;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (y == null || m == null || m < 1 || m > 12) return monthKey;
  return '${_months[m - 1]} $y';
}

// ── Money ────────────────────────────────────────────────────────────────────

/// `Rs.2,500` from paisa — same rounding as `Payment.displayAmount`.
String formatRupees(int paisa) {
  final negative = paisa < 0;
  final rupees = (paisa.abs() / 100).round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < rupees.length; i++) {
    if (i > 0 && (rupees.length - i) % 3 == 0) buf.write(',');
    buf.write(rupees[i]);
  }
  return '${negative ? '-' : ''}Rs.$buf';
}

/// Paid totals per month (`YYYY-MM`), newest month first. A payment's own
/// `monthKey` (the month it pays for) wins; `paidAt` is the fallback for
/// rows that lack one.
List<MapEntry<String, int>> paidTotalsByMonth(Iterable<Payment> payments) {
  final totals = <String, int>{};
  for (final p in payments) {
    if (p.status != PaymentStatus.paid) continue;
    final key = p.monthKey.isNotEmpty
        ? p.monthKey
        : (p.paidAt != null ? Payment.monthKeyFor(p.paidAt!) : '');
    if (key.isEmpty) continue;
    totals[key] = (totals[key] ?? 0) + p.amountPaisa;
  }
  final list = totals.entries.toList()..sort((a, b) => b.key.compareTo(a.key));
  return list;
}

// ── Students ─────────────────────────────────────────────────────────────────

/// The account a student's app access is billed to: their own for a
/// self-registered student (`parentId` empty — the student document id *is*
/// their uid), otherwise the parent's.
String primaryAccountIdFor(Student s) {
  final parent = s.parentId.trim();
  return parent.isEmpty ? s.id : parent;
}

bool isSelfRegistered(Student s) => s.parentId.trim().isEmpty;

/// The subscription chip on a student: Active only when the account that
/// pays ([primaryAccountIdFor]) holds a purchased subscription
/// (`subscriptionStatus == 'active'`) and is itself not deactivated.
/// A trial, a lapsed plan, a deleted account or no account at all is
/// Inactive.
bool isStudentSubscriptionActive(AppUser? primaryAccount) =>
    primaryAccount != null &&
    !isAccountDeactivated(primaryAccount) &&
    primaryAccount.isSubscriptionActive;

String studentSubscriptionLabel(AppUser? primaryAccount) =>
    isStudentSubscriptionActive(primaryAccount) ? 'Active' : 'Inactive';

/// The four institute levels a student can be registered at.
const instituteLevels = ['School', 'College', 'University', 'Academy'];

/// A student's level, defaulting an empty value to School (how the mobile
/// app treats a missing `instituteType`).
String studentLevel(Student s) =>
    s.instituteType.trim().isEmpty ? 'School' : s.instituteType.trim();

/// The monthly fee agreed for [s]'s seat: the student document's own
/// `monthlyFeePaisa` (set by the driver on accepting), falling back to the
/// accepted seat request's agreed fee for older rows. Zero means none was
/// agreed.
int agreedFeePaisa(Student s, Iterable<RideRequest> requests) {
  if (s.monthlyFeePaisa > 0) return s.monthlyFeePaisa;
  for (final r in requests) {
    if (r.studentId == s.id && r.isAccepted && r.hasAgreedFee) {
      return r.feePaisa;
    }
  }
  return 0;
}

// ── Places ───────────────────────────────────────────────────────────────────

/// `31.52041, 74.35874`.
String formatCoord(GeoCoord c) =>
    '${c.lat.toStringAsFixed(5)}, ${c.lng.toStringAsFixed(5)}';

/// A Google Maps search link that drops a pin on [c].
Uri googleMapsUri(GeoCoord c) => Uri.parse(
  'https://www.google.com/maps/search/?api=1&query=${c.lat},${c.lng}',
);

// ── Trips ────────────────────────────────────────────────────────────────────

String attendanceStatusLabel(AttendanceStatus s) => switch (s) {
  AttendanceStatus.pending => 'Pending',
  AttendanceStatus.boarded => 'Boarded',
  AttendanceStatus.droppedOff => 'Dropped off',
  AttendanceStatus.absent => 'Absent',
};

String tripStatusLabel(TripStatus s) => switch (s) {
  TripStatus.scheduled => 'Scheduled',
  TripStatus.inProgress => 'In progress',
  TripStatus.completed => 'Completed',
  TripStatus.cancelled => 'Cancelled',
};

String tripTypeLabel(TripType t) => switch (t) {
  TripType.morning => 'Morning',
  TripType.afternoon => 'Afternoon',
};

String missedBusStatusLabel(MissedBusStatus s) => switch (s) {
  MissedBusStatus.searching => 'Searching for a driver',
  MissedBusStatus.viewing => 'Being viewed',
  MissedBusStatus.bidOffered => 'Offer received',
  MissedBusStatus.accepted => 'Accepted',
  MissedBusStatus.declined => 'Declined',
  MissedBusStatus.noDrivers => 'No drivers available',
  MissedBusStatus.cancelled => 'Cancelled',
  MissedBusStatus.completed => 'Completed',
};

/// What the van is doing at [stop] in plain words: "Picking up",
/// "Arriving to pick up", "Dropping off", "Heading to the institute".
String stopActivityLabel(TripStop stop) {
  final arriving = stop.status == TripStopStatus.arriving;
  return switch (stop.kind) {
    TripStopKind.pickup =>
      arriving ? 'Arriving to pick up' : 'Heading to pick up',
    TripStopKind.drop =>
      arriving ? 'Arriving to drop off' : 'Heading to drop off',
    TripStopKind.institute || TripStopKind.destination =>
      arriving ? 'Arriving at the institute' : 'Heading to the institute',
  };
}

// ── Feedback ─────────────────────────────────────────────────────────────────

/// Average of the 1–5 star ratings in [feedback], ignoring out-of-range
/// values; 0 when there are none.
double feedbackAverage(Iterable<AppFeedback> feedback) {
  var sum = 0;
  var n = 0;
  for (final f in feedback) {
    if (f.rating < 1 || f.rating > 5) continue;
    sum += f.rating;
    n++;
  }
  return n == 0 ? 0 : sum / n;
}
