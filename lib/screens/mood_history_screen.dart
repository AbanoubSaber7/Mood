import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mood_app/models/mood_history_entry.dart';
import 'package:mood_app/services/mood_history_service.dart';
import 'package:mood_app/widgets/background_widget.dart';

class MoodHistoryScreen extends StatefulWidget {
  final String userName;
  const MoodHistoryScreen({super.key, required this.userName});

  @override
  State<MoodHistoryScreen> createState() => _MoodHistoryScreenState();
}

class _MoodHistoryScreenState extends State<MoodHistoryScreen> {
  final _service = MoodHistoryService();
  List<MoodHistoryEntry> _entries = const [];
  bool _loading = true;

  static const List<String> _emotionOrder = [
    'Neutral', 'Happy', 'Surprise', 'Sad', 'Angry', 'Disgust', 'Fear',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await _service.load();
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  Color _getThemeColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy': return Colors.amber.shade700;
      case 'sad': return Colors.blueGrey;
      case 'angry': return Colors.redAccent;
      case 'surprise': return Colors.orangeAccent;
      case 'fear': return Colors.deepPurple;
      case 'disgust':
      case 'neutral':
      default: return const Color(0xFFC05A4E);
    }
  }

  Future<void> _clear() async {
    await _service.clear();
    await _load();
  }

  String _formatTs(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} | ${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final latestEmotion = _entries.isNotEmpty ? _entries.first.emotion : 'Neutral';
    final themeColor = _getThemeColor(latestEmotion);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Mood Journey', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: themeColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Clear History',
            onPressed: _entries.isEmpty ? null : () => _showClearDialog(themeColor),
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: BackgroundWidget(
        emotion: latestEmotion,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _entries.isEmpty
            ? _buildEmptyState()
            : ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: _entries.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            if (i == 0) return _buildChartCard(themeColor);
            return _buildHistoryItem(_entries[i - 1]);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 80, color: Colors.white.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('No history yet, ${widget.userName}.', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildChartCard(Color themeColor) {
    final maxCount = _entries.isEmpty ? 1 : _entries.length;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mood Distribution', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D2D2D))),
              Text('Last ${_entries.length}', style: TextStyle(fontSize: 12, color: themeColor, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 25),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxCount.toDouble() + 1,
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= _emotionOrder.length) return const SizedBox.shrink();
                        return Padding(padding: const EdgeInsets.only(top: 8), child: Text(_emotionOrder[i].substring(0, 3), style: const TextStyle(fontSize: 10, color: Colors.grey)));
                      },
                    ),
                  ),
                ),
                barGroups: _buildMoodCountBars(themeColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _buildMoodCountBars(Color themeColor) {
    final counts = <String, int>{for (final e in _emotionOrder) e: 0};
    for (final entry in _entries) {
      counts[entry.emotion] = (counts[entry.emotion] ?? 0) + 1;
    }
    return List.generate(_emotionOrder.length, (i) {
      final emotion = _emotionOrder[i];
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(toY: counts[emotion]!.toDouble(), width: 12, color: counts[emotion]! > 0 ? themeColor : Colors.grey.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
        ],
      );
    });
  }

  Widget _buildHistoryItem(MoodHistoryEntry e) {
    final itemColor = _getThemeColor(e.emotion);
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: itemColor.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.face_retouching_natural_rounded, color: itemColor)),
        title: Text(e.emotion, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D2D2D))),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 4),
          Text(_formatTs(e.timestamp), style: const TextStyle(fontSize: 11, color: Colors.grey)),
          if (e.confidencePercent != null) Text('Confidence: ${e.confidencePercent!.toStringAsFixed(1)}%', style: TextStyle(fontSize: 11, color: itemColor.withOpacity(0.8))),
        ]),
        trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)), child: Text(e.source.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black54))),
      ),
    );
  }

  void _showClearDialog(Color themeColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear History?'),
        content: const Text('This will delete all your mood records permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () { _clear(); Navigator.pop(context); }, child: Text('Clear All', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}