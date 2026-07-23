import 'package:flutter/material.dart';

/// A labeled value with round +/− buttons — no keyboard needed.
/// Holding a button down repeats the step automatically.
class StepperRow extends StatelessWidget {
  final String label;
  final int value;
  final int step;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  /// Formats the value for display (e.g. seconds as "1:30"). Defaults to
  /// plain number.
  final String Function(int)? format;

  /// Optional icon shown to the left of the label (e.g. a dumbbell for Work).
  final IconData? leadingIcon;

  /// Accent color for the leading icon.
  final Color? iconColor;

  const StepperRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.step = 1,
    this.min = 0,
    this.max = 5999,
    this.format,
    this.leadingIcon,
    this.iconColor,
  });

  void _change(int delta) {
    final next = (value + delta).clamp(min, max);
    if (next != value) onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final text = format?.call(value) ?? '$value';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon,
                size: 22,
                color: iconColor ?? Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
          _HoldableIconButton(
            icon: Icons.remove_circle_outline,
            enabled: value > min,
            onStep: () => _change(-step),
          ),
          SizedBox(
            width: 72,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontFeatures: const []),
            ),
          ),
          _HoldableIconButton(
            icon: Icons.add_circle_outline,
            enabled: value < max,
            onStep: () => _change(step),
          ),
        ],
      ),
    );
  }
}

/// Icon button that fires once on tap and repeats while held down.
class _HoldableIconButton extends StatefulWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onStep;

  const _HoldableIconButton({
    required this.icon,
    required this.enabled,
    required this.onStep,
  });

  @override
  State<_HoldableIconButton> createState() => _HoldableIconButtonState();
}

class _HoldableIconButtonState extends State<_HoldableIconButton> {
  bool _holding = false;

  Future<void> _startHold() async {
    _holding = true;
    // Repeat faster the longer the button is held.
    var delay = const Duration(milliseconds: 300);
    while (_holding && mounted && widget.enabled) {
      widget.onStep();
      await Future.delayed(delay);
      if (delay.inMilliseconds > 80) {
        delay = Duration(milliseconds: (delay.inMilliseconds * 0.8).round());
      }
    }
  }

  void _stopHold() => _holding = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _startHold(),
      onLongPressEnd: (_) => _stopHold(),
      onLongPressCancel: _stopHold,
      child: IconButton(
        icon: Icon(widget.icon, size: 32),
        onPressed: widget.enabled ? widget.onStep : null,
      ),
    );
  }
}
