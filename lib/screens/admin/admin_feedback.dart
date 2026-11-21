import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transit_core/transit_core.dart';

import '../../app/admin_format.dart';
import '../../app/locale_provider.dart';
import '../../data/admin_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/entity_widgets.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/responsive.dart';

String _roleLabel(String role) => switch (role) {
  'parent' => AppStrings.t('nav_parent'),
  'student' => AppStrings.t('nav_student'),
  'driver' => AppStrings.t('nav_driver'),
  'admin' => AppStrings.t('admin_role'),
  '' => '',
  _ => '${role[0].toUpperCase()}${role.substring(1)}',
};

Color _roleColor(String role) => switch (role) {
  'parent' => AppTheme.parentPurple,
  'student' => AppTheme.studentAmber,
  'driver' => AppTheme.driverCyan,
  _ => AppTheme.adminEmerald,
};

Color _ratingColor(int rating) => rating >= 4
    ? AppTheme.success
    : rating == 3
    ? AppTheme.warning
    : AppTheme.error;

/// Every "Rate the App" submission from parents, students and drivers:
/// the overall average, the spread of stars, and each rating with its
/// comment, author, role and date.
class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  late final Stream<List<AppFeedback>> _stream = AdminRepository.instance
      .watchAllFeedback();
  int? _stars; // null = all

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: context.scaffoldBg,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
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
                        AppStrings.t('app_rating_feedback'),
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
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<List<AppFeedback>>(
                  stream: _stream,
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return Center(
                        child: LoadErrorView(
                          error: snap.error,
                          what: 'feedback',
                        ),
                      );
                    }
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final all = snap.data!;
                    final shown = _stars == null
                        ? all
                        : all.where((f) => f.rating == _stars).toList();
                    return ListView(
                      padding: centeredListPadding(
                        context,
                        maxWidth: 1100,
                        bottom: 40,
                      ),
                      children: [
                        _SummaryCard(feedback: all),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: Text(
                                '${AppStrings.t('status_all')} (${all.length})',
                              ),
                              selected: _stars == null,
                              onSelected: (_) => setState(() => _stars = null),
                            ),
                            for (final n in [5, 4, 3, 2, 1])
                              ChoiceChip(
                                label: Text(
                                  '$n★ (${all.where((f) => f.rating == n).length})',
                                ),
                                selected: _stars == n,
                                onSelected: (_) => setState(() => _stars = n),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (shown.isEmpty)
                          EmptyHint(
                            text: all.isEmpty
                                ? AppStrings.t('no_ratings_yet')
                                : AppStrings.t('no_ratings_with_stars'),
                            icon: Icons.star_border_rounded,
                          )
                        else
                          ResponsiveGrid(
                            minItemWidth: 380,
                            children: [
                              for (final f in shown) FeedbackTile(feedback: f),
                            ],
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final List<AppFeedback> feedback;
  const _SummaryCard({required this.feedback});

  @override
  Widget build(BuildContext context) {
    final avg = feedbackAverage(feedback);
    final total = feedback.length;
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Text(
                total == 0 ? '—' : avg.toStringAsFixed(1),
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
              RatingStars(value: avg, size: 16),
              const SizedBox(height: 4),
              Text(
                AppStrings.t(
                  total == 1 ? 'rating_count_one' : 'rating_count_many',
                ).replaceFirst('{count}', '$total'),
                style: TextStyle(color: context.textSecondary, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              children: [
                for (final n in [5, 4, 3, 2, 1])
                  _DistributionBar(
                    stars: n,
                    count: feedback.where((f) => f.rating == n).length,
                    total: total,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DistributionBar extends StatelessWidget {
  final int stars, count, total;
  const _DistributionBar({
    required this.stars,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '$stars★',
              style: TextStyle(color: context.textSecondary, fontSize: 11),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : count / total,
                minHeight: 7,
                backgroundColor: context.cardBgElevated,
                valueColor: AlwaysStoppedAnimation(_ratingColor(stars)),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 26,
            child: Text(
              '$count',
              textAlign: TextAlign.end,
              style: TextStyle(color: context.textSecondary, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

/// One feedback entry: stars, comment, who wrote it (name + role) and
/// when. Rows written before `userName`/`userRole` existed look the
/// account up instead (cached per uid).
class FeedbackTile extends StatelessWidget {
  final AppFeedback feedback;
  const FeedbackTile({super.key, required this.feedback});

  @override
  Widget build(BuildContext context) {
    final f = feedback;
    final needsLookup = f.userName.isEmpty || f.userRole.isEmpty;
    return FutureBuilder<AppUser?>(
      future: needsLookup
          ? AdminRepository.instance.fetchUserCached(f.userId)
          : null,
      builder: (context, snap) {
        final account = snap.data;
        final name = f.userName.isNotEmpty
            ? f.userName
            : ((account?.name ?? '').isNotEmpty
                  ? account!.name
                  : (snap.connectionState == ConnectionState.waiting
                        ? 'Loading…'
                        : AppStrings.t('anonymous_user')));
        final role = f.userRole.isNotEmpty
            ? f.userRole
            : (account?.role.name ?? '');
        final comment = (f.comment ?? '').trim();
        return GlassCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  RatingStars(value: f.rating.toDouble(), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${f.rating}/5',
                    style: TextStyle(
                      color: _ratingColor(f.rating),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formatExactTime(f.timestamp),
                    style: TextStyle(color: context.textTertiary, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                comment.isEmpty ? AppStrings.t('no_comment_left') : comment,
                style: TextStyle(
                  color: comment.isEmpty
                      ? context.textTertiary
                      : context.textPrimary,
                  fontSize: 13,
                  fontStyle: comment.isEmpty ? FontStyle.italic : null,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(
                    Icons.person_rounded,
                    size: 14,
                    color: context.textSecondary,
                  ),
                  Text(
                    name,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (role.isNotEmpty)
                    StatusBadge(
                      label: _roleLabel(role),
                      color: _roleColor(role),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Dashboard card: overall app rating, count, the latest few comments, and
/// the way into the full list.
class AppFeedbackSummaryCard extends StatefulWidget {
  const AppFeedbackSummaryCard({super.key});

  @override
  State<AppFeedbackSummaryCard> createState() => _AppFeedbackSummaryCardState();
}

class _AppFeedbackSummaryCardState extends State<AppFeedbackSummaryCard> {
  late final Stream<List<AppFeedback>> _stream = AdminRepository.instance
      .watchAllFeedback();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: AppStrings.t('app_rating_feedback'),
      icon: Icons.reviews_rounded,
      color: AppTheme.studentAmber,
      trailing: TextButton(
        onPressed: () => context.push('/admin/feedback'),
        child: Text(AppStrings.t('view_all_action')),
      ),
      child: StreamBuilder<List<AppFeedback>>(
        stream: _stream,
        builder: (context, snap) => snapshotView<List<AppFeedback>>(
          snap,
          what: 'feedback',
          builder: (all) {
            if (all.isEmpty) {
              return Text(
                AppStrings.t('no_ratings_yet'),
                style: TextStyle(color: context.textSecondary, fontSize: 12),
              );
            }
            final avg = feedbackAverage(all);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      avg.toStringAsFixed(1),
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RatingStars(value: avg),
                          Text(
                            AppStrings.t(
                              'average_of_ratings',
                            ).replaceFirst('{count}', '${all.length}'),
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                for (final f in all.take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: FeedbackTile(feedback: f),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
