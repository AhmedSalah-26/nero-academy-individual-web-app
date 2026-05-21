// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/shared_widgets/responsive_dialog.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/course_editor_cubit.dart';
import '../widgets/course_editor/attachments_step.dart';
import '../widgets/course_editor/basic_info_step.dart';
import '../widgets/course_editor/curriculum_step.dart';
import '../widgets/course_editor/pricing_step.dart';
import '../widgets/course_editor/settings_step.dart';
import 'course_edit_step_screen.dart';

/// Course Editor Screen
class CourseEditorScreen extends StatefulWidget {
  final String? courseId;

  const CourseEditorScreen({super.key, this.courseId});

  @override
  State<CourseEditorScreen> createState() => _CourseEditorScreenState();
}

class _CourseEditorScreenState extends State<CourseEditorScreen> {
  @override
  void initState() {
    super.initState();
    AppLogger.i(
        '📝 [CourseEditorScreen] initState - courseId: ${widget.courseId}');
    final cubit = context.read<CourseEditorCubit>();
    if (widget.courseId != null) {
      AppLogger.i('📝 [CourseEditorScreen] Editing existing course');
      cubit.initEditCourse(widget.courseId!);
    } else {
      AppLogger.i('📝 [CourseEditorScreen] Creating new course');
      cubit.initNewCourse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<CourseEditorCubit, CourseEditorState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.courseId != null
                  ? (isArabic ? 'تعديل الكورس' : 'Edit Course')
                  : (isArabic ? 'كورس جديد' : 'New Course'),
              style: const TextStyle(fontSize: 16),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (MediaQuery.of(context).size.width > 600) ...[
                TextButton(
                  onPressed: state.isLoading
                      ? null
                      : () => _saveDraft(context, isArabic),
                  child: Text(isArabic ? 'حفظ مسودة' : 'Save Draft'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: state.canPublish && !state.isLoading
                      ? () => _publish(context, isArabic)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isArabic ? 'نشر' : 'Publish'),
                ),
                const SizedBox(width: 16),
              ] else
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'draft') {
                      _saveDraft(context, isArabic);
                    } else if (value == 'publish') {
                      _publish(context, isArabic);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'draft',
                      enabled: !state.isLoading,
                      child: Row(
                        children: [
                          const Icon(Icons.save_outlined, size: 20),
                          const SizedBox(width: 12),
                          Text(isArabic ? 'حفظ مسودة' : 'Save Draft'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'publish',
                      enabled: state.canPublish && !state.isLoading,
                      child: Row(
                        children: [
                          const Icon(Icons.publish, size: 20),
                          const SizedBox(width: 12),
                          Text(isArabic ? 'نشر' : 'Publish'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: state.isLoading && state.currentStep == 0
              ? const Center(child: CircularProgressIndicator())
              : widget.courseId != null
                  ? _buildEditMenu(context, state, isArabic, isDark)
                  : Column(
                      children: [
                        _buildStepper(context, state, isArabic, isDark),
                        Expanded(
                          child: _buildStepContent(context, state, isArabic),
                        ),
                      ],
                    ),
        );
      },
    );
  }

  Widget _buildStepper(BuildContext context, CourseEditorState state,
      bool isArabic, bool isDark) {
    final steps = [
      isArabic ? 'المعلومات الأساسية' : 'Basic Info',
      isArabic ? 'المحتوى' : 'Curriculum',
      isArabic ? 'التسعير' : 'Pricing',
      isArabic ? 'الإعدادات' : 'Settings',
      isArabic ? 'المرفقات' : 'Attachments',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.grey50,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(steps.length, (index) {
            final isActive = index == state.currentStep;
            final isCompleted = index < state.currentStep;

            return GestureDetector(
              onTap: () => context.read<CourseEditorCubit>().setStep(index),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? AppColors.primary
                          : isCompleted
                              ? AppColors.success
                              : (isDark
                                  ? AppColors.cardDark
                                  : AppColors.grey200),
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check,
                              size: 18, color: Colors.white)
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isActive
                                    ? Colors.white
                                    : (isDark
                                        ? AppColors.textMutedDark
                                        : AppColors.textMutedLight),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    steps[index],
                    style: TextStyle(
                      color: isActive
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight),
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                  if (index < steps.length - 1) ...[
                    const SizedBox(width: 12),
                    Container(
                      width: 30,
                      height: 2,
                      color: isCompleted
                          ? AppColors.success
                          : (isDark ? AppColors.borderDark : AppColors.grey300),
                    ),
                    const SizedBox(width: 12),
                  ],
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildStepContent(
      BuildContext context, CourseEditorState state, bool isArabic) {
    switch (state.currentStep) {
      case 0:
        return const BasicInfoStep();
      case 1:
        return const CurriculumStep();
      case 2:
        return const PricingStep();
      case 3:
        return const SettingsStep();
      case 4:
        return const AttachmentsStep();
      default:
        return const BasicInfoStep();
    }
  }

  Widget _buildEditMenu(BuildContext context, CourseEditorState state,
      bool isArabic, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Row(
              children: [
                if (state.thumbnailUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      state.thumbnailUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(isDark),
                    ),
                  )
                else
                  _buildPlaceholder(isDark),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic ? state.titleAr : state.titleEn,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: state.isOriginalPublished
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          state.isOriginalPublished
                              ? (isArabic ? 'منشور' : 'Published')
                              : (isArabic ? 'مسودة' : 'Draft'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: state.isOriginalPublished
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            isArabic ? 'تعديل أجزاء الكورس' : 'Edit Course Parts',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildEditCard(
                    context: context,
                    title: isArabic ? 'المعلومات الأساسية' : 'Basic Info',
                    icon: Icons.info_outline,
                    stepIndex: 0,
                    isArabic: isArabic,
                    isDark: isDark,
                    width: _getCardWidth(constraints.maxWidth),
                  ),
                  _buildEditCard(
                    context: context,
                    title:
                        isArabic ? 'المحتوى والدروس' : 'Curriculum & Lessons',
                    icon: Icons.play_lesson_outlined,
                    stepIndex: 1,
                    isArabic: isArabic,
                    isDark: isDark,
                    width: _getCardWidth(constraints.maxWidth),
                  ),
                  _buildEditCard(
                    context: context,
                    title: isArabic ? 'التسعير' : 'Pricing',
                    icon: Icons.attach_money,
                    stepIndex: 2,
                    isArabic: isArabic,
                    isDark: isDark,
                    width: _getCardWidth(constraints.maxWidth),
                  ),
                  _buildEditCard(
                    context: context,
                    title: isArabic ? 'إعدادات النشر' : 'Publish Settings',
                    icon: Icons.settings_outlined,
                    stepIndex: 3,
                    isArabic: isArabic,
                    isDark: isDark,
                    width: _getCardWidth(constraints.maxWidth),
                  ),
                  _buildEditCard(
                    context: context,
                    title: isArabic ? 'المرفقات' : 'Attachments',
                    icon: Icons.attach_file,
                    stepIndex: 4,
                    isArabic: isArabic,
                    isDark: isDark,
                    width: _getCardWidth(constraints.maxWidth),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  double _getCardWidth(double parentWidth) {
    if (parentWidth < 400) return parentWidth;
    if (parentWidth < 800) return (parentWidth - 16) / 2;
    return (parentWidth - 32) / 3;
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: isDark ? AppColors.borderDark : AppColors.grey200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.image_outlined,
        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
      ),
    );
  }

  Widget _buildEditCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required int stepIndex,
    required bool isArabic,
    required bool isDark,
    required double width,
  }) {
    return InkWell(
      onTap: () {
        // We reuse the same cubit instance since both screens exist within the cubit wrapper
        // Wait, CourseEditorScreen wraps itself in BlocProvider? Let's check app_router for that.
        // Or if it's already in the widget tree.
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<CourseEditorCubit>(),
              child: CourseEditStepScreen(stepIndex: stepIndex),
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveDraft(BuildContext context, bool isArabic) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      barrierDismissible: false,
      builder: (ctx) => ResponsiveDialog(
        maxWidth: 300,
        content: Row(
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(width: 20),
            Expanded(child: Text(isArabic ? 'جاري الحفظ...' : 'Saving...')),
          ],
        ),
      ),
    );

    final success = await context.read<CourseEditorCubit>().saveDraft();

    if (mounted) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? (isArabic ? 'تم حفظ المسودة' : 'Draft saved')
              : (isArabic ? 'فشل في الحفظ' : 'Failed to save')),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  Future<void> _publish(BuildContext context, bool isArabic) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => ResponsiveAlertDialog(
        title: isArabic ? 'نشر الكورس' : 'Publish Course',
        content: isArabic
            ? 'هل أنت متأكد من نشر هذا الكورس؟'
            : 'Are you sure you want to publish this course?',
        confirmText: isArabic ? 'نشر' : 'Publish',
        cancelText: isArabic ? 'إلغاء' : 'Cancel',
        confirmColor: AppColors.success,
        onConfirm: () => Navigator.pop(ctx, true),
        onCancel: () => Navigator.pop(ctx, false),
      ),
    );

    if (confirmed == true && mounted) {
      // Show loading dialog
      showDialog(
        context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
        barrierDismissible: false,
        builder: (ctx) => ResponsiveDialog(
          maxWidth: 350,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 20),
              Text(
                isArabic ? 'جاري نشر الكورس...' : 'Publishing course...',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isArabic ? 'يرجى الانتظار' : 'Please wait',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

      final success = await context.read<CourseEditorCubit>().publishCourse();

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        if (success) {
          // Show success dialog
          await showDialog(
            context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
            builder: (ctx) => ResponsiveDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isArabic ? 'تم النشر بنجاح!' : 'Published Successfully!',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isArabic
                        ? 'تم نشر الكورس وأصبح متاحاً للطلاب الآن'
                        : 'Your course is now live and available to students',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isArabic ? 'حسناً' : 'OK'),
                ),
              ],
            ),
          );
          if (mounted) {
            context.pop();
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isArabic ? 'فشل في النشر' : 'Failed to publish'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}
