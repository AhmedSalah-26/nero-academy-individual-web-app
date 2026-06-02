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
                child: isDark
                    ? Image.asset(
                        'assets/footer_dark.png',
                        width: double.infinity,
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            'assets/home_hero_clean.png',
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            alignment: Alignment.centerRight,
                          ),
                          const _HeroCopy(),
                        ],
                      ),
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

class _HeroCopy extends StatelessWidget {
  const _HeroCopy();

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
                    color: const Color(0xFF1E135C),
                    fontSize: (w * 0.03).clamp(11.0, 14.0),
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: w * 0.012),
                Text(
                  'أحمد الشيخ',
                  style: TextStyle(
                    color: const Color(0xFF1E135C),
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
                    color: AppColors.primaryDark,
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
                    color: AppColors.primaryDark,
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
