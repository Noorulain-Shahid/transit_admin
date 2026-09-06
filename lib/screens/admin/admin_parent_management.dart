import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transit_core/transit_core.dart';
import '../../data/admin_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class AdminParentManagement extends StatefulWidget {
  const AdminParentManagement({super.key});
  @override
  State<AdminParentManagement> createState() => _AdminParentManagementState();
}

class _AdminParentManagementState extends State<AdminParentManagement> {
  String _search = '';

  List<AppUser> _filtered(List<AppUser> parents) => parents
      .where(
        (p) =>
            _search.isEmpty ||
            p.name.toLowerCase().contains(_search.toLowerCase()) ||
            p.email.toLowerCase().contains(_search.toLowerCase()),
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppUser>>(
      stream: AdminRepository.instance.watchUsersByRole(UserRole.parent),
      builder: (context, parentSnap) {
        final parents = parentSnap.data ?? const <AppUser>[];
        final filtered = _filtered(parents);
        return StreamBuilder<List<Student>>(
          stream: AdminRepository.instance.watchStudents(),
          builder: (context, studentSnap) {
            final childrenByParent = <String, List<Student>>{};
            for (final s in studentSnap.data ?? const <Student>[]) {
              childrenByParent.putIfAbsent(s.parentId, () => []).add(s);
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
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
                        if (!parentSnap.hasData)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else ...[
                          ...filtered.map(
                            (p) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _ParentCard(
                                parent: p,
                                children: childrenByParent[p.uid] ?? const [],
                                onTap: () => context.push(
                                  '/admin/parent-detail',
                                  extra: p.uid,
                                ),
                              ),
                            ),
                          ),
                          if (filtered.isEmpty) _buildEmpty(context),
                        ],
                      ],
                    ),
                  ),
                ],
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
                  'Parent Management',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$total parents registered',
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
          hintText: 'Search parents...',
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

  Widget _buildStats(BuildContext context, List<AppUser> parents) {
    return Row(
      children: [
        _MiniStat(
          icon: Icons.people_rounded,
          label: 'Total',
          value: '${parents.length}',
          color: AppTheme.parentPurple,
        ),
        const SizedBox(width: 8),
        _MiniStat(
          icon: Icons.check_circle_rounded,
          label: 'Active',
          value: '${parents.where((p) => p.isActive).length}',
          color: AppTheme.success,
        ),
        const SizedBox(width: 8),
        _MiniStat(
          icon: Icons.pause_circle_rounded,
          label: 'Inactive',
          value: '${parents.where((p) => !p.isActive).length}',
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
  final AppUser parent;
  final List<Student> children;
  final VoidCallback onTap;
  const _ParentCard({
    required this.parent,
    required this.children,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppTheme.parentPurple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.parentPurple.withValues(alpha: 0.2),
                  ),
                ),
                child: const Center(
                  child: Text('👨‍👩‍👧', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parent.name,
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
                          : (parent.phone.isEmpty
                                ? parent.email
                                : parent.phone),
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
          Row(
            children: [
              StatusBadge(
                label:
                    '${children.length} ${children.length == 1 ? 'child' : 'children'}',
                color: AppTheme.parentPurple,
              ),
              const SizedBox(width: 6),
              StatusBadge(
                label: parent.isActive ? 'Active' : 'Inactive',
                color: parent.isActive ? AppTheme.success : AppTheme.error,
              ),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.12),
            color.withValues(alpha: 0.04),
          ],
        ),
        borderColor: color.withValues(alpha: 0.18),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: context.textSecondary, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
