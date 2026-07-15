import 'package:flutter/material.dart';

class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> labels;

  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps * 2 - 1, (i) {
        if (i.isOdd) {
          return Container(
            width: 40,
            height: 2,
            color: i ~/ 2 < currentStep
                ? const Color(0xFFE30613)
                : Colors.white30,
          );
        }
        final step = i ~/ 2;
        final isActive = step <= currentStep;
        final isCurrent = step == currentStep;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isCurrent ? 36 : 28,
              height: isCurrent ? 36 : 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? const Color(0xFFE30613)
                    : Colors.transparent,
                border: Border.all(
                  color: isActive ? const Color(0xFFE30613) : Colors.white38,
                  width: 2,
                ),
              ),
              child: Center(
                child: isCurrent
                    ? Text(
                        '${step + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      )
                    : Icon(
                        isActive ? Icons.check : Icons.circle_outlined,
                        color: isActive ? Colors.white : Colors.white38,
                        size: 14,
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              labels.length > step ? labels[step] : '',
              style: TextStyle(
                color: isCurrent ? Colors.white : Colors.white60,
                fontSize: 11,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        );
      }),
    );
  }
}
