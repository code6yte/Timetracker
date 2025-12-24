import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/time_tracker_service.dart';
import '../models/time_entry.dart';
import '../widgets/glass_container.dart';

class StatisticsTab extends StatefulWidget {
  const StatisticsTab({super.key});

  @override
  State<StatisticsTab> createState() => _StatisticsTabState();
}

class _StatisticsTabState extends State<StatisticsTab> {
  final TimeTrackerService _service = TimeTrackerService();

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    return '${hours}h ${minutes}m';
  }

  Future<void> _handleExport() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final path = await _service.exportToCSV();
      await Share.shareXFiles([XFile(path)], text: 'My Time Tracker Export');
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today\'s Activity',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  onPressed: _handleExport,
                  icon: const Icon(Icons.download, color: Colors.blueAccent),
                  tooltip: 'Export CSV',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTodayStats(),
            const SizedBox(height: 32),
            Text(
              'Daily Goal Progress',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _buildGoalProgress(),
            const SizedBox(height: 32),
            Text(
              'This Week',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _buildWeeklyChart(),
            const SizedBox(height: 32),
            Text(
              'Category Breakdown',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _buildCategoryBreakdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalProgress() {
    return StreamBuilder<int>(
      stream: _service.getDailyGoal(),
      builder: (context, goalSnapshot) {
        return StreamBuilder<List<TimeEntry>>(
          stream: _service.getTodayEntries(),
          builder: (context, entriesSnapshot) {
            final goalSeconds = goalSnapshot.data ?? (8 * 3600);
            final entries = entriesSnapshot.data ?? [];
            final totalSeconds = entries.fold<int>(
              0,
              (sum, e) => sum + e.duration,
            );

            final progress = (totalSeconds / goalSeconds).clamp(0.0, 1.0);
            final percent = (progress * 100).toInt();

            return GlassContainer(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress: $percent%',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_formatDuration(totalSeconds)} / ${_formatDuration(goalSeconds)}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation(
                        Colors.blueAccent,
                      ),
                      minHeight: 12,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTodayStats() {
    return StreamBuilder<List<TimeEntry>>(
      stream: _service.getTodayEntries(),
      builder: (context, snapshot) {
        final entries = snapshot.data ?? [];
        final totalSeconds = entries.fold<int>(
          0,
          (sum, entry) => sum + entry.duration,
        );
        final sessionCount = entries.length;

        return GlassContainer(
          padding: const EdgeInsets.all(20.0),
          child: Wrap(
            alignment: WrapAlignment.spaceAround,
            spacing: 16.0,
            runSpacing: 16.0,
            children: [
              _buildStatItem(
                Icons.timer,
                'Total Time',
                _formatDuration(totalSeconds),
                Colors.blueAccent,
              ),
              _buildStatItem(
                Icons.playlist_add_check,
                'Sessions',
                sessionCount.toString(),
                Colors.greenAccent,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 48, color: color),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _service.getWeeklySummary(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Failed to load weekly data',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No weekly data available',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        final weekData = snapshot.data!;
        final maxDuration = weekData.fold<int>(
          0,
          (max, day) =>
              (day['duration'] as int) > max ? (day['duration'] as int) : max,
        );

        return GlassContainer(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: weekData.map((day) {
                    final height = maxDuration > 0
                        ? ((day['duration'] as int) / maxDuration * 150)
                        : 0.0;
                    final dayName = _getDayName(day['date']);

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          day['hours'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 30,
                          height: height,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.onSurface
                                .withAlpha((0.8 * 255).toInt()),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withAlpha(
                                  (0.2 * 255).toInt(),
                                ),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dayName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getDayName(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  Widget _buildCategoryBreakdown() {
    return FutureBuilder<Map<String, int>>(
      future: _service.getTodayTimeByCategory(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final categoryData = snapshot.data!;
        if (categoryData.isEmpty) {
          return const GlassContainer(
            padding: EdgeInsets.all(20.0),
            child: Center(
              child: Text(
                'No data for today',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          );
        }

        final total = categoryData.values.fold<int>(0, (sum, val) => sum + val);

        return GlassContainer(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: categoryData.entries.map((entry) {
              final percentage = (entry.value / total * 100).round();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          _formatDuration(entry.value),
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: entry.value / total,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation(
                          _getCategoryColor(entry.key),
                        ),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'work':
        return Colors.blueAccent;
      case 'study':
        return Colors.greenAccent;
      case 'personal':
        return Colors.orangeAccent;
      case 'exercise':
        return Colors.purpleAccent;
      default:
        return Colors.redAccent;
    }
  }
}
