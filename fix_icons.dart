import 'dart:io';

void main() {
  final file = File(
    'd:/Noorulain FYP/transit_admin/lib/screens/admin/admin_dashboard.dart',
  );
  final lines = file.readAsLinesSync();
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].contains("icon: '")) {
      if (i + 1 < lines.length && lines[i + 1].contains('Active Buses')) {
        lines[i] = '                      icon: Icons.directions_bus_rounded,';
      } else if (i + 1 < lines.length && lines[i + 1].contains('Students')) {
        lines[i] = '                      icon: Icons.school_rounded,';
      } else if (i + 1 < lines.length && lines[i + 1].contains('Routes')) {
        lines[i] = '                      icon: Icons.route_rounded,';
      } else if (i + 1 < lines.length && lines[i + 1].contains('Revenue')) {
        lines[i] =
            '                      icon: Icons.account_balance_wallet_rounded,';
      } else if (i + 1 < lines.length &&
          lines[i + 1].contains('color: AppTheme.studentAmber')) {
        lines[i] = '                        icon: Icons.school_rounded,';
      } else if (i + 1 < lines.length &&
          lines[i + 1].contains('color: AppTheme.parentPurple')) {
        lines[i] =
            '                        icon: Icons.family_restroom_rounded,';
      } else if (i + 1 < lines.length &&
          lines[i + 1].contains('color: AppTheme.info') &&
          i - 1 >= 0 &&
          lines[i - 1].contains('Request')) {
        lines[i] = '                        icon: Icons.alt_route_rounded,';
      } else if (i + 1 < lines.length && lines[i + 1].contains('Add Route')) {
        lines[i] =
            '                            icon: Icons.add_location_alt_rounded,';
      } else if (i + 1 < lines.length && lines[i + 1].contains('Add User')) {
        lines[i] =
            '                            icon: Icons.person_add_rounded,';
      } else if (i + 1 < lines.length && lines[i + 1].contains('Add Bus')) {
        lines[i] =
            '                            icon: Icons.directions_bus_filled_rounded,';
      } else if (i + 1 < lines.length && lines[i + 1].contains('Report')) {
        lines[i] = '                            icon: Icons.analytics_rounded,';
      } else if (lines[i].contains('⚠️') ||
          lines[i].toLowerCase().contains('warning')) {
        lines[i] = '                        icon: Icons.warning_rounded,';
      }
    }
  }
  file.writeAsStringSync(lines.join('\n'));
  print('Done fixing emojis.');
}
