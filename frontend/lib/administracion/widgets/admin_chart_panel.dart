import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'admin_common_widgets.dart';

class AdminChartPanel extends StatelessWidget {
  const AdminChartPanel({
    super.key,
    required this.title,
    required this.values,
    required this.empty,
    this.isStatusChart = false,
  });

  final String title;
  final String empty;
  final Map<String, int> values;
  final bool isStatusChart;

  @override
  Widget build(BuildContext context) {
    final formattedValues = isStatusChart
        ? values.map((k, v) => MapEntry(formatRequirementStatus(k), v))
        : values;

    final maxValue = formattedValues.values.fold<int>(
      0,
      (max, value) => value > max ? value : max,
    );

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            if (formattedValues.isEmpty)
              Text(
                empty,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              )
            else
              for (final entry in formattedValues.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.key,
                              style: const TextStyle(fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${entry.value}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      LinearProgressIndicator(
                        value: maxValue == 0 ? 0 : entry.value / maxValue,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(8),
                        backgroundColor: AppColors.surfaceLow,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isStatusChart
                              ? _statusColor(entry.key)
                              : AppColors.cyan,
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'cumplido':
        return AppColors.successText;
      case 'en proceso':
        return AppColors.cyan;
      case 'pendiente':
        return AppColors.warningText;
      default:
        return AppColors.navy;
    }
  }
}
