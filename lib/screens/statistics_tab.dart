import 'package:flutter/material.dart';
import '../services/time_tracker_service.dart';
import '../models/time_entry.dart';

class StatisticsTab extends StatefulWidget {
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today\'s Activity',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildTodayStats(),
            const SizedBox(height: 32),
            const Text(
              'This Week',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildWeeklyChart(),
            const SizedBox(height: 32),
            const Text(
              'Category Breakdown',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
        final totalSeconds = entries.fold<int>(0, (sum, entry) => sum + entry.duration);
        final sessionCount = entries.length;

        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.timer,
                  'Total Time',
                  _formatDuration(totalSeconds),
                  Colors.blue,
                ),
                _buildStatItem(
                  Icons.playlist_add_check,
                  'Sessions',
                  sessionCount.toString(),
                  Colors.green,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, size: 48, color: color),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

        return Card(
          elevation: 4,
          child: Padding(
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
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 30,
                            height: height,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            dayName,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
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
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(
                child: Text(
                  'No data for today',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          );
        }

        final total = categoryData.values.fold<int>(0, (sum, val) => sum + val);

        return Card(
          elevation: 4,
          child: Padding(
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
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _formatDuration(entry.value),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: entry.value / total,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation(_getCategoryColor(entry.key)),
                        minHeight: 8,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$percentage%',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'work':
        return Colors.blue;
      case 'study':
        return Colors.green;
      case 'personal':
        return Colors.orange;
      case 'exercise':
        return Colors.purple;
      default:
        return Colors.red;
    }
  }
}
