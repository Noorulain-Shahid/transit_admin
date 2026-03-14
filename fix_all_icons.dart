import 'dart:io';

void main() {
  final dir = Directory('d:/Noorulain FYP/transit_admin/lib/screens/admin');
  final files = dir.listSync().whereType<File>().toList();

  for (final file in files) {
    if (!file.path.endsWith('.dart') ||
        file.path.endsWith('admin_dashboard.dart') ||
        file.path.endsWith('admin_layout.dart')) {
      continue;
    }

    String content = file.readAsStringSync();

    // Convert final String icon -> final IconData icon
    content = content.replaceAll(
      'final String icon,',
      'final IconData icon;\n  final String',
    );

    // Replace text-based icon implementations with Row or Icon
    // _MiniStat text replacement
    content = content.replaceAll(
      "Text(icon, style: const TextStyle(fontSize: 22))",
      "Icon(icon, color: color, size: 26)",
    );

    content = content.replaceAll(
      "Text(icon, style: const TextStyle(fontSize: 20))",
      "Icon(icon, color: color, size: 24)",
    );

    content = content.replaceAll(
      "Text(icon, style: const TextStyle(fontSize: 18))",
      "Icon(icon, color: color, size: 22)",
    );

    // Replace $icon $value in VehicleInfo or StudentInfo etc.
    content = content.replaceAll(
      "Text(\n              '\$icon \$value',\n              style: TextStyle(",
      "Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: context.textSecondary, size: 14), const SizedBox(width:4), Text(value, style: TextStyle(",
    );

    // For anything that just adds closing block
    content = content.replaceAll(
      ",\n              ),\n            ),",
      ",\n              ),\n            )]) ,",
    );

    // Some specific pattern in admin_profile
    content = content.replaceAll(
      "Text(\n            icon,\n            style: const TextStyle(fontSize: 18),\n          ),",
      "Icon(icon, size: 22),",
    );

    // Custom replacing for _ProfileStat etc
    content = content.replaceAll(
      "Text(icon, style: const TextStyle(fontSize: 24))",
      "Icon(icon, color: AppTheme.adminAccent, size: 28)",
    );

    // Now regular expressions for mapping emojis to Icons
    Map<String, String> iconMap = {
      "'🚌'": "Icons.directions_bus_rounded",
      "'✅'": "Icons.check_circle_rounded",
      "'🔧'": "Icons.build_circle_rounded",
      "'📅'": "Icons.calendar_today_rounded",
      "'💺'": "Icons.airline_seat_recline_normal_rounded",
      "'⛽'": "Icons.local_gas_station_rounded",
      "'🗺️'": "Icons.map_rounded",
      "'🧭'": "Icons.explore_rounded",
      "'📍'": "Icons.location_on_rounded",
      "'🛑'": "Icons.stop_circle_rounded",
      "'👥'": "Icons.people_alt_rounded",
      "'🎓'": "Icons.school_rounded",
      "'⏳'": "Icons.hourglass_empty_rounded",
      "'🔔'": "Icons.notifications_rounded",
      "'💰'": "Icons.account_balance_wallet_rounded",
      "'⚙️'": "Icons.settings_rounded",
      "'🔒'": "Icons.lock_rounded",
      "'📰'": "Icons.article_rounded",
      // admin_profile specifics
      "'👤'": "Icons.person_rounded",
      "'🚌'": "Icons.directions_bus_rounded",
    };

    // Manually fixing them up
    // Replace icon: 'emoji' with icon: Icons.xxx
    // Since some characters are scrambled when read as ANSI but Dart reads as UTF-8!
    // Using RegExp to match icon: '...'
    final RegExp iconRegex = RegExp(r"icon:\s*'([^']+)'");
    content = content.replaceAllMapped(iconRegex, (match) {
      String? emoji = match.group(1);
      String fullMatch = match.group(0)!;
      // In dart reading utf-8, it will be the actual emojis.
      for (final entry in iconMap.entries) {
        if (entry.key == "'$emoji'") {
          return "icon: ${entry.value}";
        }
      }
      return "icon: Icons.star_rounded"; // fallback
    });

    file.writeAsStringSync(content);
  }
}
