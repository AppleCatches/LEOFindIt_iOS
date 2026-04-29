import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

// Quick start tutorial made for new users Implemented in main with specific text

TargetFocus tutorialTarget({
  required GlobalKey key,
  required String id,
  required String title,
  required String body,
  ContentAlign align = ContentAlign.bottom,
  double yOffset = 0,
  bool showSkip = false,
  bool showClose = true,
  bool isLastStep = false,
  VoidCallback? onCloseAll,
}) {
  return TargetFocus(
    identify: id,
    keyTarget: key,
    contents: [
      TargetContent(
        align: yOffset == 0 ? align : ContentAlign.custom,
        customPosition: yOffset == 0
            ? null
            : CustomTargetContentPosition(
          top: yOffset,
        ),
        builder: (context, controller) {
          return Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    body,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (showSkip)
                        TextButton(
                          onPressed: onCloseAll ?? controller.skip,
                          child: const Text('Skip'),
                        ),
                      if (showClose)
                        TextButton(
                          onPressed: onCloseAll ?? controller.skip,
                          child: const Text('Close'),
                        ),
                      if (!isLastStep) ...[
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: controller.next,
                          child: const Text('Next'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ],
  );
}
