import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transit_core/transit_core.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/admin_format.dart';
import '../../app/locale_provider.dart';
import '../../data/admin_repository.dart';
import '../../data/live_location_client.dart';
import '../../services/audit_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ai_check_view.dart';
import '../../widgets/account_controls.dart';
import '../../widgets/entity_widgets.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/mini_chart.dart';
import 'admin_driver_management.dart' show driverStatusColor, driverStatusLabel;
import 'admin_history_tabs.dart';
import 'admin_links.dart';
import '../../widgets/responsive.dart';

// Only Driving License / Vehicle Registration were in the requested term
// list — the other four document types stay hardcoded English.
String documentTypeLabel(DocumentType type) => switch (type) {
  DocumentType.drivingLicense => AppStrings.t('driving_license_doc'),
  DocumentType.vehicleRegistration => AppStrings.t('vehicle_registration_doc'),
  DocumentType.insuranceCertificate => 'Insurance Certificate',
  DocumentType.routePermit => 'Route Permit',
  DocumentType.medicalFitness => 'Medical Fitness',
  DocumentType.schoolContract => 'School Contract',
  DocumentType.cnic => 'CNIC / National ID',
};

// Only 'Verified' was requested — the other three document statuses stay
// hardcoded English.
String documentStatusLabel(DocumentStatus status) => switch (status) {
  DocumentStatus.notUploaded => 'Not uploaded',
  DocumentStatus.pending => 'Pending review',
  DocumentStatus.verified => AppStrings.t('verified_status'),
  DocumentStatus.rejected => 'Rejected',
};

/// English names for the audit log, which is stored in one language.
String _plainDocType(DocumentType type) => switch (type) {
  DocumentType.drivingLicense => 'Driving License',
  DocumentType.vehicleRegistration => 'Vehicle Registration',
  DocumentType.insuranceCertificate => 'Insurance Certificate',
  DocumentType.routePermit => 'Route Permit',
  DocumentType.medicalFitness => 'Medical Fitness',
  DocumentType.schoolContract => 'School Contract',
  DocumentType.cnic => 'CNIC / National ID',
};

String _plainDocStatus(DocumentStatus status) => switch (status) {
  DocumentStatus.notUploaded => 'Not uploaded',
  DocumentStatus.pending => 'Pending review',
  DocumentStatus.verified => 'Verified',
  DocumentStatus.rejected => 'Rejected',
};

Color documentStatusColor(DocumentStatus status) => switch (status) {
  DocumentStatus.notUploaded => const Color(0xFF94A3B8),
  DocumentStatus.pending => const Color(0xFFF59E0B),
  DocumentStatus.verified => const Color(0xFF10B981),
  DocumentStatus.rejected => const Color(0xFFEF4444),
};

Color _severityColor(IncidentSeverity s) => switch (s) {
  IncidentSeverity.low => AppTheme.info,
  IncidentSeverity.medium => AppTheme.warning,
  IncidentSeverity.high => AppTheme.error,
  IncidentSeverity.critical => AppTheme.error,
};

String _severityLabel(IncidentSeverity s) => switch (s) {
  IncidentSeverity.low => 'Low',
  IncidentSeverity.medium => 'Medium',
  IncidentSeverity.high => 'High',
  IncidentSeverity.critical => 'Critical',
};

const _weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class AdminDriverDetail extends StatefulWidget {
  final String driverId;
  const AdminDriverDetail({super.key, required this.driverId});
  @override
  State<AdminDriverDetail> createState() => _AdminDriverDetailState();
}

class _AdminDriverDetailState extends State<AdminDriverDetail> {
  final _repo = AdminRepository.instance;
  // Every stream is created once in `initState` (not inline in `build()`,
  // which would attach a new Firestore listener on every rebuild).
  late final Stream<Driver?> _driverStream;
  late final Stream<List<DriverDocument>> _documentsStream;

  /// `users/{uid}` — the driver's presence and account state. `Driver.status`
  /// is written once at onboarding and the rule that would let the app flip
  /// it isn't deployed, so it said "Offline" about everyone.
  late final Stream<AccountRecord?> _userStream;

  /// The same document for the account controls — its own stream, see the
  /// broadcast note below.
  late final Stream<AccountRecord?> _accountStream;

  /// Ratings, summarised here — `Driver.rating` is never maintained.
  late final Stream<List<DriverRating>> _ratingsStream;

  /// `students where driverId == uid` — the driver's booked roster.
  late final Stream<List<Student>> _rosterStream;
  late final Stream<List<RideRequest>> _requestsStream;
  late final Stream<Trip?> _activeTripStream;
  // Firestore's `snapshots()` is a *broadcast* stream: a second listener
  // attached to the same stream object while the first is still listening
  // never receives the initial snapshot (the same late-subscriber trap
  // that left Parent Detail spinning). So every widget below that listens
  // gets its own stream, even when two of them run the same query — the
  // SDK shares the underlying watch, so this costs no extra reads.
  late final Stream<List<Trip>> _tripsStream;
  late final Stream<List<Trip>> _tripsForAttendanceStream;
  late final Stream<List<Incident>> _incidentsStream;
  late final Stream<List<Incident>> _incidentsForAlertsStream;
  late final Stream<List<DriverDocument>> _documentsForAlertsStream;
  late final Stream<List<Payment>> _paymentsStream;

  // Keep the live-status poller and the open history tab alive when the
  // window is resized across the one/two-column breakpoint.
  final _liveKey = GlobalKey();
  final _historyKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final id = widget.driverId;
    _driverStream = id.isEmpty ? Stream.value(null) : _repo.watchDriver(id);
    _documentsStream = _repo.watchDriverDocuments(id);
    _userStream = _repo.watchUserRecord(id);
    _accountStream = _repo.watchUserRecord(id);
    _ratingsStream = _repo.watchRatingsForDriver(id);
    _rosterStream = _repo.watchStudentsOfDriver(id);
    _requestsStream = _repo.watchRideRequestsForDriver(id);
    _activeTripStream = _repo.watchActiveTripForDriver(id);
    _tripsStream = _repo.watchTripsForDriver(id);
    _tripsForAttendanceStream = _repo.watchTripsForDriver(id);
    _incidentsStream = _repo.watchIncidentsForDriver(id);
    _incidentsForAlertsStream = _repo.watchIncidentsForDriver(id);
    _documentsForAlertsStream = _repo.watchDriverDocuments(id);
    _paymentsStream = _repo.watchPaymentsForDriver(id);
    LocaleProvider.instance.addListener(_onLangChanged);
  }

  void _onLangChanged() => setState(() {});

  @override
  void dispose() {
    LocaleProvider.instance.removeListener(_onLangChanged);
    super.dispose();
  }

  /// "Approved" for an approved driver, otherwise the status label.
  String _driverStatusText(Driver d) =>
      d.isApproved ? 'Approved' : _plainStatus(d.status);

  static String _plainStatus(DriverStatus s) => switch (s) {
    DriverStatus.online => 'Online',
    DriverStatus.offline => 'Offline',
    DriverStatus.onTrip => 'On Trip',
    DriverStatus.suspended => 'Suspended',
    DriverStatus.pendingVerification => 'Pending verification',
  };

  Future<void> _approve(Driver d) async {
    final before = _driverStatusText(d);
    await _repo.updateDriverStatus(d.id, DriverStatus.offline);
    await _audit(
      AuditActionType.statusChange,
      d.id,
      'Approved driver ${d.name}',
      action: AuditActions.driverApprove,
      targetType: 'driver',
      targetName: d.name,
      targetRole: 'Driver',
      changes: [AuditChange('Driver status', before, 'Approved')],
    );
    if (mounted) _msg('Driver approved');
  }

  Future<void> _suspend(Driver d) async {
    final ok = await showAccountConfirmDialog(
      context,
      title: 'Suspend ${d.name}?',
      lines: const [
        'Their driver status becomes Suspended until you approve them '
            'again. The sign-in itself is not changed — use Deactivate for '
            'that.',
      ],
      confirmLabel: AppStrings.t('suspend_action'),
      color: AppTheme.error,
    );
    if (!ok) return;
    final before = _driverStatusText(d);
    await _repo.updateDriverStatus(d.id, DriverStatus.suspended);
    await _audit(
      AuditActionType.statusChange,
      d.id,
      'Suspended driver ${d.name}',
      action: AuditActions.driverSuspend,
      targetType: 'driver',
      targetName: d.name,
      targetRole: 'Driver',
      changes: [AuditChange('Driver status', before, 'Suspended')],
    );
    if (mounted) _msg('Driver suspended');
  }

  Future<void> _audit(
    AuditActionType type,
    String targetId,
    String description, {
    String action = '',
    String targetType = '',
    String targetName = '',
    String targetRole = '',
    List<AuditChange> changes = const [],
    List<AuditDetail> details = const [],
  }) {
    return AuditService.instance.logAction(
      actionType: type,
      targetEntityId: targetId,
      description: description,
      action: action,
      targetType: targetType,
      targetName: targetName,
      targetRole: targetRole,
      changes: changes,
      details: details,
    );
  }

  Future<void> _message(Driver d) async {
    final result = await _showMessageDialog(
      title: 'Message ${d.name}',
      hint:
          'e.g. Your vehicle registration photo is unclear, please re-upload.',
    );
    if (result == null || result.isEmpty) return;
    await _repo.messageUser(d.id, title: 'Message from admin', body: result);
    if (mounted) _msg('Message sent to ${d.name}');
  }

  Future<void> _verifyDocument(DriverDocument doc, Driver d) async {
    final before = _plainDocStatus(doc.status);
    await _repo.updateDriverDocument(doc.id, status: DocumentStatus.verified);
    await _audit(
      AuditActionType.statusChange,
      doc.id,
      '${_plainDocType(doc.type)} verified',
      action: AuditActions.documentVerify,
      targetType: 'document',
      targetName: '${_plainDocType(doc.type)} of ${d.name}',
      targetRole: 'Driver document',
      changes: [AuditChange('Document status', before, 'Verified')],
      details: [
        AuditDetail('Driver', '${d.name} (ID ${d.id})'),
        AuditDetail('Document', _plainDocType(doc.type)),
      ],
    );
    if (mounted) _msg('${documentTypeLabel(doc.type)} verified');
  }

  Future<void> _rejectDocument(DriverDocument doc, Driver d) async {
    final reason = await _showMessageDialog(
      title: 'Reject ${documentTypeLabel(doc.type)}',
      hint:
          'Reason the driver will see, e.g. "Photo is blurry, please re-upload."',
    );
    if (reason == null || reason.isEmpty) return;
    await _repo.updateDriverDocument(
      doc.id,
      status: DocumentStatus.rejected,
      rejectionReason: reason,
    );
    await _repo.messageUser(
      d.id,
      title: '${documentTypeLabel(doc.type)} rejected',
      body: reason,
    );
    await _audit(
      AuditActionType.statusChange,
      doc.id,
      '${_plainDocType(doc.type)} rejected',
      action: AuditActions.documentReject,
      targetType: 'document',
      targetName: '${_plainDocType(doc.type)} of ${d.name}',
      targetRole: 'Driver document',
      changes: [
        AuditChange('Document status', _plainDocStatus(doc.status), 'Rejected'),
      ],
      details: [
        AuditDetail('Driver', '${d.name} (ID ${d.id})'),
        AuditDetail('Document', _plainDocType(doc.type)),
        AuditDetail('Reason', reason),
        const AuditDetail('Driver notified', 'Yes, in the app inbox'),
      ],
    );
    if (mounted) {
      _msg('${documentTypeLabel(doc.type)} rejected and driver notified');
    }
  }

  Future<String?> _showMessageDialog({
    required String title,
    required String hint,
  }) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: InputDecoration(hintText: hint),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _msg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: context.scaffoldBg,
        child: SafeArea(
          child: StreamBuilder<Driver?>(
            stream: _driverStream,
            builder: (context, snap) {
              final d = snap.data;
              final Widget body;
              if (snap.hasError) {
                body = Center(
                  child: LoadErrorView(error: snap.error, what: 'this driver'),
                );
              } else if (snap.connectionState == ConnectionState.waiting &&
                  !snap.hasData) {
                body = const Center(child: CircularProgressIndicator());
              } else if (d == null) {
                body = Center(
                  child: Text(
                    'Driver not found.',
                    style: TextStyle(color: context.textSecondary),
                  ),
                );
              } else {
                body = _buildBody(context, d);
              }
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        Clickable(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: context.cardBgElevated,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.inputBorder),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.arrow_back_rounded,
                                color: context.textPrimary,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            AppStrings.t('driver_detail_title'),
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(child: body),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, Driver d) {
    return StreamBuilder<List<DriverRating>>(
      stream: _ratingsStream,
      builder: (context, ratingSnap) {
        final rating = DriverRatingSummary.of(ratingSnap.data ?? const []);
        return StreamBuilder<List<Student>>(
          stream: _rosterStream,
          builder: (context, rosterSnap) => StreamBuilder<List<RideRequest>>(
            stream: _requestsStream,
            builder: (context, requestSnap) {
              final roster = rosterSnap.data ?? const <Student>[];
              // One column on a phone; on a wide window the profile and
              // records sit left, live status, alerts, roster and history
              // right.
              return SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 40),
                child: ResponsiveBody(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TwoPane(
                      primary: [
                        _buildProfileCard(context, d, rating),
                        _buildDetailsCard(context, d),
                        _buildInstitutesCard(context, d),
                        _buildRoundsCard(context, d, roster),
                        _buildPerformance(context, d, rating),
                        _buildControls(context, d),
                        _buildDocuments(context, d),
                      ],
                      secondary: [
                        _LiveStatusCard(
                          // Keyed so crossing the two-column breakpoint
                          // moves the card instead of restarting its polling.
                          key: _liveKey,
                          driver: d,
                          roster: roster,
                          activeTrip: _activeTripStream,
                        ),
                        _buildAlerts(context),
                        _buildRosterCard(
                          context,
                          d,
                          rosterSnap,
                          requestSnap.data ?? const [],
                        ),
                        HistoryTabs(
                          key: _historyKey,
                          color: AppTheme.driverCyan,
                          tabs: [
                            (
                              AppStrings.t('trip_history_tab'),
                              _TripHistoryTab(trips: _tripsStream, driver: d),
                            ),
                            (
                              AppStrings.t('attendance_tab'),
                              _TripAttendanceTab(
                                trips: _tripsForAttendanceStream,
                              ),
                            ),
                            (
                              AppStrings.t('sos_history_tab'),
                              _SosTab(incidents: _incidentsStream),
                            ),
                            (
                              AppStrings.t('earnings_tab'),
                              _EarningsTab(payments: _paymentsStream),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    Driver d,
    DriverRatingSummary rating,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: StreamBuilder<AccountRecord?>(
        stream: _userStream,
        builder: (context, userSnap) {
          final record = userSnap.data?.withProfileArchived(d.isDeleted);
          final user = record?.user;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The driver's own photo, in the gold "Top rated" frame
                  // when their ratings earn it.
                  EntityAvatar(
                    photoUrl: d.photoUrl,
                    color: AppTheme.driverCyan,
                    fallbackEmoji: '🚐',
                    size: 60,
                    topRated: rating.isTopRated,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.name,
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Names, not ids. This printed the raw Firestore
                        // document id, so the card read "Bus
                        // oHmKQrX4Cx8N60RqMYi2" — a string nobody can
                        // match against a vehicle in a yard.
                        _VehicleLine(driver: d),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RatingStars(value: rating.average, size: 15),
                            const SizedBox(width: 6),
                            Text(
                              rating.label,
                              style: TextStyle(
                                color: context.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            // Presence from the driver's `users` heartbeat,
                            // the same source as every other role.
                            if (record != null)
                              AccountStatusBadge(state: record.state),
                            PresenceBadge(user: user),
                            StatusBadge(
                              label: d.isApproved
                                  ? AppStrings.t('approved_status')
                                  : driverStatusLabel(d.status),
                              color: d.isApproved
                                  ? AppTheme.success
                                  : driverStatusColor(d.status),
                            ),
                            if (rating.isTopRated) const TopRatedBadge(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LastSeenLine(user: user, fontSize: 12),
              if (record != null && record.state != AccountState.active) ...[
                const SizedBox(height: 8),
                AccountStateNote(record: record),
              ],
            ],
          );
        },
      ),
    );
  }

  /// Open SOS / safety incidents and compliance documents that have
  /// expired or are about to.
  Widget _buildAlerts(BuildContext context) {
    return StreamBuilder<List<Incident>>(
      stream: _incidentsForAlertsStream,
      builder: (context, incSnap) => StreamBuilder<List<DriverDocument>>(
        stream: _documentsForAlertsStream,
        builder: (context, docSnap) {
          final open = (incSnap.data ?? const <Incident>[])
              .where((i) => !i.isResolved)
              .toList();
          final docs = _latestPerType(docSnap.data ?? const []);
          final expiring = docs
              .where((doc) => doc.isExpired || doc.expiresSoon)
              .toList();
          final count = open.length + expiring.length;
          return SectionCard(
            title: 'Active alerts',
            icon: Icons.warning_amber_rounded,
            color: AppTheme.error,
            trailing: StatusBadge(
              label: count == 0 ? AppStrings.t('all_clear') : '$count active',
              color: count == 0 ? AppTheme.success : AppTheme.error,
            ),
            child: incSnap.hasError
                ? LoadErrorView(error: incSnap.error, what: 'alerts')
                : !incSnap.hasData
                ? const SectionLoading()
                : count == 0
                ? Text(
                    'No open SOS alerts and no expiring documents.',
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 12,
                    ),
                  )
                : Column(
                    children: [
                      for (final i in open)
                        HistoryRow(
                          color: _severityColor(i.severity),
                          title: i.title.isEmpty
                              ? (i.isAutomatic ? 'Safety alert' : 'SOS')
                              : i.title,
                          subtitle: [
                            if (i.createdAt != null)
                              formatExactTime(i.createdAt!),
                            if (i.description.isNotEmpty) i.description,
                            'Unresolved',
                          ].join(' · '),
                          trailing: _severityLabel(i.severity),
                          onTap: i.lat == null || i.lng == null
                              ? null
                              : () =>
                                    openInGoogleMaps(GeoCoord(i.lat!, i.lng!)),
                        ),
                      for (final doc in expiring)
                        HistoryRow(
                          color: doc.isExpired
                              ? AppTheme.error
                              : AppTheme.warning,
                          title:
                              '${documentTypeLabel(doc.type)} '
                              '${doc.isExpired ? 'expired' : 'expires soon'}',
                          subtitle: doc.expiryDate == null
                              ? null
                              : 'Expiry ${formatDate(doc.expiryDate!)}',
                        ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context, Driver d) {
    return SectionCard(
      title: AppStrings.t('details_title'),
      icon: Icons.badge_rounded,
      color: AppTheme.driverCyan,
      child: Column(
        children: [
          InfoLine(
            icon: Icons.badge_rounded,
            label: AppStrings.t('license_lbl'),
            value: [
              d.licenseNumber.isEmpty ? '—' : d.licenseNumber,
              if (d.licenseExpiry != null)
                '(expires ${formatDate(d.licenseExpiry!)})',
            ].join(' '),
            color: AppTheme.info,
          ),
          InfoLine(
            icon: Icons.phone_rounded,
            label: AppStrings.t('contact_lbl'),
            value: d.phone.isEmpty ? '—' : d.phone,
            color: AppTheme.adminEmerald,
          ),
          InfoLine(
            icon: Icons.email_rounded,
            label: AppStrings.t('email_lbl'),
            value: d.email.isEmpty ? '—' : d.email,
            color: AppTheme.driverCyan,
          ),
          InfoLine(
            icon: Icons.work_history_rounded,
            label: AppStrings.t('experience_lbl'),
            // Was `'${d.experienceYears} yrs'` — a plain all-Latin
            // string with no strong-direction character, sitting
            // inside this screen's RTL `Directionality` once Urdu is
            // active. With no RTL anchor, the bidi algorithm falls
            // back to the paragraph's own (RTL) base direction and
            // visually reverses the whole neutral run — "1 yrs"
            // showing as "yrs 1". Translating the unit itself fixes
            // it: "1 سال" has a real RTL character (سال), so the
            // digit anchors correctly in front of it instead of the
            // whole fragment flipping.
            value: AppStrings.t(
              'experience_years_value',
            ).replaceFirst('{count}', '${d.experienceYears}'),
            color: AppTheme.warning,
          ),
          InfoLine(
            icon: Icons.airline_seat_recline_normal_rounded,
            label: 'Vehicle seats',
            value: d.vehicleSeats > 0 ? '${d.vehicleSeats}' : 'Not set',
            color: AppTheme.purple,
          ),
          InfoLine(
            icon: Icons.local_taxi_rounded,
            label: 'Missed-bus fare',
            value: d.missedBusFarePaisa > 0
                ? formatRupees(d.missedBusFarePaisa)
                : 'Not set',
            color: AppTheme.adminEmerald,
          ),
          if (d.baseLocation != null)
            LocationBlock(
              title: 'Base location (start of day)',
              coord: d.baseLocation,
              icon: Icons.home_work_rounded,
              color: AppTheme.driverCyan,
            ),
        ],
      ),
    );
  }

  /// Institutes the driver serves: their service areas, plus any institute
  /// named only on a round.
  Widget _buildInstitutesCard(BuildContext context, Driver d) {
    final areas = d.serviceAreas.where((a) => a.name.isNotEmpty).toList();
    final known = {for (final a in areas) a.normalizedName};
    final roundOnly = <String>{
      for (final r in d.schedules)
        for (final i in r.institutes)
          if (i.trim().isNotEmpty && !known.contains(ServiceArea.normalize(i)))
            i.trim(),
    };
    return SectionCard(
      title: 'Institutes served',
      icon: Icons.account_balance_rounded,
      color: AppTheme.studentAmber,
      trailing: StatusBadge(
        label: '${areas.length + roundOnly.length}',
        color: AppTheme.studentAmber,
      ),
      child: areas.isEmpty && roundOnly.isEmpty
          ? Text(
              'This driver has not listed any institutes yet.',
              style: TextStyle(color: context.textSecondary, fontSize: 12),
            )
          : Column(
              children: [
                for (final a in areas)
                  a.location != null
                      ? LocationBlock(
                          title: a.instituteType,
                          name: a.name,
                          coord: a.location,
                          icon: Icons.school_rounded,
                          color: AppTheme.studentAmber,
                        )
                      : InfoLine(
                          icon: Icons.school_rounded,
                          label: a.instituteType,
                          value: a.name,
                          color: AppTheme.studentAmber,
                        ),
                for (final name in roundOnly)
                  InfoLine(
                    icon: Icons.school_rounded,
                    label: 'On a round',
                    value: name,
                    color: AppTheme.studentAmber,
                  ),
              ],
            ),
    );
  }

  /// Each round the driver runs: legs, days, institutes and the seats left.
  Widget _buildRoundsCard(
    BuildContext context,
    Driver d,
    List<Student> roster,
  ) {
    final rounds = d.orderedSchedules;
    return SectionCard(
      title: 'Routes & rounds',
      icon: Icons.alt_route_rounded,
      color: AppTheme.purple,
      trailing: d.vehicleSeats > 0
          ? StatusBadge(
              label: '${d.vehicleSeats}-seat vehicle',
              color: AppTheme.purple,
            )
          : null,
      child: rounds.isEmpty
          ? Text(
              'No rounds set up yet.',
              style: TextStyle(color: context.textSecondary, fontSize: 12),
            )
          : Column(
              children: [
                for (final r in rounds) _roundTile(context, d, r, roster),
              ],
            ),
    );
  }

  Widget _roundTile(
    BuildContext context,
    Driver d,
    DriverSchedule r,
    List<Student> roster,
  ) {
    final offered = d.vehicleCapacity > 0 && r.totalSeats > d.vehicleCapacity
        ? d.vehicleCapacity
        : r.totalSeats;
    final free = d.seatsFreeOn(r);
    final onRound = roster.where((s) => s.scheduleId == r.id).length;
    final days = r.weekdays.isEmpty
        ? 'Every day'
        : (r.weekdays.toList()..sort())
              .where((w) => w >= 1 && w <= 7)
              .map((w) => _weekdayNames[w - 1])
              .join(', ');
    final color = free == 0 ? AppTheme.error : AppTheme.success;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.purple.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.purple.withValues(alpha: 0.14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    r.label.isEmpty ? 'Round' : r.label,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                StatusBadge(
                  label: free == 0 ? 'Full' : '$free of $offered free',
                  color: color,
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (r.pickupRange.isNotEmpty)
              _roundLine(context, 'To institute', r.pickupRange),
            if (r.dropoffRange.isNotEmpty)
              _roundLine(context, 'Back home', r.dropoffRange),
            _roundLine(context, 'Days', days),
            _roundLine(
              context,
              'Institutes',
              r.institutes.isEmpty
                  ? 'All institutes served'
                  : r.institutes.join(', '),
            ),
            _roundLine(
              context,
              'Seats',
              '${r.bookedSeats} booked of $offered · '
                  '$onRound on the current roster',
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundLine(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: TextStyle(color: context.textSecondary, fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Every student currently booked with this driver, the fee agreed for
  /// each, and which round they ride — each a link to the student.
  Widget _buildRosterCard(
    BuildContext context,
    Driver d,
    AsyncSnapshot<List<Student>> snap,
    List<RideRequest> requests,
  ) {
    final roster = [...?snap.data]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final total = roster.fold<int>(
      0,
      (sum, s) => sum + agreedFeePaisa(s, requests),
    );
    final manual = d.manualStudentCount;
    return SectionCard(
      title: 'Booked students',
      icon: Icons.groups_rounded,
      color: AppTheme.studentAmber,
      trailing: snap.hasData
          ? StatusBadge(label: '${roster.length}', color: AppTheme.studentAmber)
          : null,
      child: snapshotView<List<Student>>(
        snap,
        what: 'booked students',
        builder: (_) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (roster.isEmpty)
              Text(
                'No students booked with this driver.',
                style: TextStyle(color: context.textSecondary, fontSize: 12),
              )
            else ...[
              Text(
                'Agreed fees total ${formatRupees(total)} / month',
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              for (final s in roster) _rosterRow(context, d, s, requests),
            ],
            if (manual > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+ $manual rider${manual == 1 ? '' : 's'} the driver added '
                  'outside the app.',
                  style: TextStyle(color: context.textTertiary, fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _rosterRow(
    BuildContext context,
    Driver d,
    Student s,
    List<RideRequest> requests,
  ) {
    final fee = agreedFeePaisa(s, requests);
    final round = d.scheduleById(s.scheduleId);
    final expected = d.expectedTimes[s.id];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => openStudentDetail(context, s.id),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.studentAmber.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.studentAmber.withValues(alpha: 0.14),
              ),
            ),
            child: Row(
              children: [
                EntityAvatar(
                  photoUrl: s.photoUrl,
                  color: AppTheme.studentAmber,
                  fallbackEmoji: '🎓',
                  size: 38,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (s.school.isNotEmpty) s.school,
                          round == null
                              ? 'No round set'
                              : (round.label.isEmpty ? 'Round' : round.label),
                          if (expected != null && expected.pickup.isNotEmpty)
                            'pickup ${expected.pickup}',
                          if (expected != null && expected.dropoff.isNotEmpty)
                            'home ${expected.dropoff}',
                        ].join(' • '),
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      fee > 0 ? formatRupees(fee) : 'No fee',
                      style: TextStyle(
                        color: fee > 0
                            ? AppTheme.adminEmerald
                            : context.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      fee > 0 ? 'per month' : 'agreed',
                      style: TextStyle(
                        color: context.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.chevron_right_rounded, color: context.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPerformance(
    BuildContext context,
    Driver d,
    DriverRatingSummary rating,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.t('performance_lbl'),
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // From the `ratings` collection (DriverRatingSummary) — the
              // driver document's `rating` field is never maintained.
              RingIndicator(
                percentage: rating.average / 5 * 100,
                color: rating.isTopRated ? topRatedGold : AppTheme.driverCyan,
                size: 72,
                strokeWidth: 7,
                center: Text(
                  rating.count == 0 ? 'New' : rating.average.toStringAsFixed(1),
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: [
                    _PerfBar(
                      label: AppStrings.t('reliability_lbl'),
                      pct: d.reliabilityScore.clamp(0, 100) / 100,
                      color: AppTheme.success,
                    ),
                    const SizedBox(height: 8),
                    _PerfBar(
                      label: AppStrings.t('rating_lbl'),
                      pct: rating.average / 5,
                      color: AppTheme.info,
                    ),
                    const SizedBox(height: 8),
                    _PerfBar(
                      label: AppStrings.t('safety_lbl'),
                      pct:
                          (1 -
                                  ((d.harshBrakingEvents + d.overSpeedEvents) /
                                          20)
                                      .clamp(0, 1))
                              .toDouble(),
                      color: AppTheme.purple,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            rating.count == 0
                ? 'No family has rated this driver yet.'
                : '${rating.count} rating${rating.count == 1 ? '' : 's'} from families'
                      '${rating.isTopRated ? ' — Top rated' : ''}',
            style: TextStyle(color: context.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context, Driver d) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.t('controls_title'),
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionBtn(
                  label: d.isApproved
                      ? AppStrings.t('approved_status')
                      : 'Approve', // not in the requested term list
                  color: AppTheme.success,
                  icon: Icons.check_circle_rounded,
                  onTap: d.isApproved ? null : () => _approve(d),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionBtn(
                  label: d.status == DriverStatus.suspended
                      ? 'Suspended' // not in the requested term list
                      : AppStrings.t('suspend_action'),
                  color: AppTheme.error,
                  icon: Icons.block_rounded,
                  onTap: d.status == DriverStatus.suspended
                      ? null
                      : () => _suspend(d),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ActionBtn(
                  label: AppStrings.t('message_driver_action'),
                  color: AppTheme.driverCyan,
                  icon: Icons.chat_bubble_rounded,
                  onTap: () => _message(d),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.t('account_section'),
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<AccountRecord?>(
            stream: _accountStream,
            builder: (context, snap) {
              final record = snap.data?.withProfileArchived(d.isDeleted);
              if (record == null) {
                return Text(
                  snap.connectionState == ConnectionState.waiting
                      ? '…'
                      : AppStrings.t('no_account_record'),
                  style: TextStyle(color: context.textSecondary, fontSize: 12),
                );
              }
              return AccountControls(
                record: record,
                deleteNote: AppStrings.t('delete_driver_note'),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDocuments(BuildContext context, Driver d) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.t('compliance_documents_title'),
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<DriverDocument>>(
            stream: _documentsStream,
            builder: (context, docSnap) {
              if (docSnap.hasError) {
                return LoadErrorView(error: docSnap.error, what: 'documents');
              }
              if (!docSnap.hasData) {
                return const SectionLoading();
              }
              final latestByType = _latestPerType(docSnap.data!);
              if (latestByType.isEmpty) {
                return Text(
                  'No documents uploaded yet.',
                  style: TextStyle(color: context.textSecondary, fontSize: 13),
                );
              }
              return Column(
                children: latestByType
                    .map(
                      (doc) => _DocumentRow(
                        doc: doc,
                        onView: (doc.fileUrl ?? '').isEmpty
                            ? null
                            : () => launchUrl(
                                Uri.parse(doc.fileUrl!),
                                mode: LaunchMode.externalApplication,
                              ),
                        onVerify: doc.status == DocumentStatus.pending
                            ? () => _verifyDocument(doc, d)
                            : null,
                        onReject: doc.status == DocumentStatus.pending
                            ? () => _rejectDocument(doc, d)
                            : null,
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  /// One row per document type — a driver may have several re-upload
  /// attempts on file, only the newest one is actionable.
  List<DriverDocument> _latestPerType(List<DriverDocument> docs) {
    final byType = <DocumentType, DriverDocument>{};
    for (final doc in docs) {
      final existing = byType[doc.type];
      if (existing == null ||
          (doc.uploadedAt ?? DateTime(0)).isAfter(
            existing.uploadedAt ?? DateTime(0),
          )) {
        byType[doc.type] = doc;
      }
    }
    final list = byType.values.toList()
      ..sort((a, b) => a.type.index.compareTo(b.type.index));
    return list;
  }
}

// ─── Live status ─────────────────────────────────────────────────────────────

/// What the driver is doing right now: the running trip (round, progress,
/// the stop the van is heading for and which children are there) and where
/// the van is, read from the Realtime Database every 10 s while this screen
/// is open.
class _LiveStatusCard extends StatefulWidget {
  final Driver driver;
  final List<Student> roster;
  final Stream<Trip?> activeTrip;
  const _LiveStatusCard({
    super.key,
    required this.driver,
    required this.roster,
    required this.activeTrip,
  });

  @override
  State<_LiveStatusCard> createState() => _LiveStatusCardState();
}

class _LiveStatusCardState extends State<_LiveStatusCard> {
  static const _pollEvery = Duration(seconds: 10);

  Timer? _poll;
  Trip? _trip;
  LiveLocation? _location;
  Object? _locationError;
  bool _locationChecked = false;
  bool _fetching = false;

  String? _attendanceTripId;
  Stream<List<AttendanceRecord>>? _attendanceStream;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    _poll = Timer.periodic(_pollEvery, (_) => _fetchLocation());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    if (_fetching) return;
    _fetching = true;
    final d = widget.driver;
    try {
      // The trip's bus first (that's the node a running trip publishes
      // to), then the driver's bus, then their uid — a self-signed-up
      // driver with no admin bus publishes under their own uid.
      final loc = await LiveLocationClient.instance.fetchFirst([
        _trip?.busId,
        d.busId,
        d.id,
      ], driverId: d.id);
      if (!mounted) return;
      setState(() {
        _location = loc;
        _locationError = null;
        _locationChecked = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = e;
        _locationChecked = true;
      });
    } finally {
      _fetching = false;
    }
  }

  Stream<List<AttendanceRecord>> _attendanceFor(String tripId) {
    if (_attendanceTripId != tripId || _attendanceStream == null) {
      _attendanceTripId = tripId;
      _attendanceStream = AdminRepository.instance.watchTripAttendance(tripId);
    }
    return _attendanceStream!;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Trip?>(
      stream: widget.activeTrip,
      builder: (context, snap) {
        final trip = snap.data;
        final tripChanged = trip?.id != _trip?.id;
        _trip = trip;
        if (tripChanged && trip != null) {
          // A trip just started — look for the van now, not in 10 s.
          WidgetsBinding.instance.addPostFrameCallback((_) => _fetchLocation());
        }
        return SectionCard(
          title: 'Live status',
          icon: Icons.sensors_rounded,
          color: AppTheme.info,
          trailing:
              snap.hasData || snap.connectionState == ConnectionState.active
              ? DotBadge(
                  label: trip == null ? 'No active trip' : 'On a trip',
                  color: trip == null ? const Color(0xFF94A3B8) : AppTheme.info,
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (snap.hasError)
                LoadErrorView(error: snap.error, what: 'the active trip')
              else if (snap.connectionState == ConnectionState.waiting)
                const SectionLoading()
              else if (trip == null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'No route is running right now.',
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                )
              else
                StreamBuilder<List<AttendanceRecord>>(
                  stream: _attendanceFor(trip.id),
                  builder: (context, attSnap) =>
                      _tripBody(context, trip, attSnap.data ?? const []),
                ),
              _locationBlock(context, trip),
            ],
          ),
        );
      },
    );
  }

  String _names(List<String> ids) {
    final byId = {for (final s in widget.roster) s.id: s.name};
    final names = [
      for (final id in ids)
        if ((byId[id] ?? '').isNotEmpty) byId[id]!,
    ];
    final unknown = ids.length - names.length;
    if (unknown > 0) {
      names.add('$unknown other student${unknown == 1 ? '' : 's'}');
    }
    return names.isEmpty ? 'no students listed' : names.join(', ');
  }

  String _instituteName(TripStop stop) {
    final byId = {for (final s in widget.roster) s.id: s};
    for (final id in stop.studentIds) {
      final school = byId[id]?.school ?? '';
      if (school.isNotEmpty) return school;
    }
    return 'the institute';
  }

  Widget _tripBody(
    BuildContext context,
    Trip trip,
    List<AttendanceRecord> attendance,
  ) {
    final d = widget.driver;
    final round = d.scheduleById(trip.scheduleId);
    final stopsDone = trip.stops
        .where(
          (s) =>
              s.status == TripStopStatus.done ||
              s.status == TripStopStatus.skipped,
        )
        .length;
    int count(AttendanceStatus st) =>
        attendance.where((a) => a.status == st).length;
    final riders = trip.riderIds.isNotEmpty
        ? trip.riderIds.length
        : (trip.studentsExpected > 0
              ? trip.studentsExpected
              : attendance.length);
    final next = trip.nextStop;
    final children = <Widget>[
      InfoLine(
        icon: Icons.alt_route_rounded,
        label: 'Trip',
        value: [
          '${tripTypeLabel(trip.type)} trip',
          if (round != null) (round.label.isEmpty ? 'Round' : round.label),
          if (trip.startedAt != null) 'started ${formatClock(trip.startedAt!)}',
        ].join(' · '),
        color: AppTheme.info,
      ),
      InfoLine(
        icon: Icons.fact_check_rounded,
        label: 'Progress',
        value: [
          if (trip.stops.isNotEmpty) '$stopsDone of ${trip.stops.length} stops',
          '${count(AttendanceStatus.boarded)} on board',
          '${count(AttendanceStatus.droppedOff)} dropped off',
          '${count(AttendanceStatus.absent)} absent',
          if (riders > 0) '$riders riders',
        ].join(' · '),
        color: AppTheme.success,
      ),
    ];
    if (trip.phase == TripPhase.arrivedInstitute) {
      children.add(
        const InfoLine(
          icon: Icons.school_rounded,
          label: 'Now',
          value: 'At the institute — handing over students',
          color: AppTheme.studentAmber,
        ),
      );
    } else if (next == null) {
      children.add(
        const InfoLine(
          icon: Icons.flag_rounded,
          label: 'Now',
          value: 'All stops done — waiting for the driver to end the trip',
          color: AppTheme.success,
        ),
      );
    } else {
      final who = next.isInstitute
          ? _instituteName(next)
          : _names(next.studentIds);
      final eta = next.etaAt == null
          ? ''
          : ' · ETA ${formatClock(next.etaAt!)}';
      final dist = next.distanceMeters == null
          ? ''
          : ' · ${(next.distanceMeters! / 1000).toStringAsFixed(1)} km away';
      children.add(
        LocationBlock(
          title: 'Now: ${stopActivityLabel(next)}',
          name: next.isInstitute && next.studentIds.isNotEmpty
              ? '$who — dropping ${_names(next.studentIds)}'
              : who,
          coord: next.location,
          icon: next.isInstitute
              ? Icons.school_rounded
              : (next.kind == TripStopKind.pickup
                    ? Icons.person_pin_circle_rounded
                    : Icons.home_rounded),
          color: AppTheme.studentAmber,
          note: 'Stop ${next.order} of ${trip.stops.length}$eta$dist',
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _locationBlock(BuildContext context, Trip? trip) {
    final loc = _location;
    if (loc != null) {
      final age = DateTime.now().difference(loc.time);
      final parts = [
        'Updated ${formatDuration(age)} ago',
        if (loc.speedKmh > 0) '${loc.speedKmh.round()} km/h',
        if (loc.isStale) 'signal may be lost',
      ];
      return LocationBlock(
        title: 'Live location',
        coord: loc.coord,
        icon: Icons.my_location_rounded,
        color: loc.isStale ? AppTheme.warning : AppTheme.success,
        note: '${parts.join(' · ')} · refreshes every 10 s',
      );
    }
    final String text;
    if (!_locationChecked) {
      text = 'Checking live location…';
    } else if (_locationError != null) {
      text = 'Could not reach live location: $_locationError';
    } else {
      text = trip == null
          ? 'Not sharing location right now.'
          : 'The trip is running but no location has been published yet.';
    }
    return InfoLine(
      icon: Icons.location_off_rounded,
      label: 'Live location',
      value: text,
      color: _locationError != null ? AppTheme.error : const Color(0xFF94A3B8),
    );
  }
}

// ─── History tabs ────────────────────────────────────────────────────────────

class _TripHistoryTab extends StatelessWidget {
  final Stream<List<Trip>> trips;
  final Driver driver;
  const _TripHistoryTab({required this.trips, required this.driver});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Trip>>(
      stream: trips,
      builder: (context, snap) => snapshotView<List<Trip>>(
        snap,
        what: 'trip history',
        builder: (list) {
          if (list.isEmpty) {
            return SingleChildScrollView(
              child: EmptyHint(
                text: driver.isApproved
                    ? AppStrings.t('no_trips_recorded_driver')
                    : 'No trips available. Driver is pending verification.',
                icon: Icons.directions_car_outlined,
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 12),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final t = list[i];
              final round = driver.scheduleById(t.scheduleId);
              final times = [
                if (t.startedAt != null) formatClock(t.startedAt!),
                if (t.endedAt != null) formatClock(t.endedAt!),
              ].join(' – ');
              final dur = t.duration == null ? '' : formatDuration(t.duration!);
              final punctual = t.onTime == null
                  ? ''
                  : (t.onTime!
                        ? 'On time'
                        : 'Late${(t.delayMinutes ?? 0) > 0 ? ' by ${t.delayMinutes} min' : ''}');
              return HistoryRow(
                color: tripStatusColor(t.status),
                title:
                    '${formatDateKey(t.dateKey)} · ${tripTypeLabel(t.type)}'
                    '${round == null ? '' : ' · ${round.label.isEmpty ? 'Round' : round.label}'}',
                subtitle: [
                  if (times.isNotEmpty) times,
                  if (dur.isNotEmpty) dur,
                  if (punctual.isNotEmpty) punctual,
                  if (t.stops.isNotEmpty) '${t.stops.length} stops',
                ].join(' · '),
                trailing: tripStatusLabel(t.status),
              );
            },
          );
        },
      ),
    );
  }
}

/// Per trip: how many boarded, how many were absent, out of how many.
class _TripAttendanceTab extends StatelessWidget {
  final Stream<List<Trip>> trips;
  const _TripAttendanceTab({required this.trips});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Trip>>(
      stream: trips,
      builder: (context, snap) => snapshotView<List<Trip>>(
        snap,
        what: 'attendance',
        builder: (all) {
          final list = all
              .where((t) => t.status != TripStatus.cancelled)
              .toList();
          if (list.isEmpty) {
            return SingleChildScrollView(
              child: EmptyHint(
                text: AppStrings.t('no_attendance_logged_driver'),
                icon: Icons.event_available_outlined,
              ),
            );
          }
          final finished = list.where((t) => t.status == TripStatus.completed);
          final boarded = finished.fold<int>(
            0,
            (s, t) => s + t.studentsBoarded,
          );
          final absent = finished.fold<int>(0, (s, t) => s + t.studentsAbsent);
          return ListView.builder(
            padding: const EdgeInsets.only(top: 12),
            itemCount: list.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Completed trips: $boarded boarded · $absent absent',
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }
              final t = list[i - 1];
              final expected = t.studentsExpected > 0
                  ? t.studentsExpected
                  : t.riderIds.length;
              final live = t.status == TripStatus.inProgress;
              final rate = expected > 0
                  ? ' · ${(t.studentsBoarded / expected * 100).round()}%'
                  : '';
              return HistoryRow(
                color: live
                    ? AppTheme.info
                    : (t.studentsAbsent > 0
                          ? AppTheme.warning
                          : AppTheme.success),
                title: '${formatDateKey(t.dateKey)} · ${tripTypeLabel(t.type)}',
                subtitle: live
                    ? 'In progress — counts are final when the trip ends'
                    : '${t.studentsBoarded} boarded · ${t.studentsAbsent} absent'
                          '${expected > 0 ? ' of $expected' : ''}$rate',
                trailing: live ? 'Live' : tripStatusLabel(t.status),
              );
            },
          );
        },
      ),
    );
  }
}

class _SosTab extends StatelessWidget {
  final Stream<List<Incident>> incidents;
  const _SosTab({required this.incidents});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Incident>>(
      stream: incidents,
      builder: (context, snap) => snapshotView<List<Incident>>(
        snap,
        what: 'SOS history',
        builder: (list) {
          if (list.isEmpty) {
            return SingleChildScrollView(
              child: EmptyHint(
                text: AppStrings.t('no_sos_alerts_clean_record'),
                icon: Icons.verified_user_outlined,
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 12),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final inc = list[i];
              final hasPin = inc.lat != null && inc.lng != null;
              return HistoryRow(
                color: inc.isResolved
                    ? const Color(0xFF94A3B8)
                    : _severityColor(inc.severity),
                title: inc.title.isEmpty
                    ? (inc.isAutomatic ? 'Safety alert' : 'SOS')
                    : inc.title,
                subtitle: [
                  if (inc.createdAt != null) formatExactTime(inc.createdAt!),
                  if (inc.description.isNotEmpty) inc.description,
                  inc.isResolved
                      ? 'Resolved${inc.resolvedAt == null ? '' : ' ${formatExactTime(inc.resolvedAt!)}'}'
                      : 'Unresolved',
                  if ((inc.resolutionNotes ?? '').isNotEmpty)
                    inc.resolutionNotes!,
                  if (hasPin) 'Tap to open the location',
                ].join(' · '),
                trailing: _severityLabel(inc.severity),
                onTap: hasPin
                    ? () => openInGoogleMaps(GeoCoord(inc.lat!, inc.lng!))
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}

/// Fees families paid this driver (`payments` marked paid), totalled per
/// month.
class _EarningsTab extends StatelessWidget {
  final Stream<List<Payment>> payments;
  const _EarningsTab({required this.payments});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Payment>>(
      stream: payments,
      builder: (context, snap) => snapshotView<List<Payment>>(
        snap,
        what: 'earnings',
        builder: (all) {
          final paid = all.where((p) => p.status == PaymentStatus.paid).toList()
            ..sort(
              (a, b) => (b.paidAt ?? b.confirmedAt ?? DateTime(0)).compareTo(
                a.paidAt ?? a.confirmedAt ?? DateTime(0),
              ),
            );
          final submitted =
              all.where((p) => p.status == PaymentStatus.submitted).toList()
                ..sort(
                  (a, b) => (b.paidAt ?? DateTime(0)).compareTo(
                    a.paidAt ?? DateTime(0),
                  ),
                );
          if (paid.isEmpty && submitted.isEmpty) {
            return SingleChildScrollView(
              child: EmptyHint(
                text: AppStrings.t('no_earnings_recorded_driver'),
                icon: Icons.account_balance_wallet_outlined,
              ),
            );
          }
          final months = paidTotalsByMonth(paid);
          final total = paid.fold<int>(0, (s, p) => s + p.amountPaisa);
          final thisMonth = Payment.monthKeyFor(DateTime.now());
          final current = months
              .where((e) => e.key == thisMonth)
              .fold<int>(0, (s, e) => s + e.value);
          final chart = months.take(6).toList().reversed.toList();
          final awaiting = all
              .where((p) => p.status == PaymentStatus.submitted)
              .length;
          return ListView(
            padding: const EdgeInsets.only(top: 12),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _EarnStat(
                      label: 'This month',
                      value: formatRupees(current),
                    ),
                  ),
                  Expanded(
                    child: _EarnStat(
                      label: 'All time',
                      value: formatRupees(total),
                    ),
                  ),
                ],
              ),
              if (awaiting > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '$awaiting payment${awaiting == 1 ? '' : 's'} waiting for '
                    'the driver to confirm.',
                    style: TextStyle(color: AppTheme.warning, fontSize: 11),
                  ),
                ),
              const SizedBox(height: 12),
              if (chart.isNotEmpty)
                MiniBarChart(
                  values: [for (final e in chart) e.value / 100],
                  labels: [
                    for (final e in chart)
                      formatMonthKey(e.key).split(' ').first,
                  ],
                  barColor: AppTheme.driverCyan,
                  barActiveColor: AppTheme.driverCyan,
                  height: 70,
                  barWidth: 16,
                ),
              const SizedBox(height: 12),
              for (final e in months)
                _EarnRow(
                  label: formatMonthKey(e.key),
                  value: formatRupees(e.value),
                  color: AppTheme.success,
                ),
              if (submitted.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Waiting for the driver',
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                for (final p in submitted.take(20)) _paymentRow(context, p),
              ],
              const SizedBox(height: 8),
              Text(
                'Recent payments',
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              for (final p in paid.take(20)) _paymentRow(context, p),
            ],
          );
        },
      ),
    );
  }

  /// One payment, with the AI check of its screenshot under it.
  Widget _paymentRow(BuildContext context, Payment p) {
    final waiting = p.status == PaymentStatus.submitted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HistoryRow(
          color: waiting ? AppTheme.warning : AppTheme.success,
          title: p.displayAmount,
          subtitle: [
            if (p.monthKey.isNotEmpty) 'For ${formatMonthKey(p.monthKey)}',
            if (p.paidAt != null)
              '${waiting ? 'sent' : 'paid'} ${formatDate(p.paidAt!)}',
            if ((p.methodName ?? '').isNotEmpty) p.methodName!,
          ].join(' · '),
          onTap: p.studentId.isEmpty
              ? null
              : () => openStudentDetail(context, p.studentId),
        ),
        if (p.slipCheck != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: SlipCheckView(check: p.slipCheck!),
          ),
      ],
    );
  }
}

class _EarnStat extends StatelessWidget {
  final String label, value;
  const _EarnStat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: context.textSecondary, fontSize: 11),
        ),
        Text(
          value,
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────
class _DocumentRow extends StatelessWidget {
  final DriverDocument doc;
  final VoidCallback? onView;
  final VoidCallback? onVerify;
  final VoidCallback? onReject;
  const _DocumentRow({
    required this.doc,
    required this.onView,
    this.onVerify,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final color = documentStatusColor(doc.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    documentTypeLabel(doc.type),
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                StatusBadge(
                  label: documentStatusLabel(doc.status),
                  color: color,
                ),
              ],
            ),
            if (doc.expiryDate != null) ...[
              const SizedBox(height: 4),
              Text(
                'Expires ${formatDate(doc.expiryDate!)}',
                style: TextStyle(color: context.textSecondary, fontSize: 12),
              ),
            ],
            if (doc.docCheck != null) DocCheckView(check: doc.docCheck!),
            if (doc.status == DocumentStatus.rejected &&
                doc.rejectionReason != null &&
                doc.rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                doc.rejectionReason!,
                style: TextStyle(color: context.textSecondary, fontSize: 12),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              children: [
                TextButton.icon(
                  onPressed: onView,
                  icon: const Icon(Icons.open_in_new_rounded, size: 15),
                  label: Text(AppStrings.t('view_action')),
                ),
                if (onVerify != null)
                  TextButton.icon(
                    onPressed: onVerify,
                    icon: Icon(
                      Icons.check_circle_rounded,
                      size: 15,
                      color: AppTheme.success,
                    ),
                    label: Text(
                      'Verify',
                      style: TextStyle(color: AppTheme.success),
                    ),
                  ),
                if (onReject != null)
                  TextButton.icon(
                    onPressed: onReject,
                    icon: Icon(
                      Icons.cancel_rounded,
                      size: 15,
                      color: AppTheme.error,
                    ),
                    label: Text(
                      'Reject',
                      style: TextStyle(color: AppTheme.error),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PerfBar extends StatelessWidget {
  final String label;
  final double pct;
  final Color color;
  const _PerfBar({required this.label, required this.pct, required this.color});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(color: context.textSecondary, fontSize: 11),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: context.cardBgElevated,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${(pct * 100).toInt()}%',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;
  const _ActionBtn({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Clickable(
      onTap: onTap,
      child: Opacity(
        opacity: disabled ? 0.5 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.14),
                color.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 15),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EarnRow extends StatelessWidget {
  final String label, value;
  final Color color;
  const _EarnRow({
    required this.label,
    required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: context.textSecondary, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Bus LHR-4201 • Morning Round", resolved from the fleet rather than
/// printed as the ids the driver document actually stores.
class _VehicleLine extends StatefulWidget {
  final Driver driver;
  const _VehicleLine({required this.driver});

  @override
  State<_VehicleLine> createState() => _VehicleLineState();
}

class _VehicleLineState extends State<_VehicleLine> {
  // Held across rebuilds (this card now rebuilds on every presence tick),
  // so the bus listener isn't re-attached each time.
  String? _busId;
  Stream<Bus?>? _bus;

  Stream<Bus?> _busFor(String id) {
    if (id != _busId || _bus == null) {
      _busId = id;
      _bus = AdminRepository.instance.watchBus(id);
    }
    return _bus!;
  }

  @override
  Widget build(BuildContext context) {
    final busId = widget.driver.busId?.trim() ?? '';
    if (busId.isEmpty) {
      // A self-signed-up driver runs their own vehicle — no fleet bus.
      return _RouteLine(
        driver: widget.driver,
        prefix: widget.driver.vehicleSeats > 0
            ? 'Own vehicle (${widget.driver.vehicleSeats} seats)'
            : 'No bus assigned',
      );
    }
    return StreamBuilder<Bus?>(
      stream: _busFor(busId),
      builder: (context, snap) {
        final bus = snap.data;
        // While the vehicle loads, the id is still worse than nothing:
        // say what is known and fill the rest in when it arrives.
        final label = bus == null
            ? 'Bus …'
            : '${AppStrings.t('bus_prefix')} '
                  '${bus.busNumber.isEmpty ? bus.plateNumber : bus.busNumber}';
        return _RouteLine(driver: widget.driver, prefix: label);
      },
    );
  }
}

class _RouteLine extends StatefulWidget {
  final Driver driver;
  final String prefix;
  const _RouteLine({required this.driver, required this.prefix});

  @override
  State<_RouteLine> createState() => _RouteLineState();
}

class _RouteLineState extends State<_RouteLine> {
  String? _routeId;
  Stream<BusRoute?>? _route;

  Stream<BusRoute?> _routeFor(String id) {
    if (id != _routeId || _route == null) {
      _routeId = id;
      _route = AdminRepository.instance.watchRoute(id);
    }
    return _route!;
  }

  @override
  Widget build(BuildContext context) {
    final routeId = widget.driver.routeId?.trim() ?? '';
    final rounds = widget.driver.schedules.length;
    if (routeId.isEmpty) {
      // Self-signed-up drivers run their own rounds instead of an
      // admin-assigned route.
      final tail = rounds > 0
          ? '$rounds round${rounds == 1 ? '' : 's'}'
          : AppStrings.t('no_route_status');
      return Text(
        '${widget.prefix} • $tail',
        style: TextStyle(color: context.textSecondary, fontSize: 13),
      );
    }
    return StreamBuilder<BusRoute?>(
      stream: _routeFor(routeId),
      builder: (context, snap) {
        final name = snap.data?.name;
        return Text(
          '${widget.prefix} • ${name == null || name.isEmpty ? AppStrings.t('no_route_status') : name}',
          style: TextStyle(color: context.textSecondary, fontSize: 13),
        );
      },
    );
  }
}
