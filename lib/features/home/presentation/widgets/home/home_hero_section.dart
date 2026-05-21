// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/routing/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../../cart/presentation/cubit/cart_state.dart';
import '../../../../notifications/presentation/cubit/notifications_cubit.dart';
import '../../../../notifications/presentation/cubit/notifications_state.dart';
import 'home_app_bar.dart';

/// Hero Section — matches the reference design
/// Layout:
///   ┌─────────────────────────────────────────┐
///   │  [bell] [cal] [bookmark] [chat]  [≡]    │  ← icons row
///   │                           [teacher img] │
///   │  مرحباً بك في منصة                       │
///   │  أ. مصطفى زغلول (bold large)             │
///   │  مدرس الكيمياء (purple)                  │
///   │  الكيمياء مش صعبة ..                     │
///   │  المهم تفهمها صح! (purple underline)     │
///   │ ┌────────────── search ──────────────┐  │
///   │ │  🔍  ابحث عن درس، امتحان، مذكرة … │  │
///   │ └────────────────────────────────────┘  │
///   └─────────────────────────────────────────┘
class HomeSliverAppBar extends StatelessWidget {
  final String? userName;

  const HomeSliverAppBar({super.key, this.userName});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    
    // Estimate expanded height based on image aspect ratio and AppBar
    // HomeAppBar ~ 80px + Image (4:3 aspect ratio = w * 0.75)
    final expandedHeight = w * 0.75 + 80.0;

    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFFEEE4FC),
      expandedHeight: expandedHeight,
      toolbarHeight: 70, // Height for HomeAppBar
      titleSpacing: 0,
      title: HomeAppBar(userName: userName),
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero content + teacher image (pushed down by the title automatically, but since it's background it might underlap. 
              // We'll add a SizedBox to prevent the image from going under the AppBar)
              const SizedBox(height: 70),
              Expanded(
                child: Image.asset(
                    'assets/footer2.png',
                    width: double.infinity,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
              ],
            ),
          ),
        ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(50.0 + (w * 0.04) + 6.0),
        child: Container(
          // Transparent to show the image behind it!
          color: Colors.transparent,
          padding: EdgeInsets.only(
            left: w * 0.04,
            right: w * 0.04,
            bottom: w * 0.04,
            top: 6,
          ),
          child: GestureDetector(
            onTap: () => context.pushNamed('search'),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.04),
                    child: Icon(Icons.search_rounded,
                        color: const Color(0xFF5D5FEF), size: w * 0.055),
                  ),
                  Text(
                    'ابحث عن درس، امتحان، مذكرة ...',
                    style: TextStyle(
                      color: Colors.black38,
                      fontSize: w * 0.036,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Quick Icon Button with label underneath
// ─────────────────────────────────────────────────
class _QuickIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? badge;

  const _QuickIcon({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: EdgeInsets.all(w * 0.025),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                    )
                  ],
                ),
                child: Icon(icon, size: w * 0.055, color: Colors.black87),
              ),
              if (badge != null)
                Positioned(top: -2, right: -2, child: badge!),
            ],
          ),
          SizedBox(height: w * 0.01),
          Text(
            label,
            style: TextStyle(
              fontSize: w * 0.024,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();
  @override
  Widget build(BuildContext context) => Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
            color: Colors.red, shape: BoxShape.circle),
      );
}

class _CountDot extends StatelessWidget {
  final int count;
  const _CountDot({required this.count});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
            color: Colors.red, shape: BoxShape.circle),
        child: Text(
          '$count',
          style: const TextStyle(color: Colors.white, fontSize: 8),
        ),
      );
}
