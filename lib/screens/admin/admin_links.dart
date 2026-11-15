import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transit_core/transit_core.dart';

import '../../app/admin_format.dart';
import '../../data/admin_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/entity_widgets.dart';
import '../../widgets/glass_card.dart';

/// Cross-links between the three detail screens. Each shows just enough to
/// recognise the other record (a name, a round) and opens that record's
/// own detail screen instead of duplicating its data here.

void openDriverDetail(BuildContext context, String driverId) =>
    context.push('/admin/driver-detail', extra: driverId);

void openStudentDetail(BuildContext context, String studentId) =>
    context.push('/admin/student-detail', extra: studentId);

void openParentDetail(BuildContext context, String parentId) =>
    context.push('/admin/parent-detail', extra: parentId);

/// "Driver: Ahmed Raza · Round 1 (06:30 – 07:00)" → driver detail.
class DriverLink extends StatefulWidget {
  final String driverId;
  final String? scheduleId;
  final String label;
  const DriverLink({
    super.key,
    required this.driverId,
    this.scheduleId,
    this.label = 'Booked driver',
  });

  @override
  State<DriverLink> createState() => _DriverLinkState();
}

class _DriverLinkState extends State<DriverLink> {
  late Stream<Driver?> _stream = AdminRepository.instance.watchDriver(
    widget.driverId,
  );

  @override
  void didUpdateWidget(covariant DriverLink old) {
    super.didUpdateWidget(old);
    if (old.driverId != widget.driverId) {
      _stream = AdminRepository.instance.watchDriver(widget.driverId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Driver?>(
      stream: _stream,
      builder: (context, snap) {
        final d = snap.data;
        final String value;
        if (snap.hasError) {
          value = 'Could not load driver';
        } else if (!snap.hasData &&
            snap.connectionState == ConnectionState.waiting) {
          value = 'Loading…';
        } else if (d == null) {
          value = 'Driver record not found';
        } else {
          final round = d.scheduleById(widget.scheduleId);
          value = [
            d.name.isEmpty ? 'Unnamed driver' : d.name,
            if (d.isDeleted) '(archived)',
            if (round != null)
              '· ${round.label.isEmpty ? 'Round' : round.label}'
                  '${round.timeRange.isEmpty ? '' : ' (${round.timeRange})'}',
          ].join(' ');
        }
        return InfoLine(
          icon: Icons.directions_bus_rounded,
          label: widget.label,
          value: value,
          color: AppTheme.driverCyan,
          onTap: () => openDriverDetail(context, widget.driverId),
        );
      },
    );
  }
}

/// A student as a tappable card: photo, level/school, booked driver, and
/// their home pickup and institute drop-off pins.
class StudentSummaryCard extends StatelessWidget {
  final Student student;
  final bool showLocations;
  const StudentSummaryCard({
    super.key,
    required this.student,
    this.showLocations = true,
  });

  @override
  Widget build(BuildContext context) {
    final s = student;
    final sub = [
      studentLevel(s),
      if (s.school.isNotEmpty) s.school,
      if (s.grade.isNotEmpty) s.grade,
    ].join(' • ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.parentPurple.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.parentPurple.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => openStudentDetail(context, s.id),
              child: Row(
                children: [
                  EntityAvatar(
                    photoUrl: s.photoUrl,
                    color: AppTheme.studentAmber,
                    fallbackEmoji: '🎓',
                    size: 42,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.name.isEmpty ? 'Unnamed student' : s.name,
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          sub,
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        if (s.isDeleted || s.isTransportSuspended) ...[
                          const SizedBox(height: 4),
                          StatusBadge(
                            label: s.isDeleted
                                ? 'Archived'
                                : 'Transport suspended',
                            color: s.isDeleted
                                ? AppTheme.error
                                : AppTheme.warning,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: context.textTertiary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (s.hasDriver)
              DriverLink(driverId: s.driverId!, scheduleId: s.scheduleId)
            else
              const InfoLine(
                icon: Icons.directions_bus_rounded,
                label: 'Booked driver',
                value: 'No driver booked yet',
                color: AppTheme.warning,
              ),
            if (showLocations) ...[
              LocationBlock(
                title: 'Home — pickup point',
                coord: s.pickupLocation,
                icon: Icons.home_rounded,
                color: AppTheme.parentPurple,
              ),
              LocationBlock(
                title: 'Institute — drop-off point',
                name: s.school,
                coord: s.dropoffLocation,
                icon: Icons.school_rounded,
                color: AppTheme.studentAmber,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
