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
    final expandedHeight = w * 0.75 + 80.0;

    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor:
          isDark ? AppColors.backgroundDark : const Color(0xFFEEE4FC),
      expandedHeight: expandedHeight,
      toolbarHeight: 70,
      titleSpacing: 0,
      title: HomeAppBar(userName: userName),
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 70),
              Expanded(
                child: Image.asset(
                  isDark ? 'assets/footer_dark.png' : 'assets/footer2.png',
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
          color: Colors.transparent,
          padding: EdgeInsets.only(
            left: w * 0.04,
            right: w * 0.04,
            bottom: w * 0.04,
            top: 6,
          ),
          child: GlassSearchBar(
            hintText:
                '\u0627\u0628\u062d\u062b \u0639\u0646 \u062f\u0631\u0633\u060c \u0627\u0645\u062a\u062d\u0627\u0646\u060c \u0645\u0630\u0643\u0631\u0629 ...',
            onTap: () => context.pushNamed('search'),
            readOnly: true,
            height: 50,
            borderRadius: 14,
            iconSize: w * 0.055,
            hintStyle: TextStyle(fontSize: w * 0.036),
          ),
        ),
      ),
    );
  }
}
