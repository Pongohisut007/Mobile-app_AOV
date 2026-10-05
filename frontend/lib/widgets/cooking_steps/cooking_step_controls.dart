import 'package:flutter/material.dart';
import 'package:flutter_application_1/l10n/l10n.dart';

class CookingStepControls extends StatelessWidget {
  const CookingStepControls({
    super.key,
    required this.currentIndex,
    required this.totalSteps,
    required this.onPrevious,
    required this.onContinue,
  });

  final int currentIndex;
  final int totalSteps;
  final VoidCallback onPrevious;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final isLast = currentIndex == totalSteps - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            height: 58,
            child: IconButton.filledTonal(
              tooltip: context.l10n.previousStep,
              onPressed: currentIndex == 0 ? null : onPrevious,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: SizedBox(
              height: 58,
              child: FilledButton.icon(
                key: const Key('complete-step-button'),
                onPressed: onContinue,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF24BDB8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: Icon(
                  isLast ? Icons.done_all_rounded : Icons.check_rounded,
                ),
                label: Text(
                  isLast ? context.l10n.finishCooking : context.l10n.finishStep,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
