import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transit_core/transit_core.dart';
import '../../data/admin_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class AdminParentDetail extends StatefulWidget {
  final String parentId;
  const AdminParentDetail({super.key, required this.parentId});

  @override
  State<AdminParentDetail> createState() => _AdminParentDetailState();
}

class _AdminParentDetailState extends State<AdminParentDetail> {
  final _repo = AdminRepository.instance;
  bool _editing = false;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _startEditing(AppUser p) {
    _nameCtrl.text = p.name;
    _phoneCtrl.text = p.phone;
    _emailCtrl.text = p.email;
    setState(() => _editing = true);
  }

  Future<void> _save(AppUser p) async {
    setState(() => _saving = true);
    try {
      await _repo.updateUser(p.uid, {
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
      });
      if (mounted) {
        setState(() => _editing = false);
        _msg('Saved');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleActive(AppUser p) async {
    await _repo.updateUser(p.uid, {'isActive': !p.isActive});
    if (mounted) _msg(p.isActive ? 'Account deactivated' : 'Account activated');
  }

  Future<void> _message(AppUser p) async {
    final ctrl = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Message ${p.name}'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. We\'ve fixed the pickup time issue you reported.',
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
    await _repo.messageUser(p.uid, title: 'Message from admin', body: text);
    if (mounted) _msg('Message sent to ${p.name}');
  }

  void _msg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: context.scaffoldBg,
        child: SafeArea(
          child: StreamBuilder<AppUser?>(
            stream: _repo.watchUser(widget.parentId),
            builder: (context, snap) {
              final p = snap.data;
              return Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: !snap.hasData
                        ? const Center(child: CircularProgressIndicator())
                        : p == null
                        ? Center(
                            child: Text(
                              'Parent not found.',
                              style: TextStyle(color: context.textSecondary),
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.only(bottom: 40),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Column(
                                children: [
                                  _buildProfileCard(context, p),
                                  const SizedBox(height: 12),
                                  _buildChildrenSection(context, p),
                                  const SizedBox(height: 12),
                                  _buildControls(context, p),
                                ],
                              ),
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
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
              'Parent Detail',
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, AppUser p) {
    return GlassCard(
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
                  color: AppTheme.parentPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppTheme.parentPurple.withValues(alpha: 0.25),
                  ),
                ),
                child: const Center(
                  child: Text('👨‍👩‍👧', style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    StatusBadge(
                      label: p.isActive ? 'Active' : 'Inactive',
                      color: p.isActive ? AppTheme.success : AppTheme.error,
                    ),
                  ],
                ),
              ),
              if (!_editing)
                IconButton(
                  onPressed: () => _startEditing(p),
                  icon: Icon(Icons.edit_rounded, color: context.textSecondary),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (_editing) ...[
            _EditField(label: 'Name', controller: _nameCtrl),
            const SizedBox(height: 8),
            _EditField(label: 'Phone', controller: _phoneCtrl),
            const SizedBox(height: 8),
            _EditField(label: 'Email', controller: _emailCtrl),
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
                    onTap: _saving ? null : () => _save(p),
                  ),
                ),
              ],
            ),
          ] else ...[
            _DetailRow(
              icon: Icons.phone_rounded,
              label: 'Phone',
              value: p.phone.isEmpty ? '—' : p.phone,
            ),
            _DetailRow(
              icon: Icons.email_rounded,
              label: 'Email',
              value: p.email.isEmpty ? '—' : p.email,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChildrenSection(BuildContext context, AppUser p) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.child_care_rounded,
                color: AppTheme.parentPurple,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Children',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<Student>>(
            stream: _repo.watchStudents(),
            builder: (context, snap) {
              final children = (snap.data ?? const <Student>[])
                  .where((s) => s.parentId == p.uid)
                  .toList();
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (children.isEmpty) {
                return Text(
                  'No linked children.',
                  style: TextStyle(color: context.textSecondary, fontSize: 12),
                );
              }
              return Column(
                children: children
                    .map(
                      (child) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () => context.push(
                            '/admin/student-detail',
                            extra: child.id,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.parentPurple.withValues(
                                alpha: 0.05,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.parentPurple.withValues(
                                  alpha: 0.12,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppTheme.parentPurple.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.menu_book_rounded,
                                    color: AppTheme.parentPurple,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        child.name,
                                        style: TextStyle(
                                          color: context.textPrimary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${child.grade} • ${child.school}',
                                        style: TextStyle(
                                          color: context.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
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
                        ),
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

  Widget _buildControls(BuildContext context, AppUser p) {
    return GlassCard(
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
                  label: p.isActive ? 'Deactivate' : 'Activate',
                  color: p.isActive ? AppTheme.error : AppTheme.success,
                  icon: p.isActive
                      ? Icons.block_rounded
                      : Icons.check_circle_rounded,
                  onTap: () => _toggleActive(p),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionBtn(
                  label: 'Message',
                  color: AppTheme.parentPurple,
                  icon: Icons.chat_bubble_rounded,
                  onTap: () => _message(p),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────
class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _EditField({required this.label, required this.controller});
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: TextStyle(color: context.textPrimary, fontSize: 14),
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: context.textTertiary, size: 16),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(color: context.textSecondary, fontSize: 12),
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
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
