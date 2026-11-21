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

// Urdu doesn't inflect for count the way English's child/children does, but
// "1 بچہ" (1 child) still reads oddly with the plain plural, so this keeps
// the same singular/plural branch the English string had, translated.
String _childrenLabel(int count) =>
    '$count ${count == 1 ? AppStrings.t('child_singular') : AppStrings.t('children_plural')}';

class AdminParentManagement extends StatefulWidget {
  const AdminParentManagement({super.key});
  @override
  State<AdminParentManagement> createState() => _AdminParentManagementState();
}

class _AdminParentManagementState extends State<AdminParentManagement> {
  String _search = '';
  // Constructed once each — see the identical note on
  // `_AdminDriverManagementState._driversStream`.
  //
  // Deleted parents are deliberately *included*: an account the parent
  // deleted, or an admin deactivated or deleted, used to vanish from this
  // list. It now stays, badged Active / Deactivated / Deleted.
  late final Stream<List<AccountRecord>> _parentsStream = AdminRepository
      .instance
      .watchAccountsByRole(UserRole.parent);
  late final Stream<List<Student>> _studentsStream = AdminRepository.instance
      .watchStudents();

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

  /// Search over name, email and phone; Active accounts first, then
  /// Deactivated, then Deleted, each by name — so a list full of
  /// tombstones doesn't bury the live families.
  List<AccountRecord> _filtered(List<AccountRecord> parents) {
    final q = _search.trim().toLowerCase();
    final list = parents.where((r) {
      final p = r.user;
      return q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.email.toLowerCase().contains(q) ||
          p.phone.toLowerCase().contains(q);
    }).toList();
    list.sort((a, b) {
      final byState = a.state.index.compareTo(b.state.index);
      if (byState != 0) return byState;
      return a.user.name.toLowerCase().compareTo(b.user.name.toLowerCase());
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AccountRecord>>(
      stream: _parentsStream,
      builder: (context, parentSnap) {
        final parents = parentSnap.data ?? const <AccountRecord>[];
        final filtered = _filtered(parents);
        return StreamBuilder<List<Student>>(
          stream: _studentsStream,
          builder: (context, studentSnap) {
            final childrenByParent = <String, List<Student>>{};
            for (final s in studentSnap.data ?? const <Student>[]) {
              childrenByParent.putIfAbsent(s.parentId, () => []).add(s);
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              child: ResponsiveBody(
                child: Column(
                  children: [
                    _buildHeader(context, parents.length),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _buildSearch(context),
                          const SizedBox(height: 10),
                          _buildStats(context, parents),
                          const SizedBox(height: 14),
                          if (parentSnap.hasError)
                            LoadErrorView(
                              error: parentSnap.error,
                              what: 'parents',
                            )
                          else if (!parentSnap.hasData)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else ...[
                            ResponsiveGrid(
                              children: [
                                for (final p in filtered)
                                  _ParentCard(
                                    record: p,
                                    children:
                                        childrenByParent[p.uid] ?? const [],
                                    onTap: () => context.push(
                                      '/admin/parent-detail',
                                      extra: p.uid,
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
            AppTheme.parentPurple.withValues(alpha: 0.15),
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
              gradient: AppTheme.parentGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.family_restroom_rounded,
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
                  AppStrings.t('parent_management'),
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppStrings.t(
                    'parents_registered',
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
          hintText: AppStrings.t('search_parents_hint'),
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

  Widget _buildStats(BuildContext context, List<AccountRecord> parents) {
    int count(AccountState s) => parents.where((p) => p.state == s).length;
    return Row(
      children: [
        MiniStat(
          icon: Icons.people_rounded,
          label: AppStrings.t('total_lbl'),
          value: '${parents.length}',
          color: AppTheme.parentPurple,
        ),
        const SizedBox(width: 8),
        MiniStat(
          icon: Icons.check_circle_rounded,
          label: AppStrings.t('active_lbl'),
          value: '${count(AccountState.active)}',
          color: AppTheme.success,
        ),
        const SizedBox(width: 8),
        MiniStat(
          icon: Icons.pause_circle_rounded,
          label: AppStrings.t('deactivated_status'),
          value: '${count(AccountState.deactivated)}',
          color: AppTheme.warning,
        ),
        const SizedBox(width: 8),
        MiniStat(
          icon: Icons.delete_forever_rounded,
          label: AppStrings.t('deleted_status'),
          value: '${count(AccountState.deleted)}',
          color: AppTheme.error,
        ),
      ],
    );
  }

  Widget _buildEmpty(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Column(
      children: [
        Icon(Icons.search_off_rounded, color: context.textTertiary, size: 48),
        const SizedBox(height: 12),
        Text(
          'No parents match your search',
          style: TextStyle(color: context.textSecondary, fontSize: 14),
        ),
      ],
    ),
  );
}

// ─── Parent Card ─────────────────────────────────────────────────────────────
class _ParentCard extends StatelessWidget {
  final AccountRecord record;
  final List<Student> children;
  final VoidCallback onTap;
  const _ParentCard({
    required this.record,
    required this.children,
    required this.onTap,
  });

  AppUser get parent => record.user;

  @override
  Widget build(BuildContext context) {
    final state = record.state;
    final deactivated = state != AccountState.active;
    final contact = [
      if (parent.phone.isNotEmpty) parent.phone,
      if (parent.email.isNotEmpty) parent.email,
    ].join(' • ');
    return Opacity(
      // A tombstone stays readable but visibly isn't a live account.
      opacity: deactivated ? 0.75 : 1,
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                EntityAvatar(
                  photoUrl: parent.photoUrl,
                  color: AppTheme.parentPurple,
                  fallbackEmoji: '👨‍👩‍👧',
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parent.name.isEmpty ? 'Unnamed parent' : parent.name,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        children.isNotEmpty
                            ? children.map((c) => c.name).join(' • ')
                            : (contact.isEmpty
                                  ? 'No contact details'
                                  : contact),
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
              children: [
                AccountStatusBadge(state: state),
                PresenceBadge(user: parent),
                StatusBadge(
                  label: _childrenLabel(children.length),
                  color: AppTheme.parentPurple,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (deactivated) ...[
              Text(
                accountStateReason(record),
                style: TextStyle(
                  color: accountStateColor(state),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
            ],
            LastSeenLine(user: parent),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────
