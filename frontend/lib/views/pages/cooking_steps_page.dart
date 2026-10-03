import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/food.dart';
import 'package:flutter_application_1/widgets/cooking_steps/cooking_step_card.dart';
import 'package:flutter_application_1/widgets/cooking_steps/cooking_steps_header.dart';
import 'package:flutter_application_1/widgets/cooking_steps/cooking_step_controls.dart';
import 'package:flutter_application_1/widgets/cooking_steps/empty_steps.dart';

class CookingStepsPage extends StatefulWidget {
  const CookingStepsPage({
    super.key,
    required this.food,
  });

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

    _pageController = PageController(
      viewportFraction: 0.88,
    );
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
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            28,
            8,
            28,
            36,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.celebration_rounded,
                size: 58,
                color: Color(0xFFFF6847),
              ),
              const SizedBox(height: 12),
              const Text(
                'ทำอาหารเสร็จแล้ว!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'คุณทำ ${widget.food.name} ครบทุกขั้นตอนแล้ว',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('กลับไปหน้าสูตรอาหาร'),
                ),
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
            colors: [
              Color(0xFF6650A5),
              Color(0xFF769FDA),
              Color(0xFF83D5DC),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              CookingStepsHeader(
                recipeName: widget.food.name,
                currentStep: steps.isEmpty ? 0 : _currentIndex + 1,
                totalSteps: steps.length,
                onClose: () => Navigator.pop(context),
              ),

              if (steps.isEmpty)
                const Expanded(
                  child: EmptySteps(),
                )
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                        ),
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