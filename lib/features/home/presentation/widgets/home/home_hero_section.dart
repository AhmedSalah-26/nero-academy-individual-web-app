import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/shared_widgets/glass_search_bar.dart';
import '../../../../../core/theme/app_colors.dart';
import 'home_app_bar.dart';

class HomeSliverAppBar extends StatelessWidget {
  final String? userName;

  const HomeSliverAppBar({super.key, this.userName});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final toolbarHeight = (w * 0.24).clamp(92.0, 108.0);
    final expandedHeight =
        (w * 0.58 + toolbarHeight + 54.0).clamp(335.0, 395.0);

    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor:
          isDark ? AppColors.backgroundDark : const Color(0xFFEEE4FC),
      expandedHeight: expandedHeight,
      toolbarHeight: toolbarHeight,
      titleSpacing: 0,
      title: HomeAppBar(userName: userName),
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: toolbarHeight),
              Expanded(
                child: _HeroVisual(isDark: isDark),
              ),
            ],
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(46.0 + (w * 0.038) + 8.0),
        child: Container(
          color: Colors.transparent,
          padding: EdgeInsets.only(
            left: w * 0.04,
            right: w * 0.04,
            bottom: w * 0.038,
            top: 8,
          ),
          child: GlassSearchBar(
            hintText: 'ابحث عن درس، امتحان، مذكرة ...',
            onTap: () => context.pushNamed('search'),
            readOnly: true,
            height: 46,
            borderRadius: 12,
            iconSize: w * 0.05,
            hintStyle: TextStyle(fontSize: w * 0.033),
          ),
        ),
      ),
    );
  }
}

class _HeroVisual extends StatelessWidget {
  final bool isDark;

  const _HeroVisual({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color:
                isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          ),
        ),
        _AnimatedChemistryShapes(isDark: isDark),
        Image.asset(
          'assets/home_hero_cutout.png',
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          alignment: Alignment.centerRight,
        ),
        _HeroCopy(isDark: isDark),
      ],
    );
  }
}

class _AnimatedChemistryShapes extends StatefulWidget {
  final bool isDark;

  const _AnimatedChemistryShapes({required this.isDark});

  @override
  State<_AnimatedChemistryShapes> createState() =>
      _AnimatedChemistryShapesState();
}

class _AnimatedChemistryShapesState extends State<_AnimatedChemistryShapes>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _BrushSashPainter(isDark: widget.isDark, turn: t),
              ),
              _FloatingChemShape(
                left: 0.80,
                top: 0.12,
                size: 46,
                turn: t,
                depth: 0.45,
                painter: _DotGridPainter(isDark: widget.isDark),
              ),
              _FloatingChemShape(
                left: 0.90,
                top: 0.33,
                size: 54,
                turn: 1 - t,
                depth: 0.7,
                painter: _FlaskPainter(isDark: widget.isDark),
              ),
              _FloatingChemShape(
                left: 0.86,
                top: 0.58,
                size: 54,
                turn: t,
                depth: 0.55,
                painter: _MoleculePainter(isDark: widget.isDark),
              ),
              _FloatingChemShape(
                left: 0.77,
                top: 0.23,
                size: 38,
                turn: 1 - t,
                depth: 0.35,
                painter: _HexagonPainter(isDark: widget.isDark),
              ),
              _FloatingChemShape(
                left: 0.18,
                top: 0.63,
                size: 64,
                turn: t,
                depth: 0.42,
                painter: _MoleculePainter(isDark: widget.isDark, faint: true),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FloatingChemShape extends StatelessWidget {
  final double left;
  final double top;
  final double size;
  final double turn;
  final double depth;
  final CustomPainter painter;

  const _FloatingChemShape({
    required this.left,
    required this.top,
    required this.size,
    required this.turn,
    required this.depth,
    required this.painter,
  });

  @override
  Widget build(BuildContext context) {
    final xTilt = (turn - 0.5) * depth;
    final yTilt = (0.5 - turn) * depth * 0.65;
    final floatOffset = (turn - 0.5) * 10;

    return Positioned(
      left: MediaQuery.of(context).size.width * left,
      top: MediaQuery.of(context).size.width * top + floatOffset,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0015)
          ..rotateX(xTilt)
          ..rotateY(yTilt)
          ..rotateZ((turn - 0.5) * 0.12),
        child: CustomPaint(
          size: Size.square(size),
          painter: painter,
        ),
      ),
    );
  }
}

class _BrushSashPainter extends CustomPainter {
  final bool isDark;
  final double turn;

  const _BrushSashPainter({required this.isDark, required this.turn});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final lift = (turn - 0.5) * h * 0.025;
    final base = Path()
      ..moveTo(-w * 0.05, h * 0.78 + lift)
      ..cubicTo(
        w * 0.18,
        h * 0.78 + lift,
        w * 0.35,
        h * 0.58 - lift,
        w * 0.52,
        h * 0.55,
      )
      ..cubicTo(
        w * 0.72,
        h * 0.51 + lift,
        w * 0.86,
        h * 0.23 - lift,
        w * 1.08,
        h * 0.24,
      );

    final shadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = h * 0.19
      ..color = Colors.black.withValues(alpha: isDark ? 0.22 : 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawPath(base.shift(Offset(0, h * 0.025)), shadowPaint);

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = h * 0.17
      ..shader = LinearGradient(
        colors: isDark
            ? [
                AppColors.primaryOnDark.withValues(alpha: 0.04),
                AppColors.primaryOnDark.withValues(alpha: 0.34),
                AppColors.primary.withValues(alpha: 0.48),
                AppColors.primaryDark.withValues(alpha: 0.16),
              ]
            : [
                AppColors.primaryLight.withValues(alpha: 0.05),
                AppColors.primaryLight.withValues(alpha: 0.55),
                AppColors.primary.withValues(alpha: 0.26),
                AppColors.primaryDark.withValues(alpha: 0.08),
              ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawPath(base, glowPaint);

    final ridgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = h * 0.045
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: isDark ? 0.04 : 0.18),
          AppColors.primaryOnDark.withValues(alpha: isDark ? 0.44 : 0.26),
          AppColors.primaryDark.withValues(alpha: isDark ? 0.20 : 0.12),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    for (var i = 0; i < 7; i++) {
      final offset = (i - 3) * h * 0.018;
      final texturePath = Path()
        ..moveTo(-w * 0.02, h * (0.74 + i * 0.006) + lift + offset)
        ..cubicTo(
          w * 0.22,
          h * (0.78 - i * 0.012) + lift,
          w * 0.43,
          h * (0.57 + i * 0.006) - lift,
          w * 0.57,
          h * (0.56 - i * 0.004),
        )
        ..cubicTo(
          w * 0.73,
          h * (0.52 + i * 0.003) + lift,
          w * 0.86,
          h * (0.26 - i * 0.004) - lift,
          w * 1.06,
          h * (0.24 + i * 0.006),
        );
      ridgePaint.strokeWidth = h * (0.01 + (i % 3) * 0.006);
      ridgePaint.color = ridgePaint.color.withValues(alpha: 0.18);
      canvas.drawPath(texturePath, ridgePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BrushSashPainter oldDelegate) {
    return oldDelegate.isDark != isDark || oldDelegate.turn != turn;
  }
}

abstract class _ChemPainter extends CustomPainter {
  final bool isDark;
  final bool faint;

  const _ChemPainter({required this.isDark, this.faint = false});

  Color get stroke => (isDark ? AppColors.primaryOnDark : AppColors.primary)
      .withValues(alpha: faint ? 0.28 : 0.72);

  Color get fill => (isDark ? AppColors.primaryOnDark : AppColors.primary)
      .withValues(alpha: faint ? 0.12 : 0.22);

  void drawGlassDisc(Canvas canvas, Size size) {
    final s = size.width;
    final rect = Offset.zero & size;
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.28 : 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s * 0.52, s * 0.56),
        width: s * 0.78,
        height: s * 0.72,
      ),
      shadowPaint,
    );
    final fillPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.45),
        radius: 0.95,
        colors: [
          Colors.white.withValues(alpha: isDark ? 0.16 : 0.30),
          (isDark ? AppColors.primaryOnDark : AppColors.primary)
              .withValues(alpha: faint ? 0.07 : 0.14),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawOval(rect.deflate(s * 0.04), fillPaint);
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.026
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: isDark ? 0.28 : 0.55),
          stroke.withValues(alpha: faint ? 0.28 : 0.82),
          AppColors.primaryDark.withValues(alpha: isDark ? 0.40 : 0.20),
        ],
      ).createShader(rect);
    canvas.drawOval(rect.deflate(s * 0.06), rimPaint);
  }

  @override
  bool shouldRepaint(covariant _ChemPainter oldDelegate) {
    return oldDelegate.isDark != isDark || oldDelegate.faint != faint;
  }
}

class _FlaskPainter extends _ChemPainter {
  const _FlaskPainter({required super.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    drawGlassDisc(canvas, size);
    final s = size.width;
    final rect = Offset.zero & size;
    final strokePaint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.045
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: isDark ? 0.12 : 0.22),
          fill,
          AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.16),
        ],
      ).createShader(rect)
      ..style = PaintingStyle.fill;
    final liquidPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primaryOnDark.withValues(alpha: isDark ? 0.55 : 0.42),
          AppColors.primary.withValues(alpha: isDark ? 0.72 : 0.50),
          AppColors.primaryDark.withValues(alpha: isDark ? 0.60 : 0.30),
        ],
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    final body = Path()
      ..moveTo(s * 0.42, s * 0.16)
      ..lineTo(s * 0.42, s * 0.36)
      ..lineTo(s * 0.22, s * 0.78)
      ..quadraticBezierTo(s * 0.50, s * 0.92, s * 0.78, s * 0.78)
      ..lineTo(s * 0.58, s * 0.36)
      ..lineTo(s * 0.58, s * 0.16);
    canvas.drawPath(body, fillPaint);
    final liquid = Path()
      ..moveTo(s * 0.31, s * 0.72)
      ..quadraticBezierTo(s * 0.50, s * 0.66, s * 0.70, s * 0.72)
      ..quadraticBezierTo(s * 0.56, s * 0.86, s * 0.30, s * 0.77)
      ..close();
    canvas.drawPath(liquid, liquidPaint);
    canvas.drawPath(body, strokePaint);
    canvas.drawLine(
      Offset(s * 0.36, s * 0.16),
      Offset(s * 0.64, s * 0.16),
      strokePaint,
    );
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.48 : 0.66)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s * 0.025;
    canvas.drawLine(
        Offset(s * 0.49, s * 0.24), Offset(s * 0.49, s * 0.55), shinePaint);
    canvas.drawCircle(Offset(s * 0.42, s * 0.66), s * 0.035, shinePaint);
    canvas.drawCircle(Offset(s * 0.56, s * 0.72), s * 0.026, shinePaint);
  }
}

class _MoleculePainter extends _ChemPainter {
  const _MoleculePainter({required super.isDark, super.faint});

  @override
  void paint(Canvas canvas, Size size) {
    drawGlassDisc(canvas, size);
    final s = size.width;
    final strokePaint = Paint()
      ..color = stroke
      ..strokeWidth = s * 0.035
      ..strokeCap = StrokeCap.round;
    final fillPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        colors: [
          Colors.white.withValues(alpha: isDark ? 0.30 : 0.50),
          fill,
          AppColors.primary.withValues(alpha: faint ? 0.14 : 0.34),
        ],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.fill;
    final points = [
      Offset(s * 0.50, s * 0.28),
      Offset(s * 0.25, s * 0.68),
      Offset(s * 0.72, s * 0.72),
    ];
    canvas.drawLine(points[0], points[1], strokePaint);
    canvas.drawLine(points[0], points[2], strokePaint);
    canvas.drawLine(points[1], points[2], strokePaint);
    for (final point in points) {
      canvas.drawCircle(
        point.translate(s * 0.025, s * 0.03),
        s * 0.12,
        Paint()
          ..color = Colors.black.withValues(alpha: isDark ? 0.22 : 0.08)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawCircle(point, s * 0.12, fillPaint);
      canvas.drawCircle(point, s * 0.12, strokePaint);
      canvas.drawCircle(
        point.translate(-s * 0.035, -s * 0.04),
        s * 0.03,
        Paint()..color = Colors.white.withValues(alpha: isDark ? 0.42 : 0.65),
      );
    }
  }
}

class _HexagonPainter extends _ChemPainter {
  const _HexagonPainter({required super.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    drawGlassDisc(canvas, size);
    final s = size.width;
    final center = Offset(s / 2, s / 2);
    final strokePaint = Paint()
      ..color = stroke.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.035;
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * 3.1415926535 / 180;
      final point = Offset(
        center.dx + s * 0.36 * math.cos(angle),
        center.dy + s * 0.36 * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, strokePaint);
    canvas.drawLine(
        center, Offset(center.dx, center.dy - s * 0.28), strokePaint);
    canvas.drawLine(center, Offset(center.dx + s * 0.24, center.dy + s * 0.14),
        strokePaint);
    canvas.drawLine(center, Offset(center.dx - s * 0.24, center.dy + s * 0.14),
        strokePaint);
  }
}

class _DotGridPainter extends _ChemPainter {
  const _DotGridPainter({required super.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final paint = Paint()
      ..color = stroke.withValues(alpha: 0.48)
      ..style = PaintingStyle.fill;
    for (var row = 0; row < 5; row++) {
      for (var col = 0; col < 5; col++) {
        canvas.drawCircle(
          Offset(s * (0.16 + col * 0.17), s * (0.16 + row * 0.17)),
          s * 0.035,
          paint,
        );
      }
    }
  }
}

class _HeroCopy extends StatelessWidget {
  final bool isDark;

  const _HeroCopy({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.only(
            left: w * 0.05,
            right: w * 0.50,
            bottom: w * 0.02,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'مرحبا بك في منصة',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textMainDark
                        : const Color(0xFF1E135C),
                    fontSize: (w * 0.03).clamp(11.0, 14.0),
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: w * 0.012),
                Text(
                  'أحمد الشيخ',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.primaryOnDark
                        : const Color(0xFF1E135C),
                    fontSize: (w * 0.078).clamp(27.0, 39.0),
                    fontWeight: FontWeight.w900,
                    height: 1.08,
                  ),
                ),
                SizedBox(height: w * 0.018),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: w * 0.022,
                    vertical: w * 0.008,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.primary : AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    'مدرس الكيمياء للمرحلة الثانوية',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: (w * 0.021).clamp(8.5, 11.0),
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                ),
                SizedBox(height: w * 0.014),
                Text(
                  'الكيمياء مش صعبه .. المهم تفهمها صح',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.primaryDark,
                    fontSize: (w * 0.019).clamp(8.0, 10.0),
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
