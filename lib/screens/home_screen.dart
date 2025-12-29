import 'package:flutter/material.dart';
import 'timer_tab.dart';
import 'settings_screen.dart';
import 'reports_screen.dart';
import '../services/time_tracker_service.dart';
import '../models/task.dart';
import '../models/time_entry.dart';
import '../models/project.dart';
import 'project_details_screen.dart';
import '../widgets/glass_container.dart';
import '../utils/ui_helpers.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PageController _pageController;
  String? _expandedProjectId;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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

    AppUI.showAppBottomSheet(
      context: context,
      title: 'New Project',
      content: StatefulBuilder(
        builder: (context, setDialogState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
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
                    color: Theme.of(context).colorScheme.onSurface.withAlpha((0.18 * 255).toInt()),
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
            const SizedBox(height: 24),
            Text(
              'Color',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _defaultColors.map((color) {
                final isSelected = selectedColor == color;
                return GestureDetector(
                  onTap: () => setDialogState(() => selectedColor = color),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _safeParseColor(color),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.onSurface,
                              width: 3,
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: _safeParseColor(color).withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: isSelected 
                      ? Icon(Icons.check, color: Theme.of(context).colorScheme.onInverseSurface, size: 24)
                      : null,
                  ),
                );
              }).toList(),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _safeParseColor(selectedColor),
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      final name = nameController.text.trim();
                      if (name.isNotEmpty) {
                        final nav = Navigator.of(context);
                        try {
                          await _service.createProject(name, selectedColor);
                        } catch (e) {
                          if (!mounted) return;
                          AppUI.showSnackBar(
                            context, 
                            'Failed to create project: $e', 
                            type: SnackBarType.error
                          );
                          return;
                        }
                        if (!mounted) return;
                        nav.pop();
                      }
                    },
                    child: const Text('Create Project', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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

    AppUI.showAppBottomSheet(
      context: context,
      title: 'New Task',
      content: StatefulBuilder(
        builder: (context, setDialogState) {
          return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                const SizedBox(height: 20),
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
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      decoration: InputDecoration(
                        labelText: 'Project',
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.onSurface.withAlpha(
                              (0.18 * 255).toInt(),
                            ),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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
                          selectedColor = p.color;
                        });
                      },
                    );
                  },
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          final title = taskController.text.trim();
                          if (title.isEmpty) return;
                          
                          // Optional: Default to Inbox if no project selected, or handle as error
                          // keeping original logic: warning if null (though initialValue is '')
                          // Actually initialValue is '' (Inbox), so selectedProjectId might be '' which is valid for Inbox?
                          // The original code checked: if (selectedProjectId == null) warning.
                          // But initialValue is set to '' if selectedProjectId is null.
                          // Let's stick to original logic but fix the check.
                          // The dropdown sets selectedProjectId to v.
                          
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
                            AppUI.showSnackBar(
                              context, 
                              'Failed to create task: $e', 
                              type: SnackBarType.error
                            );
                            return;
                          }
                          if (!mounted) return;
                          nav.pop();
                        },
                        child: const Text('Create Task', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            );
        },
      ),
    );
  }

  Future<void> _deleteProject(Project p) async {
    final confirmed = await AppUI.showConfirmDialog(
      context,
      title: 'Delete Project',
      body: 'Delete "${p.name}"? This will not delete tasks automatically.',
      confirmLabel: 'Delete',
      confirmColor: Colors.redAccent,
    );
    
    if (confirmed) {
      try {
        await _service.deleteProject(p.id);
        if (!mounted) return;
        AppUI.showSnackBar(
          context, 
          'Project deleted', 
          type: SnackBarType.success
        );
      } catch (e) {
        if (!mounted) return;
        AppUI.showSnackBar(
          context, 
          'Failed to delete project: $e', 
          type: SnackBarType.error
        );
      }
    }
  }

  void _showEditProjectDialog(Project project) {
    final nameController = TextEditingController(text: project.name);
    String selectedColor = project.color;

    AppUI.showAppBottomSheet(
      context: context,
      title: 'Edit Project',
      content: StatefulBuilder(
        builder: (context, setDialogState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
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
            const SizedBox(height: 24),
            Text(
              'Color',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _defaultColors.map((color) {
                final isSelected = selectedColor == color;
                return GestureDetector(
                  onTap: () =>
                      setDialogState(() => selectedColor = color),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _safeParseColor(color),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.onSurface,
                              width: 3,
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: _safeParseColor(color).withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: isSelected 
                      ? Icon(Icons.check, color: Theme.of(context).colorScheme.onInverseSurface, size: 24)
                      : null,
                  ),
                );
              }).toList(),
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
                      final name = nameController.text.trim();
                      if (name.isEmpty) return;
                      final nav = Navigator.of(context);
                      try {
                        await _service.updateProject(
                          project.id,
                          name,
                          selectedColor,
                        );
                      } catch (e) {
                        if (!mounted) return;
                        AppUI.showSnackBar(
                          context, 
                          'Failed to update project: $e', 
                          type: SnackBarType.error
                        );
                        return;
                      }
                      if (!mounted) return;
                      nav.pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _safeParseColor(selectedColor),
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
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
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: [
              _buildDashboard(),
              const TimerTab(),
              const ReportsScreen(),
              const SettingsScreen(),
            ],
          ),
          if (_currentIndex == 0)
            Positioned(
              bottom: 96,
              right: 24,
              child: FloatingActionButton(
                heroTag: 'add_fab',
                onPressed: () => _showAddMenu(context),
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.add),
              ),
            ),
          // Persistent running stopwatch stop button (hide for focus sessions)
          StreamBuilder<TimeEntry?>(
            stream: _service.getRunningTimer(),
            builder: (context, snapshot) {
              final running = snapshot.data;
              // Do not show stop FAB for focus sessions (sync only with stopwatch)
              // Also hide if on Dashboard (index 0) or Timer tab (index 1) to avoid duplication
              if (running == null || running.source == 'focus' || _currentIndex == 0 || _currentIndex == 1) {
                return const SizedBox.shrink();
              }
              return Positioned(
                bottom: 96,
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
                    try {
                      await _service.stopTimer(running.id);
                    } catch (e) {
                      debugPrint('Failed to stop timer: $e');
                    }
                  },
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: GlassContainer(
        margin: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        color: Colors.black,
        opacity: 0.26,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
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
      ),
    );
  }

  Widget _buildDashboard() {
    final screenWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        screenWidth * 0.03,
        8,
        screenWidth * 0.03,
        160,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Quick stats row
          Row(
            children: [
              Expanded(
                child: GlassContainer(
                  padding: const EdgeInsets.all(10),
                  child: StreamBuilder<List<TimeEntry>>(
                    stream: _service.getTodayEntries(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const SizedBox.shrink();
                      }
                      final entries = snapshot.data ?? [];
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
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${hours}h',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
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
                  padding: const EdgeInsets.all(10),
                  child: StreamBuilder<List<dynamic>>(
                    stream: _service.getTasks(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
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
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${tasks.length}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
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

          const SizedBox(height: 24),
          Text(
            'Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          StreamBuilder<List<Project>>(
            stream: _service.getProjects(),
            builder: (context, projectSnap) {
              final projects = projectSnap.data ?? [];
              
              return StreamBuilder<List<Task>>(
                stream: _service.getTasks(),
                builder: (context, taskSnap) {
                  final allTasks = taskSnap.data ?? [];
                  final inboxTasks = allTasks.where((t) => t.projectId.isEmpty).toList();

                  return Column(
                    children: [
                      // Inbox Section
                      _buildDashboardExpansionCard(
                        project: null,
                        tasks: inboxTasks,
                      ),
                      // Project Sections
                      ...projects.map((p) {
                        final pTasks = allTasks.where((t) => t.projectId == p.id).toList();
                        return _buildDashboardExpansionCard(
                          project: p,
                          tasks: pTasks,
                        );
                      }),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardExpansionCard({Project? project, required List<Task> tasks}) {
    final String id = project?.id ?? 'inbox';
    final String name = project?.name ?? 'Inbox';
    final Color color = project != null ? _safeParseColor(project.color) : Colors.grey;
    final bool isExpanded = _expandedProjectId == id;

    if (id == 'inbox' && tasks.isEmpty) return const SizedBox.shrink();

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 8),
      borderRadius: BorderRadius.circular(16),
      color: color,
      opacity: 0.08,
      child: Column(
        children: [
          ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: Icon(
              project != null ? Icons.folder_rounded : Icons.inbox_rounded,
              color: color,
              size: 20,
            ),
            title: Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${tasks.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            onTap: () {
              setState(() {
                _expandedProjectId = isExpanded ? null : id;
              });
            },
          ),
          if (isExpanded)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: tasks.isEmpty
                  ? Text(
                      'No tasks',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tasks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final t = tasks[index];
                        return _buildCompactTaskItem(t, color);
                      },
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactTaskItem(Task t, Color projectColor) {
    return StreamBuilder<TimeEntry?>(
      stream: _service.getRunningTimer(),
      builder: (context, snap) {
        final isRunning = snap.data?.taskId == t.id;
        
        return GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          borderRadius: BorderRadius.circular(10),
          color: projectColor,
          opacity: 0.05,
          child: Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: projectColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t.title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  isRunning ? Icons.stop_circle : Icons.play_arrow_rounded,
                  color: isRunning ? Colors.redAccent : Colors.amberAccent,
                  size: 22,
                ),
                onPressed: () async {
                  if (isRunning) {
                    await _service.stopTimer(snap.data!.id);
                  } else {
                    final hasRunning = await _service.hasRunningTimer();
                    if (hasRunning) {
                      if (!mounted) return;
                      final shouldStart = await AppUI.showConfirmDialog(
                        context,
                        title: 'Timer Running',
                        body: 'Stop current timer and start this one?',
                        confirmLabel: 'Start',
                        confirmColor: Colors.amber,
                      );
                      if (!shouldStart) return;
                    }
                    await _service.startTimer(t.id, t.title, t.category);
                  }
                },
              ),
            ],
          ),
        );
      },
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

    AppUI.showAppBottomSheet(
      context: context,
      title: 'Edit Task',
      content: StatefulBuilder(
        builder: (context, setDialogState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: editController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Task name',
                labelStyle: const TextStyle(color: Colors.white60),
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
            const SizedBox(height: 20),
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
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  decoration: InputDecoration(
                    labelText: 'Project',
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(
                          (0.18 * 255).toInt(),
                        ),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final title = editController.text.trim();
                      if (title.isEmpty) return;
                      final nav = Navigator.of(context);
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
                        AppUI.showSnackBar(
                          context, 
                          'Task updated', 
                          type: SnackBarType.success
                        );
                      } catch (e) {
                        if (!mounted) return;
                        AppUI.showSnackBar(
                          context, 
                          'Failed to update task: $e', 
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
                    child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
