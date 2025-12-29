import 'package:flutter/material.dart';
import '../services/time_tracker_service.dart';
import '../widgets/glass_container.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TimeTrackerService _service = TimeTrackerService();
  
  // Date states
  DateTime _selectedDate = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          indicatorWeight: 3,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Day'),
            Tab(text: 'Week'),
            Tab(text: 'Month'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDayView(),
          _buildWeekView(),
          _buildMonthView(),
        ],
      ),
    );
  }

  // ==================== DAY VIEW ====================

  Widget _buildDayView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateSelector(
            label: DateFormat('EEEE, MMM d').format(_selectedDate),
            onPrev: () => _changeDate(-1),
            onNext: () => _changeDate(1),
          ),
          const SizedBox(height: 24),
          _buildSummaryCards(_selectedDate, _selectedDate),
          const SizedBox(height: 24),
          Text(
            'Hourly Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _buildHourlyChart(_selectedDate),
          const SizedBox(height: 24),
          Text(
            'Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _buildCategoryDistribution(_selectedDate, _selectedDate),
        ],
      ),
    );
  }

  // ==================== WEEK VIEW ====================

  Widget _buildWeekView() {
    // Calculate start/end of the selected week
    final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final dateRangeLabel = '${DateFormat('MMM d').format(startOfWeek)} - ${DateFormat('MMM d').format(endOfWeek)}';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateSelector(
            label: dateRangeLabel,
            onPrev: () => _changeDate(-7),
            onNext: () => _changeDate(7),
          ),
          const SizedBox(height: 24),
          _buildSummaryCards(startOfWeek, endOfWeek),
          const SizedBox(height: 24),
          Text(
            'Weekly Performance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _buildDailyBarChart(startOfWeek, endOfWeek), // 7 Bars
          const SizedBox(height: 24),
          Text(
            'Activity Heatmap',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          // Show heatmap for the last 4 weeks ending at endOfWeek to show consistency
          _buildHeatmap(endOfWeek.subtract(const Duration(days: 27)), endOfWeek),
          const SizedBox(height: 24),
          Text(
            'Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _buildCategoryDistribution(startOfWeek, endOfWeek),
        ],
      ),
    );
  }

  // ==================== MONTH VIEW ====================

  Widget _buildMonthView() {
    final startOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final endOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateSelector(
            label: DateFormat('MMMM y').format(_selectedDate),
            onPrev: () => setState(() => _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1)),
            onNext: () => setState(() => _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1)),
          ),
          const SizedBox(height: 24),
          _buildSummaryCards(startOfMonth, endOfMonth),
          const SizedBox(height: 24),
          Text(
            'Daily Trend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _buildDailyBarChart(startOfMonth, endOfMonth, isCompact: true),
          const SizedBox(height: 24),
          Text(
            'Monthly Heatmap',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _buildHeatmap(startOfMonth, endOfMonth),
          const SizedBox(height: 24),
          Text(
            'Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _buildCategoryDistribution(startOfMonth, endOfMonth),
        ],
      ),
    );
  }

  // ==================== WIDGETS ====================

  Widget _buildDateSelector({required String label, required VoidCallback onPrev, required VoidCallback onNext}) {
    return GlassContainer(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(DateTime start, DateTime end) {
    // We need to fetch total duration for this range
    // Since we don't have a direct 'Total Duration' stream, we can use getDailyBreakdown and sum it up
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _service.getDailyBreakdown(start, end),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: LinearProgressIndicator());
        
        double totalHours = 0;
        for (var day in snapshot.data!) {
          totalHours += (day['hours'] as double);
        }
        
        final daysCount = end.difference(start).inDays + 1;
        final avgHours = totalHours / daysCount;

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Time',
                '${totalHours.toStringAsFixed(1)}h',
                Icons.access_time_filled,
                Colors.blueAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Daily Avg',
                '${avgHours.toStringAsFixed(1)}h',
                Icons.analytics,
                Colors.purpleAccent,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyChart(DateTime date) {
    return FutureBuilder<List<double>>(
      future: _service.getHourlyProductivity(date),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
        
        final data = snapshot.data!;
        final maxVal = data.isEmpty ? 1.0 : data.reduce((a, b) => a > b ? a : b);
        final safeMax = maxVal == 0 ? 1.0 : maxVal;

        return GlassContainer(
          padding: const EdgeInsets.all(16),
          height: 220,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(24, (index) {
                    final heightPct = data[index] / safeMax;
                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Tooltip(
                            message: '$index:00 - ${data[index].toStringAsFixed(1)}m',
                            child: Container(
                              height: 140 * heightPct,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('00:00', style: TextStyle(fontSize: 10)),
                  Text('06:00', style: TextStyle(fontSize: 10)),
                  Text('12:00', style: TextStyle(fontSize: 10)),
                  Text('18:00', style: TextStyle(fontSize: 10)),
                  Text('23:00', style: TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDailyBarChart(DateTime start, DateTime end, {bool isCompact = false}) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _service.getDailyBreakdown(start, end),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
        
        final data = snapshot.data!;
        double maxHours = 0;
        for (var d in data) {
          if (d['hours'] > maxHours) maxHours = d['hours'];
        }
        if (maxHours == 0) maxHours = 1;

        return GlassContainer(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
          height: 220,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: data.map((dayData) {
                    final hours = dayData['hours'] as double;
                    final heightPct = hours / maxHours;
                    
                    return Expanded(
                      child: Tooltip(
                        message: '${DateFormat('MMM d').format(dayData['date'])}: ${hours.toStringAsFixed(1)}h',
                        child: Container(
                          height: 150 * heightPct,
                          margin: EdgeInsets.symmetric(horizontal: isCompact ? 1 : 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              // Separate Row for labels to avoid wrapping issues
              Row(
                children: data.map((dayData) {
                  final date = dayData['date'] as DateTime;
                  final showLabel = isCompact ? (date.day % 5 == 0) : true;
                  final label = isCompact 
                      ? '${date.day}' 
                      : DateFormat('E').format(date).substring(0, 1);

                  return Expanded(
                    child: Center(
                      child: showLabel 
                        ? Text(
                            label,
                            style: TextStyle(
                              fontSize: 9,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.visible,
                          )
                        : const SizedBox.shrink(),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeatmap(DateTime start, DateTime end) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _service.getDailyBreakdown(start, end),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 100);
        
        final data = snapshot.data!;
        
        // Calculate leading empty spaces for calendar alignment
        final firstDay = data.first['date'] as DateTime;
        final leadingSpaces = firstDay.weekday - 1; // 0 for Monday, 6 for Sunday
        
        return GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day of week headers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) => 
                  SizedBox(
                    width: 20, 
                    child: Text(
                      d, 
                      style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    )
                  )
                ).toList(),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: data.length + leadingSpaces,
                itemBuilder: (context, index) {
                  if (index < leadingSpaces) {
                    return const SizedBox.shrink();
                  }
                  
                  final day = data[index - leadingSpaces];
                  final hours = day['hours'] as double;
                  final date = day['date'] as DateTime;
                  
                  // Intensity logic
                  Color color;
                  if (hours == 0) {
                    color = Colors.grey.withOpacity(0.1);
                  } else if (hours < 2) {
                    color = Colors.green.withOpacity(0.3);
                  } else if (hours < 4) {
                    color = Colors.green.withOpacity(0.5);
                  } else if (hours < 6) {
                    color = Colors.green.withOpacity(0.7);
                  } else {
                    color = Colors.green.withOpacity(0.9);
                  }

                  return Tooltip(
                    message: '${DateFormat('yyyy-MM-dd').format(date)}\n${hours.toStringAsFixed(1)} hrs',
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Text('Less', style: TextStyle(fontSize: 10)),
                  SizedBox(width: 4),
                  Icon(Icons.square_rounded, size: 12, color: Colors.grey),
                  Icon(Icons.square_rounded, size: 12, color: Colors.green),
                  SizedBox(width: 4),
                  Text('More', style: TextStyle(fontSize: 10)),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryDistribution(DateTime start, DateTime end) {
    return FutureBuilder<Map<String, int>>(
      future: _service.getCategoryBreakdown(start, end),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return GlassContainer(
            padding: const EdgeInsets.all(16),
            child: const Center(child: Text('No data for this period')),
          );
        }

        final data = snapshot.data!;
        final totalSeconds = data.values.fold(0, (sum, val) => sum + val);
        final sortedKeys = data.keys.toList()
          ..sort((a, b) => data[b]!.compareTo(data[a]!));

        return GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: sortedKeys.map((cat) {
              final seconds = data[cat]!;
              final pct = seconds / totalSeconds;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        cat,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Stack(
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: pct,
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.tertiary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(pct * 100).toStringAsFixed(0)}%',
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
}
