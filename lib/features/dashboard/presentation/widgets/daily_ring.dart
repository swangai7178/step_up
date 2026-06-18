import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:step_up_clone/core/constants/app_constants.dart';

class DailyRing extends StatelessWidget {
  final double progress;
  final int steps;
  final int target;

  const DailyRing({
    super.key,
    required this.progress,
    required this.steps,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    const size = 220.0;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: progress),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, animatedProgress, child) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Custom Painter for structural background track and bright progress ring
              Positioned.fill(
                child: CustomPaint(
                  painter: _RingPainter(
                    progress: animatedProgress,
                    strokeWidth: 16.0,
                  ),
                ),
              ),
              // Inside Text Readout
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    steps.toString(),
                    style: TextStyle(
                      color: AppConstants.textBright,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'of $target steps',
                    style: TextStyle(
                      color: AppConstants.textBright.withValues(alpha: 0.4),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 1. Draw Background Track Ring
    final trackPaint = Paint()
      ..color = AppConstants.backgroundDark.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    
    // Draw a secondary darker overlay border for depth
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawCircle(center, radius, borderPaint);

    // 2. Draw Rolling Progress Radial Arc
    final progressPaint = Paint()
      ..color = AppConstants.primaryAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Convert flat percentage mapping into safe radians starting at top center (-90 degrees)
    final startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}