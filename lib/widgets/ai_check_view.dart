import 'package:flutter/material.dart';
import 'package:transit_core/transit_core.dart';

import '../app/admin_format.dart';
import '../theme/app_theme.dart';

/// The AI checks the mobile app runs — on a family's payment screenshot
/// (`Payment.slipCheck`) and on a driver's licence / registration photo
/// (`DriverDocument.docCheck`) — shown to the admin. Display only: the
/// reading happens on the phones; nothing here calls ML Kit or Gemini.

String _engineLabel(String engine) => switch (engine) {
  'gemini' => 'read by Gemini',
  'ocr+gemini' => 'read on the phone + Gemini',
  _ => 'read on the phone',
};

/// "✅ AI: matches" / "⚠️ AI: 2 issues".
class AiBadge extends StatelessWidget {
  final bool matches;
  final int issueCount;
  const AiBadge({super.key, required this.matches, required this.issueCount});

  @override
  Widget build(BuildContext context) {
    final color = matches ? AppTheme.success : AppTheme.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        matches
            ? '✅ AI: matches'
            : '⚠️ AI: $issueCount issue${issueCount == 1 ? '' : 's'}',
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String label, value;
  const _Line(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 104,
          child: Text(
            label,
            style: TextStyle(color: context.textTertiary, fontSize: 11.5),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Messages extends StatelessWidget {
  final List<String> messages;
  final String bullet;
  const _Messages(this.messages, {this.bullet = '⚠️'});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final m in messages)
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(bullet, style: const TextStyle(fontSize: 11)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  m,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

/// A badge that opens into everything the check read. Starts open when
/// there is something to warn about.
class _Expandable extends StatefulWidget {
  final bool matches;
  final int issueCount;
  final String headline;
  final List<Widget> details;
  const _Expandable({
    required this.matches,
    required this.issueCount,
    required this.headline,
    required this.details,
  });

  @override
  State<_Expandable> createState() => _ExpandableState();
}

class _ExpandableState extends State<_Expandable> {
  late bool _open = !widget.matches;

  @override
  Widget build(BuildContext context) {
    final color = widget.matches ? AppTheme.success : AppTheme.warning;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Row(
              children: [
                AiBadge(matches: widget.matches, issueCount: widget.issueCount),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.headline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ),
                Icon(
                  _open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  size: 18,
                  color: context.textTertiary,
                ),
              ],
            ),
          ),
          if (_open) ...widget.details,
        ],
      ),
    );
  }
}

/// The slip check on one payment.
class SlipCheckView extends StatelessWidget {
  final SlipCheck check;
  const SlipCheckView({super.key, required this.check});

  @override
  Widget build(BuildContext context) {
    final c = check;
    final receiver = [
      if ((c.receiverName ?? '').isNotEmpty) c.receiverName!,
      if ((c.receiverAccountLast4 ?? '').isNotEmpty)
        '••${c.receiverAccountLast4}',
    ].join(' · ');
    return _Expandable(
      matches: c.matches,
      issueCount: c.issues.length,
      headline: c.matches
          ? 'Screenshot matches the bill'
          : c.issues.map(SlipCheck.shortLabel).join(', '),
      details: [
        const SizedBox(height: 4),
        if (c.amountLabel != null) _Line('Amount read', c.amountLabel!),
        if ((c.transactionId ?? '').isNotEmpty)
          _Line('Transaction ID', c.transactionId!),
        if (c.paidAt != null) _Line('Date', formatExactTime(c.paidAt!)),
        if (receiver.isNotEmpty) _Line('Sent to', receiver),
        if ((c.senderName ?? '').isNotEmpty) _Line('Sent by', c.senderName!),
        if (c.provider != 'unknown') _Line('App', c.providerLabel),
        if (c.issues.isNotEmpty) _Messages(c.messages()),
        const SizedBox(height: 4),
        Text(
          'Automatic check, ${_engineLabel(c.engine)}'
          '${c.checkedAt == null ? '' : ' · ${formatExactTime(c.checkedAt!)}'}',
          style: TextStyle(color: context.textTertiary, fontSize: 10),
        ),
      ],
    );
  }
}

/// The document check on one licence / registration card.
class DocCheckView extends StatelessWidget {
  final DocCheck check;
  const DocCheckView({super.key, required this.check});

  @override
  Widget build(BuildContext context) {
    final c = check;
    return _Expandable(
      matches: c.matches,
      issueCount: c.issues.length,
      headline: c.matches
          ? [
              'Looks right',
              if (c.nameMatchPercent != null) 'name ${c.nameMatchPercent}%',
            ].join(' · ')
          : c.issues.map(DocCheck.shortLabel).join(', '),
      details: [
        const SizedBox(height: 4),
        for (final f in c.displayFields) _Line(f.key, f.value),
        if (c.nameMatchPercent != null)
          _Line('Name match', '${c.nameMatchPercent}% with the profile'),
        if (c.expiryDate != null && !c.fields.containsKey('expiryDate'))
          _Line('Valid until', formatDate(c.expiryDate!)),
        if (c.issues.isNotEmpty) _Messages(c.messages()),
        if (c.notes.isNotEmpty) _Messages(c.noteMessages(), bullet: 'ℹ️'),
        const SizedBox(height: 4),
        Text(
          'Automatic check, ${_engineLabel(c.engine)} — verify against the '
          'image before approving.',
          style: TextStyle(color: context.textTertiary, fontSize: 10),
        ),
      ],
    );
  }
}
