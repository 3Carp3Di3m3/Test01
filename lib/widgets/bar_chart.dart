import 'package:flutter/material.dart';

/// A tiny dependency-free bar chart. Draws one rounded bar per value with
/// optional labels underneath; the tallest bar is highlighted.
class MiniBarChart extends StatelessWidget {
  final List<int> values;
  final List<String> labels;
  final double height;

  const MiniBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxValue = values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (values[i] > 0)
                      Text(
                        '${values[i]}',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const SizedBox(height: 2),
                    // Bar grows with value; a floor so empty days still show.
                    TweenAnimationBuilder<double>(
                      tween: Tween(
                        begin: 0,
                        end: maxValue == 0 ? 0.0 : values[i] / maxValue,
                      ),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      builder: (context, t, _) => Container(
                        height: 6 + t * (height - 46),
                        decoration: BoxDecoration(
                          color: values[i] == maxValue && maxValue > 0
                              ? scheme.primary
                              : scheme.primary.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      i < labels.length ? labels[i] : '',
                      style: TextStyle(
                          color: scheme.outline, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
