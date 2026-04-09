import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Small badge/indicator showing pending offline sync count.
class SyncIndicatorWidget extends StatelessWidget {
  final int pendingCount;
  final VoidCallback? onTap;

  const SyncIndicatorWidget({
    super.key,
    required this.pendingCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (pendingCount <= 0) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: AppColors.warning,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              '$pendingCount pending',
              style: const TextStyle(
                color: AppColors.warning,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
