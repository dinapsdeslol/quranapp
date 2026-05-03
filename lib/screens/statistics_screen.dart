import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../services/audio_player_service.dart';

class StatisticsScreen extends StatefulWidget {
  final UserProfile userProfile;

  const StatisticsScreen({super.key, required this.userProfile});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final AudioPlayerService _audioService = AudioPlayerService();
  int _monthlyGoal = 20;
  int _totalMinutes = 0;
  Map<String, int> _dailyMinutes = {};
  List<MapEntry<String, int>> _topTracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _monthlyGoal = prefs.getInt('monthly_goal_hours') ?? 20;
    });

    final minutes = await _audioService.getTotalListeningMinutes();
    final daily = await _audioService.getDailyListeningMinutes();
    final top = await _audioService.getTopTracks();

    if (mounted) {
      setState(() {
        _totalMinutes = minutes;
        _dailyMinutes = daily;
        _topTracks = top;
        _isLoading = false;
      });
    }
  }

  Future<void> _changeGoal() async {
    final goals = [10, 15, 20, 25, 30, 40, 50];
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Monthly Listening Goal (hours)'),
        children: goals
            .map(
              (goal) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, goal),
                child: Text('$goal hours'),
              ),
            )
            .toList(),
      ),
    );

    if (selected != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('monthly_goal_hours', selected);
      setState(() {
        _monthlyGoal = selected;
      });
    }
  }

  double _getProgress() {
    final goalMinutes = _monthlyGoal * 60;
    return (_totalMinutes / goalMinutes).clamp(0.0, 1.0);
  }

  List<FlSpot> _getChartSpots() {
    final now = DateTime.now();
    final spots = <FlSpot>[];

    for (int i = 29; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      final key = date.toString().split(' ')[0];
      final minutes = _dailyMinutes[key] ?? 0;
      spots.add(FlSpot((30 - i).toDouble(), minutes.toDouble()));
    }

    return spots;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalHours = _totalMinutes ~/ 60;
    final remainingMinutes = _totalMinutes % 60;
    final progress = _getProgress();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade600, Colors.teal.shade800],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome,',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  widget.userProfile.fullName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.timelapse, color: Colors.teal, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Listening Time',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${totalHours}h ${remainingMinutes}m',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Monthly Goal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: _changeGoal,
                icon: const Icon(Icons.edit, size: 16),
                label: Text('$_monthlyGoal hours'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(
                progress >= 1.0 ? Colors.green : Colors.teal,
              ),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(_totalMinutes / 60).toStringAsFixed(1)} / $_monthlyGoal hours',
            style: TextStyle(
              fontSize: 14,
              color: progress >= 1.0 ? Colors.green : Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Daily Listening (Last 30 Days)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxY(),
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}m',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() % 5 == 0) {
                          return Text(
                            '${value.toInt() + 1}',
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: _getBarGroups(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Most Listened',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (_topTracks.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No listening data yet'),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _topTracks.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final track = _topTracks[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.shade100,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Colors.teal.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text('Track ${track.key}'),
                  trailing: Text(
                    '${track.value}x',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  double _getMaxY() {
    if (_dailyMinutes.isEmpty) return 60;
    final max = _dailyMinutes.values.fold<int>(0, (max, value) => value > max ? value : max);
    return (max + 10).toDouble();
  }

  List<BarChartGroupData> _getBarGroups() {
    final now = DateTime.now();
    final groups = <BarChartGroupData>[];

    for (int i = 29; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      final key = date.toString().split(' ')[0];
      final minutes = _dailyMinutes[key] ?? 0;

      groups.add(
        BarChartGroupData(
          x: 30 - i,
          barRods: [
            BarChartRodData(
              toY: minutes.toDouble(),
              color: Colors.teal.shade400,
              width: 8,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }

    return groups;
  }
}
