import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transit_core/transit_core.dart';

import '../../app/admin_format.dart';
import '../../data/admin_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/entity_widgets.dart';
import '../../widgets/glass_card.dart';

/// A [GlassCard] with a tab strip over fixed-height, independently
/// scrolling history lists — the "History" block on the Parent, Student and
/// Driver detail screens.
class HistoryTabs extends StatefulWidget {
  final Color color;
  final List<(String label, Widget body)> tabs;
  final double height;
  const HistoryTabs({
    super.key,
    required this.color,
    required this.tabs,
    this.height = 320,
  });

  @override
  State<HistoryTabs> createState() => _HistoryTabsState();
}

class _HistoryTabsState extends State<HistoryTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _ctrl = TabController(
    length: widget.tabs.length,
    vsync: this,
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          TabBar(
            controller: _ctrl,
            isScrollable: true,
            labelColor: widget.color,
            unselectedLabelColor: context.textTertiary,
            indicatorColor: widget.color,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            tabAlignment: TabAlignment.start,
            tabs: [for (final t in widget.tabs) Tab(text: t.$1)],
          ),
          SizedBox(
            height: widget.height,
            child: TabBarView(
              controller: _ctrl,
              children: [for (final t in widget.tabs) t.$2],
            ),
          ),
        ],
      ),
    );
  }
}

Color attendanceColor(AttendanceStatus s) => switch (s) {
  AttendanceStatus.boarded => AppTheme.info,
  AttendanceStatus.droppedOff => AppTheme.success,
  AttendanceStatus.absent => AppTheme.error,
  AttendanceStatus.pending => const Color(0xFF94A3B8),
};

Color tripStatusColor(TripStatus s) => switch (s) {
  TripStatus.completed => AppTheme.success,
  TripStatus.inProgress => AppTheme.info,
  TripStatus.scheduled => const Color(0xFF94A3B8),
  TripStatus.cancelled => AppTheme.error,
};

Color missedBusColor(MissedBusStatus s) => switch (s) {
  MissedBusStatus.completed => AppTheme.success,
  MissedBusStatus.accepted => AppTheme.info,
  MissedBusStatus.searching ||
  MissedBusStatus.viewing ||
  MissedBusStatus.bidOffered => AppTheme.warning,
  MissedBusStatus.declined ||
  MissedBusStatus.noDrivers ||
  MissedBusStatus.cancelled => AppTheme.error,
};

/// Wraps a future-backed history list with error/loading states and a
/// refresh: past history doesn't change by itself, so these are one-shot
/// reads rather than open listeners, and the admin can pull a fresh copy.
class _FutureList<T> extends StatefulWidget {
  final Future<List<T>> Function() load;
  final String what;
  final String emptyText;
  final IconData emptyIcon;
  final Widget Function(BuildContext context, List<T> items) builder;
  const _FutureList({
    super.key,
    required this.load,
    required this.what,
    required this.emptyText,
    required this.emptyIcon,
    required this.builder,
  });

  @override
  State<_FutureList<T>> createState() => _FutureListState<T>();
}

class _FutureListState<T> extends State<_FutureList<T>> {
  late Future<List<T>> _future = widget.load();

  void _reload() => setState(() => _future = widget.load());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<T>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SectionLoading();
        }
        if (snap.hasError) {
          return SingleChildScrollView(
            child: LoadErrorView(
              error: snap.error,
              what: widget.what,
              onRetry: _reload,
            ),
          );
        }
        final items = snap.data ?? const [];
        if (items.isEmpty) {
          return SingleChildScrollView(
            child: Column(
              children: [
                EmptyHint(text: widget.emptyText, icon: widget.emptyIcon),
                TextButton.icon(
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          );
        }
        // Pull-to-refresh is touch-only; the button is how a mouse (or a
        // desktop window) reloads.
        return Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: _reload,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(
                  '${items.length} record${items.length == 1 ? '' : 's'} · Refresh',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _reload(),
                child: widget.builder(context, items),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Per-trip attendance marks for one or more students, newest first.
///
/// [names] maps student id → name, for a parent with several children
/// (shown only when [showStudent]).
class AttendanceHistoryList extends StatelessWidget {
  final List<String> studentIds;
  final Map<String, String> names;
  final bool showStudent;
  const AttendanceHistoryList({
    super.key,
    required this.studentIds,
    this.names = const {},
    this.showStudent = false,
  });

  @override
  Widget build(BuildContext context) {
    return _FutureList<AttendanceRecord>(
      key: ValueKey(studentIds.join(',')),
      load: () =>
          AdminRepository.instance.fetchAttendanceForStudents(studentIds),
      what: 'attendance',
      emptyText: studentIds.isEmpty
          ? 'No students linked, so there is no attendance to show.'
          : 'No trip attendance recorded yet.',
      emptyIcon: Icons.assignment_outlined,
      builder: (context, rows) => ListView.builder(
        padding: const EdgeInsets.only(top: 12),
        itemCount: rows.length,
        itemBuilder: (context, i) {
          final r = rows[i];
          final who =
              names[r.studentId] ??
              (r.studentName.isNotEmpty ? r.studentName : 'Student');
          final marked = r.markedAt == null
              ? 'Not marked yet'
              : 'Marked ${formatClock(r.markedAt!)}';
          return HistoryRow(
            color: attendanceColor(r.status),
            title: showStudent
                ? '$who — ${attendanceStatusLabel(r.status)}'
                : attendanceStatusLabel(r.status),
            subtitle: '${formatDateKey(r.dateKey)} · $marked',
            trailing: attendanceStatusLabel(r.status),
          );
        },
      ),
    );
  }
}

/// The trips a student rode (from their attendance rows), with the trip's
/// own type, status, times and driver.
class StudentTripHistoryList extends StatelessWidget {
  final String studentId;
  const StudentTripHistoryList({super.key, required this.studentId});

  Future<List<(AttendanceRecord, Trip?)>> _load() async {
    final repo = AdminRepository.instance;
    final rows = await repo.fetchStudentAttendance(studentId);
    final trips = await repo.fetchTripsByIds(rows.map((r) => r.tripId));
    return [for (final r in rows) (r, trips[r.tripId])];
  }

  @override
  Widget build(BuildContext context) {
    return _FutureList<(AttendanceRecord, Trip?)>(
      key: ValueKey(studentId),
      load: _load,
      what: 'trip history',
      emptyText: 'No trips recorded for this student yet.',
      emptyIcon: Icons.route_rounded,
      builder: (context, rows) => ListView.builder(
        padding: const EdgeInsets.only(top: 12),
        itemCount: rows.length,
        itemBuilder: (context, i) {
          final (r, trip) = rows[i];
          if (trip == null) {
            return HistoryRow(
              color: attendanceColor(r.status),
              title: '${formatDateKey(r.dateKey)} — trip record unavailable',
              trailing: attendanceStatusLabel(r.status),
            );
          }
          final times = [
            if (trip.startedAt != null)
              'Started ${formatClock(trip.startedAt!)}',
            if (trip.endedAt != null) 'ended ${formatClock(trip.endedAt!)}',
          ].join(', ');
          return HistoryRow(
            color: tripStatusColor(trip.status),
            title:
                '${formatDateKey(trip.dateKey)} · ${tripTypeLabel(trip.type)} trip',
            subtitle: [
              tripStatusLabel(trip.status),
              if (times.isNotEmpty) times,
              'Student: ${attendanceStatusLabel(r.status)}',
            ].join(' · '),
            trailing: trip.driverId.isEmpty ? null : 'Driver ›',
            onTap: trip.driverId.isEmpty
                ? null
                : () => context.push(
                    '/admin/driver-detail',
                    extra: trip.driverId,
                  ),
          );
        },
      ),
    );
  }
}

/// Missed-bus requests raised for [studentIds], newest first.
class MissedBusHistoryList extends StatelessWidget {
  final List<String> studentIds;
  final bool showStudent;
  const MissedBusHistoryList({
    super.key,
    required this.studentIds,
    this.showStudent = false,
  });

  @override
  Widget build(BuildContext context) {
    return _FutureList<MissedBusRequest>(
      key: ValueKey(studentIds.join(',')),
      load: () =>
          AdminRepository.instance.fetchMissedBusForStudents(studentIds),
      what: 'missed-bus requests',
      emptyText: 'No missed-bus requests on record.',
      emptyIcon: Icons.fact_check_outlined,
      builder: (context, rows) => ListView.builder(
        padding: const EdgeInsets.only(top: 12),
        itemCount: rows.length,
        itemBuilder: (context, i) =>
            _MissedBusRow(request: rows[i], showStudent: showStudent),
      ),
    );
  }
}

class _MissedBusRow extends StatelessWidget {
  final MissedBusRequest request;
  final bool showStudent;
  const _MissedBusRow({required this.request, required this.showStudent});

  @override
  Widget build(BuildContext context) {
    final r = request;
    final when = r.createdAt == null ? '' : formatExactTime(r.createdAt!);
    final route = [
      if (r.currentStopName.isNotEmpty) 'From ${r.currentStopName}',
      if (r.destinationStopName.isNotEmpty) 'to ${r.destinationStopName}',
    ].join(' ');
    final driver = (r.assignedDriverName ?? '').isNotEmpty
        ? 'Driver: ${r.assignedDriverName}'
        : '';
    final fare = r.displayFare == null ? '' : 'Fare ${r.displayFare}';
    final picked = r.pickedUpAt == null
        ? ''
        : 'Picked up ${formatClock(r.pickedUpAt!)}';
    return HistoryRow(
      color: missedBusColor(r.status),
      title: showStudent && r.studentName.isNotEmpty
          ? '${r.studentName} — ${missedBusStatusLabel(r.status)}'
          : missedBusStatusLabel(r.status),
      subtitle: [
        when,
        route,
        driver,
        fare,
        picked,
      ].where((e) => e.isNotEmpty).join(' · '),
      onTap: (r.assignedDriverId ?? '').isEmpty
          ? null
          : () =>
                context.push('/admin/driver-detail', extra: r.assignedDriverId),
    );
  }
}

/// Live sign-in / sign-out history of one account (`users/{uid}/accessLog`).
class AccessLogList extends StatefulWidget {
  final String uid;
  final String? emptyText;
  const AccessLogList({super.key, required this.uid, this.emptyText});

  @override
  State<AccessLogList> createState() => _AccessLogListState();
}

class _AccessLogListState extends State<AccessLogList> {
  late final Stream<List<AccessLogEntry>> _stream = AdminRepository.instance
      .watchAccessLog(widget.uid);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AccessLogEntry>>(
      stream: _stream,
      builder: (context, snap) => snapshotView(
        snap,
        what: 'access history',
        builder: (rows) {
          if (rows.isEmpty) {
            return SingleChildScrollView(
              child: EmptyHint(
                text:
                    widget.emptyText ??
                    'No sign-ins recorded yet. Entries appear the next time '
                        'this account opens the app.',
                icon: Icons.verified_user_outlined,
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 12),
            itemCount: rows.length,
            itemBuilder: (context, i) {
              final e = rows[i];
              return HistoryRow(
                color: e.isSignIn ? AppTheme.success : const Color(0xFF94A3B8),
                title: e.label,
                subtitle: [
                  if (e.at != null) formatExactTime(e.at!),
                  if (e.platform.isNotEmpty) 'on ${e.platform}',
                ].join(' · '),
              );
            },
          );
        },
      ),
    );
  }
}
