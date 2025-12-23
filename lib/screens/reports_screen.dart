import 'package:flutter/material.dart';
import '../services/time_tracker_service.dart';
import '../models/time_entry.dart';
import '../widgets/glass_container.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final TimeTrackerService _service = TimeTrackerService();
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'All';
  String _searchQuery = '';

  Color _getAccentColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  void _showEntryDetails(TimeEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          entry.taskTitle,
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category: ${entry.category}',
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              'Start: ${DateFormat('HH:mm').format(entry.startTime)}',
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              'Duration: ${(entry.duration / 60).toStringAsFixed(1)} minutes',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  void _exportReports() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export feature coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Advanced Reports'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _exportReports,
            tooltip: 'Export Reports',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilters(),
            const SizedBox(height: 24),
            _buildSectionTitle('Productivity Heatmap (Last 30 Days)'),
            const SizedBox(height: 16),
            _buildHeatmap(),
            const SizedBox(height: 32),
            _buildSectionTitle('24h Activity Timeline'),

            const SizedBox(height: 16),
            _buildTimeline(),
            const SizedBox(height: 32),
            _buildSectionTitle('Hourly Productivity'),
            const SizedBox(height: 16),
            _buildHourlyChart(),
            const SizedBox(height: 32),
            _buildSectionTitle('Detailed Logs'),
            const SizedBox(height: 16),
            _buildLogsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildFilters() {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Search tasks...',
                    hintStyle: TextStyle(color: Colors.white54),
                    prefixIcon: Icon(Icons.search, color: Colors.white54),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.calendar_today, color: Colors.white),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Filter Category: ',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StreamBuilder(
                  stream: _service.getCategories(),
                  builder: (context, snapshot) {
                    final cats = [
                      'All',
                      'Work',
                      'Study',
                      'Personal',
                      'Exercise',
                      ...(snapshot.data ?? []).map((e) => e.name),
                    ];
                    return DropdownButton<String>(
                      value: _selectedCategory,
                      dropdownColor: Colors.grey[900],
                      style: const TextStyle(color: Colors.white),
                      isExpanded: true,
                      items: cats
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedCategory = val!),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - 32; // Account for padding

        return StreamBuilder<List<TimeEntry>>(
          stream: _service.getTimeEntries(_selectedDate, _selectedDate),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading timeline: ${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'No activity for this date',
                  style: TextStyle(color: Colors.white54),
                ),
              );
            }
            final entries = snapshot.data!;

            return GlassContainer(
              height: 120,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                children: [
                  // Hour markers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      25,
                      (i) => i % 6 == 0
                          ? Text(
                              '$i',
                              style: const TextStyle(
                                color: Colors.white24,
                                fontSize: 10,
                              ),
                            )
                          : const SizedBox(width: 1),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Task blocks with better positioning
                  SizedBox(
                    height: 40,
                    child: Stack(
                      children: entries.map((e) {
                        final startPercent =
                            (e.startTime.hour + e.startTime.minute / 60.0) /
                            24.0;
                        final durationPercent = (e.duration / 3600.0) / 24.0;
                        final left = availableWidth * startPercent;
                        final width = (availableWidth * durationPercent).clamp(
                          20.0,
                          availableWidth,
                        );

                        return Positioned(
                          left: left,
                          width: width,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: _getAccentColor(
                                context,
                              ).withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Tooltip(
                              message:
                                  '${e.taskTitle}\n${DateFormat('HH:mm').format(e.startTime)} - ${e.endTime != null ? DateFormat('HH:mm').format(e.endTime!) : "Running"}',
                              child: InkWell(
                                onTap: () => _showEntryDetails(e),
                                child: const SizedBox.expand(),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
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

  Widget _buildHourlyChart() {
    return FutureBuilder<List<double>>(
      future: _service.getHourlyProductivity(_selectedDate),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        final maxVal = data.isEmpty
            ? 1.0
            : data.reduce((a, b) => a > b ? a : b);

        return GlassContainer(
          height: 200,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(24, (i) {
              final height = (data[i] / (maxVal == 0 ? 1.0 : maxVal)) * 140;
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 8,
                    height: height.toDouble(),
                    decoration: BoxDecoration(
                      color: i >= 9 && i <= 17
                          ? _getAccentColor(context)
                          : _getAccentColor(context).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (i % 4 == 0)
                    Text(
                      '$i',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 8,
                      ),
                    ),
                ],
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildLogsList() {
    return StreamBuilder<List<TimeEntry>>(
      stream: _service.getFilteredEntries(
        query: _searchQuery,
        category: _selectedCategory,
        startDate: _selectedDate,
        endDate: _selectedDate,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final entries = snapshot.data!;

        if (entries.isEmpty) {
          return const Center(
            child: Text(
              'No logs found for this criteria',
              style: TextStyle(color: Colors.white54),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: entries.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final e = entries[index];
            return GlassContainer(
              padding: const EdgeInsets.all(12),
              child: ListTile(
                dense: true,
                title: Text(
                  e.taskTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${e.category} • ${DateFormat('HH:mm').format(e.startTime)} - ${e.endTime != null ? DateFormat('HH:mm').format(e.endTime!) : "Running"}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: Text(
                  '${(e.duration / 60).toStringAsFixed(1)}m',
                  style: TextStyle(
                    color: _getAccentColor(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeatmap() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _service
          .getWeeklySummary(), // I'll use a slightly different logic for 30 days
      builder: (context, snapshot) {
        // Mocking a heatmap grid for now to show visual intent for the project
        return GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Less',
                    style: TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                  Text(
                    'More',
                    style: TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: List.generate(35, (index) {
                  final level = (index % 5) * 0.2; // Mock productivity levels
                  return Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: _getAccentColor(
                        context,
                      ).withValues(alpha: level.clamp(0.1, 1.0)),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}
