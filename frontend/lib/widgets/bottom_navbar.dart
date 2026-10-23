import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/theme_extensions.dart';

class AppBottomNavBar extends StatelessWidget {
  final String currentRoute;
  final VoidCallback? onRefreshRequired;

  const AppBottomNavBar({
    super.key,
    required this.currentRoute,
    this.onRefreshRequired,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xff161B2F) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 65,
          child: Row(
            children: [
              Expanded(
                child: _navItem(
                  context,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                  route: '/dashboard',
                  isSelected: currentRoute == '/dashboard',
                ),
              ),
              Expanded(
                child: _navItem(
                  context,
                  icon: Icons.history_rounded,
                  activeIcon: Icons.history_rounded,
                  label: 'History',
                  route: '/history',
                  isSelected: currentRoute == '/history',
                ),
              ),
              Expanded(
                child: _addButtonItem(context),
              ),
              Expanded(
                child: _navItem(
                  context,
                  icon: Icons.pie_chart_outline_rounded,
                  activeIcon: Icons.pie_chart_rounded,
                  label: 'Analytics',
                  route: '/analytics',
                  isSelected: currentRoute == '/analytics',
                ),
              ),
              Expanded(
                child: _navItem(
                  context,
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings_rounded,
                  label: 'Settings',
                  route: '/settings',
                  isSelected: currentRoute == '/settings',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xff1E1E2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Add Transaction",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 24),
              _optionTile(
                ctx,
                icon: Icons.trending_down_rounded,
                iconColor: Colors.redAccent,
                title: "Expenses",
                subtitle: "Add a new expense",
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/add-expense').then((res) {
                    if (res == true && onRefreshRequired != null) {
                      onRefreshRequired!();
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              _optionTile(
                ctx,
                icon: Icons.trending_up_rounded,
                iconColor: Colors.green,
                title: "Income",
                subtitle: "Add new income",
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/add-income').then((res) {
                    if (res == true && onRefreshRequired != null) {
                      onRefreshRequired!();
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              _optionTile(
                ctx,
                icon: Icons.swap_horiz_rounded,
                iconColor: Colors.blue,
                title: "Transfer",
                subtitle: "Transfer between accounts",
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/add-transfer').then((res) {
                    if (res == true && onRefreshRequired != null) {
                      onRefreshRequired!();
                    }
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _optionTile(BuildContext ctx, {required IconData icon, required Color iconColor, required String title, required String subtitle, required VoidCallback onTap}) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xff2A2A3C) : const Color(0xffF5F5F5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: isDark ? Colors.white38 : Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _addButtonItem(BuildContext context) {
    return InkWell(
      onTap: () => _showAddOptions(context),
      borderRadius: BorderRadius.circular(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xff7B4DFF),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff7B4DFF).withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            "Add",
            style: TextStyle(
              color: Color(0xff7B4DFF),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required String route,
    required bool isSelected,
  }) {
    final activeColor = const Color(0xff7B4DFF);
    final inactiveColor = context.bottomBarIcon;

    return InkWell(
      onTap: () async {
        if (currentRoute != route) {
          if (route == '/dashboard') {
            context.go('/dashboard');
          } else {
            final res = await context.push(route);
            if (res == true && onRefreshRequired != null) {
              onRefreshRequired!();
            }
          }
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? activeColor : inactiveColor,
            size: 24,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isSelected ? activeColor : inactiveColor,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
