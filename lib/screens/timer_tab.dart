import 'package:flutter/material.dart';
import 'dart:async';
import '../services/time_tracker_service.dart';
import '../models/task.dart';
import '../models/time_entry.dart';
import '../widgets/glass_container.dart';
import '../utils/ui_helpers.dart';

class TimerTab extends StatefulWidget {
  const TimerTab({super.key});

  @override
  State<TimerTab> createState() => _TimerTabState();
}

class _TimerTabState extends State<TimerTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TimeTrackerService _service = TimeTrackerService();

  // Running entry state (persistent)
  TimeEntry? _runningEntry;
  Timer? _runningUpdateTimer; // updates elapsed/remaining display

  // Selected tasks for controls
  Task? _selectedTask;
  Task? _focusTask;

  // Focus configuration
  int _selectedFocusDurationMinutes = 25; // default focus duration in minutes
  final List<int> _focusDurationOptions = [15, 20, 25, 30, 45, 60];

  // Local UI state for focus countdown when expectedDuration is set
  int _displaySeconds = 25 * 60; 
  bool get _isRunning => _runningEntry != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Set initial display seconds based on default focus duration
    _displaySeconds = _selectedFocusDurationMinutes * 60;

    // Listen for any running timer persisted in Firestore
    _service.getRunningTimer().listen((entry) {
      if (!mounted) return;
      setState(() {
        _runningEntry = entry;
        if (_runningEntry != null) {
          final elapsed = DateTime.now().difference(_runningEntry!.startTime).inSeconds;
          if (_runningEntry!.expectedDuration != null) {
            _selectedFocusDurationMinutes = (_runningEntry!.expectedDuration! ~/ 60);
            _displaySeconds = (_runningEntry!.expectedDuration! - elapsed).clamp(
              0,
              _runningEntry!.expectedDuration!,
            );
          } else {
            _displaySeconds = elapsed;
          }
        } else {
          // Sync display seconds when timer stops
          if (_tabController.index == 1) {
            _displaySeconds = _selectedFocusDurationMinutes * 60;
          } else {
            _displaySeconds = 0;
          }
        }
      });
      _startRunningUpdateTimer();
    });
  }

  @override
  void dispose() {
    _runningUpdateTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  // --- Shared Helpers ---
  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color _getAccentColor(Task? task) {
    if (task == null || task.color.isEmpty) return Colors.amberAccent;
    try {
      return Color(int.parse(task.color.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.amberAccent;
    }
  }

  Future<bool> _showNoTaskConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('No Task Selected'),
                content: const Text(
                  'Do you want to start the timer without a specific task?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Start'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  void _startRunningUpdateTimer() {
    _runningUpdateTimer?.cancel();
    if (_runningEntry == null) return;
    _runningUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        final elapsed = DateTime.now()
            .difference(_runningEntry!.startTime)
            .inSeconds;
        if (_runningEntry!.expectedDuration != null) {
          _displaySeconds = (_runningEntry!.expectedDuration! - elapsed).clamp(
            0,
            _runningEntry!.expectedDuration!,
          );
          if (_displaySeconds == 0) {
            _runningUpdateTimer?.cancel();
            _handleFocusCompletion();
          }
        } else {
          _displaySeconds = elapsed;
        }
      });
    });
  }

  // --- Stopwatch / Focus Logic now backed by persistent running entry ---
  void _toggleStopwatch() async {
    if (_isRunning && _runningEntry?.expectedDuration == null) {
      // Stop persistent running timer
      await _service.stopTimer(_runningEntry!.id);
    } else {
      String taskId = 'general_task';
      String taskTitle = 'General Session';
      String category = 'Uncategorized';

      if (_selectedTask == null) {
        final confirmed = await _showNoTaskConfirmation();
        if (!confirmed) return;
      } else {
        taskId = _selectedTask!.id;
        taskTitle = _selectedTask!.title;
        category =
            _selectedTask!.projectId.isNotEmpty
                ? _selectedTask!.projectId
                : 'Inbox';
      }

      await _service.startTimer(taskId, taskTitle, category);
    }
  }

  void _toggleFocus() async {
    if (_isRunning && _runningEntry?.expectedDuration != null) {
      // Stop focus
      await _service.stopTimer(_runningEntry!.id);
    } else {
      String taskId = 'general_task';
      String taskTitle = 'General Session';
      String category = 'Uncategorized';

      if (_focusTask == null) {
        final confirmed = await _showNoTaskConfirmation();
        if (!confirmed) return;
      } else {
        taskId = _focusTask!.id;
        taskTitle = _focusTask!.title;
        category =
            _focusTask!.projectId.isNotEmpty ? _focusTask!.projectId : 'Inbox';
      }

      // Start focus with chosen expected duration
      await _service.startTimer(
        taskId,
        taskTitle,
        category,
        expectedDuration: _selectedFocusDurationMinutes * 60,
        source: 'focus',
      );
    }
  }

  Future<void> _handleFocusCompletion() async {
    // Called when countdown reaches zero
    if (_runningEntry != null && _runningEntry!.expectedDuration != null) {
      try {
        await _service.stopTimer(_runningEntry!.id);
        if (!mounted) return;
        AppUI.showSnackBar(
          context, 
          'Focus Session Complete & Logged!', 
          type: SnackBarType.success
        );
      } catch (e) {
        if (!mounted) return;
        AppUI.showSnackBar(
          context, 
          'Failed to stop focus session: $e', 
          type: SnackBarType.error
        );
      }
    }
  }

  Future<void> _resetTimer() async {
    if (_isRunning) {
      await _service.stopTimer(_runningEntry!.id);
    }
    setState(() {
      if (_runningEntry?.expectedDuration != null || _tabController.index == 1) {
        _displaySeconds = _selectedFocusDurationMinutes * 60;
      } else {
        _displaySeconds = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Timer & Focus',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amberAccent,
          indicatorWeight: 4,
          labelColor: Colors.amberAccent,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          tabs: const [
            Tab(text: 'Stopwatch'),
            Tab(text: 'Focus'),
          ],
        ),
      ),
      body: StreamBuilder<List<Task>>(
        stream: _service.getTasks(),
        builder: (context, snapshot) {
          final tasks = snapshot.data ?? [];
          return TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            controller: _tabController,
            children: [
              _buildTimerView(
                isStopwatch: true,
                tasks: tasks,
                seconds:
                    (_runningEntry != null &&
                            _runningEntry!.expectedDuration == null)
                        ? _displaySeconds
                        : _displaySeconds,
                isRunning:
                    (_runningEntry != null &&
                        _runningEntry!.expectedDuration == null),
                onToggle: _toggleStopwatch,
                task: _selectedTask,
                onTaskChanged: (t) => setState(() => _selectedTask = t),
              ),
              _buildTimerView(
                isStopwatch: false,
                tasks: tasks,
                seconds:
                    (_runningEntry != null &&
                            _runningEntry!.expectedDuration != null)
                        ? _displaySeconds
                        : (_selectedFocusDurationMinutes * 60),
                isRunning:
                    (_runningEntry != null &&
                        _runningEntry!.expectedDuration != null),
                onToggle: _toggleFocus,
                task: _focusTask,
                onTaskChanged: (t) => setState(() => _focusTask = t),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimerView({
    required bool isStopwatch,
    required List<Task> tasks,
    required int seconds,
    required bool isRunning,
    required VoidCallback onToggle,
    required Task? task,
    required Function(Task?) onTaskChanged,
  }) {
    // Determine effective task to display
    Task? effectiveTask = task;
    if (isRunning && _runningEntry != null) {
      // Try to find the running task in the list
      try {
        effectiveTask = tasks.firstWhere((t) => t.id == _runningEntry!.taskId);
      } catch (_) {
        // Not found in list (e.g. 'general_task' or deleted)
        effectiveTask = null;
      }
    }

    final accentColor = _getAccentColor(effectiveTask);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
        child: Column(
          children: [
            _buildTaskSelector(onTaskChanged, effectiveTask, tasks),
            const SizedBox(height: 12),
            if (!isStopwatch) ...[
              const SizedBox(height: 8),
              // Duration selector for focus sessions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Duration:',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: _selectedFocusDurationMinutes,
                      items:
                          _focusDurationOptions
                              .map(
                                (d) => DropdownMenuItem<int>(
                                  value: d,
                                  child: Text('$d min'),
                                ),
                              )
                              .toList(),
                      onChanged:
                          isRunning
                              ? null
                              : (v) => setState(() {
                                if (v != null) _selectedFocusDurationMinutes = v;
                              }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 180, // Compact ring
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value:
                            1.0 -
                            (seconds /
                                (((_runningEntry != null &&
                                            _runningEntry!.expectedDuration !=
                                                null)
                                        ? _runningEntry!.expectedDuration!
                                        : (_selectedFocusDurationMinutes * 60))
                                    .toDouble())),
                        strokeWidth: 8, // Thinner stroke
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                        backgroundColor:
                            Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.2),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      _formatTime(seconds),
                      style: TextStyle(
                        fontSize: 42, // Compact font
                        fontWeight: FontWeight.w300,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text(
                _formatTime(seconds),
                style: TextStyle(
                  fontSize: 64, // Compact font
                  fontWeight: FontWeight.w200,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -3,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(isRunning, onToggle, accentColor),
                const SizedBox(width: 24),
                _buildResetButton(accentColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetButton(Color color) {
    return GestureDetector(
      onTap: _resetTimer,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        ),
        child: Icon(
          Icons.refresh_rounded,
          size: 28,
          color: color,
        ),
      ),
    );
  }

  Widget _buildActionButton(bool isRunning, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64, // Compact button
        height: 64,
        decoration: BoxDecoration(
          color: isRunning ? Colors.redAccent : color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: isRunning
                  ? Colors.redAccent.withValues(alpha: 0.3)
                  : color.withValues(alpha: 0.3),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(
          isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
          size: 32,
          color: isRunning
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildTaskSelector(
    Function(Task?) onChanged,
    Task? currentValue,
    List<Task> tasks,
  ) {
    // Deduplicate tasks by id to avoid multiple DropdownMenuItems with same value
    final Map<String, Task> uniqueById = {};
    for (var t in tasks) {
      uniqueById[t.id] = t;
    }
    final uniqueTasks = uniqueById.values.toList();

    // Ensure the currently selected value references one of the items
    Task? selectedValue;
    if (currentValue != null) {
      final matches = uniqueTasks.where((t) => t.id == currentValue.id);
      selectedValue = matches.isNotEmpty ? matches.first : null;
    }

    return GlassContainer(
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Task>(
          value: selectedValue,
          hint: Text(
            (_isRunning && _runningEntry?.taskId == 'general_task')
                ? 'General Session'
                : 'Select a Task',
            style: TextStyle(
              color:
                  (_isRunning && _runningEntry?.taskId == 'general_task')
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight:
                  (_isRunning && _runningEntry?.taskId == 'general_task')
                      ? FontWeight.bold
                      : FontWeight.normal,
            ),
          ),
          dropdownColor: Theme.of(context).colorScheme.surface,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          isExpanded: true,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
          ),
          items:
              uniqueTasks
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _getAccentColor(t),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              t.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
          onChanged: _isRunning ? null : onChanged,
        ),
      ),
    );
  }
}
