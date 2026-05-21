import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/shared_widgets/loading_skeleton.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../data/models/instructor_commission_model.dart';
import '../../cubit/admin_commission_cubit.dart';

/// Admin Commission Content — manages instructor commission rates
class AdminCommissionContent extends StatefulWidget {
  const AdminCommissionContent({super.key});

  @override
  State<AdminCommissionContent> createState() => _AdminCommissionContentState();
}

class _AdminCommissionContentState extends State<AdminCommissionContent> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AdminCommissionCubit>().loadCommissions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return BlocConsumer<AdminCommissionCubit, AdminCommissionState>(
      listener: (context, state) {
        if (state.actionStatus == AdminCommissionStatus.success &&
            state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        if (state.actionStatus == AdminCommissionStatus.error &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        return Column(
          children: [
            // Summary card
            _buildSummaryCard(state, isDark, isArabic),
            const SizedBox(height: 16),
            // Search bar
            _buildSearchBar(isDark, isArabic),
            const SizedBox(height: 16),
            // Instructor list
            Expanded(
              child: _buildBody(state, isDark, isArabic),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(
      AdminCommissionState state, bool isDark, bool isArabic) {
    final avgCommission = state.instructors.isEmpty
        ? 30.0
        : state.instructors
                .map((e) => e.commissionRate)
                .reduce((a, b) => a + b) /
            state.instructors.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              isArabic ? 'العمولة المتوسطة' : 'Avg Commission',
              '${avgCommission.toStringAsFixed(1)}%',
              Icons.percent_rounded,
            ),
          ),
          Container(
            width: 1,
            height: 48,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _buildStatItem(
              isArabic ? 'عدد المدرسين' : 'Instructors',
              '${state.instructors.length}',
              Icons.people_rounded,
            ),
          ),
          Container(
            width: 1,
            height: 48,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _buildStatItem(
              isArabic ? 'نسبة المنصة' : 'Platform %',
              '${avgCommission.toStringAsFixed(0)}%',
              Icons.business_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 22),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSearchBar(bool isDark, bool isArabic) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) =>
            context.read<AdminCommissionCubit>().filterInstructors(value),
        decoration: InputDecoration(
          hintText: isArabic ? 'بحث عن مدرس...' : 'Search instructor...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<AdminCommissionCubit>().filterInstructors('');
                  },
                )
              : null,
          filled: true,
          fillColor: isDark ? AppColors.cardDark : AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AdminCommissionState state, bool isDark, bool isArabic) {
    if (state.status == AdminCommissionStatus.loading) {
      return _buildLoadingSkeleton(isDark);
    }

    if (state.status == AdminCommissionStatus.error) {
      return _buildErrorState(state, isDark, isArabic);
    }

    final items = context.read<AdminCommissionCubit>().filteredInstructors;

    if (items.isEmpty) {
      return _buildEmptyState(isDark, isArabic);
    }

    return RefreshIndicator(
      onRefresh: () => context.read<AdminCommissionCubit>().loadCommissions(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (context, index) => _buildInstructorCard(
          items[index],
          isDark,
          isArabic,
        ),
      ),
    );
  }

  Widget _buildInstructorCard(
    InstructorCommissionModel instructor,
    bool isDark,
    bool isArabic,
  ) {
    final commissionColor = instructor.commissionRate >= 40
        ? AppColors.error
        : instructor.commissionRate >= 20
            ? AppColors.warning
            : AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showCommissionDialog(instructor, isDark, isArabic),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: instructor.avatarUrl != null
                      ? NetworkImage(instructor.avatarUrl!)
                      : null,
                  child: instructor.avatarUrl == null
                      ? Text(
                          (instructor.name ?? '?')[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              instructor.displayName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.textMainDark
                                    : AppColors.textMainLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (instructor.isVerified)
                            const Padding(
                              padding: EdgeInsetsDirectional.only(start: 4),
                              child: Icon(
                                Icons.verified_rounded,
                                size: 16,
                                color: AppColors.info,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        instructor.email ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildTag(
                            '${instructor.totalCourses} ${isArabic ? 'كورس' : 'courses'}',
                            Icons.school_rounded,
                            isDark,
                          ),
                          const SizedBox(width: 8),
                          _buildTag(
                            '${instructor.totalStudents} ${isArabic ? 'طالب' : 'students'}',
                            Icons.people_rounded,
                            isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Commission badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: commissionColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: commissionColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        instructor.formattedCommission,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: commissionColor,
                        ),
                      ),
                      Text(
                        isArabic ? 'عمولة' : 'Commission',
                        style: TextStyle(
                          fontSize: 9,
                          color: commissionColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.grey100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }

  void _showCommissionDialog(
    InstructorCommissionModel instructor,
    bool isDark,
    bool isArabic,
  ) {
    HapticFeedback.lightImpact();
    double currentCommission = instructor.commissionRate;
    final controller = TextEditingController(
      text: currentCommission.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: instructor.avatarUrl != null
                    ? NetworkImage(instructor.avatarUrl!)
                    : null,
                child: instructor.avatarUrl == null
                    ? Text(
                        (instructor.name ?? '?')[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                instructor.displayName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                isArabic ? 'تعديل العمولة' : 'Edit Commission',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Slider
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: AppColors.primary.withValues(alpha: 0.2),
                  thumbColor: AppColors.primary,
                  overlayColor: AppColors.primary.withValues(alpha: 0.1),
                  valueIndicatorColor: AppColors.primary,
                  valueIndicatorTextStyle: const TextStyle(color: Colors.white),
                ),
                child: Slider(
                  value: currentCommission,
                  min: 0,
                  max: 100,
                  divisions: 100,
                  label: '${currentCommission.toStringAsFixed(0)}%',
                  onChanged: (value) {
                    setDialogState(() {
                      currentCommission = value;
                      controller.text = value.toStringAsFixed(0);
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),
              // Manual input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      onChanged: (value) {
                        final v = double.tryParse(value);
                        if (v != null && v >= 0 && v <= 100) {
                          setDialogState(() => currentCommission = v);
                        }
                      },
                      decoration: InputDecoration(
                        suffixText: '%',
                        labelText: isArabic ? 'نسبة العمولة' : 'Commission %',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Preview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : AppColors.grey50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildPreviewRow(
                      isArabic ? 'عمولة المنصة' : 'Platform Commission',
                      '${currentCommission.toStringAsFixed(0)}%',
                      AppColors.error,
                      isDark,
                    ),
                    const SizedBox(height: 8),
                    _buildPreviewRow(
                      isArabic ? 'نصيب المدرس' : 'Instructor Share',
                      '${(100 - currentCommission).toStringAsFixed(0)}%',
                      AppColors.success,
                      isDark,
                    ),
                    const Divider(height: 16),
                    _buildPreviewRow(
                      isArabic
                          ? 'مثال: كورس 100 ج.م'
                          : 'Example: 100 EGP course',
                      '',
                      isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                      isDark,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildPreviewChip(
                          isArabic ? 'المنصة' : 'Platform',
                          '${currentCommission.toStringAsFixed(0)} ${isArabic ? 'ج.م' : 'EGP'}',
                          AppColors.error,
                          isDark,
                        ),
                        _buildPreviewChip(
                          isArabic ? 'المدرس' : 'Instructor',
                          '${(100 - currentCommission).toStringAsFixed(0)} ${isArabic ? 'ج.م' : 'EGP'}',
                          AppColors.success,
                          isDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(isArabic ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                this.context.read<AdminCommissionCubit>().setCommission(
                      instructor.instructorId,
                      currentCommission,
                    );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(isArabic ? 'حفظ' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewRow(
      String label, String value, Color color, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
        if (value.isNotEmpty)
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
      ],
    );
  }

  Widget _buildPreviewChip(
      String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 5,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: LoadingSkeleton(
          height: 90,
          width: double.infinity,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildErrorState(
      AdminCommissionState state, bool isDark, bool isArabic) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: AppColors.error.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            isArabic ? 'حدث خطأ' : 'Something went wrong',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.errorMessage ?? '',
            style: TextStyle(
              fontSize: 13,
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () =>
                context.read<AdminCommissionCubit>().loadCommissions(),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, bool isArabic) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 64,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
          const SizedBox(height: 16),
          Text(
            isArabic ? 'لا يوجد مدرسين' : 'No instructors found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
        ],
      ),
    );
  }
}
