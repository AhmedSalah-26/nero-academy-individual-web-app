import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/shared_widgets/error_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/app_logger.dart';
import '../../domain/entities/portfolio_item_entity.dart';
import '../cubit/portfolio_cubit.dart';
import '../cubit/portfolio_state.dart';
import '../widgets/portfolio/portfolio_app_bar.dart';
import '../widgets/portfolio/portfolio_stats_header.dart';
import '../widgets/portfolio/portfolio_tab_bar.dart';
import '../widgets/portfolio/portfolio_courses_tab.dart';
import '../widgets/portfolio/portfolio_achievements_tab.dart';

/// Portfolio Screen
class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  @override
  void initState() {
    super.initState();
    _loadPortfolio();
  }

  void _loadPortfolio() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    AppLogger.i('📊 [PortfolioScreen] Loading portfolio for user: $userId');

    if (userId != null) {
      context.read<PortfolioCubit>().loadPortfolio(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: BlocBuilder<PortfolioCubit, PortfolioState>(
        builder: (context, state) {
          return Column(
            children: [
              PortfolioAppBar(
                isDark: isDark,
                onShare: state.hasData ? () => _sharePortfolio() : null,
              ),
              Expanded(
                child: state.isLoading
                    ? _buildLoading(isDark)
                    : state.isError
                        ? _buildError(state, isDark)
                        : _buildContent(state, isDark),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoading(bool isDark) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }

  Widget _buildError(PortfolioState state, bool isDark) {
    return ErrorState(
      type: ErrorType.generic,
      message: state.errorMessage ?? 'errors.unknown'.tr(),
      onRetry: _loadPortfolio,
    );
  }

  Widget _buildContent(PortfolioState state, bool isDark) {
    return Column(
      children: [
        PortfolioStatsHeader(stats: state.stats, isDark: isDark),
        const SizedBox(height: 8),
        PortfolioTabBar(
          selectedIndex: state.selectedTabIndex,
          onTabChanged: _onTabChanged,
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _buildTabContent(state, isDark),
        ),
      ],
    );
  }

  Widget _buildTabContent(PortfolioState state, bool isDark) {
    switch (state.selectedTabIndex) {
      case 0:
        return PortfolioCoursesTab(
          courses: state.completedCourses,
          onTap: _goToCourse,
          onBrowseCourses: _browseCourses,
          isDark: isDark,
        );
      case 1:
        return PortfolioAchievementsTab(
          achievements: state.achievements,
          isDark: isDark,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _onTabChanged(int index) {
    HapticFeedback.lightImpact();
    context.read<PortfolioCubit>().changeTab(index);
  }

  void _goToCourse(PortfolioItemEntity course) {
    HapticFeedback.lightImpact();
    AppLogger.i('[PortfolioScreen] Go to course: ${course.courseId}');
    AppRouter.goToCourseDetails(context, course.courseId);
  }

  void _browseCourses() {
    AppRouter.goToHome(context);
  }

  void _sharePortfolio() {
    HapticFeedback.mediumImpact();
    final state = context.read<PortfolioCubit>().state;
    final shareText =
        'Check out my learning portfolio! I\'ve completed ${state.stats.completedCourses} courses.';
    Share.share(shareText);
  }
}
