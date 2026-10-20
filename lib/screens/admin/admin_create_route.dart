import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transit_core/transit_core.dart';
import '../../app/locale_provider.dart';
import '../../data/admin_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

/// Replaces the old "Route creation — coming soon" stub on Route
/// Management's empty state with a real form that writes a `BusRoute`
/// document via `AdminRepository.createRoute`.
///
/// Scope note: this admin app has no map picker anywhere (unlike the
/// mobile app's stop/location pickers), so each stop is captured as a
/// name + scheduled time only — `RouteStop.location` is written as
/// `GeoCoord(0, 0)` (a real place, the Gulf of Guinea — deliberately
/// obviously wrong rather than a plausible-looking fake coordinate) and
/// flagged with a `note` marking it as needing a real pin. Wiring an
/// actual map picker into the admin app is a larger follow-up, not
/// something to fake here.
class AdminCreateRoute extends StatefulWidget {
  const AdminCreateRoute({super.key});

  @override
  State<AdminCreateRoute> createState() => _AdminCreateRouteState();
}

class _StopDraft {
  final nameCtrl = TextEditingController();
  final timeCtrl = TextEditingController();

  void dispose() {
    nameCtrl.dispose();
    timeCtrl.dispose();
  }
}

class _AdminCreateRouteState extends State<AdminCreateRoute> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _stops = <_StopDraft>[_StopDraft()];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    LocaleProvider.instance.addListener(_onLangChanged);
  }

  void _onLangChanged() => setState(() {});

  @override
  void dispose() {
    LocaleProvider.instance.removeListener(_onLangChanged);
    _nameCtrl.dispose();
    for (final s in _stops) {
      s.dispose();
    }
    super.dispose();
  }

  void _addStop() => setState(() => _stops.add(_StopDraft()));

  void _removeStop(int i) {
    setState(() {
      _stops[i].dispose();
      _stops.removeAt(i);
    });
  }

  Future<void> _create() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final stops = <RouteStop>[];
      for (var i = 0; i < _stops.length; i++) {
        final draft = _stops[i];
        if (draft.nameCtrl.text.trim().isEmpty) continue;
        stops.add(
          RouteStop(
            id: 'stop_${DateTime.now().microsecondsSinceEpoch}_$i',
            name: draft.nameCtrl.text.trim(),
            // Deliberately obvious placeholder, not a plausible-looking
            // fake coordinate — see this file's class-level doc comment.
            location: const GeoCoord(0, 0),
            scheduledTime: draft.timeCtrl.text.trim(),
            order: i,
            note: 'Needs a real map pin — admin app has no map picker yet',
          ),
        );
      }
      await AdminRepository.instance.createRoute(
        BusRoute(id: '', name: _nameCtrl.text.trim(), stops: stops),
      );
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: context.scaffoldBg,
        child: SafeArea(
          child: Column(
            children: [
              _Header(onBack: () => context.pop()),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: TextFormField(
                            controller: _nameCtrl,
                            style: TextStyle(color: context.textPrimary),
                            decoration: InputDecoration(
                              labelText: AppStrings.t('route_name_lbl'),
                              border: InputBorder.none,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? AppStrings.t('route_name_required')
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.t('stops_lbl'),
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...List.generate(_stops.length, (i) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GlassCard(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: TextField(
                                      controller: _stops[i].nameCtrl,
                                      style: TextStyle(
                                        color: context.textPrimary,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: AppStrings.t(
                                          'stop_name_lbl',
                                        ),
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: _stops[i].timeCtrl,
                                      textDirection: TextDirection.ltr,
                                      style: TextStyle(
                                        color: context.textPrimary,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: AppStrings.t('time_lbl'),
                                        hintText: '7:15 AM',
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  if (_stops.length > 1)
                                    IconButton(
                                      icon: Icon(
                                        Icons.close_rounded,
                                        color: context.textTertiary,
                                        size: 18,
                                      ),
                                      onPressed: () => _removeStop(i),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                        TextButton.icon(
                          onPressed: _addStop,
                          icon: const Icon(
                            Icons.add_rounded,
                            color: AppTheme.adminAccent,
                          ),
                          label: Text(
                            AppStrings.t('add_stop_action'),
                            style: const TextStyle(
                              color: AppTheme.adminAccent,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.adminAccent,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                            onPressed: _saving ? null : _create,
                            child: Text(
                              _saving
                                  ? AppStrings.t('saving_action')
                                  : AppStrings.t('create_route_action'),
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

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
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: context.textPrimary,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            AppStrings.t('create_route_action'),
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
