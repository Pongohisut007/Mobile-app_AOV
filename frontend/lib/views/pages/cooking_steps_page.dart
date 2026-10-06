import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/food.dart';
import 'package:flutter_application_1/widgets/cooking_steps/cooking_step_card.dart';
import 'package:flutter_application_1/widgets/cooking_steps/cooking_steps_header.dart';
import 'package:flutter_application_1/widgets/cooking_steps/cooking_step_controls.dart';
import 'package:flutter_application_1/widgets/cooking_steps/empty_steps.dart';
import 'package:flutter_application_1/l10n/l10n.dart';
import 'package:flutter_application_1/widgets/common/app_sheet.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';
import 'package:flutter_application_1/widgets/common/app_dialog.dart';

class CookingStepsPage extends StatefulWidget {
  const CookingStepsPage({super.key, required this.food});

  final Food food;

  @override
  State<CookingStepsPage> createState() => _CookingStepsPageState();
}

class _CookingStepsPageState extends State<CookingStepsPage> {
  late final PageController _pageController;

  int _currentIndex = 0;
  final Set<int> _completedSteps = {};

  @override
  void initState() {
    super.initState();

    _pageController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index < 0 || index >= widget.food.steps.length) {
      return;
    }

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _completeOrContinue() {
    setState(() {
      _completedSteps.add(_currentIndex);
    });

    if (_currentIndex < widget.food.steps.length - 1) {
      _goTo(_currentIndex + 1);
      return;
    }

    _showCompletedSheet();
  }

  void _showCompletedSheet() {
    showAppBottomSheet<void>(
      context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEDE8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.celebration_rounded,
                    size: 40,
                    color: Color(0xFFFF6847),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.cookingDone,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ProfileColors.ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.cookingDoneMessage(
                  widget.food.displayName(context),
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ProfileColors.muted,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              AppDialogButton(
                label: context.l10n.backToRecipePage,
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.food.steps;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6650A5), Color(0xFF769FDA), Color(0xFF83D5DC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              CookingStepsHeader(
                recipeName: widget.food.displayName(context),
                currentStep: steps.isEmpty ? 0 : _currentIndex + 1,
                totalSteps: steps.length,
                onClose: () => Navigator.pop(context),
              ),

              if (steps.isEmpty)
                const Expanded(child: EmptySteps())
              else ...[
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: steps.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        child: CookingStepCard(
                          step: steps[index],
                          stepNumber: index + 1,
                          totalSteps: steps.length,
                          isCompleted: _completedSteps.contains(index),
                          isActive: index == _currentIndex,
                        ),
                      );
                    },
                  ),
                ),

                CookingStepControls(
                  currentIndex: _currentIndex,
                  totalSteps: steps.length,
                  onPrevious: () => _goTo(_currentIndex - 1),
                  onContinue: _completeOrContinue,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
