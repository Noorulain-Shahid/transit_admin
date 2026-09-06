import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transit_core/transit_core.dart';
import '../../data/admin_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import 'admin_student_management.dart'
    show subscriptionStatusLabel, subscriptionStatusColor;

class AdminStudentDetail extends StatefulWidget {
  final String studentId;
  const AdminStudentDetail({super.key, required this.studentId});
  @override
  State<AdminStudentDetail> createState() => _AdminStudentDetailState();
}

class _AdminStudentDetailState extends State<AdminStudentDetail>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _repo = AdminRepository.instance;
  bool _editing = false;
  final _nameCtrl = TextEditingController();
  final _gradeCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController();
  final _medicalCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _nameCtrl.dispose();
    _gradeCtrl.dispose();
    _schoolCtrl.dispose();
    _medicalCtrl.dispose();
    super.dispose();
  }

  void _startEditing(Student s) {
    _nameCtrl.text = s.name;
    _gradeCtrl.text = s.grade;
    _schoolCtrl.text = s.school;
    _medicalCtrl.text = s.medicalNotes ?? '';
    setState(() => _editing = true);
  }

  Future<void> _save(Student s) async {
    setState(() => _saving = true);
    try {
      await _repo.updateStudent(s.id, {
        'name': _nameCtrl.text.trim(),
        'grade': _gradeCtrl.text.trim(),
        'school': _schoolCtrl.text.trim(),
        'medicalNotes': _medicalCtrl.text.trim(),
      });
      if (mounted) {
        setState(() => _editing = false);
        _msg('Saved');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleSuspended(Student s) async {
    await _repo.updateStudent(s.id, {
      'isTransportSuspended': !s.isTransportSuspended,
    });
    if (mounted) {
      _msg(
        s.isTransportSuspended ? 'Transport re-enabled' : 'Transport suspended',
      );
    }
  }

  Future<void> _message(Student s) async {
    final ctrl = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Message about ${s.name}'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Your driver assignment has been updated.',
          ),
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
    if (text == null || text.isEmpty) return;
    // Messages a student's own account when they have one; the parent link
    // (`students/{id}.parentId`) is the fallback recipient for a child too
    // young to hold a login, since that's who actually reads the inbox.
    await _repo.messageUser(
      s.parentId,
      title: 'Message from admin about ${s.name}',
      body: text,
    );
    if (mounted) _msg('Message sent');
  }

  void _msg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: context.scaffoldBg,
        child: SafeArea(
          child: StreamBuilder<Student?>(
            stream: _repo.watchStudent(widget.studentId),
            builder: (context, snap) {
              final s = snap.data;
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        GestureDetector(
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
                            'Student Detail',
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (s != null && !_editing)
                          GestureDetector(
                            onTap: () => _startEditing(s),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppTheme.studentAmber.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.studentAmber.withValues(
                                    alpha: 0.25,
                                  ),
                                ),
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                color: AppTheme.studentAmber,
                                size: 18,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: !snap.hasData
                        ? const Center(child: CircularProgressIndicator())
                        : s == null
                        ? Center(
                            child: Text(
                              'Student not found.',
                              style: TextStyle(color: context.textSecondary),
                            ),
                          )
                        : _buildBody(context, s),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, Student s) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // Profile card
            GlassCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.studentAmber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppTheme.studentAmber.withValues(
                              alpha: 0.25,
                            ),
                          ),
                        ),
                        child: const Center(
                          child: Text('🎓', style: TextStyle(fontSize: 26)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.name,
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                StatusBadge(
                                  label: s.isTransportSuspended
                                      ? 'Suspended'
                                      : 'Active',
                                  color: s.isTransportSuspended
                                      ? AppTheme.warning
                                      : AppTheme.success,
                                ),
                                const SizedBox(width: 6),
                                StatusBadge(
                                  label:
                                      '💳 ${subscriptionStatusLabel(s.subscriptionStatus)}',
                                  color: subscriptionStatusColor(
                                    s.subscriptionStatus,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_editing) ...[
                    const SizedBox(height: 14),
                    _EditField(label: 'Name', controller: _nameCtrl),
                    const SizedBox(height: 8),
                    _EditField(label: 'Grade', controller: _gradeCtrl),
                    const SizedBox(height: 8),
                    _EditField(label: 'School', controller: _schoolCtrl),
                    const SizedBox(height: 8),
                    _EditField(
                      label: 'Medical notes',
                      controller: _medicalCtrl,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionBtn(
                            label: 'Cancel',
                            color: AppTheme.error,
                            icon: Icons.close_rounded,
                            onTap: _saving
                                ? null
                                : () => setState(() => _editing = false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActionBtn(
                            label: _saving ? 'Saving…' : 'Save',
                            color: AppTheme.success,
                            icon: Icons.check_rounded,
                            onTap: _saving ? null : () => _save(s),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Info grid
            GlassCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Details',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.school_rounded,
                    label: 'School',
                    value: s.school.isEmpty ? '—' : s.school,
                    color: AppTheme.purple,
                  ),
                  _InfoRow(
                    icon: Icons.grade_rounded,
                    label: 'Grade',
                    value: s.grade.isEmpty ? '—' : s.grade,
                    color: AppTheme.purple,
                  ),
                  _InfoRow(
                    icon: Icons.directions_bus_rounded,
                    label: 'Driver',
                    value: (s.driverId ?? '').isEmpty
                        ? 'Unassigned'
                        : s.driverId!,
                    color: AppTheme.driverCyan,
                  ),
                  _InfoRow(
                    icon: Icons.route_rounded,
                    label: 'Route',
                    value: (s.routeId ?? '').isEmpty
                        ? 'Unassigned'
                        : s.routeId!,
                    color: AppTheme.info,
                  ),
                  if ((s.medicalNotes ?? '').isNotEmpty)
                    _InfoRow(
                      icon: Icons.medical_information_rounded,
                      label: 'Medical',
                      value: s.medicalNotes!,
                      color: AppTheme.error,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Management actions
            GlassCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Controls',
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
                          label: s.isTransportSuspended
                              ? 'Re-enable'
                              : 'Suspend',
                          color: s.isTransportSuspended
                              ? AppTheme.success
                              : AppTheme.warning,
                          icon: s.isTransportSuspended
                              ? Icons.check_circle_rounded
                              : Icons.block_rounded,
                          onTap: () => _toggleSuspended(s),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionBtn(
                          label: 'Message',
                          color: AppTheme.studentAmber,
                          icon: Icons.chat_bubble_rounded,
                          onTap: () => _message(s),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Data tabs (illustrative history — attendance/trip/missed-log
            // data sources aren't wired up yet, out of scope for this pass)
            GlassCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  TabBar(
                    controller: _tabCtrl,
                    isScrollable: true,
                    labelColor: AppTheme.studentAmber,
                    unselectedLabelColor: context.textTertiary,
                    indicatorColor: AppTheme.studentAmber,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    tabAlignment: TabAlignment.start,
                    tabs: const [
                      Tab(text: 'Attendance'),
                      Tab(text: 'Trip History'),
                      Tab(text: 'Missed Logs'),
                      Tab(text: 'Access'),
                    ],
                  ),
                  SizedBox(
                    height: 260,
                    child: TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _buildAttendance(context, s),
                        _buildTripHistory(context, s),
                        _buildMissedLogs(context, s),
                        _buildAccessLogs(context, s),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Real attendance data has no query wired up yet — `AttendanceRecord`
  /// lives under `trips/{tripId}/attendance/{studentId}` in `transit_core`,
  /// and no trip has ever been recorded for any student in this schema (live
  /// tracking/Phase 2 hasn't started — see the mobile app's
  /// IMPLEMENTATION.md). Until that collection-group query exists,
  /// `attendanceList` is honestly empty rather than hardcoded — this method
  /// is what actually decides what the tab shows once real data does arrive.
  Widget _buildAttendance(BuildContext context, Student? s) {
    if (s == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final List<(String date, String status, Color color)> attendanceList =
        const [];

    if (!s.hasDriver || attendanceList.isEmpty) {
      return _AttendanceEmptyState(hasDriver: s.hasDriver);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 12),
      itemCount: attendanceList.length,
      itemBuilder: (context, i) {
        final entry = attendanceList[i];
        return _LogRow(date: entry.$1, status: entry.$2, color: entry.$3);
      },
    );
  }

  /// Same situation as `_buildAttendance` above: no trip has ever been
  /// recorded for any student in this schema yet (live tracking/Phase 2
  /// hasn't started — see the mobile app's IMPLEMENTATION.md), so
  /// `tripHistoryList` is honestly empty rather than hardcoded. The
  /// completed/missed color-coding is preserved on `_LogRow` — it just now
  /// only ever runs over real entries, once a real query fills the list.
  Widget _buildTripHistory(BuildContext context, Student? s) {
    if (s == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final List<(String date, String status, Color color)> tripHistoryList =
        const [];

    if (!s.hasDriver || tripHistoryList.isEmpty) {
      return _TripHistoryEmptyState(hasDriver: s.hasDriver);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 12),
      itemCount: tripHistoryList.length,
      itemBuilder: (context, i) {
        final entry = tripHistoryList[i];
        return _LogRow(date: entry.$1, status: entry.$2, color: entry.$3);
      },
    );
  }

  /// Same situation as `_buildAttendance`/`_buildTripHistory`: no missed-log
  /// event has ever been recorded for any student in this schema yet (no
  /// trip has run — see the mobile app's IMPLEMENTATION.md), so
  /// `missedLogsList` is honestly empty rather than hardcoded. The missed
  /// pickup/drop color-coding is preserved on `_LogRow`, running only over
  /// real entries once a real query fills the list.
  Widget _buildMissedLogs(BuildContext context, Student? s) {
    if (s == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final List<(String date, String status, Color color)> missedLogsList =
        const [];

    if (!s.hasDriver || missedLogsList.isEmpty) {
      return _MissedLogsEmptyState(hasDriver: s.hasDriver);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 12),
      itemCount: missedLogsList.length,
      itemBuilder: (context, i) {
        final entry = missedLogsList[i];
        return _LogRow(date: entry.$1, status: entry.$2, color: entry.$3);
      },
    );
  }

  /// Access/subscription events have no query wired up yet either — there is
  /// no per-student event log for subscription changes in `transit_core`
  /// today (only the current `subscriptionStatus` field, no history), so
  /// `accessLogsList` is honestly empty rather than hardcoded. The
  /// active/renewed/blocked color-coding is preserved on `_LogRow`, running
  /// only over real entries once a real event log exists.
  Widget _buildAccessLogs(BuildContext context, Student? s) {
    if (s == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final List<(String date, String status, Color color)> accessLogsList =
        const [];

    if (accessLogsList.isEmpty) {
      return const _AccessLogsEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 12),
      itemCount: accessLogsList.length,
      itemBuilder: (context, i) {
        final entry = accessLogsList[i];
        return _LogRow(date: entry.$1, status: entry.$2, color: entry.$3);
      },
    );
  }
}

// ─── Sub-widgets ────────────────────────────────────────────────────────────
class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;
  const _EditField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
  });
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: context.textPrimary, fontSize: 14),
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            SizedBox(
              width: 56,
              child: Text(
                label,
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
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
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: disabled ? 0.5 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.14),
                color.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared neumorphic shell (soft, elevated card — two opposing shadows
/// rather than this app's usual glassmorphic `GlassCard`) for a tab's empty
/// state. Each tab supplies its own icon/title/subtitle on top of it.
class _NeumorphicEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _NeumorphicEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.45)
                  : const Color(0xFFB8BEC8).withValues(alpha: 0.6),
              offset: const Offset(6, 6),
              blurRadius: 12,
            ),
            BoxShadow(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.white.withValues(alpha: 0.9),
              offset: const Offset(-6, -6),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: context.textTertiary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textTertiary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Attendance tab's empty state — separately flags the actual reason (no
/// driver assigned vs. a driver assigned but no trips run yet) so an admin
/// knows what to fix rather than just seeing a dead end.
class _AttendanceEmptyState extends StatelessWidget {
  final bool hasDriver;
  const _AttendanceEmptyState({required this.hasDriver});

  @override
  Widget build(BuildContext context) {
    return _NeumorphicEmptyState(
      icon: Icons.assignment_outlined,
      title: 'No attendance records exist for this student.',
      subtitle: hasDriver
          ? 'A driver is assigned, but no trips have been recorded yet.'
          : 'Ensure a driver is assigned to begin tracking trips.',
    );
  }
}

/// Trip History tab's empty state — same reasoning as attendance's.
class _TripHistoryEmptyState extends StatelessWidget {
  final bool hasDriver;
  const _TripHistoryEmptyState({required this.hasDriver});

  @override
  Widget build(BuildContext context) {
    return _NeumorphicEmptyState(
      icon: Icons.route_rounded,
      title: 'No trip history exists for this student.',
      subtitle: hasDriver
          ? 'A driver is assigned, but no trips have been recorded yet.'
          : 'Ensure a driver is assigned to begin tracking trips.',
    );
  }
}

/// Missed Logs tab's empty state — same reasoning as attendance's, but
/// framed for admin triage (an alert-style icon) rather than a routine log.
class _MissedLogsEmptyState extends StatelessWidget {
  final bool hasDriver;
  const _MissedLogsEmptyState({required this.hasDriver});

  @override
  Widget build(BuildContext context) {
    return _NeumorphicEmptyState(
      icon: Icons.fact_check_outlined,
      title: 'No missed logs exist for this student.',
      subtitle: hasDriver
          ? 'A driver is assigned, but no trips have been recorded yet.'
          : 'Ensure a driver is assigned to begin tracking trips.',
    );
  }
}

/// Access tab's empty state — no `hasDriver` distinction, since subscription
/// events are unrelated to whether a driver is assigned.
class _AccessLogsEmptyState extends StatelessWidget {
  const _AccessLogsEmptyState();

  @override
  Widget build(BuildContext context) {
    return const _NeumorphicEmptyState(
      icon: Icons.verified_user_outlined,
      title: 'No access or subscription events recorded for this student.',
      subtitle: 'Events appear here once a subscription change is recorded.',
    );
  }
}

class _LogRow extends StatelessWidget {
  final String date, status;
  final Color color;
  const _LogRow({
    required this.date,
    required this.status,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Text(
              date,
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                status,
                style: TextStyle(color: context.textPrimary, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
