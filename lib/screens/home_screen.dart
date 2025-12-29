import 'package:flutter/material.dart';
import 'tasks_tab.dart';
import 'timer_tab.dart';
import 'settings_screen.dart';
import 'reports_screen.dart';
import '../services/time_tracker_service.dart';
import '../models/task.dart';
import '../models/time_entry.dart';
import '../models/project.dart';
import 'project_details_screen.dart';
import '../widgets/glass_container.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _showAddMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.folder_shared),
              title: const Text('Add Project'),
              onTap: () {
                Navigator.pop(ctx);
                _showAddProjectDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_task_rounded),
              title: const Text('Add Task'),
              onTap: () {
                Navigator.pop(ctx);
                _showAddTaskDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  int _currentIndex = 0;
  final List<Widget> _tabs = [
    const TasksTab(),
    const TimerTab(),
    const ReportsScreen(),
    const SettingsScreen(),
  ];

  final TimeTrackerService _service = TimeTrackerService();

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

  void _showAddProjectDialog() {
    final TextEditingController nameController = TextEditingController();
    String selectedColor = '#FFC107';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor:
              Theme.of(context).dialogTheme.backgroundColor ??
              Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'New Project',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Project Name',
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha((0.18 * 255).toInt()),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _safeParseColor(selectedColor),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: _safeParseColor(selectedColor),
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  final nav = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await _service.createProject(name, selectedColor);
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text('Failed to create project: $e')),
                    );
                    return;
                  }
                  if (!mounted) return;
                  nav.pop();
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog() {
    final TextEditingController taskController = TextEditingController();
    String? selectedProjectId;
    String selectedProjectName = 'Inbox';
    String selectedColor = '#FFC107';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor:
                Theme.of(context).dialogTheme.backgroundColor ??
                Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text(
              'New Task',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: taskController,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Task name',
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(
                          (0.18 * 255).toInt(),
                        ),
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
                const SizedBox(height: 12),
                StreamBuilder<List<Project>>(
                  stream: _service.getProjects(),
                  builder: (context, snap) {
                    final projects = snap.data ?? [];
                    final items = [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('Inbox'),
                      ),
                      ...projects.map(
                        (p) => DropdownMenuItem<String>(
                          value: p.id,
                          child: Text(p.name),
                        ),
                      ),
                    ];
                    return DropdownButtonFormField<String>(
                      initialValue: selectedProjectId ?? '',
                      items: items,
                      decoration: const InputDecoration(labelText: 'Project'),
                      onChanged: (v) {
                        setDialogState(() {
                          selectedProjectId = v;
                          final p = projects.firstWhere(
                            (pr) => pr.id == v,
                            orElse: () => Project(
                              id: '',
                              name: 'Inbox',
                              color: '#FFC107',
                              createdAt: DateTime.now().millisecondsSinceEpoch,
                            ),
                          );
                          selectedProjectName = p.name;
                        });
                      },
                    );
                  },
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
                  final title = taskController.text.trim();
                  if (title.isEmpty) return;
                  if (selectedProjectId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select a project for the task'),
                      ),
                    );
                    return;
                  }
                  final messenger = ScaffoldMessenger.of(context);
                  final nav = Navigator.of(context);
                  try {
                    await _service.createTask(
                      title,
                      '',
                      selectedProjectId ?? '',
                      selectedProjectName,
                      selectedColor,
                    );
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text('Failed to create task: $e')),
                    );
                    return;
                  }
                  if (!mounted) return;
                  nav.pop();
                },
                child: const Text('Create Task'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteProject(Project p) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            Theme.of(context).dialogTheme.backgroundColor ??
            Theme.of(context).colorScheme.surface,
        title: Text(
          'Delete Project',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          'Delete "${p.name}"? This will not delete tasks automatically.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
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
    if (confirmed != true) return;
    try {
      await _service.deleteProject(p.id);
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Project deleted')));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to delete project: $e')),
      );
    }
  }

  void _showEditProjectDialog(Project project) {
    final nameController = TextEditingController(text: project.name);
    String selectedColor = project.color;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor:
                Theme.of(context).dialogTheme.backgroundColor ??
                Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text(
              'Edit Project',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Project Name',
                      labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.onSurface.withAlpha(
                            (0.18 * 255).toInt(),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: _safeParseColor(selectedColor),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: _defaultColors.map((color) {
                      final isSelected = selectedColor == color;
                      return GestureDetector(
                        onTap: () =>
                            setDialogState(() => selectedColor = color),
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
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;
                  final messenger = ScaffoldMessenger.of(context);
                  final nav = Navigator.of(context);
                  try {
                    await _service.updateProject(
                      project.id,
                      name,
                      selectedColor,
                    );
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text('Failed to update project: $e')),
                    );
                    return;
                  }
                  if (!mounted) return;
                  nav.pop();
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          _currentIndex == 0 ? _buildDashboard() : _tabs[_currentIndex],
          if (_currentIndex == 0)
            Positioned(
              bottom: 24,
              right: 24,
              child: FloatingActionButton.extended(
                heroTag: 'add_fab',
                onPressed: () => _showAddMenu(context),
                icon: const Icon(Icons.add),
                label: const Text('Add'),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          // Persistent running stopwatch stop button (hide for focus sessions)
          StreamBuilder<TimeEntry?>(
            stream: _service.getRunningTimer(),
            builder: (context, snapshot) {
              final running = snapshot.data;
              // Do not show stop FAB for focus sessions (sync only with stopwatch)
              if (running == null || running.source == 'focus') {
                return const SizedBox.shrink();
              }
              return Positioned(
                bottom: 24,
                left: 24,
                child: FloatingActionButton.extended(
                  heroTag: 'stop_fab',
                  backgroundColor: Colors.redAccent,
                  icon: const Icon(Icons.stop),
                  label: Text(
                    running.taskTitle.length > 20
                        ? '${running.taskTitle.substring(0, 20)}...'
                        : running.taskTitle,
                  ),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await _service.stopTimer(running.id);
                      if (!mounted) return;
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Timer stopped')),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(content: Text('Failed to stop timer: $e')),
                      );
                    }
                  },
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        bottom: true,
        minimum: const EdgeInsets.only(bottom: 8),
        child: GlassContainer(
          margin: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          borderRadius: BorderRadius.circular(14),
          color: Colors.black,
          opacity: 0.26,
          height: 72,
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
            type: BottomNavigationBarType.fixed,
            iconSize: 24,
            selectedFontSize: 12,
            unselectedFontSize: 11,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.folder_shared),
                label: 'Projects',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Timer'),
              BottomNavigationBarItem(
                icon: Icon(Icons.insights),
                label: 'Reports',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    final screenWidth = MediaQuery.of(context).size.width;
    // final isSmallScreen = screenWidth < 600; // Unused variable removed

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        screenWidth * 0.03,
        12,
        screenWidth * 0.03,
        100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),

          // Quick stats row
          Row(
            children: [
              Expanded(
                child: GlassContainer(
                  padding: const EdgeInsets.all(12),
                  child: StreamBuilder<List<TimeEntry>>(
                    stream: _service.getTodayEntries(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading data',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        );
                      }
                      final entries = snapshot.data ?? [];
                      // Only count non-focus entries for the dashboard Today stat
                      final totalSeconds = entries.fold<int>(
                        0,
                        (s, e) => s + ((e.source == 'focus') ? 0 : e.duration),
                      );
                      final hours = (totalSeconds / 3600).floor();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Today',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Semantics(
                            label: 'Today\'s tracked hours: $hours hours',
                            child: Text(
                              '${hours}h',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GlassContainer(
                  padding: const EdgeInsets.all(12),
                  child: StreamBuilder<List<dynamic>>(
                    stream: _service.getTasks(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading data',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        );
                      }
                      final tasks = snapshot.data ?? [];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tasks',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Semantics(
                            label: 'Number of tasks: ${tasks.length}',
                            child: Text(
                              '${tasks.length}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          // Projects section (recent)
          Text(
            'Projects',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<Project>>(
            stream: _service.getProjects(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 60);
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading projects',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                );
              }
              final projects = snapshot.data ?? [];
              if (projects.isEmpty) {
                return GlassContainer(
                  padding: const EdgeInsets.all(12),
                  child: Center(
                    child: Text(
                      'No projects yet',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }

              final recentP = projects.take(3).toList();
              return Column(
                children: [
                  ...recentP.map((p) {
                    return Dismissible(
                      key: Key(p.id),
                      direction: DismissDirection.horizontal,
                      background: Container(
                        padding: const EdgeInsets.only(left: 20),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade700,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.open_in_new, color: Colors.white),
                            const SizedBox(width: 8),
                            Text('Open', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      secondaryBackground: Container(
                        padding: const EdgeInsets.only(right: 20),
                        alignment: Alignment.centerRight,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: const [
                            Icon(Icons.delete, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          if (!mounted) return false;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProjectDetailsScreen(project: p),
                            ),
                          );
                          return false;
                        }
                        if (direction == DismissDirection.endToStart) {
                          final messenger = ScaffoldMessenger.of(context);
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor:
                                  Theme.of(
                                    context,
                                  ).dialogTheme.backgroundColor ??
                                  Theme.of(context).colorScheme.surface,
                              title: Text(
                                'Delete Project',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              content: Text(
                                'Delete "${p.name}"? This will not delete tasks automatically.',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
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
                            try {
                              await _service.deleteProject(p.id);
                              if (!mounted) return false;
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Project deleted'),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return false;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Failed to delete project: $e'),
                                ),
                              );
                            }
                          }
                          return false;
                        }
                        return false;
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProjectDetailsScreen(project: p),
                              ),
                            );
                          },
                          child: GlassContainer(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            color: _safeParseColor(p.color),
                            opacity: 0.08,
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: _safeParseColor(p.color),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    p.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: Colors.white70,
                                  ),
                                  onSelected: (v) async {
                                    if (v == 'view') {
                                      setState(() => _currentIndex = 0);
                                    } else if (v == 'details') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ProjectDetailsScreen(project: p),
                                        ),
                                      );
                                    } else if (v == 'edit') {
                                      _showEditProjectDialog(p);
                                    } else if (v == 'delete') {
                                      await _deleteProject(p);
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'view',
                                      child: Text('Open'),
                                    ),
                                    PopupMenuItem(
                                      value: 'details',
                                      child: Text('Details'),
                                    ),
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  if (projects.length > 3)
                    TextButton(
                      onPressed: () => setState(() => _currentIndex = 0),
                      child: Text(
                        'View All Projects',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          Text(
            'Recent Tasks',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<Task>>(
            stream: _service.getTasks(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading tasks',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                );
              }
              final tasks = snapshot.data ?? [];
              if (tasks.isEmpty) {
                return GlassContainer(
                  padding: const EdgeInsets.all(12),
                  child: Center(
                    child: Text(
                      'No recent tasks',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }
              final recent = tasks.take(3).toList();
              return Column(
                children: [
                  ...recent.map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: GlassContainer(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        color: _safeParseColor(t.color),
                        opacity: 0.06,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _safeParseColor(t.color),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                t.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.timer,
                                color: Colors.amberAccent,
                              ),
                              tooltip: 'Start Timer',
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                try {
                                  await _service.startTimer(
                                    t.id,
                                    t.title,
                                    t.category,
                                  );
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Timer started for ${t.title}',
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to start timer: $e',
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert,
                                color: Colors.white70,
                              ),
                              onSelected: (v) async {
                                if (v == 'edit') {
                                  _showEditTaskDialog(t);
                                } else if (v == 'delete') {
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor:
                                          Theme.of(
                                            context,
                                          ).dialogTheme.backgroundColor ??
                                          Theme.of(context).colorScheme.surface,
                                      title: Text(
                                        'Delete Task',
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                      ),
                                      content: Text(
                                        'Delete "${t.title}"?',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text(
                                            'Delete',
                                            style: TextStyle(
                                              color: Colors.redAccent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true) {
                                    try {
                                      await _service.deleteTask(t.id);
                                      if (!mounted) return;
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text('Task deleted'),
                                        ),
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Failed to delete task: $e',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (tasks.length > 3)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _currentIndex = 0;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Navigate to full tasks list'),
                          ),
                        );
                      },
                      child: Text(
                        'View All Tasks',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _showEditTaskDialog(Task task) {
    final TextEditingController editController = TextEditingController(
      text: task.title,
    );
    String? selectedProjectId = task.projectId.isNotEmpty
        ? task.projectId
        : null;
    String selectedProjectName = task.projectId.isNotEmpty
        ? task.category
        : 'Inbox';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Edit Task',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: editController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Task name',
                  labelStyle: TextStyle(color: Colors.white60),
                ),
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<Project>>(
                stream: _service.getProjects(),
                builder: (context, snap) {
                  final projects = snap.data ?? [];
                  final items = [
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('Inbox'),
                    ),
                    ...projects.map(
                      (p) => DropdownMenuItem<String>(
                        value: p.id,
                        child: Text(p.name),
                      ),
                    ),
                  ];
                  return DropdownButtonFormField<String>(
                    initialValue: selectedProjectId ?? '',
                    items: items,
                    decoration: const InputDecoration(labelText: 'Project'),
                    onChanged: (v) {
                      setDialogState(() {
                        selectedProjectId = v;
                        final p = projects.firstWhere(
                          (pr) => pr.id == v,
                          orElse: () => Project(
                            id: '',
                            name: 'Inbox',
                            color: '#FFC107',
                            createdAt: DateTime.now().millisecondsSinceEpoch,
                          ),
                        );
                        selectedProjectName = p.name;
                      });
                    },
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = editController.text.trim();
                if (title.isEmpty) return;
                final nav = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await _service.updateTask(
                    task.id,
                    title,
                    task.description,
                    selectedProjectId ?? '',
                    selectedProjectName,
                  );
                  if (!mounted) return;
                  nav.pop();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Task updated')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(content: Text('Failed to update task: $e')),
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
}
