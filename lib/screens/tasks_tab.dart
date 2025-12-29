import 'package:flutter/material.dart';
import '../services/time_tracker_service.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../widgets/glass_container.dart';
import '../utils/ui_helpers.dart';

class TasksTab extends StatefulWidget {
  const TasksTab({super.key});

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  final TimeTrackerService _service = TimeTrackerService();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController taskTitleController = TextEditingController();
  String selectedColor = '#FFC107'; // Default to Amber/Yellow

  final List<String> defaultColors = [
    '#FFC107',
    '#FF9800',
    '#2196F3',
    '#4CAF50',
    '#9C27B0',
    '#F44336',
    '#607D8B',
    '#795548',
  ];

  @override
  void dispose() {
    nameController.dispose();
    taskTitleController.dispose();
    super.dispose();
  }

  void _showEditProjectDialog(Project project) {
    nameController.text = project.name;
    selectedColor = project.color;

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
                    color: Theme.of(context).colorScheme.primary,
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
              children: defaultColors.map((color) {
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
                        ? Icon(
                            Icons.check,
                            color: Theme.of(context).colorScheme.onInverseSurface,
                            size: 24,
                          )
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
                        await _service.updateProject(project.id, name, selectedColor);
                        if (!mounted) return;
                        nav.pop();
                        AppUI.showSnackBar(
                          context, 
                          'Project updated', 
                          type: SnackBarType.success
                        );
                      } catch (e) {
                        if (!mounted) return;
                        AppUI.showSnackBar(
                          context, 
                          'Failed to update project: $e', 
                          type: SnackBarType.error
                        );
                      }
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

  void _deleteProject(Project project) async {
    final confirmed = await AppUI.showConfirmDialog(
      context,
      title: 'Delete Project',
      body: 'Delete "${project.name}"? This will not delete tasks automatically.',
      confirmLabel: 'Delete',
      confirmColor: Colors.redAccent,
    );

    if (confirmed) {
      try {
        await _service.deleteProject(project.id);
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

  void _showEditTaskDialog(Task task) {
    taskTitleController.text = task.title;
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
              controller: taskTitleController,
              autofocus: true,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
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
                    onPressed: () async {
                      final title = taskTitleController.text.trim();
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

  Color _safeParseColor(String colorStr, {Color? fallback}) {
    try {
      return Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
    } catch (_) {
      return fallback ?? const Color(0xFF2196F3);
    }
  }

  void _showAddProjectDialog() {
    nameController.clear();
    selectedColor = '#FFC107';

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
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(
                      (0.18 * 255).toInt(),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color(
                      int.parse(selectedColor.replaceFirst('#', '0xFF')),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Theme Color',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: defaultColors.map((color) {
                final isSelected = selectedColor == color;
                return GestureDetector(
                  onTap: () => setDialogState(() => selectedColor = color),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Color(
                        int.parse(color.replaceFirst('#', '0xFF')),
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(int.parse(color.replaceFirst('#', '0xFF'))).withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 24,
                          )
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
                      backgroundColor: Color(
                        int.parse(selectedColor.replaceFirst('#', '0xFF')),
                      ),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      if (nameController.text.isNotEmpty) {
                        final nav = Navigator.of(context);
                        try {
                          await _service.createProject(
                            nameController.text.trim(),
                            selectedColor,
                          );
                        } catch (e) {
                          if (!mounted) return;
                          AppUI.showSnackBar(
                            context, 
                            'Failed to create project: $e', 
                            type: SnackBarType.error
                          );
                          return;
                        }
                        if (!mounted) {
                          return;
                        }
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
    taskTitleController.clear();
    String? selectedProjectId;
    String selectedProjectName = 'Inbox';
    String selectedColor = '#FFC107';

    AppUI.showAppBottomSheet(
      context: context,
      title: 'New Task',
      content: StatefulBuilder(
        builder: (context, setDialogState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: taskTitleController,
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
                      final title = taskTitleController.text.trim();
                      if (title.isEmpty) return;
                      if (selectedProjectId == null) {
                        AppUI.showSnackBar(
                          context, 
                          'Please select a project for the task', 
                          type: SnackBarType.warning
                        );
                        return;
                      }
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
        ),
      ),
    );
  }

  String? _expandedProjectId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildHeaderAction(
                      icon: Icons.create_new_folder_rounded,
                      label: 'New Project',
                      color: Colors.amberAccent,
                      onTap: _showAddProjectDialog,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildHeaderAction(
                      icon: Icons.add_task_rounded,
                      label: 'Quick Task',
                      color: Theme.of(context).colorScheme.onSurface,
                      onTap: _showAddTaskDialog,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Projects & Tasks',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
          StreamBuilder<List<Project>>(
            stream: _service.getProjects(),
            builder: (context, projectSnap) {
              if (!projectSnap.hasData) {
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final projects = projectSnap.data ?? [];
              
              return StreamBuilder<List<Task>>(
                stream: _service.getTasks(),
                builder: (context, taskSnap) {
                  if (!taskSnap.hasData) {
                    return const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final allTasks = taskSnap.data ?? [];
                  
                  final inboxTasks = allTasks.where((t) => t.projectId.isEmpty).toList();

                  // Create a list of items to display: Inbox + Projects
                  final List<dynamic> listItems = [
                    'Inbox', // Special marker for inbox
                    ...projects,
                  ];

                  if (listItems.length == 1 && inboxTasks.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'Create a project or task to get started!',
                           style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                           ),
                          ),
                      ),
                    );
                  }
                  
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = listItems[index];

                        if (item is String && item == 'Inbox') {
                          return _buildProjectExpansionCard(
                            project: null, // Indicates Inbox
                            tasks: inboxTasks,
                          );
                        }

                        if (item is Project) {
                          final projectTasks = allTasks.where((t) => t.projectId == item.id).toList();
                          return _buildProjectExpansionCard(
                            project: item,
                            tasks: projectTasks,
                          );
                        }
                        
                        return const SizedBox.shrink();
                      },
                      childCount: listItems.length,
                    ),
                  );
                },
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 160)), // Padding at the bottom
        ],
      ),
    );
  }

  Widget _buildProjectExpansionCard({Project? project, required List<Task> tasks}) {
    final String id = project?.id ?? 'inbox';
    final String name = project?.name ?? 'Inbox';
    final Color color = project != null ? _safeParseColor(project.color) : Colors.grey;
    final bool isExpanded = _expandedProjectId == id;

    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      borderRadius: BorderRadius.circular(16),
      color: color,
      opacity: 0.1,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: Icon(
              project != null ? Icons.folder_rounded : Icons.inbox_rounded,
              color: color,
            ),
            title: Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              '${tasks.length} task${tasks.length == 1 ? '' : 's'}',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (project != null)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
                    onSelected: (val) {
                      if (val == 'edit') {
                        _showEditProjectDialog(project);
                      } else if (val == 'delete') {
                        _deleteProject(project);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit Project')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete Project', style: TextStyle(color: Colors.redAccent))),
                    ],
                  ),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                ),
              ],
            ),
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedProjectId = null;
                } else {
                  _expandedProjectId = id;
                }
              });
            },
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: tasks.isEmpty 
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No tasks here!',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.check_box_outline_blank, color: color, size: 20),
                      title: Text(task.title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.play_arrow_rounded, color: Colors.amberAccent, size: 24),
                            onPressed: () => _startTimerForTask(task),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
                            onPressed: () => _showEditTaskDialog(task),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Future<void> _startTimerForTask(Task task) async {
    try {
      final hasRunning = await _service.hasRunningTimer();
      if (hasRunning) {
        if (!mounted) return;
        final shouldStart = await AppUI.showConfirmDialog(
          context,
          title: 'Timer Running',
          body: 'Another timer is currently running. Stop it and start this one?',
          confirmLabel: 'Start New',
          confirmColor: Colors.amber,
        );
        if (!shouldStart) return;
      }
      await _service.startTimer(task.id, task.title, task.category);
      if (!mounted) return;
      AppUI.showSnackBar(context, 'Timer started!', type: SnackBarType.success);
    } catch (e) {
      if (!mounted) return;
      AppUI.showSnackBar(context, 'Failed to start timer: $e', type: SnackBarType.error);
    }
  }

  Widget _buildHeaderAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.symmetric(vertical: 12),
        color: color,
        opacity: 0.1,
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}