import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

/// Creates a nice-looking tutorial target for TutorialCoachMark
TargetFocus tutorialTarget({
  required GlobalKey key,
  required String id,
  required String title,
  required String body,
  ContentAlign align = ContentAlign.bottom,
  double yOffset = 0,
  bool showSkip = true,
}) {
  return TargetFocus(
    identify: id,
    keyTarget: key,
    contents: [
      TargetContent(
        align: yOffset == 0 ? align : ContentAlign.custom,
        customPosition: yOffset == 0
            ? null
            : CustomTargetContentPosition(top: yOffset),
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
                      /*
                      if (showSkip)
                        TextButton(
                          onPressed: controller.skip,
                          child: const Text('Skip'),
                        ),*/
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: controller.next,
                        child: const Text('Next'),
                      ),
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

/// Blinks / pulses a widget when tutorial mode is active (used in AppDrawer)
class TutorialBlinker extends StatefulWidget {
  final Widget child;
  final bool isTutorialMode;

  const TutorialBlinker({
    super.key,
    required this.child,
    required this.isTutorialMode,
  });

  @override
  State<TutorialBlinker> createState() => _TutorialBlinkerState();
}

class _TutorialBlinkerState extends State<TutorialBlinker>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _anim = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

    if (widget.isTutorialMode) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(TutorialBlinker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTutorialMode && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.isTutorialMode && _ctrl.isAnimating) {
      _ctrl.reset();
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isTutorialMode) return widget.child;
    return FadeTransition(opacity: _anim, child: widget.child);
  }
}
