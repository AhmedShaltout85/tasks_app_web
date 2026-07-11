import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:tasks_app/models/daily_task_model.dart';

class TaskPriorityChart extends StatelessWidget {
  final List<DailyTaskModel> tasks;

  const TaskPriorityChart({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final high = tasks.where((t) => t.taskPriority.toUpperCase() == 'HIGH').length;
    final medium = tasks.where((t) => t.taskPriority.toUpperCase() == 'MEDIUM').length;
    final low = tasks.where((t) => t.taskPriority.toUpperCase() == 'LOW').length;
    final other = tasks.length - high - medium - low;
    final total = tasks.length;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.bar_chart_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'توزيع المهام حسب الأولوية',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              if (total > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$total مهمة',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Cairo',
                      color: colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          tasks.isEmpty
              ? SizedBox(
                  height: 180,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bar_chart_rounded,
                            size: 40, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text(
                          'لا توجد بيانات',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontFamily: 'Cairo',
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxY(high, medium, low, other),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final labels = ['عالية', 'متوسطة', 'منخفضة'];
                            return BarTooltipItem(
                              '${labels[group.x]}: ${rod.toY.round()}',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              final labels = {
                                0: 'عالية',
                                1: 'متوسطة',
                                2: 'منخفضة',
                              };
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  labels[value.toInt()] ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: _getGridInterval(high, medium, low, other),
                            getTitlesWidget: (value, meta) {
                              if (value == 0 || value != value.roundToDouble()) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                '${value.toInt()}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'Cairo',
                                  color: Colors.grey.shade400,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles:
                            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles:
                            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval:
                            _getGridInterval(high, medium, low, other),
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withValues(alpha: isDark ? 0.15 : 0.12),
                          strokeWidth: 1,
                          dashArray: [4, 4],
                        ),
                      ),
                      barGroups: [
                        BarChartGroupData(
                          x: 0,
                          barRods: [
                            BarChartRodData(
                              toY: high.toDouble(),
                              width: 36,
                              borderRadius:
                                  const BorderRadius.vertical(top: Radius.circular(8)),
                              gradient: const LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Color(0xFFE53935), Color(0xFFF44336)],
                              ),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: _getMaxY(high, medium, low, other),
                                color: const Color(0xFFF44336).withValues(alpha: 0.06),
                              ),
                            ),
                          ],
                          showingTooltipIndicators: [0],
                        ),
                        BarChartGroupData(
                          x: 1,
                          barRods: [
                            BarChartRodData(
                              toY: medium.toDouble(),
                              width: 36,
                              borderRadius:
                                  const BorderRadius.vertical(top: Radius.circular(8)),
                              gradient: const LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Color(0xFFF57C00), Color(0xFFFF9800)],
                              ),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: _getMaxY(high, medium, low, other),
                                color: const Color(0xFFFF9800).withValues(alpha: 0.06),
                              ),
                            ),
                          ],
                          showingTooltipIndicators: [0],
                        ),
                        BarChartGroupData(
                          x: 2,
                          barRods: [
                            BarChartRodData(
                              toY: low.toDouble(),
                              width: 36,
                              borderRadius:
                                  const BorderRadius.vertical(top: Radius.circular(8)),
                              gradient: const LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Color(0xFF388E3C), Color(0xFF4CAF50)],
                              ),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: _getMaxY(high, medium, low, other),
                                color: const Color(0xFF4CAF50).withValues(alpha: 0.06),
                              ),
                            ),
                          ],
                          showingTooltipIndicators: [0],
                        ),
                      ],
                    ),
                  ),
                ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatBadge(
                  context: context,
                  color: const Color(0xFFF44336),
                  label: 'عالية',
                  count: high,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatBadge(
                  context: context,
                  color: const Color(0xFFFF9800),
                  label: 'متوسطة',
                  count: medium,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatBadge(
                  context: context,
                  color: const Color(0xFF4CAF50),
                  label: 'منخفضة',
                  count: low,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _getMaxY(int high, int medium, int low, int other) {
    final maxVal = [high, medium, low, other].reduce((a, b) => a > b ? a : b);
    return (maxVal == 0 ? 5 : maxVal + 3).toDouble();
  }

  double _getGridInterval(int high, int medium, int low, int other) {
    final maxVal = [high, medium, low, other].reduce((a, b) => a > b ? a : b);
    if (maxVal <= 5) return 1;
    if (maxVal <= 20) return 5;
    if (maxVal <= 50) return 10;
    return (maxVal / 5).ceilToDouble();
  }

  Widget _buildStatBadge({
    required BuildContext context,
    required Color color,
    required String label,
    required int count,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$label ($count)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Cairo',
                color: Theme.of(context).colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
