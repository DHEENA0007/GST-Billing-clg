import re

file_path = "lib/screens/ai/ai_insights_screen.dart"
with open(file_path, 'r') as f:
    content = f.read()

# Insert the helper methods before the last closing brace of the StatefulWidget
helper_code = """
  Widget _buildSeverityPieChart(List alerts) {
    if (alerts.isEmpty) return const SizedBox.shrink();
    final counts = <String, int>{};
    for (var a in alerts) {
      if (a is! Map) continue;
      final severity = (a['severity']?.toString() ?? a['type']?.toString() ?? 'unknown').toUpperCase();
      counts[severity] = (counts[severity] ?? 0) + 1;
    }
    
    final sections = counts.entries.map((e) {
      final color = _alertColor(e.key);
      return PieChartSectionData(
        value: e.value.toDouble(),
        title: '${e.value}',
        color: color,
        radius: 40,
        titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return _buildPieChartCard('ALERTS BY SEVERITY', sections, counts.keys.toList(), counts.values.toList(), _alertColor);
  }

  Widget _buildStrategyPieChart(List recs) {
    if (recs.isEmpty) return const SizedBox.shrink();
    final counts = <String, int>{};
    for (var r in recs) {
      if (r is! Map) continue;
      final category = (r['category']?.toString() ?? 'General').toUpperCase();
      counts[category] = (counts[category] ?? 0) + 1;
    }

    final colors = [Colors.indigo, Colors.blue, Colors.teal, Colors.orange, Colors.purple];
    int colorIdx = 0;
    final Map<String, Color> catColors = {};

    final sections = counts.entries.map((e) {
      if (!catColors.containsKey(e.key)) {
        catColors[e.key] = colors[colorIdx % colors.length];
        colorIdx++;
      }
      return PieChartSectionData(
        value: e.value.toDouble(),
        title: '${e.value}',
        color: catColors[e.key]!,
        radius: 40,
        titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return _buildPieChartCard('STRATEGIES BY CATEGORY', sections, counts.keys.toList(), counts.values.toList(), (k) => catColors[k]!);
  }

  Widget _buildHealthPieChart(List factors) {
    if (factors.isEmpty) return const SizedBox.shrink();
    
    final sections = <PieChartSectionData>[];
    final legends = <String>[];
    final values = <int>[];
    
    for (var f in factors) {
      if (f is! Map) continue;
      final name = (f['name']?.toString() ?? f['factor']?.toString() ?? '').toUpperCase();
      final scoreVal = f['score'] ?? f['value'] ?? 0;
      final scoreD = scoreVal is num ? scoreVal.toDouble() : 0.0;
      final color = _getHealthColor(scoreD);
      
      sections.add(PieChartSectionData(
        value: scoreD,
        title: '${scoreD.toInt()}%',
        color: color.withOpacity(0.8),
        radius: 40,
        titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 10),
      ));
      legends.add(name);
      values.add(scoreD.toInt());
    }

    return _buildPieChartCard('HEALTH METRICS', sections, legends, values, (k) => _getHealthColor(values[legends.indexOf(k)].toDouble()));
  }

  Widget _buildPieChartCard(String title, List<PieChartSectionData> sections, List<String> legends, List<int> values, Color Function(String) colorMap) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1.5)),
                const Icon(Icons.pie_chart_rounded, color: Color(0xFF94A3B8), size: 16),
            ]
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: PieChart(PieChartData(sections: sections, centerSpaceRadius: 40, sectionsSpace: 2)),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: List.generate(legends.length, (i) {
              final color = colorMap(legends[i]);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(width: 6),
                  Text('${legends[i]} (${values[i]})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _GlassMetricCard"""

match = re.search(r'  Widget _buildUrgencyChip\(String urgency\) \{.*?  \}\n}', content, re.DOTALL)
if match:
    new_content = content[:match.end() - 2] + helper_code + content[match.end() - 2 + len('\nclass _GlassMetricCard'):]
    with open(file_path, 'w') as f:
        f.write(new_content)
    print("Injected helper methods.")
else:
    print("Could not find insertion point!")
