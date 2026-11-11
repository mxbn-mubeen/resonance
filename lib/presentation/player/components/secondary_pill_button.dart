import 'package:flutter/material.dart';

class SecondaryPillButton extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData icon;
  final String label;
  final bool enabled;
  final bool isActive;

  const SecondaryPillButton({
    super.key,
    required this.onTap,
    required this.icon,
    required this.label,
    this.enabled = true,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? Colors.white24
        : isActive
            ? Colors.greenAccent
            : Colors.white.withValues(alpha: 0.85);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 17),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

