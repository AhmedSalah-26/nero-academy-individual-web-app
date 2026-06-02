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
    final expandedHeight = (w * 0.56 + 72.0).clamp(265.0, 330.0);

    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor:
          isDark ? AppColors.backgroundDark : const Color(0xFFEEE4FC),
      expandedHeight: expandedHeight,
      toolbarHeight: 58,
      titleSpacing: 0,
      title: HomeAppBar(userName: userName),
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 58),
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
                            'assets/home_hero_generated_reference.png',
                            width: double.infinity,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
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
        preferredSize: Size.fromHeight(44.0 + (w * 0.028) + 4.0),
        child: Container(
          color: Colors.transparent,
          padding: EdgeInsets.only(
            left: w * 0.04,
            right: w * 0.04,
            bottom: w * 0.028,
            top: 4,
          ),
          child: GlassSearchBar(
            hintText:
                '\u0627\u0628\u062d\u062b \u0639\u0646 \u062f\u0631\u0633\u060c \u0627\u0645\u062a\u062d\u0627\u0646\u060c \u0645\u0630\u0643\u0631\u0629 ...',
            onTap: () => context.pushNamed('search'),
            readOnly: true,
            height: 44,
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
            left: w * 0.055,
            right: w * 0.54,
            bottom: w * 0.018,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'مرحباً بك في',
                  style: TextStyle(
                    color: const Color(0xFF1E135C),
                    fontSize: (w * 0.027).clamp(10.0, 13.0),
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: w * 0.006),
                Text(
                  'منصة',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: (w * 0.032).clamp(12.0, 15.0),
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: w * 0.01),
                Text(
                  'أحمد الشيخ',
                  style: TextStyle(
                    color: const Color(0xFF1E135C),
                    fontSize: (w * 0.075).clamp(26.0, 37.0),
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
