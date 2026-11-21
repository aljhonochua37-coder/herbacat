import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class CautionCallout extends StatelessWidget {
  final String title;
  final String message;

  const CautionCallout({
    super.key,
    this.title = 'Safety Precautions & Contraindications',
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFBF0EC), // Soft clay background wash
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(
            color: AppColors.primary, // 4px terracotta left border
            width: 4,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A94452C),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.labelLg(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

