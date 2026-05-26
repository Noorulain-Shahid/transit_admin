import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import 'admin_user_models.dart';

class AdminParentManagement extends StatefulWidget {
  const AdminParentManagement({super.key});
  @override
  State<AdminParentManagement> createState() => _AdminParentManagementState();
}

class _AdminParentManagementState extends State<AdminParentManagement> {
  String _search = '';
  String _filterPlan = 'All';

  List<ParentRecord> get _filtered => mockParents.where((p) {
    if (_search.isNotEmpty && !p.name.toLowerCase().contains(_search.toLowerCase())) return false;
    if (_filterPlan != 'All' && p.planLabel != _filterPlan) return false;
    return true;
  }).toList();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 120),
      child: Column(children: [
        _buildHeader(context),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(children: [
          _buildSearch(context),
          const SizedBox(height: 10),
          _buildFilters(),
          const SizedBox(height: 12),
          _buildStats(context),
          const SizedBox(height: 12),

          // Plan cards
          GlassCard(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Subscription Plans', style: TextStyle(color: context.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Row(children: [
              _PlanBadge(name: 'Basic', price: '₨300', desc: '1 child', color: const Color(0xFF94A3B8), icon: Icons.star_border_rounded),
              const SizedBox(width: 8),
              _PlanBadge(name: 'Standard', price: '₨700', desc: '2-3 kids', color: AppTheme.info, icon: Icons.star_half_rounded),
              const SizedBox(width: 8),
              _PlanBadge(name: 'Premium', price: '₨1200', desc: 'Unlimited', color: AppTheme.purple, icon: Icons.star_rounded),
            ]),
          ])),
          const SizedBox(height: 14),

          // Parent list
          ..._filtered.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ParentCard(parent: p, onTap: () => context.push('/admin/parent-detail', extra: p)),
          )),
          if (_filtered.isEmpty) _buildEmpty(context),
        ])),
      ]),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [AppTheme.parentPurple.withValues(alpha: 0.15), Colors.transparent])),
      child: Row(children: [
        Container(width: 44, height: 44,
          decoration: BoxDecoration(gradient: AppTheme.parentGradient, borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.family_restroom_rounded, color: Colors.white, size: 24)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Parent Management', style: TextStyle(color: context.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text('${mockParents.length} parents registered', style: TextStyle(color: context.textSecondary, fontSize: 13)),
        ])),
        GestureDetector(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add parent form'))),
          child: Container(width: 40, height: 40,
            decoration: BoxDecoration(gradient: AppTheme.parentGradient, borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: AppTheme.parentPurple.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 22)),
        ),
      ]),
    );
  }

  Widget _buildSearch(BuildContext context) {
    return GlassCard(padding: const EdgeInsets.all(4), child: TextField(
      onChanged: (v) => setState(() => _search = v),
      style: TextStyle(color: context.textPrimary, fontSize: 14),
      decoration: InputDecoration(hintText: 'Search parents...', prefixIcon: Icon(Icons.search_rounded, color: context.textTertiary),
        border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
    ));
  }

  Widget _buildFilters() {
    return SizedBox(height: 36, child: ListView(scrollDirection: Axis.horizontal, children: [
      _FilterChip(label: 'Plan: $_filterPlan', icon: Icons.workspace_premium_rounded, color: AppTheme.parentPurple, onTap: () {
        final p = ['All', 'Basic', 'Standard', 'Premium'];
        setState(() => _filterPlan = p[(p.indexOf(_filterPlan) + 1) % p.length]);
      }),
    ]));
  }

  Widget _buildStats(BuildContext context) {
    return Row(children: [
      _MiniStat(icon: Icons.people_rounded, label: 'Total', value: '${mockParents.length}', color: AppTheme.parentPurple),
      const SizedBox(width: 8),
      _MiniStat(icon: Icons.check_circle_rounded, label: 'Active', value: '${mockParents.where((p) => p.status == SubscriptionStatus.active).length}', color: AppTheme.success),
      const SizedBox(width: 8),
      _MiniStat(icon: Icons.error_rounded, label: 'Expired', value: '${mockParents.where((p) => p.status == SubscriptionStatus.expired).length}', color: AppTheme.error),
    ]);
  }

  Widget _buildEmpty(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 40),
    child: Column(children: [
      Icon(Icons.search_off_rounded, color: context.textTertiary, size: 48), const SizedBox(height: 12),
      Text('No parents match your filters', style: TextStyle(color: context.textSecondary, fontSize: 14)),
    ]));
}

// ─── Parent Card ─────────────────────────────────────────────────────────────
class _ParentCard extends StatelessWidget {
  final ParentRecord parent; final VoidCallback onTap;
  const _ParentCard({required this.parent, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GlassCard(onTap: onTap, padding: const EdgeInsets.all(14), child: Column(children: [
      Row(children: [
        Container(width: 46, height: 46,
          decoration: BoxDecoration(color: AppTheme.parentPurple.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.parentPurple.withValues(alpha: 0.2))),
          child: const Center(child: Text('👨‍👩‍👧', style: TextStyle(fontSize: 20)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(parent.name, style: TextStyle(color: context.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text('${parent.childrenCount} children • ${parent.contact}', style: TextStyle(color: context.textSecondary, fontSize: 12)),
        ])),
        Icon(Icons.chevron_right_rounded, color: context.textTertiary),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        StatusBadge(label: parent.planLabel, color: parent.planColor),
        const SizedBox(width: 6),
        StatusBadge(label: parent.statusLabel, color: parent.statusColor),
        const Spacer(),
        Text('Next: ${parent.nextBillingDate}', style: TextStyle(color: context.textTertiary, fontSize: 11)),
      ]),
    ]));
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────
class _PlanBadge extends StatelessWidget {
  final String name, price, desc; final Color color; final IconData icon;
  const _PlanBadge({required this.name, required this.price, required this.desc, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.15))),
      child: Column(children: [
        Icon(icon, color: color, size: 22), const SizedBox(height: 4),
        Text(name, style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
        Text(price, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        Text(desc, style: TextStyle(color: context.textTertiary, fontSize: 10)),
      ]),
    ));
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon; final String label, value; final Color color;
  const _MiniStat({required this.icon, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Expanded(child: GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      gradient: LinearGradient(colors: [color.withValues(alpha: 0.12), color.withValues(alpha: 0.04)]),
      borderColor: color.withValues(alpha: 0.18),
      child: Column(children: [
        Icon(icon, color: color, size: 20), const SizedBox(height: 4),
        Text(value, style: TextStyle(color: context.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
        Text(label, style: TextStyle(color: context.textSecondary, fontSize: 10)),
      ]),
    ));
  }
}

class _FilterChip extends StatelessWidget {
  final String label; final IconData icon; final Color color; final VoidCallback onTap;
  const _FilterChip({required this.label, required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: context.surfaceBorder)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color), const SizedBox(width: 6),
        Text(label, style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(width: 4), Icon(Icons.unfold_more_rounded, size: 14, color: context.textTertiary),
      ]),
    ));
  }
}

// ─── Mock Data ──────────────────────────────────────────────────────────────
final mockParents = [
  const ParentRecord(id: 'par_1', name: 'Shahid Ali', childrenCount: 2, childrenNames: ['Noorulain', 'Haya'], contact: '0321-6666666',
    email: 'shahid@email.com', plan: ParentPlan.standard, status: SubscriptionStatus.active, nextBillingDate: 'Jun 15', amountDue: 700, address: 'North Colony'),
  const ParentRecord(id: 'par_2', name: 'Sarah Ahmed', childrenCount: 1, childrenNames: ['Emma'], contact: '0333-7777777',
    email: 'sarah@email.com', plan: ParentPlan.basic, status: SubscriptionStatus.active, nextBillingDate: 'Jun 20', amountDue: 300, address: 'Civic Center'),
  const ParentRecord(id: 'par_3', name: 'Fatima Khan', childrenCount: 1, childrenNames: ['Zara'], contact: '0345-9999999',
    email: 'fatima@email.com', plan: ParentPlan.basic, status: SubscriptionStatus.expired, nextBillingDate: 'Expired', amountDue: 300, address: 'West Town'),
  const ParentRecord(id: 'par_4', name: 'Hassan Raza', childrenCount: 1, childrenNames: ['Ali'], contact: '0300-1234567',
    email: 'hassan@email.com', plan: ParentPlan.premium, status: SubscriptionStatus.active, nextBillingDate: 'Jul 01', amountDue: 1200, address: 'East Wing'),
  const ParentRecord(id: 'par_5', name: 'Farooq Ahmed', childrenCount: 1, childrenNames: ['Omar'], contact: '0312-5551234',
    email: 'farooq@email.com', plan: ParentPlan.basic, status: SubscriptionStatus.trial, nextBillingDate: 'Jun 05', amountDue: 0, address: 'Model Town'),
];
