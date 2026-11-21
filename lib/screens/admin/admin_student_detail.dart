import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transit_core/transit_core.dart';
import '../../app/admin_format.dart';
import '../../app/locale_provider.dart';
import '../../data/admin_repository.dart';
import '../../services/audit_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/account_controls.dart';
import '../../widgets/confirm_delete_dialog.dart';
import '../../widgets/entity_widgets.dart';
import '../../widgets/glass_card.dart';
import 'admin_history_tabs.dart';
import 'admin_links.dart';
import 'admin_student_management.dart' show instituteTypeLabel;
import '../../widgets/responsive.dart';

class AdminStudentDetail extends StatefulWidget {
  final String studentId;
  const AdminStudentDetail({super.key, required this.studentId});
  @override
  State<AdminStudentDetail> createState() => _AdminStudentDetailState();
}

class _AdminStudentDetailState extends State<AdminStudentDetail> {
  final _repo = AdminRepository.instance;
  bool _editing = false;
  final _nameCtrl = TextEditingController();
  final _gradeCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController();
  final _medicalCtrl = TextEditingController();
  String _level = 'School';
  bool _saving = false;
  // Set in `initState` (not a field initializer — `widget` isn't attached
  // yet at that point) exactly once, same fix applied across every other
  // screen in this app that built its stream inline inside `build()`.
  late final Stream<Student?> _studentStream;
  final _historyKey = GlobalKey();

  /// The account that uses the app for this student — their own for a
  /// self-registered student, the parent's for a child (see
  /// [primaryAccountIdFor]). Re-created only if that id changes.
  String? _accountId;
  Stream<AccountRecord?>? _accountStream;

  Stream<AccountRecord?> _accountFor(Student s) {
    final id = primaryAccountIdFor(s);
    if (id != _accountId || _accountStream == null) {
      _accountId = id;
      _accountStream = _repo.watchUserRecord(id);
    }
    return _accountStream!;
  }

  /// The parent's name for an audit line, when this is a child.
  String? _parentName;

  @override
  void initState() {
    super.initState();
    _studentStream = widget.studentId.isEmpty
        ? Stream.value(null)
        : _repo.watchStudent(widget.studentId);
    LocaleProvider.instance.addListener(_onLangChanged);
  }

  void _onLangChanged() => setState(() {});

  @override
  void dispose() {
    LocaleProvider.instance.removeListener(_onLangChanged);
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
    _level = studentLevel(s);
    setState(() => _editing = true);
  }

  Future<void> _save(Student s) async {
    setState(() => _saving = true);
    try {
      final name = _nameCtrl.text.trim();
      final grade = _gradeCtrl.text.trim();
      final school = _schoolCtrl.text.trim();
      final medical = _medicalCtrl.text.trim();
      await _repo.updateStudent(s.id, {
        'name': name,
        'grade': grade,
        'school': school,
        'instituteType': _level,
        'medicalNotes': medical,
      });
      final changes = [
        if (name != s.name) AuditChange('Name', s.name, name),
        if (grade != s.grade) AuditChange('Grade', s.grade, grade),
        if (school != s.school) AuditChange('School', s.school, school),
        if (_level != studentLevel(s))
          AuditChange('Level', studentLevel(s), _level),
        if (medical != (s.medicalNotes ?? ''))
          const AuditChange('Medical notes', 'previous text', 'updated'),
      ];
      if (changes.isNotEmpty) {
        await AuditService.instance.logAction(
          actionType: AuditActionType.update,
          action: AuditActions.studentEdit,
          targetEntityId: s.id,
          targetType: 'student',
          targetName: name.isEmpty ? s.name : name,
          targetRole: _studentRole(s),
          description: 'Edited student ${name.isEmpty ? s.name : name}',
          changes: changes,
        );
      }
      if (mounted) {
        setState(() => _editing = false);
        _msg('Saved');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// "Student" for a self-registered student, "Student (child of Sara)"
  /// for a child.
  String _studentRole(Student s) {
    if (isSelfRegistered(s)) return 'Student (own account)';
    final parent = (_parentName ?? '').trim();
    return parent.isEmpty ? 'Student (child)' : 'Student (child of $parent)';
  }

  Future<void> _toggleSuspended(Student s) async {
    final suspending = !s.isTransportSuspended;
    final ok = await showAccountConfirmDialog(
      context,
      title: suspending
          ? 'Suspend transport for ${s.name}?'
          : 'Re-enable transport for ${s.name}?',
      lines: [
        suspending
            ? 'The student is taken off transport until you re-enable it. '
                  'The account itself is not changed.'
            : 'The student can use transport again.',
      ],
      confirmLabel: suspending
          ? AppStrings.t('suspend_action')
          : AppStrings.t('re_enable_action'),
      color: suspending ? AppTheme.warning : AppTheme.success,
    );
    if (!ok) return;
    await _repo.updateStudent(s.id, {'isTransportSuspended': suspending});
    await AuditService.instance.logAction(
      actionType: AuditActionType.statusChange,
      action: AuditActions.studentTransport,
      targetEntityId: s.id,
      targetType: 'student',
      targetName: s.name,
      targetRole: _studentRole(s),
      description: suspending
          ? 'Suspended transport for ${s.name}'
          : 'Re-enabled transport for ${s.name}',
      changes: [
        AuditChange(
          'Transport',
          suspending ? 'Active' : 'Suspended',
          suspending ? 'Suspended' : 'Active',
        ),
      ],
    );
    if (mounted) {
      _msg(
        s.isTransportSuspended ? 'Transport re-enabled' : 'Transport suspended',
      );
    }
  }

  /// Removes (archives) a child of a parent — see
  /// `AdminRepository.deleteStudent`'s doc comment. Does not touch the
  /// parent's own account. A self-registered student is an account and
  /// uses the account controls instead.
  Future<void> _deleteStudent(Student s) async {
    final confirmed = await showConfirmDeleteDialog(context);
    if (!confirmed) return;
    await _repo.deleteStudent(s.id);
    await AuditService.instance.logAction(
      actionType: AuditActionType.delete,
      action: AuditActions.studentArchive,
      targetEntityId: s.id,
      targetType: 'student',
      targetName: s.name,
      targetRole: _studentRole(s),
      description: 'Removed student ${s.name}',
      changes: const [AuditChange('Student record', 'Active', 'Archived')],
      details: [
        if (s.parentId.trim().isNotEmpty)
          AuditDetail(
            'Parent',
            '${(_parentName ?? '').isEmpty ? 'Unknown' : _parentName} '
                '(ID ${s.parentId.trim()})',
          ),
        if (s.school.isNotEmpty) AuditDetail('School', s.school),
      ],
    );
    if (mounted) context.pop();
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
    // The account that actually reads the inbox: the student's own when
    // self-registered (`parentId` empty), otherwise the parent's — a child
    // too young to hold a login has no inbox of their own.
    await _repo.messageUser(
      primaryAccountIdFor(s),
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
            stream: _studentStream,
            builder: (context, snap) {
              final s = snap.data;
              final Widget body;
              if (snap.hasError) {
                body = Center(
                  child: LoadErrorView(error: snap.error, what: 'this student'),
                );
              } else if (snap.connectionState == ConnectionState.waiting &&
                  !snap.hasData) {
                body = const Center(child: CircularProgressIndicator());
              } else if (s == null) {
                body = Center(
                  child: Text(
                    'Student not found.',
                    style: TextStyle(color: context.textSecondary),
                  ),
                );
              } else {
                body = StreamBuilder<AccountRecord?>(
                  stream: _accountFor(s),
                  builder: (context, accountSnap) =>
                      _buildBody(context, s, accountSnap),
                );
              }
              return Column(
                children: [
                  _buildHeader(context, s),
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

  Widget _buildHeader(BuildContext context, Student? s) {
    return Container(
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
              AppStrings.t('student_detail_title'),
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (s != null && !_editing)
            Clickable(
              onTap: () => _startEditing(s),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.studentAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.studentAmber.withValues(alpha: 0.25),
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
    );
  }

  Widget _buildBody(
    BuildContext context,
    Student s,
    AsyncSnapshot<AccountRecord?> accountSnap,
  ) {
    final self = isSelfRegistered(s);
    // For a self-registered student an archived student record counts as a
    // deactivated account (the old admin "Delete" archived only that).
    final record = self
        ? accountSnap.data?.withProfileArchived(s.isDeleted)
        : accountSnap.data;
    final account = record?.user;
    if (!self) _parentName = account?.name;
    final accountLoaded =
        accountSnap.hasData ||
        accountSnap.hasError ||
        accountSnap.connectionState == ConnectionState.active ||
        accountSnap.connectionState == ConnectionState.done;
    // One column on a phone; on a wide window the student's record sits
    // left, transport and history right.
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: ResponsiveBody(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TwoPane(
            primary: [
              _buildProfileCard(context, s, record, accountLoaded, self),
              _buildDetailsCard(context, s),
              _buildAccountCard(context, s, account, accountLoaded, self),
              _buildControls(context, s, record, accountLoaded, self),
            ],
            secondary: [
              _buildTransportCard(context, s),
              HistoryTabs(
                // Keyed so a resize across the breakpoint keeps the open tab.
                key: _historyKey,
                color: AppTheme.studentAmber,
                tabs: [
                  (
                    AppStrings.t('attendance_tab'),
                    AttendanceHistoryList(studentIds: [s.id]),
                  ),
                  (
                    AppStrings.t('trip_history_tab'),
                    StudentTripHistoryList(studentId: s.id),
                  ),
                  (
                    AppStrings.t('missed_logs_tab'),
                    MissedBusHistoryList(studentIds: [s.id]),
                  ),
                  (
                    self
                        ? AppStrings.t('access_tab')
                        : '${AppStrings.t('access_tab')} (parent)',
                    AccessLogList(
                      uid: primaryAccountIdFor(s),
                      emptyText: self
                          ? null
                          : 'This child signs in through the parent\'s account; '
                                'no sign-ins recorded for it yet.',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    Student s,
    AccountRecord? record,
    bool accountLoaded,
    bool self,
  ) {
    final account = record?.user;
    final subActive = isStudentSubscriptionActive(account);
    final accountState = record?.state;
    final accountOff =
        accountState != null && accountState != AccountState.active;
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EntityAvatar(
                photoUrl: s.photoUrl,
                color: AppTheme.studentAmber,
                fallbackEmoji: '🎓',
                size: 60,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name.isEmpty ? 'Unnamed student' : s.name,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (s.displayCode.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      SelectableText(
                        s.displayCode,
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        // Transport: whether the admin has suspended rides.
                        Tooltip(
                          message: 'Transport',
                          child: StatusBadge(
                            label: s.isTransportSuspended
                                ? AppStrings.t('suspended_status')
                                : AppStrings.t('active_lbl'),
                            color: s.isTransportSuspended
                                ? AppTheme.warning
                                : AppTheme.success,
                          ),
                        ),
                        // Subscription: a purchased plan on the account that
                        // pays — the student's own, or the parent's. This
                        // chip used to read the student document's own
                        // `subscriptionStatus`, which defaults to `active`
                        // and nothing ever changes, so it said "Active" for
                        // everyone.
                        Tooltip(
                          message: self
                              ? 'Subscription on the student\'s own account'
                              : 'Subscription on the parent\'s account',
                          child: StatusBadge(
                            label: !accountLoaded
                                ? '💳 …'
                                : '💳 ${subActive ? 'Active' : 'Inactive'}',
                            color: !accountLoaded
                                ? const Color(0xFF94A3B8)
                                : (subActive
                                      ? AppTheme.success
                                      : AppTheme.error),
                          ),
                        ),
                        if (accountLoaded)
                          PresenceBadge(
                            user: account,
                            prefix: self ? null : 'Parent',
                          ),
                        // A self-registered student's own account state.
                        if (self && accountState != null)
                          AccountStatusBadge(state: accountState),
                        if (!self && s.isDeleted)
                          const StatusBadge(
                            label: 'Archived',
                            color: AppTheme.error,
                          ),
                        if (!self && accountOff)
                          StatusBadge(
                            label:
                                'Parent account '
                                '${accountStateLabel(accountState).toLowerCase()}',
                            color: accountStateColor(accountState),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (self && record != null && accountOff) ...[
            const SizedBox(height: 8),
            AccountStateNote(record: record),
          ],
          if (accountLoaded) ...[
            const SizedBox(height: 12),
            Text(
              self ? 'App activity' : 'App activity (parent\'s account)',
              style: TextStyle(
                color: context.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            LastSeenLine(user: account, fontSize: 12),
          ],
          if (_editing) ...[
            const SizedBox(height: 14),
            _EditField(label: AppStrings.t('name_lbl'), controller: _nameCtrl),
            const SizedBox(height: 12),
            _LevelPicker(
              value: _level,
              onChanged: (v) => setState(() => _level = v),
            ),
            const SizedBox(height: 12),
            _EditField(
              label: AppStrings.t('grade_lbl'),
              controller: _gradeCtrl,
            ),
            const SizedBox(height: 12),
            _EditField(
              label: AppStrings.t('school_lbl'),
              controller: _schoolCtrl,
            ),
            const SizedBox(height: 12),
            _EditField(
              label: AppStrings.t('medical_notes_lbl'),
              controller: _medicalCtrl,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    label: AppStrings.t('cancel_action'),
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
                    label: _saving
                        ? AppStrings.t('saving_action')
                        : AppStrings.t('save_action'),
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
    );
  }

  Widget _buildDetailsCard(BuildContext context, Student s) {
    return SectionCard(
      title: AppStrings.t('details_title'),
      icon: Icons.badge_rounded,
      color: AppTheme.studentAmber,
      child: Column(
        children: [
          InfoLine(
            icon: Icons.layers_rounded,
            label: 'Level',
            value: instituteTypeLabel(studentLevel(s)),
            color: AppTheme.purple,
          ),
          InfoLine(
            icon: Icons.school_rounded,
            label: AppStrings.t('school_lbl'),
            value: s.school.isEmpty ? '—' : s.school,
            color: AppTheme.purple,
          ),
          InfoLine(
            icon: Icons.grade_rounded,
            label: AppStrings.t('grade_lbl'),
            value: s.grade.isEmpty ? '—' : s.grade,
            color: AppTheme.purple,
          ),
          if (s.studentIdNumber.trim().isNotEmpty)
            InfoLine(
              icon: Icons.numbers_rounded,
              label: 'Roll number',
              value: s.studentIdNumber.trim(),
              color: AppTheme.info,
            ),
          if ((s.medicalNotes ?? '').isNotEmpty)
            InfoLine(
              icon: Icons.medical_information_rounded,
              label: 'Medical',
              value: s.medicalNotes!,
              color: AppTheme.error,
            ),
          if (s.createdAt != null)
            InfoLine(
              icon: Icons.event_rounded,
              label: 'Registered',
              value: formatDate(s.createdAt!),
              color: AppTheme.info,
            ),
        ],
      ),
    );
  }

  /// Who drives this student and between which two points: the booked
  /// driver (a link to their own detail screen, not a copy of their data),
  /// the agreed fee, the home pickup pin and the institute drop-off pin.
  Widget _buildTransportCard(BuildContext context, Student s) {
    final fee = s.monthlyFeePaisa;
    return SectionCard(
      title: 'Transport',
      icon: Icons.directions_bus_rounded,
      color: AppTheme.driverCyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (s.hasDriver)
            DriverLink(driverId: s.driverId!, scheduleId: s.scheduleId)
          else
            InfoLine(
              icon: Icons.directions_bus_rounded,
              label: 'Booked driver',
              value: AppStrings.t('unassigned_status'),
              color: AppTheme.warning,
            ),
          if (s.hasDriver)
            InfoLine(
              icon: Icons.payments_rounded,
              label: 'Agreed fee',
              value: fee > 0
                  ? '${formatRupees(fee)} / month'
                        '${s.feeStartedAt == null ? '' : ' · since ${formatDate(s.feeStartedAt!)}'}'
                  : 'No fee agreed yet',
              color: AppTheme.adminEmerald,
            ),
          LocationBlock(
            title: 'Pickup point (home)',
            coord: s.pickupLocation,
            icon: Icons.home_rounded,
            color: AppTheme.parentPurple,
          ),
          LocationBlock(
            title: 'Drop-off point (institute)',
            name: s.school,
            coord: s.dropoffLocation,
            icon: Icons.school_rounded,
            color: AppTheme.studentAmber,
          ),
        ],
      ),
    );
  }

  /// The parent (a link to their detail screen) or, for a self-registered
  /// student, their own account — contact details and every emergency
  /// contact on file at both levels.
  Widget _buildAccountCard(
    BuildContext context,
    Student s,
    AppUser? account,
    bool accountLoaded,
    bool self,
  ) {
    final guardian = [
      if (s.guardianName.isNotEmpty) s.guardianName,
      if (s.guardianPhone.isNotEmpty) s.guardianPhone,
    ].join(' · ');
    return SectionCard(
      title: self ? 'Account & contacts' : 'Parent & contacts',
      icon: self ? Icons.person_rounded : Icons.family_restroom_rounded,
      color: AppTheme.parentPurple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!self)
            InfoLine(
              icon: Icons.family_restroom_rounded,
              label: 'Parent',
              value: !accountLoaded
                  ? 'Loading…'
                  : account == null
                  ? 'Parent account not found'
                  : '${account.name.isEmpty ? 'Unnamed parent' : account.name}'
                        '${isAccountDeactivated(account) ? ' (deactivated)' : ''}',
              color: AppTheme.parentPurple,
              onTap: () => openParentDetail(context, s.parentId.trim()),
            )
          else
            const InfoLine(
              icon: Icons.person_rounded,
              label: 'Account',
              value: 'Self-registered student',
              color: AppTheme.parentPurple,
            ),
          InfoLine(
            icon: Icons.phone_rounded,
            label: AppStrings.t('phone_lbl'),
            value: (account?.phone ?? '').isNotEmpty
                ? account!.phone
                : (s.guardianPhone.isNotEmpty ? s.guardianPhone : '—'),
            color: AppTheme.adminEmerald,
          ),
          InfoLine(
            icon: Icons.email_rounded,
            label: AppStrings.t('email_lbl'),
            value: (account?.email ?? '').isNotEmpty ? account!.email : '—',
            color: AppTheme.driverCyan,
          ),
          if (!self && guardian.isNotEmpty)
            InfoLine(
              icon: Icons.shield_rounded,
              label: 'Guardian',
              value: guardian,
              color: AppTheme.info,
            ),
          const SizedBox(height: 4),
          EmergencyContactsBlock(
            title: 'Emergency contacts on the student record',
            contacts: s.emergencyContacts,
          ),
          const SizedBox(height: 4),
          EmergencyContactsBlock(
            title: self
                ? 'Emergency contacts on the account'
                : 'Emergency contacts on the parent\'s account',
            contacts: account?.emergencyContacts ?? const [],
          ),
        ],
      ),
    );
  }

  Widget _buildControls(
    BuildContext context,
    Student s,
    AccountRecord? record,
    bool accountLoaded,
    bool self,
  ) {
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
                  label: s.isTransportSuspended
                      ? 'Re-enable' // not requested this pass
                      : AppStrings.t('suspend_action'),
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
                  label: AppStrings.t('message_action'),
                  color: AppTheme.studentAmber,
                  icon: Icons.chat_bubble_rounded,
                  onTap: () => _message(s),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // A self-registered student is an account of their own:
          // Deactivate / Activate / Delete permanently, like a parent or a
          // driver. A child has no sign-in; removing it archives the
          // record, as before.
          if (self) ...[
            const SizedBox(height: 4),
            Text(
              AppStrings.t('account_section'),
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (record != null)
              AccountControls(
                record: record,
                deleteNote: AppStrings.t('delete_student_note'),
              )
            else
              Text(
                accountLoaded ? AppStrings.t('no_account_record') : '…',
                style: TextStyle(color: context.textSecondary, fontSize: 12),
              ),
          ] else
            SizedBox(
              width: double.infinity,
              child: _ActionBtn(
                label: AppStrings.t('delete_action'),
                color: AppTheme.error,
                icon: Icons.delete_outline_rounded,
                onTap: s.isDeleted ? null : () => _deleteStudent(s),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ────────────────────────────────────────────────────────────

/// Level choice for the edit form: School / College / University / Academy.
/// A record holding some other free-text value keeps it as an option, so
/// opening the editor never silently rewrites it.
class _LevelPicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _LevelPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = [
      ...instituteLevels,
      if (!instituteLevels.contains(value)) value,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Level',
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in options)
              ChoiceChip(
                label: Text(instituteTypeLabel(o)),
                selected: o == value,
                onSelected: (_) => onChanged(o),
                selectedColor: AppTheme.studentAmber.withValues(alpha: 0.25),
                labelStyle: TextStyle(
                  color: o == value
                      ? AppTheme.studentOrange
                      : context.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Label-outside layout — the localized label sits above the Neumorphic
/// input box (not as a Material floating label riding on the box's top
/// border), so a wider Urdu label never clips against the box's edge the
/// way a floating label did.
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
    final isDark = context.isDark;
    return Column(
      // start = right-aligned under Urdu/RTL, left-aligned under
      // English/LTR — the ambient Directionality already flips this.
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.45)
                    : const Color(0xFFB8BEC8).withValues(alpha: 0.6),
                offset: const Offset(4, 4),
                blurRadius: 10,
              ),
              BoxShadow(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.white.withValues(alpha: 0.9),
                offset: const Offset(-4, -4),
                blurRadius: 10,
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: TextStyle(color: context.textPrimary, fontSize: 14),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
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
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
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
