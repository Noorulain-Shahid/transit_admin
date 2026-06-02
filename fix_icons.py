import re
import sys

path = 'd:/Noorulain FYP/transit_admin/lib/screens/admin/admin_dashboard.dart'
try:
    with open(path, 'r', encoding='utf-8') as f:
        text = f.read()

    lines = text.split('\n')
    for i, line in enumerate(lines):
        if "icon: '" in line:
            if i+1 < len(lines) and 'Active Buses' in lines[i+1]: lines[i] = '                      icon: Icons.directions_bus_rounded,'
            elif i+1 < len(lines) and 'Students' in lines[i+1]: lines[i] = '                      icon: Icons.school_rounded,'
            elif i+1 < len(lines) and 'Routes' in lines[i+1]: lines[i] = '                      icon: Icons.route_rounded,'
            elif i+1 < len(lines) and 'Revenue' in lines[i+1]: lines[i] = '                      icon: Icons.account_balance_wallet_rounded,'
            elif i+1 < len(lines) and 'color: AppTheme.studentAmber' in lines[i+1]: lines[i] = '                        icon: Icons.school_rounded,'
            elif i+1 < len(lines) and 'color: AppTheme.parentPurple' in lines[i+1]: lines[i] = '                        icon: Icons.family_restroom_rounded,'
            elif i+1 < len(lines) and 'color: AppTheme.info' in lines[i+1] and 'Request' in lines[i-1]: lines[i] = '                        icon: Icons.alt_route_rounded,'
            elif i+1 < len(lines) and 'Add Route' in lines[i+1]: lines[i] = '                            icon: Icons.add_location_alt_rounded,'
            elif i+1 < len(lines) and 'Add User' in lines[i+1]: lines[i] = '                            icon: Icons.person_add_rounded,'
            elif i+1 < len(lines) and 'Add Bus' in lines[i+1]: lines[i] = '                            icon: Icons.directions_bus_filled_rounded,'
            elif i+1 < len(lines) and 'Report' in lines[i+1]: lines[i] = '                            icon: Icons.analytics_rounded,'
            elif 'warning' in lines[i].lower() or '⚠️' in lines[i]: lines[i] = '                        icon: Icons.warning_rounded,'

    with open(path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))
    print("Success")
except Exception as e:
    print("Error:", e)
