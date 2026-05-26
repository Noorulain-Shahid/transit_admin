import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import 'admin_user_models.dart';

class AdminUserDetailPage extends StatefulWidget {
  final AdminUserRecord user;

  const AdminUserDetailPage({super.key, required this.user});

  @override
  State<AdminUserDetailPage> createState() => _AdminUserDetailPageState();
}

class _AdminUserDetailPageState extends State<AdminUserDetailPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _contactController;
  late final TextEditingController _addressController;
  late final TextEditingController _extraController;
  late bool _active;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _contactController = TextEditingController(text: widget.user.contact);
    _addressController = TextEditingController(text: widget.user.address);
    _extraController = TextEditingController(text: widget.user.extra);
    _active = widget.user.active;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _extraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    return Scaffold(
      body: Container(
        decoration: context.scaffoldBg,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              children: [
                _Header(title: 'User Detail', onBack: () => context.pop()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      GlassCard(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: user.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: user.color.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  user.icon,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.role,
                                    style: TextStyle(
                                      color: context.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user.name,
                                    style: TextStyle(
                                      color: context.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user.detail,
                                    style: TextStyle(
                                      color: context.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _active
                                    ? AppTheme.success.withValues(alpha: 0.12)
                                    : AppTheme.error.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _active
                                      ? AppTheme.success.withValues(alpha: 0.22)
                                      : AppTheme.error.withValues(alpha: 0.22),
                                ),
                              ),
                              child: Text(
                                _active ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  color: _active ? AppTheme.success : AppTheme.error,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      GlassCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Details',
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _Field(label: 'Name', controller: _nameController),
                            _Field(label: 'Contact', controller: _contactController),
                            _Field(label: 'Address / Assignment', controller: _addressController),
                            _Field(label: 'Extra Info', controller: _extraController),
                            const SizedBox(height: 8),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: _active,
                              onChanged: (value) => setState(() => _active = value),
                              title: Text(
                                'Account Active',
                                style: TextStyle(color: context.textPrimary),
                              ),
                              subtitle: Text(
                                'Toggle whether this account can access the app.',
                                style: TextStyle(color: context.textSecondary),
                              ),
                              activeColor: AppTheme.adminEmerald,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      GlassCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Admin Actions',
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _ActionBtn(
                                    label: 'Save Changes',
                                    color: AppTheme.adminEmerald,
                                    onTap: () => _showMessage(
                                      context,
                                      'Changes saved for ${_nameController.text}.',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _ActionBtn(
                                    label: 'Cancel Subscription',
                                    color: AppTheme.warning,
                                    onTap: () => _showMessage(
                                      context,
                                      'Subscription cancellation flow will be handled here.',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _ActionBtn(
                                    label: _active ? 'Deactivate Account' : 'Reactivate Account',
                                    color: AppTheme.info,
                                    onTap: () => setState(() => _active = !_active),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _Field({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        style: TextStyle(color: context.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: context.textSecondary),
          filled: true,
          fillColor: context.inputFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: context.inputBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: context.inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppTheme.adminEmerald, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.16), color.withValues(alpha: 0.08)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  const _Header({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: context.cardBgElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.inputBorder),
              ),
              child: Center(
                child: Text(
                  '←',
                  style: TextStyle(color: context.textPrimary, fontSize: 18),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            title,
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
