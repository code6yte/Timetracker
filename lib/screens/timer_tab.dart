import 'dart:async';
import 'package:flutter/material.dart';
import '../services/time_tracker_service.dart';
import '../models/time_entry.dart';

class TimerTab extends StatefulWidget {
  @override
  State<TimerTab> createState() => _TimerTabState();
}

class _TimerTabState extends State<TimerTab> {
  final TimeTrackerService _service = TimeTrackerService();
  Timer? _timer;
  int _elapsedSeconds = 0;
  TimeEntry? _currentEntry;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimerCounter(DateTime startTime) {
    _timer?.cancel();
    _elapsedSeconds = DateTime.now().difference(startTime).inSeconds;
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  void _stopTimerCounter() {
    _timer?.cancel();
    _elapsedSeconds = 0;
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _showTaskSelectionDialog() async {
    final tasks = await _service.getTasks().first;

    if (tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a task first')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Task'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(int.parse(task.color.replaceFirst('#', '0xFF'))),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                title: Text(task.title),
                subtitle: Text(task.category),
                onTap: () async {
                  Navigator.pop(context);
                  await _service.startTimer(task.id, task.title, task.category);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Timer started for ${task.title}')),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TimeEntry?>(
      stream: _service.getRunningTimer(),
      builder: (context, snapshot) {
        final runningTimer = snapshot.data;

        if (runningTimer != null && _currentEntry?.id != runningTimer.id) {
          _currentEntry = runningTimer;
          _startTimerCounter(runningTimer.startTime);
        } else if (runningTimer == null && _currentEntry != null) {
          _stopTimerCounter();
          _currentEntry = null;
        }

        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (runningTimer != null) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.timer, size: 64, color: Colors.white),
                          const SizedBox(height: 16),
                          Text(
                            runningTimer.taskTitle,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            runningTimer.category,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      _formatDuration(_elapsedSeconds),
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 48),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await _service.stopTimer(runningTimer.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Timer stopped')),
                        );
                      },
                      icon: const Icon(Icons.stop, size: 28),
                      label: const Text('Stop Timer', style: TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ] else ...[
                    Icon(Icons.timer_off, size: 120, color: Colors.grey[400]),
                    const SizedBox(height: 24),
                    const Text(
                      'No Timer Running',
                      style: TextStyle(fontSize: 24, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Start tracking your time',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 48),
                    ElevatedButton.icon(
                      onPressed: _showTaskSelectionDialog,
                      icon: const Icon(Icons.play_arrow, size: 28),
                      label: const Text('Start Timer', style: TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  _buildTodaysSummary(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTodaysSummary() {
    return StreamBuilder<List<TimeEntry>>(
      stream: _service.getTodayEntries(),
      builder: (context, snapshot) {
        final entries = snapshot.data ?? [];
        final totalSeconds = entries.fold<int>(0, (sum, entry) => sum + entry.duration);

        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'Today\'s Total',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDuration(totalSeconds),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${entries.length} session${entries.length != 1 ? 's' : ''}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
