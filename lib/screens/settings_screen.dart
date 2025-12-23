import 'package:flutter/material.dart';
import '../auth_service.dart';
import '../theme_controller.dart';
import '../widgets/glass_container.dart';
import '../login_page.dart';
import '../services/time_tracker_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ThemeController _themeController = ThemeController();
  final TimeTrackerService _trackerService = TimeTrackerService();
  final TextEditingController _goalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _themeController.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeController.removeListener(_onThemeChanged);
    _goalController.dispose();
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  // Profile editing dialog
  void _showProfileDialog() {
    final user = AuthService().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No user signed in')));
      return;
    }

    final TextEditingController nameController = TextEditingController(
      text: user.displayName ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Display Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              final nav = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await user.updateDisplayName(newName);
                if (!mounted) return;
                nav.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Profile updated')),
                );
                setState(() {});
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text('Failed to update profile: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Projects removed from Settings screen per compact UI design.

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          isSmallScreen ? 12 : 24,
          12,
          isSmallScreen ? 12 : 24,
          100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Profile Section (moved from Home)
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    (AuthService().currentUser?.displayName ??
                                AuthService().currentUser?.email ??
                                'P')
                            .toString()
                            .trim()
                            .isNotEmpty
                        ? (AuthService().currentUser?.displayName ??
                                  AuthService().currentUser?.email ??
                                  'P')
                              .toString()
                              .trim()
                              .substring(0, 1)
                              .toUpperCase()
                        : 'P',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  AuthService().currentUser?.displayName ??
                      AuthService().currentUser?.email ??
                      'Your Profile',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  AuthService().currentUser?.email ?? '',
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white70),
                  onPressed: _showProfileDialog,
                ),
              ),
            ),

            // Daily Goal Section
            const Text(
              'Daily Goal',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<int>(
              stream: _trackerService.getDailyGoal(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading goal: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                final currentGoal = snapshot.data ?? (8 * 3600);
                final hours = (currentGoal / 3600).toStringAsFixed(1);
                return GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Target: $hours hours/day',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _goalController.text = (currentGoal / 3600)
                              .toString();
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Set Daily Goal (Hours)'),
                              content: TextField(
                                controller: _goalController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  suffixText: 'hrs',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    final hrs = double.tryParse(
                                      _goalController.text,
                                    );
                                    if (hrs == null || hrs <= 0 || hrs > 24) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Please enter a valid goal between 0.1 and 24 hours.',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    final nav = Navigator.of(context);
                                    await _trackerService.setDailyGoal(
                                      (hrs * 3600).toInt(),
                                    );
                                    if (!mounted) {
                                      return;
                                    }
                                    nav.pop();
                                  },
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Text('Edit'),
                      ),
                    ],
                  ),
                );
              },
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
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: SegmentedButton<ThemeMode>(
                segments: const <ButtonSegment<ThemeMode>>[
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto),
                    label: Text('System'),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode),
                    label: Text('Light'),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode),
                    label: Text('Dark'),
                  ),
                ],
                selected: <ThemeMode>{_themeController.themeMode},
                onSelectionChanged: (Set<ThemeMode> newSelection) {
                  _themeController.setThemeMode(newSelection.first);
                },
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
                    dense: true,
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: const Text(
                      'Logout',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () async {
                      final buildContext = context;
                      final nav = Navigator.of(buildContext);
                      final confirmed = await showDialog<bool>(
                        context: buildContext,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF1E1E1E),
                          title: const Text(
                            'Confirm Logout',
                            style: TextStyle(color: Colors.white),
                          ),
                          content: const Text(
                            'Are you sure you want to logout?',
                            style: TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => nav.pop(false),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Colors.white54),
                              ),
                            ),
                            TextButton(
                              onPressed: () => nav.pop(true),
                              child: const Text(
                                'Logout',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        if (!mounted) return;
                        await AuthService().logout();
                        if (!mounted) {
                          return;
                        }
                        nav.pushAndRemoveUntil(
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
}
