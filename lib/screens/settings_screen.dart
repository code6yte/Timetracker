import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../auth_service.dart';
import '../theme_controller.dart';
import '../widgets/glass_container.dart';
import '../login_page.dart';
import '../services/time_tracker_service.dart';
import '../utils/ui_helpers.dart';
import '../models/time_entry.dart';

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
    if (user == null || user.isAnonymous) {
      AppUI.showSnackBar(
        context, 
        user == null ? 'No user signed in' : 'Profile editing is not available for guests', 
        type: SnackBarType.warning
      );
      return;
    }

    final TextEditingController nameController = TextEditingController(
      text: user.displayName ?? '',
    );

    AppUI.showAppBottomSheet(
      context: context,
      title: 'Edit Profile',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: nameController,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'Display Name',
              labelStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final newName = nameController.text.trim();
                    final nav = Navigator.of(context);
                    try {
                      await user.updateDisplayName(newName);
                      if (!mounted) return;
                      nav.pop();
                      AppUI.showSnackBar(
                        context, 
                        'Profile updated', 
                        type: SnackBarType.success
                      );
                      setState(() {});
                    } catch (e) {
                      if (!mounted) return;
                      AppUI.showSnackBar(
                        context, 
                        'Failed to update profile: $e', 
                        type: SnackBarType.error
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

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
          8,
          isSmallScreen ? 12 : 24,
          100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            // Profile Section (moved from Home)
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    (AuthService().currentUser?.isAnonymous ?? false)
                        ? 'G'
                        : (AuthService().currentUser?.displayName ??
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
                  (AuthService().currentUser?.isAnonymous ?? false)
                      ? 'Guest User'
                      : AuthService().currentUser?.displayName ??
                          AuthService().currentUser?.email ??
                          'Your Profile',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.black
                        : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  (AuthService().currentUser?.isAnonymous ?? false)
                      ? 'Limited Access'
                      : AuthService().currentUser?.email ?? '',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  onPressed: _showProfileDialog,
                ),
              ),
            ),

            // Daily Goal Section
            Text(
              'Daily Goal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
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
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  );
                }
                final currentGoal = snapshot.data ?? (8 * 3600);
                final hours = (currentGoal / 3600).toStringAsFixed(1);
                return GlassContainer(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Target: $hours hours/day',
                        style: TextStyle(
                          color:
                              Theme.of(context).brightness == Brightness.light
                              ? Colors.black
                              : Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _goalController.text = (currentGoal / 3600)
                              .toString();
                          AppUI.showAppBottomSheet(
                            context: context,
                            title: 'Set Daily Goal',
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  controller: _goalController,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Hours per day',
                                    suffixText: 'hrs',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                        ),
                                        child: Text(
                                          'Cancel',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          final hrs = double.tryParse(
                                            _goalController.text,
                                          );
                                          if (hrs == null || hrs <= 0 || hrs > 24) {
                                            AppUI.showSnackBar(
                                              context, 
                                              'Please enter a valid goal between 0.1 and 24 hours.',
                                              type: SnackBarType.warning
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
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context).colorScheme.primary,
                                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
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
            Text(
              'Appearance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            GlassContainer(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
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

            const SizedBox(height: 12),

            // Data Section
            Text(
              'Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            GlassContainer(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.download,
                      color: Colors.blueAccent,
                    ),
                    title: const Text('Export Data (CSV)'),
                    subtitle: Text(
                      'Export tracked entries as CSV',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    onTap: () async {
                      try {
                        final path = await _trackerService.exportToCSV();
                        await Share.shareXFiles([
                          XFile(path),
                        ], text: 'Time Tracker Export');
                        if (mounted) {
                          AppUI.showSnackBar(
                            context, 
                            'Exported to $path', 
                            type: SnackBarType.success
                          );
                        }
                      } catch (e) {
                        AppUI.showSnackBar(
                          context, 
                          'Export failed: $e', 
                          type: SnackBarType.error
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            // Account Section
            Text(
              'Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<bool>(
              stream: Stream.fromFuture(_trackerService.hasRunningTimer()),
              builder: (context, snapshot) {
                // We use a StreamBuilder but since hasRunningTimer is a Future, 
                // we should actually use a proper stream or just check once.
                // However, to keep it simple and reactive to the service, 
                // let's check if the user can logout.
                return GlassContainer(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      StreamBuilder<TimeEntry?>(
                        stream: _trackerService.getRunningTimer(),
                        builder: (context, timerSnap) {
                          final isRunning = timerSnap.hasData && timerSnap.data != null;
                          if (isRunning) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                'Finish your active timer to logout',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            );
                          }
                          return ListTile(
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
                              final confirmed = await AppUI.showConfirmDialog(
                                buildContext,
                                title: 'Confirm Logout',
                                body: 'Are you sure you want to logout?',
                                confirmLabel: 'Logout',
                                confirmColor: Colors.redAccent,
                              );
                              
                              if (confirmed) {
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
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
