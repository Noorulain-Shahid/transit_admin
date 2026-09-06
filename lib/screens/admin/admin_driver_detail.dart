import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transit_core/transit_core.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/admin_repository.dart';
import '../../services/audit_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/mini_chart.dart';
import 'admin_driver_management.dart' show driverStatusLabel, driverStatusColor;

String documentTypeLabel(DocumentType type) => switch (type) {
  DocumentType.drivingLicense => 'Driving License',
  DocumentType.vehicleRegistration => 'Vehicle Registration',
  DocumentType.insuranceCertificate => 'Insurance Certificate',
  DocumentType.routePermit => 'Route Permit',
  DocumentType.medicalFitness => 'Medical Fitness',
  DocumentType.schoolContract => 'School Contract',
};

String documentStatusLabel(DocumentStatus status) => switch (status) {
  DocumentStatus.notUploaded => 'Not uploaded',
  DocumentStatus.pending => 'Pending review',
  DocumentStatus.verified => 'Verified',
  DocumentStatus.rejected => 'Rejected',
};

Color documentStatusColor(DocumentStatus status) => switch (status) {
  DocumentStatus.notUploaded => const Color(0xFF94A3B8),
  DocumentStatus.pending => const Color(0xFFF59E0B),
  DocumentStatus.verified => const Color(0xFF10B981),
  DocumentStatus.rejected => const Color(0xFFEF4444),
};

class AdminDriverDetail extends StatefulWidget {
  final String driverId;
  const AdminDriverDetail({super.key, required this.driverId});
  @override
  State<AdminDriverDetail> createState() => _AdminDriverDetailState();
}

class _AdminDriverDetailState extends State<AdminDriverDetail>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _repo = AdminRepository.instance;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _approve(Driver d) async {
    await _repo.updateDriverStatus(d.id, DriverStatus.offline);
    await _audit(
      AuditActionType.statusChange,
      d.id,
      'Approved driver ${d.name}',
    );
    if (mounted) _msg('Driver approved');
  }

  Future<void> _suspend(Driver d) async {
    await _repo.updateDriverStatus(d.id, DriverStatus.suspended);
    await _audit(
      AuditActionType.statusChange,
      d.id,
      'Suspended driver ${d.name}',
    );
    if (mounted) _msg('Driver suspended');
  }

  Future<void> _audit(
    AuditActionType type,
    String targetId,
    String description,
  ) {
    final adminId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
    return AuditService.instance.logAction(
      adminId: adminId,
      actionType: type,
      targetEntityId: targetId,
      description: description,
    );
  }

  Future<void> _message(Driver d) async {
    final result = await _showMessageDialog(
      title: 'Message ${d.name}',
      hint:
          'e.g. Your vehicle registration photo is unclear, please re-upload.',
    );
    if (result == null || result.isEmpty) return;
    await _repo.messageUser(d.id, title: 'Message from admin', body: result);
    if (mounted) _msg('Message sent to ${d.name}');
  }

  Future<void> _verifyDocument(DriverDocument doc) async {
    await _repo.updateDriverDocument(doc.id, status: DocumentStatus.verified);
    await _audit(
      AuditActionType.statusChange,
      doc.id,
      '${documentTypeLabel(doc.type)} verified',
    );
    if (mounted) _msg('${documentTypeLabel(doc.type)} verified');
  }

  Future<void> _rejectDocument(DriverDocument doc, Driver d) async {
    final reason = await _showMessageDialog(
      title: 'Reject ${documentTypeLabel(doc.type)}',
      hint:
          'Reason the driver will see, e.g. "Photo is blurry, please re-upload."',
    );
    if (reason == null || reason.isEmpty) return;
    await _repo.updateDriverDocument(
      doc.id,
      status: DocumentStatus.rejected,
      rejectionReason: reason,
    );
    await _repo.messageUser(
      d.id,
      title: '${documentTypeLabel(doc.type)} rejected',
      body: reason,
    );
    await _audit(
      AuditActionType.statusChange,
      doc.id,
      '${documentTypeLabel(doc.type)} rejected: $reason',
    );
    if (mounted) {
      _msg('${documentTypeLabel(doc.type)} rejected and driver notified');
    }
  }

  Future<String?> _showMessageDialog({
    required String title,
    required String hint,
  }) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: InputDecoration(hintText: hint),
          autofocus: true,
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
  }

  void _msg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: context.scaffoldBg,
        child: SafeArea(
          child: StreamBuilder<Driver?>(
            stream: _repo.watchDriver(widget.driverId),
            builder: (context, snap) {
              final d = snap.data;
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
                            'Driver Detail',
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
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
                        : d == null
                        ? Center(
                            child: Text(
                              'Driver not found.',
                              style: TextStyle(color: context.textSecondary),
                            ),
                          )
                        : _buildBody(context, d),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, Driver d) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // Profile card
            GlassCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.driverCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppTheme.driverCyan.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Center(
                      child: Text('🚐', style: TextStyle(fontSize: 26)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.name,
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          d.busId?.isNotEmpty == true
                              ? 'Bus ${d.busId} • ${d.routeId ?? 'No route'}'
                              : 'No bus assigned',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            StatusBadge(
                              label: driverStatusLabel(d.status),
                              color: driverStatusColor(d.status),
                            ),
                            const SizedBox(width: 6),
                            StatusBadge(
                              label: d.isApproved ? 'Approved' : 'Pending',
                              color: d.isApproved
                                  ? AppTheme.success
                                  : AppTheme.warning,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Details
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
                    icon: Icons.badge_rounded,
                    label: 'License',
                    value: d.licenseNumber.isEmpty ? '—' : d.licenseNumber,
                    color: AppTheme.info,
                  ),
                  _InfoRow(
                    icon: Icons.phone_rounded,
                    label: 'Contact',
                    value: d.phone.isEmpty ? '—' : d.phone,
                    color: AppTheme.adminEmerald,
                  ),
                  _InfoRow(
                    icon: Icons.email_rounded,
                    label: 'Email',
                    value: d.email.isEmpty ? '—' : d.email,
                    color: AppTheme.driverCyan,
                  ),
                  _InfoRow(
                    icon: Icons.route_rounded,
                    label: 'Route',
                    value: d.routeId?.isNotEmpty == true
                        ? d.routeId!
                        : 'Unassigned',
                    color: AppTheme.purple,
                  ),
                  _InfoRow(
                    icon: Icons.work_history_rounded,
                    label: 'Experience',
                    value: '${d.experienceYears} yrs',
                    color: AppTheme.warning,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Performance
            GlassCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Performance',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      RingIndicator(
                        percentage: d.rating / 5 * 100,
                        color: AppTheme.driverCyan,
                        size: 72,
                        strokeWidth: 7,
                        center: Text(
                          d.rating.toStringAsFixed(1),
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          children: [
                            _PerfBar(
                              label: 'Reliability',
                              pct: d.reliabilityScore.clamp(0, 100) / 100,
                              color: AppTheme.success,
                            ),
                            const SizedBox(height: 8),
                            _PerfBar(
                              label: 'Rating',
                              pct: d.rating / 5,
                              color: AppTheme.info,
                            ),
                            const SizedBox(height: 8),
                            _PerfBar(
                              label: 'Safety',
                              pct:
                                  (1 -
                                          ((d.harshBrakingEvents +
                                                      d.overSpeedEvents) /
                                                  20)
                                              .clamp(0, 1))
                                      .toDouble(),
                              color: AppTheme.purple,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Controls
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
                          label: d.isApproved ? 'Approved' : 'Approve',
                          color: AppTheme.success,
                          icon: Icons.check_circle_rounded,
                          onTap: d.isApproved ? null : () => _approve(d),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionBtn(
                          label: d.status == DriverStatus.suspended
                              ? 'Suspended'
                              : 'Suspend',
                          color: AppTheme.error,
                          icon: Icons.block_rounded,
                          onTap: d.status == DriverStatus.suspended
                              ? null
                              : () => _suspend(d),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionBtn(
                          label: 'Message Driver',
                          color: AppTheme.driverCyan,
                          icon: Icons.chat_bubble_rounded,
                          onTap: () => _message(d),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Documents
            GlassCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Compliance Documents',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<List<DriverDocument>>(
                    stream: _repo.watchDriverDocuments(d.id),
                    builder: (context, docSnap) {
                      if (!docSnap.hasData) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final latestByType = _latestPerType(docSnap.data!);
                      if (latestByType.isEmpty) {
                        return Text(
                          'No documents uploaded yet.',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 13,
                          ),
                        );
                      }
                      return Column(
                        children: latestByType
                            .map(
                              (doc) => _DocumentRow(
                                doc: doc,
                                onView: (doc.fileUrl ?? '').isEmpty
                                    ? null
                                    : () => launchUrl(
                                        Uri.parse(doc.fileUrl!),
                                        mode: LaunchMode.externalApplication,
                                      ),
                                onVerify: doc.status == DocumentStatus.pending
                                    ? () => _verifyDocument(doc)
                                    : null,
                                onReject: doc.status == DocumentStatus.pending
                                    ? () => _rejectDocument(doc, d)
                                    : null,
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tabs (illustrative history — trip/attendance/SOS/earnings data
            // sources aren't wired up yet, out of scope for this pass)
            GlassCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  TabBar(
                    controller: _tabCtrl,
                    isScrollable: true,
                    labelColor: AppTheme.driverCyan,
                    unselectedLabelColor: context.textTertiary,
                    indicatorColor: AppTheme.driverCyan,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    tabAlignment: TabAlignment.start,
                    tabs: const [
                      Tab(text: 'Trip History'),
                      Tab(text: 'Attendance'),
                      Tab(text: 'SOS History'),
                      Tab(text: 'Earnings'),
                    ],
                  ),
                  SizedBox(
                    height: 260,
                    child: TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _buildTrips(context),
                        _buildAttendance(context),
                        _buildSOS(context),
                        _buildEarnings(context),
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

  /// One row per document type — a driver may have several re-upload
  /// attempts on file, only the newest one is actionable.
  List<DriverDocument> _latestPerType(List<DriverDocument> docs) {
    final byType = <DocumentType, DriverDocument>{};
    for (final doc in docs) {
      final existing = byType[doc.type];
      if (existing == null ||
          (doc.uploadedAt ?? DateTime(0)).isAfter(
            existing.uploadedAt ?? DateTime(0),
          )) {
        byType[doc.type] = doc;
      }
    }
    final list = byType.values.toList()
      ..sort((a, b) => a.type.index.compareTo(b.type.index));
    return list;
  }

  Widget _buildTrips(BuildContext context) {
    final items = [
      ('May 26', 'Route A — Completed (34 students)', AppTheme.success),
      ('May 25', 'Route A — Completed (32 students)', AppTheme.success),
      ('May 24', 'Route A — Delayed 8 min', AppTheme.warning),
      ('May 23', 'Route A — Completed (35 students)', AppTheme.success),
    ];
    return ListView(
      padding: const EdgeInsets.only(top: 12),
      children: items
          .map((e) => _LogRow(date: e.$1, status: e.$2, color: e.$3))
          .toList(),
    );
  }

  Widget _buildAttendance(BuildContext context) {
    final items = [
      ('May 26', 'Present — On time', AppTheme.success),
      ('May 25', 'Present — On time', AppTheme.success),
      ('May 24', 'Present — Late 8 min', AppTheme.warning),
      ('May 22', 'Absent', AppTheme.error),
    ];
    return ListView(
      padding: const EdgeInsets.only(top: 12),
      children: items
          .map((e) => _LogRow(date: e.$1, status: e.$2, color: e.$3))
          .toList(),
    );
  }

  Widget _buildSOS(BuildContext context) {
    final items = [
      ('May 20', 'Vehicle breakdown — Route A', AppTheme.error),
      ('Apr 15', 'Medical emergency — student fainted', AppTheme.error),
    ];
    return ListView(
      padding: const EdgeInsets.only(top: 12),
      children: items
          .map((e) => _LogRow(date: e.$1, status: e.$2, color: e.$3))
          .toList(),
    );
  }

  Widget _buildEarnings(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Earnings',
                style: TextStyle(color: context.textSecondary, fontSize: 12),
              ),
              Text(
                '₨45,000',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MiniBarChart(
            values: const [35, 42, 38, 45, 40, 48],
            labels: const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
            barColor: AppTheme.driverCyan,
            barActiveColor: AppTheme.driverCyan,
            height: 70,
            barWidth: 16,
          ),
          const SizedBox(height: 16),
          _EarnRow(
            label: 'Base Salary',
            value: '₨30,000',
            color: AppTheme.info,
          ),
          _EarnRow(
            label: 'Trip Bonus',
            value: '₨10,000',
            color: AppTheme.success,
          ),
          _EarnRow(
            label: 'Deductions',
            value: '-₨2,000',
            color: AppTheme.error,
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────
class _DocumentRow extends StatelessWidget {
  final DriverDocument doc;
  final VoidCallback? onView;
  final VoidCallback? onVerify;
  final VoidCallback? onReject;
  const _DocumentRow({
    required this.doc,
    required this.onView,
    this.onVerify,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final color = documentStatusColor(doc.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    documentTypeLabel(doc.type),
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                StatusBadge(
                  label: documentStatusLabel(doc.status),
                  color: color,
                ),
              ],
            ),
            if (doc.status == DocumentStatus.rejected &&
                doc.rejectionReason != null &&
                doc.rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                doc.rejectionReason!,
                style: TextStyle(color: context.textSecondary, fontSize: 12),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onView,
                  icon: const Icon(Icons.open_in_new_rounded, size: 15),
                  label: const Text('View'),
                ),
                if (onVerify != null)
                  TextButton.icon(
                    onPressed: onVerify,
                    icon: Icon(
                      Icons.check_circle_rounded,
                      size: 15,
                      color: AppTheme.success,
                    ),
                    label: Text(
                      'Verify',
                      style: TextStyle(color: AppTheme.success),
                    ),
                  ),
                if (onReject != null)
                  TextButton.icon(
                    onPressed: onReject,
                    icon: Icon(
                      Icons.cancel_rounded,
                      size: 15,
                      color: AppTheme.error,
                    ),
                    label: Text(
                      'Reject',
                      style: TextStyle(color: AppTheme.error),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
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
              width: 60,
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

class _PerfBar extends StatelessWidget {
  final String label;
  final double pct;
  final Color color;
  const _PerfBar({required this.label, required this.pct, required this.color});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(color: context.textSecondary, fontSize: 11),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: context.cardBgElevated,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${(pct * 100).toInt()}%',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
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
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
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

class _EarnRow extends StatelessWidget {
  final String label, value;
  final Color color;
  const _EarnRow({
    required this.label,
    required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: context.textSecondary, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
