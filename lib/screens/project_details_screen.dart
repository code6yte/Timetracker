import 'package:flutter/material.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../services/time_tracker_service.dart';
import '../widgets/glass_container.dart';

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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'New Task in ${widget.project.name}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: TextField(
          controller: _taskController,
          style: const TextStyle(color: Colors.white),
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Task Name',
            labelStyle: const TextStyle(color: Colors.white60),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white24),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: accentColor),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              if (_taskController.text.isNotEmpty) {
                final nav = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
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
                    messenger.showSnackBar(
                      SnackBar(content: Text('Failed to add task: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Add Task'),
          ),
        ],
      ),
    );
  }

  void _showEditTaskDialog(Task task) {
    _taskController.text = task.title;
    final accentColor = _safeParseColor(widget.project.color);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Edit Task',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: TextField(
          controller: _taskController,
          style: const TextStyle(color: Colors.white),
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Task Name',
            labelStyle: const TextStyle(color: Colors.white60),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white24),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: accentColor),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              if (_taskController.text.isNotEmpty) {
                final nav = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
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
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Task updated')),
                  );
                  nav.pop();
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(content: Text('Failed to edit task: $e')),
                  );
                }
              }
            },
            child: const Text('Update Task'),
          ),
        ],
      ),
    );
  }

  void _deleteTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Delete Task', style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete "${task.title}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
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
    if (!mounted) return;
    if (confirmed == true) {
      try {
        await _service.deleteTask(task.id);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Task deleted')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete task: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _safeParseColor(widget.project.color);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          widget.project.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
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
                    style: const TextStyle(color: Colors.white54, fontSize: 16),
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
                      style: const TextStyle(
                        color: Colors.white,
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
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                await _service.startTimer(
                                  task.id,
                                  task.title,
                                  widget.project.name,
                                );
                                if (!mounted) {
                                  return;
                                }
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Timer started for ${task.title}!',
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              } catch (e) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to start timer: $e'),
                                  ),
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
                          icon: const Icon(
                            Icons.more_vert,
                            color: Colors.white70,
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
