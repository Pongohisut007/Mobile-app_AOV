import 'package:flutter/material.dart';
import 'package:flutter_application_1/l10n/l10n.dart';

class CookingStepsHeader extends StatelessWidget {
  const CookingStepsHeader({
    super.key,
    required this.recipeName,
    required this.currentStep,
    required this.totalSteps,
    required this.onClose,
  });

  final String recipeName;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 14, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.cookingNow,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 3),
                Text(
                  recipeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  context.l10n.stepProgress(currentStep, totalSteps),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: context.l10n.close,
            onPressed: onClose,
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
        ],
      ),
    );
  }
}
