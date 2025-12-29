import 'package:flutter/material.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../services/time_tracker_service.dart';
import '../widgets/glass_container.dart';
import '../utils/ui_helpers.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final Project project;

  const ProjectDetailsScreen({super.key, required this.project});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  final TimeTrackerService _service = TimeTrackerService();
  final TextEditingController _taskController = TextEditingController();

  Color _safeParseColor(String colorStr, {Color? fallback}) {
    try {
      return Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
    } catch (_) {
      return fallback ?? const Color(0xFF2196F3);
    }
  }

  void _showAddTaskDialog() {
    _taskController.clear();
    final accentColor = _safeParseColor(widget.project.color);

    AppUI.showAppBottomSheet(
      context: context,
      title: 'New Task in ${widget.project.name}',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _taskController,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Task Name',
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
                borderSide: BorderSide(color: accentColor),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    if (_taskController.text.isNotEmpty) {
                      final nav = Navigator.of(context);
                      try {
                        await _service.createTask(
                          _taskController.text.trim(),
                          '',
                          widget.project.id,
                          widget.project.name,
                          widget.project.color,
                        );
                        if (mounted) {
                          nav.pop();
                        }
                      } catch (e) {
                        if (mounted) {
                          AppUI.showSnackBar(
                            context, 
                            'Failed to add task: $e', 
                            type: SnackBarType.error
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Add Task', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showEditTaskDialog(Task task) {
    _taskController.text = task.title;
    final accentColor = _safeParseColor(widget.project.color);

    AppUI.showAppBottomSheet(
      context: context,
      title: 'Edit Task',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _taskController,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Task Name',
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
                borderSide: BorderSide(color: accentColor),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    if (_taskController.text.isNotEmpty) {
                      final nav = Navigator.of(context);
                      try {
                        final newTitle = _taskController.text.trim();
                        await _service.updateTask(
                          task.id,
                          newTitle,
                          task.description,
                          widget.project.id,
                          widget.project.name,
                        );
                        if (!mounted) return;
                        AppUI.showSnackBar(
                          context, 
                          'Task updated', 
                          type: SnackBarType.success
                        );
                        nav.pop();
                      } catch (e) {
                        if (!mounted) return;
                        AppUI.showSnackBar(
                          context, 
                          'Failed to edit task: $e', 
                          type: SnackBarType.error
                        );
                      }
                    }
                  },
                  child: const Text('Update Task', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _deleteTask(Task task) async {
    final confirmed = await AppUI.showConfirmDialog(
      context,
      title: 'Delete Task',
      body: 'Delete "${task.title}"?',
      confirmLabel: 'Delete',
      confirmColor: Colors.redAccent,
    );
    
    if (!mounted) return;
    if (confirmed) {
      try {
        await _service.deleteTask(task.id);
        if (!mounted) return;
        AppUI.showSnackBar(
          context, 
          'Task deleted', 
          type: SnackBarType.success
        );
      } catch (e) {
        if (!mounted) return;
        AppUI.showSnackBar(
          context, 
          'Failed to delete task: $e', 
          type: SnackBarType.error
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _safeParseColor(widget.project.color);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.project.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      body: StreamBuilder<List<Task>>(
        stream: _service.getTasksByProject(widget.project.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final tasks = snapshot.data!;

          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedOpacity(
                    opacity: 0.7,
                    duration: const Duration(seconds: 2),
                    child: Icon(
                      Icons.assignment_outlined,
                      size: 64,
                      color: accentColor.withAlpha((0.3 * 255).toInt()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tasks yet in ${widget.project.name}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showAddTaskDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Your First Task'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.fromLTRB(
              MediaQuery.of(context).size.width > 600 ? 32 : 16,
              20,
              MediaQuery.of(context).size.width > 600 ? 32 : 16,
              MediaQuery.of(context).size.width > 600 ? 120 : 100,
            ),
            itemCount: tasks.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Dismissible(
                key: Key(task.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) => _deleteTask(task),
                child: GlassContainer(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  color: _safeParseColor(task.color),
                  opacity: 0.06,
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: accentColor.withAlpha((0.15 * 255).toInt()),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.timer,
                              color: Colors.amberAccent,
                              size: 28,
                            ),
                            onPressed: () async {
                              try {
                                // Check for existing running timer
                                final hasRunning = await _service.hasRunningTimer();

                                if (hasRunning) {
                                  if (!context.mounted) return;
                                  final shouldStart = await AppUI.showConfirmDialog(
                                    context,
                                    title: 'Timer Running',
                                    body: 'Another timer is currently running. Stop it and start this one?',
                                    confirmLabel: 'Start New',
                                    confirmColor: Colors.amber,
                                  );

                                  if (!shouldStart) return;
                                }

                                await _service.startTimer(
                                  task.id,
                                  task.title,
                                  widget.project.name,
                                );
                                if (!mounted) {
                                  return;
                                }
                                AppUI.showSnackBar(
                                  context, 
                                  'Timer started for ${task.title}!', 
                                  type: SnackBarType.success
                                );
                              } catch (e) {
                                if (!mounted) return;
                                AppUI.showSnackBar(
                                  context, 
                                  'Failed to start timer: $e', 
                                  type: SnackBarType.error
                                );
                              }
                            },
                            tooltip: 'Start Timer',
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showEditTaskDialog(task);
                            } else if (value == 'delete') {
                              _deleteTask(task);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                          icon: Icon(
                            Icons.more_vert,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        backgroundColor: accentColor,
        elevation: 8,
        child: const Icon(Icons.add_task, color: Colors.white, size: 28),
      ),
    );
  }
}