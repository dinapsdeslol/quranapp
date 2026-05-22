import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/audio_service.dart';

class StatsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const StatsScreen({super.key, required this.userData});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final AudioService _audio = AudioService();
  int _totalMin = 0;
  int _goal = 20;
  Map<String, int> _daily = {};
  List<MapEntry<String, int>> _top = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      _goal = prefs.getInt('goal_hours') ?? 20;
      _totalMin = 0;
      _daily = {};
      _top = [];
      for (int i = 29; i >= 0; i--) {
        final date = DateTime.now().subtract(Duration(days: i));
        final key = 'listen_${date.toString().split(' ')[0]}';
        final val = prefs.getInt(key) ?? 0;
        _totalMin += val;
        _daily[key.split('_')[1]] = val;
      }
      if (mounted) {
        setState(() { _loading = false; });
      }
      return;
    }
    final total = await _audio.getTotalMinutes();
    final daily = await _audio.getDailyMinutes();
    final top = await _audio.getTopTracks();
    final goal = await _audio.getMonthlyGoal();
    if (mounted) {
      setState(() { _totalMin = total; _daily = daily; _top = top; _goal = goal; _loading = false; });
    }
  }

  Future<void> _changeGoal() async {
    final goals = [5, 10, 15, 20, 25, 30, 40, 50];
    final picked = await showDialog<int>(context: context, builder: (_) => SimpleDialog(title: const Text('Monthly Goal (hours)'), children: goals.map((g) => SimpleDialogOption(onPressed: () => Navigator.pop(context, g), child: Text('$g hours'))).toList()));
    if (picked != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('goal_hours', picked);
      setState(() => _goal = picked);
    }
  }

  String _getFullName() {
    final first = widget.userData['firstName'] ?? '';
    final last = widget.userData['lastName'] ?? '';
    return '$first $last';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final hours = _totalMin ~/ 60;
    final mins = _totalMin % 60;
    final progress = (_totalMin / (_goal * 60)).clamp(0.0, 1.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1565C0)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Welcome,', style: TextStyle(fontSize: 16, color: Colors.white70)),
                Text(_getFullName(), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.timelapse, color: Colors.blue, size: 36),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Listening Time', style: TextStyle(fontSize: 14, color: Colors.grey)),
                      Text('${hours}h ${mins}m', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Monthly Goal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton.icon(onPressed: _changeGoal, icon: const Icon(Icons.edit, size: 16), label: Text('$_goal hours')),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress, backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(progress >= 1.0 ? Colors.green : Colors.blue), minHeight: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text('${(_totalMin / 60).toStringAsFixed(1)} / $_goal hours', style: TextStyle(fontSize: 14, color: progress >= 1.0 ? Colors.green : Colors.grey.shade600, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          const Text('Daily Listening (Last 30 Days)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround, maxY: _getMaxY(), barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, _) => Text('${v.toInt()}m', style: const TextStyle(fontSize: 10)))),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) { if (v.toInt() % 7 == 0) return Text('${v.toInt() + 1}', style: const TextStyle(fontSize: 10)); return const Text(''); })),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false), borderData: FlBorderData(show: false), barGroups: _getBars(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Most Listened', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_top.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('No listening data yet')))
          else
            ListView.separated(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _top.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (_, i) => ListTile(
                leading: CircleAvatar(backgroundColor: Colors.blue.shade100, child: Text('${i + 1}', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold))),
                title: Text('Track ${_top[i].key}'),
                trailing: Text('${_top[i].value}x', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              ),
            ),
        ],
      ),
    );
  }

  double _getMaxY() {
    if (_daily.isEmpty) return 60;
    final max = _daily.values.fold(0, (a, b) => b > a ? b : a);
    return (max + 10).toDouble();
  }

  List<BarChartGroupData> _getBars() {
    final keys = _daily.keys.toList();
    return List.generate(keys.length, (i) {
      return BarChartGroupData(x: i, barRods: [BarChartRodData(toY: _daily[keys[i]]!.toDouble(), color: Colors.blue.shade400, width: 8, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))]);
    });
  }
}
