import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transit_core/transit_core.dart';
import '../../app/admin_format.dart';
import '../../app/locale_provider.dart';
import '../../data/admin_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/entity_widgets.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/mini_stat.dart';
import '../../widgets/responsive.dart';

// `student.instituteType`/`student.grade` are free-text data fields (a
// school can type anything into the signup form), not a fixed Dart enum —
// only the two known common values this task named get translated; anything
// else (the default 'School', or a custom grade like 'Grade 5') passes
// through unchanged, exactly like a student's own name is never translated.
String instituteTypeLabel(String type) => switch (type) {
  'University' => AppStrings.t('university_type'),
  'College' => AppStrings.t('college_type'),
  'Academy' => AppStrings.t('academy_type'),
  'School' => AppStrings.t('school_type'),
  _ => type,
};

// Education-level filter dropdown — distinct from `instituteTypeLabel`
// above (which displays whatever free-text value a student's own record
// happens to hold) because the filter only ever offers these fixed
// options, regardless of what custom values exist in the data.
const _levelFilters = ['All', ...instituteLevels];

String _levelFilterDisplay(String level) => switch (level) {
  'All' => AppStrings.t('all_levels_filter'),
  _ => instituteTypeLabel(level),
};

// `Student.instituteType` is a free-text field (a school can type anything
// into the signup form) that defaults to empty for a school-level student
// rather than literally storing 'School' — so the 'School' filter matches
// both the empty default and an explicit 'School' value, the same
// either-or already used for the institute label shown on each card.
bool _matchesLevel(Student s, String level) =>
    level == 'All' || studentLevel(s) == level;

// An active student with no driver needs admin attention (nobody will pick
// them up); a suspended student with no driver is expected, not a problem —
// so only the active+unassigned combination is flagged.
bool _needsDriverAttention(Student s) =>
    (s.driverId ?? '').isEmpty && !s.isTransportSuspended;

String subscriptionStatusLabel(SubscriptionStatus s) => switch (s) {
  SubscriptionStatus.active => 'Active',
  SubscriptionStatus.trial => 'Trial',
  SubscriptionStatus.gracePeriod => 'Grace Period',
  SubscriptionStatus.expired => 'Expired',
  SubscriptionStatus.suspended => 'Suspended',
  SubscriptionStatus.cancelled => 'Cancelled',
};

Color subscriptionStatusColor(SubscriptionStatus s) => switch (s) {
  SubscriptionStatus.active => const Color(0xFF10B981),
  SubscriptionStatus.trial => const Color(0xFF3B82F6),
  SubscriptionStatus.gracePeriod => const Color(0xFFF59E0B),
  SubscriptionStatus.expired => const Color(0xFFEF4444),
  SubscriptionStatus.suspended => const Color(0xFFF59E0B),
  SubscriptionStatus.cancelled => const Color(0xFFEF4444),
};

class AdminStudentManagement extends StatefulWidget {
  const AdminStudentManagement({super.key});
  @override
  State<AdminStudentManagement> createState() => _AdminStudentManagementState();
}

class _AdminStudentManagementState extends State<AdminStudentManagement> {
  String _search = '';
  String _levelFilter = 'All';
  // Constructed once — see the identical note on
  // `_AdminDriverManagementState._driversStream`.
  // Archived self-registered students stay listed (badged Deactivated or
  // Deleted) — they are accounts, and can be activated again.
  late final Stream<List<Student>> _studentsStream = AdminRepository.instance
      .watchStudents(includeArchivedSelfRegistered: true);

  // The accounts behind the students — a self-registered student's own
  // `users` doc, a child's parent's — for presence and the subscription
  // chip. Deleted accounts are kept: a child of a parent who deleted their
  // account must read "Inactive", not fall back to looking fine.
  late final Stream<List<AccountRecord>> _studentUsersStream = AdminRepository
      .instance
      .watchAccountsByRole(UserRole.student);
  late final Stream<List<AppUser>> _parentUsersStream = AdminRepository.instance
      .watchUsersByRole(UserRole.parent, includeDeleted: true);

  @override
  void initState() {
    super.initState();
    LocaleProvider.instance.addListener(_onLangChanged);
  }

  void _onLangChanged() => setState(() {});

  @override
  void dispose() {
    LocaleProvider.instance.removeListener(_onLangChanged);
    super.dispose();
  }

  List<Student> _filtered(
    List<Student> students,
    Map<String, AccountRecord> records,
  ) {
    final q = _search.trim().toLowerCase();
    final list = students
        .where(
          (s) =>
              (q.isEmpty ||
                  s.name.toLowerCase().contains(q) ||
                  s.school.toLowerCase().contains(q) ||
                  s.displayCode.toLowerCase().contains(q)) &&
              _matchesLevel(s, _levelFilter),
        )
        .toList();
    // Deactivated and deleted student accounts sink to the bottom.
    list.sort(
      (a, b) => _ownAccountState(
        a,
        records,
      ).index.compareTo(_ownAccountState(b, records).index),
    );
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AccountRecord>>(
      stream: _studentUsersStream,
      builder: (context, studentUsersSnap) => StreamBuilder<List<AppUser>>(
        stream: _parentUsersStream,
        builder: (context, parentUsersSnap) {
          final studentRecords = <String, AccountRecord>{
            for (final r in studentUsersSnap.data ?? const <AccountRecord>[])
              r.uid: r,
          };
          final accounts = <String, AppUser>{
            for (final u in parentUsersSnap.data ?? const <AppUser>[]) u.uid: u,
            for (final r in studentRecords.values) r.uid: r.user,
          };
          final accountsLoaded =
              studentUsersSnap.hasData && parentUsersSnap.hasData;
          return _buildList(context, accounts, studentRecords, accountsLoaded);
        },
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    Map<String, AppUser> accounts,
    Map<String, AccountRecord> studentRecords,
    bool accountsLoaded,
  ) {
    return StreamBuilder<List<Student>>(
      stream: _studentsStream,
      builder: (context, snap) {
        final students = snap.data ?? const <Student>[];
        final filtered = _filtered(students, studentRecords);
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120),
          child: ResponsiveBody(
            child: Column(
              children: [
                _buildHeader(context, students.length),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildSearch(context),
                      const SizedBox(height: 10),
                      _buildLevelFilter(context),
                      const SizedBox(height: 10),
                      _buildStats(context, students),
                      const SizedBox(height: 14),
                      if (snap.hasError)
                        LoadErrorView(error: snap.error, what: 'students')
                      else if (!snap.hasData)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else ...[
                        ResponsiveGrid(
                          children: [
                            for (final s in filtered)
                              _StudentCard(
                                student: s,
                                ownAccount: isSelfRegistered(s)
                                    ? _ownAccountState(s, studentRecords)
                                    : null,
                                account: accounts[primaryAccountIdFor(s)],
                                accountLoaded: accountsLoaded,
                                onTap: () => context.push(
                                  '/admin/student-detail',
                                  extra: s.id,
                                ),
                              ),
                          ],
                        ),
                        if (filtered.isEmpty) _buildEmpty(context),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, int total) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.studentAmber.withValues(alpha: 0.15),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppTheme.studentGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.t('student_management'),
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppStrings.t(
                    'students_enrolled',
                  ).replaceFirst('{count}', '$total'),
                  style: TextStyle(color: context.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(4),
      child: TextField(
        onChanged: (v) => setState(() => _search = v),
        style: TextStyle(color: context.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: AppStrings.t('search_students_hint'),
          prefixIcon: Icon(Icons.search_rounded, color: context.textTertiary),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildLevelFilter(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: _LevelFilterChip(
        label:
            '${AppStrings.t('level_prefix')}: ${_levelFilterDisplay(_levelFilter)}',
        selected: _levelFilter,
        options: _levelFilters,
        displayLabel: _levelFilterDisplay,
        onSelected: (level) => setState(() => _levelFilter = level),
      ),
    );
  }

  Widget _buildStats(BuildContext context, List<Student> students) {
    return Row(
      children: [
        MiniStat(
          icon: Icons.people_rounded,
          label: AppStrings.t('total_lbl'),
          value: '${students.length}',
          color: AppTheme.studentAmber,
        ),
        const SizedBox(width: 8),
        MiniStat(
          icon: Icons.directions_bus_rounded,
          label: AppStrings.t('with_driver_status'),
          value:
              '${students.where((s) => (s.driverId ?? '').isNotEmpty).length}',
          color: AppTheme.success,
        ),
        const SizedBox(width: 8),
        MiniStat(
          icon: Icons.block_rounded,
          label: AppStrings.t('suspended_status'),
          value: '${students.where((s) => s.isTransportSuspended).length}',
          color: AppTheme.warning,
        ),
      ],
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, color: context.textTertiary, size: 48),
          const SizedBox(height: 12),
          Text(
            'No students match your search',
            style: TextStyle(color: context.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/// A self-registered student's own account state (an archived student
/// record counts as Deactivated). A child has no account — always Active
/// here; its parent's state shows on the parent.
AccountState _ownAccountState(Student s, Map<String, AccountRecord> records) {
  if (!isSelfRegistered(s)) return AccountState.active;
  final record = records[s.id];
  if (record == null) {
    return s.isDeleted ? AccountState.deactivated : AccountState.active;
  }
  return record.withProfileArchived(s.isDeleted).state;
}

// ─── Student Card ────────────────────────────────────────────────────────────
class _StudentCard extends StatelessWidget {
  final Student student;

  /// The student's own account state — self-registered students only.
  final AccountState? ownAccount;

  /// The account that uses the app for this student: their own when
  /// self-registered, otherwise their parent's (see [primaryAccountIdFor]).
  final AppUser? account;
  final bool accountLoaded;
  final VoidCallback onTap;
  const _StudentCard({
    required this.student,
    required this.ownAccount,
    required this.account,
    required this.accountLoaded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subActive = isStudentSubscriptionActive(account);
    final sub = [
      instituteTypeLabel(studentLevel(student)),
      if (student.school.isNotEmpty) student.school,
      if (student.grade.isNotEmpty) student.grade,
    ].join(' • ');
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              EntityAvatar(
                photoUrl: student.photoUrl,
                color: AppTheme.studentAmber,
                fallbackEmoji: '🎓',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: context.textTertiary),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (ownAccount != null) AccountStatusBadge(state: ownAccount!),
              _InfoPill(
                icon: _needsDriverAttention(student)
                    ? Icons.warning_amber_rounded
                    : Icons.directions_bus_rounded,
                label: (student.driverId ?? '').isEmpty
                    ? AppStrings.t('no_driver_status')
                    : 'Assigned', // not in the requested term list
                color: _needsDriverAttention(student)
                    ? AppTheme.warning
                    : AppTheme.driverCyan,
              ),
              // Transport on/off for this student (an admin can suspend it).
              StatusBadge(
                label: student.isTransportSuspended
                    ? AppStrings.t('suspended_status')
                    : AppStrings.t('active_lbl'),
                color: student.isTransportSuspended
                    ? AppTheme.warning
                    : AppTheme.success,
              ),
              // Purchased subscription on the account that pays.
              Tooltip(
                message: isSelfRegistered(student)
                    ? "Subscription on the student's own account"
                    : "Subscription on the parent's account",
                child: StatusBadge(
                  label: !accountLoaded
                      ? '💳 …'
                      : '💳 ${subActive ? 'Active' : 'Inactive'}',
                  color: !accountLoaded
                      ? const Color(0xFF94A3B8)
                      : (subActive ? AppTheme.success : AppTheme.error),
                ),
              ),
              if (accountLoaded)
                PresenceBadge(
                  user: account,
                  prefix: isSelfRegistered(student) ? null : 'Parent',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Education-level filter pill — opens a [PopupMenuButton] menu on tap,
/// matching the same pill-plus-dropdown pattern used for the status filter
/// on Driver Management (`_StatusFilterChip`).
class _LevelFilterChip extends StatelessWidget {
  final String label;
  final String selected;
  final List<String> options;
  final String Function(String option) displayLabel;
  final ValueChanged<String> onSelected;
  const _LevelFilterChip({
    required this.label,
    required this.selected,
    required this.options,
    required this.displayLabel,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: selected,
      onSelected: onSelected,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (context) => options
          .map(
            (option) => PopupMenuItem<String>(
              value: option,
              child: Text(displayLabel(option)),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.surfaceBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_outlined, size: 14, color: AppTheme.studentAmber),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.unfold_more_rounded,
              size: 14,
              color: context.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared sub-widgets ─────────────────────────────────────────────────────
class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
