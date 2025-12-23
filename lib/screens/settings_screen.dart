import 'package:flutter/material.dart';
import '../auth_service.dart';
import '../theme_controller.dart';
import '../widgets/glass_container.dart';
import '../login_page.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ThemeController _themeController = ThemeController();

  @override
  void initState() {
    super.initState();
    _themeController.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeController.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Appearance Section
            const Text(
              'Appearance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildThemeOption(
                    title: 'System Default',
                    icon: Icons.brightness_auto,
                    value: ThemeMode.system,
                    groupValue: _themeController.themeMode,
                    onChanged: (val) => _themeController.setThemeMode(val!),
                  ),
                  const Divider(color: Colors.white24),
                  _buildThemeOption(
                    title: 'Light Mode',
                    icon: Icons.light_mode,
                    value: ThemeMode.light,
                    groupValue: _themeController.themeMode,
                    onChanged: (val) => _themeController.setThemeMode(val!),
                  ),
                  const Divider(color: Colors.white24),
                  _buildThemeOption(
                    title: 'Dark Mode',
                    icon: Icons.dark_mode,
                    value: ThemeMode.dark,
                    groupValue: _themeController.themeMode,
                    onChanged: (val) => _themeController.setThemeMode(val!),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Account Section
            const Text(
              'Account',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: const Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () async {
                      await AuthService().logout();
                      if (mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                          (route) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required String title,
    required IconData icon,
    required ThemeMode value,
    required ThemeMode groupValue,
    required ValueChanged<ThemeMode?> onChanged,
  }) {
    final isSelected = value == groupValue;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.blueAccent : Colors.white70,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.blueAccent : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Colors.blueAccent)
          : const Icon(Icons.circle_outlined, color: Colors.white24),
      onTap: () => onChanged(value),
    );
  }
}
