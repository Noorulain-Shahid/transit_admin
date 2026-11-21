import 'dart:async';

import 'package:flutter/material.dart';
import 'package:transit_core/transit_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/admin_format.dart';
import '../app/locale_provider.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';
import 'responsive.dart';

// ── Presence clock ───────────────────────────────────────────────────────────

/// One app-wide 30-second tick for every Online/Offline chip and "last
/// seen" line.
///
/// The `users` streams already push a change the moment an app writes
/// `isOnline`/`lastSeenAt` — but an app killed by the OS writes nothing, and
/// the only sign it has gone is its heartbeat getting old. Without a clock,
/// a chip rendered "Online" would stay that way until some unrelated field
/// changed. One shared timer (running only while something is listening)
/// rather than one per chip on a list of hundreds.
class PresenceClock extends ChangeNotifier {
  PresenceClock._();
  static final PresenceClock instance = PresenceClock._();

  static const tick = Duration(seconds: 30);
  Timer? _timer;

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    _timer ??= Timer.periodic(tick, (_) => notifyListeners());
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!hasListeners) {
      _timer?.cancel();
      _timer = null;
    }
  }
}

/// Rebuilds [builder] on every [PresenceClock] tick with the current time.
class PresenceBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DateTime now) builder;
  const PresenceBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: PresenceClock.instance,
    builder: (context, _) => builder(context, DateTime.now()),
  );
}

// ── Badges ───────────────────────────────────────────────────────────────────

/// A pill with a coloured dot — same shape as [StatusBadge].
class DotBadge extends StatelessWidget {
  final String label;
  final Color color;
  const DotBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Live Online / Offline chip from `users/{uid}` presence
/// ([AppUser.isOnlineAt]). [prefix] distinguishes whose presence it is
/// when that isn't the person on the card ("Parent online").
class PresenceBadge extends StatelessWidget {
  final AppUser? user;
  final String? prefix;
  const PresenceBadge({super.key, required this.user, this.prefix});

  @override
  Widget build(BuildContext context) {
    return PresenceBuilder(
      builder: (context, now) {
        final online = isUserOnline(user, now);
        final word = online ? 'online' : 'offline';
        final label = prefix == null
            ? (online ? 'Online' : 'Offline')
            : '$prefix $word';
        return DotBadge(
          label: label,
          color: online ? AppTheme.success : const Color(0xFF94A3B8),
        );
      },
    );
  }
}

/// Colour of an [AccountState]: green Active, orange Deactivated (can be
/// activated again), red Deleted (final).
Color accountStateColor(AccountState state) => switch (state) {
  AccountState.active => AppTheme.success,
  AccountState.deactivated => AppTheme.warning,
  AccountState.deleted => AppTheme.error,
};

String accountStateText(AccountState state) => switch (state) {
  AccountState.active => AppStrings.t('active_lbl'),
  AccountState.deactivated => AppStrings.t('deactivated_status'),
  AccountState.deleted => AppStrings.t('deleted_status'),
};

/// Account state chip: Active, Deactivated or Deleted (see [AccountState]).
class AccountStatusBadge extends StatelessWidget {
  final AccountState state;
  const AccountStatusBadge({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return StatusBadge(
      label: accountStateText(state),
      color: accountStateColor(state),
    );
  }
}

/// "Online now" / "Offline for 2 h 15 m · Last seen 14 Nov, 9:42 PM".
class LastSeenLine extends StatelessWidget {
  final AppUser? user;
  final double fontSize;
  const LastSeenLine({super.key, required this.user, this.fontSize = 11});

  @override
  Widget build(BuildContext context) {
    return PresenceBuilder(
      builder: (context, now) {
        final online = isUserOnline(user, now);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(
                online ? Icons.wifi_tethering_rounded : Icons.schedule_rounded,
                size: fontSize + 2,
                color: online ? AppTheme.success : context.textTertiary,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                lastSeenLabel(user, now),
                style: TextStyle(
                  color: online ? AppTheme.success : context.textSecondary,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

const topRatedGold = Color(0xFFF5B301);
const _topRatedGoldDeep = Color(0xFFB7791F);

/// "★ Top rated" — shown beside a driver whose ratings clear
/// [DriverRatingSummary.isTopRated].
class TopRatedBadge extends StatelessWidget {
  const TopRatedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFDE68A), topRatedGold],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: topRatedGold.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium_rounded,
            size: 13,
            color: Color(0xFF5B3A00),
          ),
          SizedBox(width: 4),
          Text(
            'Top rated',
            style: TextStyle(
              color: Color(0xFF5B3A00),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Five stars for [value] (0–5), halves included.
class RatingStars extends StatelessWidget {
  final double value;
  final double size;
  const RatingStars({super.key, required this.value, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final icon = i < value.floor()
            ? Icons.star_rounded
            : (i < value ? Icons.star_half_rounded : Icons.star_border_rounded);
        return Icon(icon, color: AppTheme.studentAmber, size: size);
      }),
    );
  }
}

// ── Avatar ───────────────────────────────────────────────────────────────────

/// A person's uploaded photo (`photoUrl`, a network image), falling back to
/// [fallbackEmoji] when there is none or it fails to load.
///
/// [topRated] wraps it in the gold "reward" ring with a medal in the corner.
class EntityAvatar extends StatelessWidget {
  final String? photoUrl;
  final double size;
  final Color color;
  final String fallbackEmoji;
  final bool topRated;

  const EntityAvatar({
    super.key,
    required this.photoUrl,
    required this.color,
    required this.fallbackEmoji,
    this.size = 46,
    this.topRated = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.3;
    final fallback = Center(
      child: Text(fallbackEmoji, style: TextStyle(fontSize: size * 0.45)),
    );
    final url = photoUrl?.trim() ?? '';
    final Widget image = url.isEmpty
        ? fallback
        : Image.network(
            url,
            fit: BoxFit.cover,
            width: size,
            height: size,
            errorBuilder: (_, _, _) => fallback,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : Center(
                    child: SizedBox(
                      width: size * 0.35,
                      height: size * 0.35,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
          );

    final tile = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radius),
        border: topRated
            ? null
            : Border.all(color: color.withValues(alpha: 0.22)),
      ),
      clipBehavior: Clip.antiAlias,
      child: image,
    );

    if (!topRated) return tile;

    final ring = size * 0.07 < 2.5 ? 2.5 : size * 0.07;
    final medal = size * 0.36 < 16 ? 16.0 : size * 0.36;
    return SizedBox(
      width: size + ring * 2 + medal * 0.25,
      height: size + ring * 2 + medal * 0.25,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: EdgeInsets.all(ring),
            decoration: BoxDecoration(
              gradient: const SweepGradient(
                colors: [
                  Color(0xFFFDE68A),
                  topRatedGold,
                  _topRatedGoldDeep,
                  topRatedGold,
                  Color(0xFFFDE68A),
                ],
              ),
              borderRadius: BorderRadius.circular(radius + ring),
              boxShadow: [
                BoxShadow(
                  color: topRatedGold.withValues(alpha: 0.45),
                  blurRadius: 10,
                ),
              ],
            ),
            child: tile,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: medal,
              height: medal,
              decoration: BoxDecoration(
                color: topRatedGold,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Icon(
                Icons.star_rounded,
                size: medal * 0.7,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Layout pieces ────────────────────────────────────────────────────────────

/// A titled [GlassCard] — the standard block on every detail screen.
class SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;
  final Widget? trailing;
  const SectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Label/value row. With [onTap] it reads as a link (chevron) — used for
/// "go to this driver / parent / student".
class InfoLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;
  final Widget? trailing;
  const InfoLine({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final row = Container(
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
            width: 84,
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
                color: onTap != null ? color : context.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                decoration: onTap != null ? TextDecoration.underline : null,
                decorationColor: color,
              ),
            ),
          ),
          ?trailing,
          if (onTap != null)
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: onTap == null
          ? row
          : Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onTap,
                child: row,
              ),
            ),
    );
  }
}

Future<void> openInGoogleMaps(GeoCoord c) =>
    launchUrl(googleMapsUri(c), mode: LaunchMode.externalApplication);

/// One place: what it is ([name]), its exact coordinates, and a link that
/// opens it in Google Maps. A missing coordinate says so plainly.
class LocationBlock extends StatelessWidget {
  final String title;
  final String? name;
  final GeoCoord? coord;
  final IconData icon;
  final Color color;
  final String? note;
  const LocationBlock({
    super.key,
    required this.title,
    required this.coord,
    required this.icon,
    required this.color,
    this.name,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    final c = coord;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if ((name ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      name!.trim(),
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  SelectableText(
                    c == null ? 'No pin set on the map' : formatCoord(c),
                    style: TextStyle(
                      color: c == null
                          ? context.textTertiary
                          : context.textPrimary,
                      fontSize: 12,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if ((note ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      note!,
                      style: TextStyle(
                        color: context.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (c != null)
              TextButton.icon(
                onPressed: () => openInGoogleMaps(c),
                style: TextButton.styleFrom(
                  foregroundColor: color,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.map_rounded, size: 15),
                label: const Text(
                  'Open in Maps',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A list of emergency contacts, or an explicit "none".
class EmergencyContactsBlock extends StatelessWidget {
  final String title;
  final List<EmergencyContact> contacts;
  const EmergencyContactsBlock({
    super.key,
    required this.title,
    required this.contacts,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        if (contacts.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'None on file.',
              style: TextStyle(color: context.textTertiary, fontSize: 12),
            ),
          )
        else
          ...contacts.map(
            (c) => InfoLine(
              icon: Icons.contact_emergency_rounded,
              label: c.relation.isEmpty ? 'Contact' : c.relation,
              value: [
                if (c.name.isNotEmpty) c.name,
                if (c.phone.isNotEmpty) c.phone,
              ].join(' · ').ifEmpty('—'),
              color: AppTheme.error,
            ),
          ),
      ],
    );
  }
}

extension _IfEmpty on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

/// A coloured history row: dot, title, optional subtitle, optional trailing
/// text. Wraps instead of overflowing.
class HistoryRow extends StatelessWidget {
  final Color color;
  final String title;
  final String? subtitle;
  final String? trailing;
  final VoidCallback? onTap;
  const HistoryRow({
    super.key,
    required this.color,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final body = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if ((subtitle ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if ((trailing ?? '').isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              trailing!,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: onTap == null ? body : Clickable(onTap: onTap, child: body),
    );
  }
}

/// Muted one-line explanation for an empty list.
class EmptyHint extends StatelessWidget {
  final String text;
  final IconData icon;
  const EmptyHint({
    super.key,
    required this.text,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 30, color: context.textTertiary),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// What a failed query shows instead of a spinner that never ends.
class LoadErrorView extends StatelessWidget {
  final Object? error;
  final String what;
  final VoidCallback? onRetry;
  const LoadErrorView({
    super.key,
    required this.error,
    required this.what,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.error,
            size: 26,
          ),
          const SizedBox(height: 6),
          Text(
            'Could not load $what.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$error',
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: context.textSecondary, fontSize: 11),
          ),
          if (onRetry != null)
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}

/// Small centred spinner for a section that is still loading.
class SectionLoading extends StatelessWidget {
  const SectionLoading({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 16),
    child: Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ),
    ),
  );
}

/// Renders a snapshot's three states: error ([LoadErrorView]), still
/// loading ([SectionLoading]), or data.
Widget snapshotView<T>(
  AsyncSnapshot<T> snap, {
  required String what,
  required Widget Function(T data) builder,
  VoidCallback? onRetry,
}) {
  if (snap.hasError) {
    return LoadErrorView(error: snap.error, what: what, onRetry: onRetry);
  }
  if (!snap.hasData) return const SectionLoading();
  return builder(snap.data as T);
}
