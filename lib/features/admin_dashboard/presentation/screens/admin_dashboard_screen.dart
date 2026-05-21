import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/shared_widgets/dashboard/dashboard_widgets.dart';
import '../cubit/admin_dashboard_cubit.dart';
import '../widgets/admin_home/admin_home_content.dart';
import '../widgets/admin_users/admin_users_content.dart';
import '../widgets/admin_courses/admin_courses_content.dart';
import '../widgets/admin_categories/admin_categories_content.dart';
import '../widgets/admin_levels/admin_levels_content.dart';
import '../widgets/admin_enrollments/admin_enrollments_content.dart';
import '../widgets/admin_banners/admin_banners_content.dart';
import '../widgets/admin_coupons/admin_global_coupons_content.dart';
import '../widgets/admin_coupons/admin_instructor_coupons_content.dart';
import '../widgets/admin_payouts/admin_payouts_content.dart';
import '../widgets/admin_reports/admin_course_reports_content.dart';
import '../widgets/admin_reports/admin_review_reports_content.dart';
import '../widgets/admin_analytics/admin_analytics_content.dart';
import '../widgets/admin_settings/admin_settings_content.dart';
import '../widgets/admin_reviews/admin_reviews_content.dart';
import '../widgets/admin_qa/admin_qa_content.dart';
import '../widgets/admin_forum/admin_forum_content.dart';
import '../widgets/admin_commissions/admin_commission_content.dart';
import '../widgets/admin_instructor_requests/admin_instructor_requests_content.dart';

/// Admin Dashboard Screen
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  // Navigation items for admin dashboard
  static const List<DashboardNavItem> _navItems = [
    DashboardNavItem(
      label: 'Dashboard',
      labelAr: 'الرئيسية',
      icon: Icons.dashboard_rounded,
    ),
    DashboardNavItem(
      label: 'Users',
      labelAr: 'المستخدمين',
      icon: Icons.people_rounded,
    ),
    DashboardNavItem(
      label: 'Courses',
      labelAr: 'الكورسات',
      icon: Icons.school_rounded,
    ),
    DashboardNavItem(
      label: 'Categories',
      labelAr: 'التصنيفات',
      icon: Icons.category_rounded,
    ),
    DashboardNavItem(
      label: 'Levels',
      labelAr: 'المستويات',
      icon: Icons.layers_rounded,
    ),
    DashboardNavItem(
      label: 'Enrollments',
      labelAr: 'التسجيلات',
      icon: Icons.assignment_ind_rounded,
    ),
    DashboardNavItem(
      label: 'Banners',
      labelAr: 'البانرات',
      icon: Icons.image_rounded,
    ),
    DashboardNavItem(
      label: 'Global Coupons',
      labelAr: 'الكوبونات العامة',
      icon: Icons.local_offer_rounded,
    ),
    DashboardNavItem(
      label: 'Instructor Coupons',
      labelAr: 'كوبونات المدرسين',
      icon: Icons.confirmation_number_rounded,
    ),
    DashboardNavItem(
      label: 'Payouts',
      labelAr: 'المدفوعات',
      icon: Icons.payments_rounded,
    ),
    DashboardNavItem(
      label: 'Commissions',
      labelAr: 'العمولات',
      icon: Icons.percent_rounded,
    ),
    DashboardNavItem(
      label: 'Course Reports',
      labelAr: 'بلاغات الكورسات',
      icon: Icons.report_rounded,
    ),
    DashboardNavItem(
      label: 'Review Reports',
      labelAr: 'بلاغات التقييمات',
      icon: Icons.rate_review_rounded,
    ),
    DashboardNavItem(
      label: 'Reviews',
      labelAr: 'التقييمات',
      icon: Icons.star_rounded,
    ),
    DashboardNavItem(
      label: 'Q&A',
      labelAr: 'الأسئلة',
      icon: Icons.question_answer_rounded,
    ),
    DashboardNavItem(
      label: 'Forums',
      labelAr: 'المنتديات',
      icon: Icons.forum_rounded,
    ),
    DashboardNavItem(
      label: 'Analytics',
      labelAr: 'التحليلات',
      icon: Icons.analytics_rounded,
    ),
    DashboardNavItem(
      label: 'Settings',
      labelAr: 'الإعدادات',
      icon: Icons.settings_rounded,
    ),
    DashboardNavItem(
      label: 'Instructor Requests',
      labelAr:
          '\u0637\u0644\u0628\u0627\u062a \u0627\u0644\u0645\u062f\u0631\u0633\u064a\u0646',
      icon: Icons.assignment_turned_in_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Load dashboard data
    context.read<AdminDashboardCubit>().loadAll();
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return AdminHomeContent(
          onNavigate: (index) => setState(() => _selectedIndex = index),
        );
      case 1:
        return const AdminUsersContent();
      case 2:
        return const AdminCoursesContent();
      case 3:
        return const AdminCategoriesContent();
      case 4:
        return const AdminLevelsContent();
      case 5:
        return const AdminEnrollmentsContent();
      case 6:
        return const AdminBannersContent();
      case 7:
        return const AdminGlobalCouponsContent();
      case 8:
        return const AdminInstructorCouponsContent();
      case 9:
        return const AdminPayoutsContent();
      case 10:
        return const AdminCommissionContent();
      case 11:
        return const AdminCourseReportsContent();
      case 12:
        return const AdminReviewReportsContent();
      case 13:
        return const AdminReviewsContent();
      case 14:
        return const AdminQAContent();
      case 15:
        return const AdminForumContent();
      case 16:
        return const AdminAnalyticsContent();
      case 17:
        return const AdminSettingsContent();
      case 18:
        return const AdminInstructorRequestsContent();
      default:
        return const AdminHomeContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      title: 'Admin Dashboard',
      titleAr: 'لوحة تحكم الأدمن',
      navItems: _navItems,
      selectedIndex: _selectedIndex,
      onNavItemSelected: (index) {
        setState(() => _selectedIndex = index);
      },
      content: _buildContent(),
    );
  }
}
