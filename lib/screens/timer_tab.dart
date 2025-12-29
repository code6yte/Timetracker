import 'package:flutter/material.dart';
import 'dart:async';
import '../services/time_tracker_service.dart';
import '../models/task.dart';
import '../models/time_entry.dart';
import '../widgets/glass_container.dart';

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

  // Local UI state for focus countdown when expectedDuration is set
  int _displaySeconds =
      0; // shows elapsed (stopwatch) or remaining (focus) depending on _runningEntry.expectedDuration
  bool get _isRunning => _runningEntry != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Listen for any running timer persisted in Firestore
    _service.getRunningTimer().listen((entry) {
      if (!mounted) return;
      setState(() {
        _runningEntry = entry;
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
      if (_selectedTask == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Select a task first')));
        return;
      }
      await _service.startTimer(
        _selectedTask!.id,
        _selectedTask!.title,
        _selectedTask!.projectId.isNotEmpty
            ? _selectedTask!.projectId
            : 'Inbox',
      );
    }
  }

  void _toggleFocus() async {
    if (_isRunning && _runningEntry?.expectedDuration != null) {
      // Stop focus
      await _service.stopTimer(_runningEntry!.id);
    } else {
      if (_focusTask == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a task for focus session')),
        );
        return;
      }
      // Start focus with expected duration of 25 minutes
      await _service.startTimer(
        _focusTask!.id,
        _focusTask!.title,
        _focusTask!.projectId.isNotEmpty ? _focusTask!.projectId : 'Inbox',
        expectedDuration: 25 * 60,
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Focus Session Complete & Logged!')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to stop focus session: $e')),
        );
      }
    }
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTimerView(
            isStopwatch: true,
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
            seconds:
                (_runningEntry != null &&
                    _runningEntry!.expectedDuration != null)
                ? _displaySeconds
                : _displaySeconds,
            isRunning:
                (_runningEntry != null &&
                _runningEntry!.expectedDuration != null),
            onToggle: _toggleFocus,
            task: _focusTask,
            onTaskChanged: (t) => setState(() => _focusTask = t),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerView({
    required bool isStopwatch,
    required int seconds,
    required bool isRunning,
    required VoidCallback onToggle,
    required Task? task,
    required Function(Task?) onTaskChanged,
  }) {
    final accentColor = _getAccentColor(task);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          children: [
            _buildTaskSelector(onTaskChanged, task),
            const SizedBox(height: 12),
            if (!isStopwatch) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: 240, // Slightly smaller ring
                height: 240,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: seconds / (25 * 60),
                        strokeWidth: 12,
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      _formatTime(seconds),
                      style: TextStyle(
                        fontSize: 64, // Slightly smaller text
                        fontWeight: FontWeight.w200,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -2,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text(
                _formatTime(seconds),
                style: TextStyle(
                  fontSize: 84, // Slightly smaller text
                  fontWeight: FontWeight.w200,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -4,
                ),
              ),
            ],
            const SizedBox(height: 20),
            _buildActionButton(isRunning, onToggle, accentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(bool isRunning, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72, // Slightly smaller button
        height: 72,
        decoration: BoxDecoration(
          color: isRunning ? Colors.redAccent : color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: isRunning
                  ? Colors.redAccent.withValues(alpha: 0.4)
                  : color.withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
          size: 40,
          color: isRunning
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildTaskSelector(Function(Task?) onChanged, Task? currentValue) {
    return StreamBuilder<List<Task>>(
      stream: _service.getTasks(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 56);
        final tasks = snapshot.data!;
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
                'Select a Task',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              items: uniqueTasks
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
      },
    );
  }
}