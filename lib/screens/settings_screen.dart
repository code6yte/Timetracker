import 'package:flutter/material.dart';
import '../auth_service.dart';
import '../theme_controller.dart';
import '../widgets/glass_container.dart';
import '../login_page.dart';
import '../services/time_tracker_service.dart';
import '../models/category.dart';

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
        backgroundColor:
            Theme.of(context).dialogTheme.backgroundColor ??
            Theme.of(context).colorScheme.surface,
        title: Text(
          'Edit Profile',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
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

  final List<String> _defaultColors = [
    '#FFC107',
    '#FF9800',
    '#2196F3',
    '#4CAF50',
    '#9C27B0',
    '#F44336',
    '#607D8B',
    '#795548',
  ];

  Color _safeParseColor(String colorStr, {Color? fallback}) {
    try {
      return Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
    } catch (_) {
      return fallback ?? const Color(0xFF2196F3);
    }
  }

  void _showAddCategoryDialog() {
    final TextEditingController nameController = TextEditingController();
    String selectedColor = _defaultColors.first;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor:
              Theme.of(context).dialogTheme.backgroundColor ??
              Theme.of(context).colorScheme.surface,
          title: Text(
            'New Category',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Category Name',
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: _defaultColors.map((color) {
                  final isSelected = selectedColor == color;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedColor = color),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _safeParseColor(color),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: Theme.of(context).colorScheme.onSurface,
                                width: 2,
                              )
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(context);
                try {
                  await _trackerService.createProject(name, selectedColor);
                  if (!mounted) return;
                  nav.pop();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Category created')),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Failed to create category: $e')),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCategoryDialog(Category cat) {
    final TextEditingController nameController = TextEditingController(
      text: cat.name,
    );
    String selectedColor = cat.color;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor:
              Theme.of(context).dialogTheme.backgroundColor ??
              Theme.of(context).colorScheme.surface,
          title: Text(
            'Edit Category',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Category Name',
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: _defaultColors.map((color) {
                  final isSelected = selectedColor == color;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedColor = color),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _safeParseColor(color),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: Theme.of(context).colorScheme.onSurface,
                                width: 2,
                              )
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(context);
                try {
                  await _trackerService.updateProject(
                    cat.id,
                    name,
                    selectedColor,
                  );
                  if (!mounted) return;
                  nav.pop();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Category updated')),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Failed to update category: $e')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteCategory(Category cat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            Theme.of(context).dialogTheme.backgroundColor ??
            Theme.of(context).colorScheme.surface,
        title: Text(
          'Delete Category',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          'Delete "${cat.name}"? This will not delete tasks automatically.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final messenger = ScaffoldMessenger.of(context);
      try {
        await _trackerService.deleteProject(cat.id);
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Category deleted')),
        );
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to delete category: $e')),
        );
      }
    }
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
          32,
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
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.black
                        : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  AuthService().currentUser?.email ?? '',
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
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
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

            // Categories Section
            Text(
              'Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            GlassContainer(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  StreamBuilder<List<Category>>(
                    stream: _trackerService.getCategories(),
                    builder: (context, snap) {
                      if (!snap.hasData) return const SizedBox(height: 60);
                      final cats = snap.data ?? [];
                      if (cats.isEmpty) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'No categories yet',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            TextButton(
                              onPressed: _showAddCategoryDialog,
                              child: Text('Add'),
                            ),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          ...cats.map(
                            (c) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: _safeParseColor(c.color),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              title: Text(
                                c.name,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                    onPressed: () => _showEditCategoryDialog(c),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () => _deleteCategory(c),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _showAddCategoryDialog,
                              child: Text('Add Category'),
                            ),
                          ),
                        ],
                      );
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
            GlassContainer(
              padding: const EdgeInsets.all(12),
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
                          backgroundColor:
                              Theme.of(context).dialogTheme.backgroundColor ??
                              Theme.of(context).colorScheme.surface,
                          title: Text(
                            'Confirm Logout',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          content: Text(
                            'Are you sure you want to logout?',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => nav.pop(false),
                              child: Text(
                                'Cancel',
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
