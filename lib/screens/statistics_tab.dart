import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today\'s Activity',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildTodayStats(),
            const SizedBox(height: 32),
            const Text(
              'This Week',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildWeeklyChart(),
            const SizedBox(height: 32),
            const Text(
              'Category Breakdown',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildCategoryBreakdown(),
          ],
        ),
      ),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
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
          style: const TextStyle(fontSize: 14, color: Colors.white70),
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
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final weekData = snapshot.data!;
        final maxDuration = weekData.fold<int>(
          0,
          (max, day) => day['duration'] > max ? day['duration'] : max,
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
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 30,
                          height: height,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dayName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
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
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          _formatDuration(entry.value),
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: entry.value / total,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation(
                        _getCategoryColor(entry.key),
                      ),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$percentage%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white60,
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
