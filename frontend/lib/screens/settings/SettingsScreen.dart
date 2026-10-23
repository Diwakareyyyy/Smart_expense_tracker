import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_extensions.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/bottom_navbar.dart';
import '../../widgets/profile_avatar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;
  String selectedCurrency = '₹ INR';

  @override
  void initState() {
    super.initState();
    context.read<UserProvider>().loadFromStorage();
  }

  void _showCurrencyDialog(BuildContext context) {
    final currencies = ['₹ INR', '\$ USD', '€ EUR'];

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: context.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Currency',
            style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: currencies.map((currency) {
              final isSelected = selectedCurrency == currency;
              return ListTile(
                title: Text(
                  currency,
                  style: TextStyle(
                    color: isSelected ? const Color(0xff7B4DFF) : context.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Color(0xff7B4DFF))
                    : null,
                onTap: () {
                  setState(() => selectedCurrency = currency);
                  Navigator.pop(ctx);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: context.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'About',
            style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Smart AI Expense Tracker helps you manage income, expenses, budgets, and insights in one place.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: context.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Logout',
            style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to log out?',
            style: TextStyle(color: context.textSecondary, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('No'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await AuthService.instance.logout();
                if (context.mounted) context.go('/login');
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: context.appBg,
      appBar: AppBar(
        backgroundColor: context.appBg,
        elevation: 0,
        title: Text(
          "Settings",
          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: context.textPrimary),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentRoute: '/settings'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff6A3DFF), Color(0xff9D74FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff7B4DFF).withValues(alpha: 0.22),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ProfileAvatar(
                    photo: user.profilePhoto,
                    name: user.userName,
                    radius: 30,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.userEmail.isNotEmpty ? user.userEmail : 'Premium User',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _sectionHeader('Profile'),
            _settingsTile(
              context,
              icon: Icons.person_outline,
              iconBgColor: const Color(0xff7B4DFF),
              title: 'Edit Profile',
              subtitle: 'Update your personal details',
              onTap: () async {
                await context.push('/profile');
                if (mounted) context.read<UserProvider>().loadFromStorage();
              },
            ),
            const SizedBox(height: 18),
            _sectionHeader('Preferences'),
            const SizedBox(height: 10),
            _settingsSwitchTile(
              context,
              icon: themeProvider.isDark ? Icons.dark_mode : Icons.light_mode,
              iconBgColor: Colors.orange,
              title: "App Theme",
              subtitle: themeProvider.isDark ? 'Dark mode enabled' : 'Light mode enabled',
              value: themeProvider.isDark,
              onChanged: (val) => themeProvider.toggleTheme(val),
            ),
            const SizedBox(height: 10),
            _settingsSwitchTile(
              context,
              icon: Icons.notifications_outlined,
              iconBgColor: Colors.redAccent,
              title: 'Notifications',
              subtitle: notificationsEnabled ? 'Enabled' : 'Disabled',
              value: notificationsEnabled,
              onChanged: (val) => setState(() => notificationsEnabled = val),
            ),
            const SizedBox(height: 18),
            _sectionHeader('Support'),
            _settingsTile(
              context,
              icon: Icons.menu_book_rounded,
              iconBgColor: Colors.deepOrange,
              title: 'How to Use',
              subtitle: 'App guide and tutorials',
              onTap: () => context.push('/guide'),
            ),
            const SizedBox(height: 10),
            _settingsTile(
              context,
              icon: Icons.privacy_tip_outlined,
              iconBgColor: Colors.blue,
              title: 'Privacy Policy',
              subtitle: 'Read terms and privacy details',
              onTap: () => context.push('/terms'),
            ),
            const SizedBox(height: 10),
            _settingsTile(
              context,
              icon: Icons.info_outline,
              iconBgColor: Colors.purple,
              title: 'About',
              subtitle: 'App details and version info',
              onTap: () => _showAboutDialog(context),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.logout, color: Colors.white),
                label: Text(
                  "Logout",
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                onPressed: () => _showLogoutDialog(context),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(color: context.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _settingsTile(
    BuildContext context, {
    required IconData icon,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.divider.withValues(alpha: 0.35)),
        boxShadow: context.isDarkTheme
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconBgColor,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: context.textSecondary),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _settingsSwitchTile(
    BuildContext context, {
    required IconData icon,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.divider.withValues(alpha: 0.35)),
        boxShadow: context.isDarkTheme
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: SwitchListTile.adaptive(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: CircleAvatar(
          backgroundColor: iconBgColor,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: context.textSecondary),
        ),
        value: value,
        activeColor: const Color(0xff7B4DFF),
        onChanged: onChanged,
      ),
    );
  }
}
