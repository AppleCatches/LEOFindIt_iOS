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
    alignSkip: Alignment.topRight,
    contents: [
      TargetContent(
        align: align,
        customPosition: yOffset == 0
            ? null
            : CustomTargetContentPosition(top: yOffset),
        builder: (context, controller) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    body,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Skip button is intentionally disabled after the user starts the guide
                      /*
                      if (showSkip)
                        TextButton(
                          onPressed: controller.skip,
                          child: const Text('Skip'),
                        ),
                      */
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
