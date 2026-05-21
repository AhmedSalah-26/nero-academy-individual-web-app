import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/parent_portal_cubit.dart';
import '../cubit/parent_portal_state.dart';
import '../../domain/entities/parent_dashboard_entity.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

class ParentDashboardScreen extends StatefulWidget {
  final String parentPhone;

  const ParentDashboardScreen({super.key, required this.parentPhone});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  int _selectedStudentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<ParentPortalCubit>()..fetchStudentsByPhone(widget.parentPhone),
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.locale.languageCode == 'ar'
              ? 'نتائج الأبناء'
              : 'Children Results'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.push('/settings'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: BlocBuilder<ParentPortalCubit, ParentPortalState>(
          builder: (context, state) {
            if (state is ParentPortalLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ParentPortalError) {
              return Center(
                  child: Text(state.message,
                      style: const TextStyle(color: Colors.red)));
            } else if (state is ParentPortalLoaded) {
              final students = state.students;
              final isDark = Theme.of(context).brightness == Brightness.dark;

              if (students.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_off,
                          size: 64, color: AppColors.grey500),
                      const SizedBox(height: 16),
                      Text(
                        context.locale.languageCode == 'ar'
                            ? 'لا يوجد أبناء مسجلين بهذا الرقم'
                            : 'No children registered with this number',
                        style:
                            const TextStyle(fontSize: 18, color: AppColors.grey600),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  // Student Selector
                  if (students.length > 1) ...[
                    Container(
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                      ),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final st = students[index];
                          final isSelected = _selectedStudentIndex == index;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedStudentIndex = index;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark
                                        ? AppColors.cardDark
                                        : Colors.white),
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDark
                                          ? AppColors.borderDark
                                          : AppColors.borderLight),
                                  width: 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: isSelected
                                        ? Colors.white.withValues(alpha: 0.2)
                                        : AppColors.primary
                                            .withValues(alpha: 0.1),
                                    backgroundImage: st.avatarUrl != null
                                        ? NetworkImage(st.avatarUrl!)
                                        : null,
                                    child: st.avatarUrl == null
                                        ? Icon(Icons.person,
                                            size: 16,
                                            color: isSelected
                                                ? Colors.white
                                                : AppColors.primary)
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    st.name.split(' ').take(2).join(' '),
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark
                                              ? AppColors.white
                                              : AppColors.textMainLight),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  // Selected Student Data
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _StudentCard(
                          student: students[_selectedStudentIndex.clamp(
                              0, students.length - 1)],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final StudentDashboardData student;

  const _StudentCard({required this.student});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = context.locale.languageCode == 'ar';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: isDark ? 0.3 : 0.15),
                  AppColors.primary.withValues(alpha: isDark ? 0.05 : 0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.5),
                        width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: student.avatarUrl != null
                        ? NetworkImage(student.avatarUrl!)
                        : null,
                    child: student.avatarUrl == null
                        ? const Icon(Icons.person,
                            size: 30, color: AppColors.primary)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isArabic ? 'طالب' : 'Student',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.menu_book_rounded,
                        color: AppColors.primary, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      isArabic ? 'الدورات المسجلة' : 'Enrolled Courses',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (student.courses.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          isDark ? AppColors.backgroundDark : AppColors.grey50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isArabic
                          ? 'لم يسجل الطالب في أي دورات بعد'
                          : 'Student is not enrolled in any courses yet',
                      style: TextStyle(
                          color:
                              isDark ? AppColors.grey400 : AppColors.grey600),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ...student.courses.map((c) => _CourseProgressItem(course: c)),
                const SizedBox(height: 32),
                Row(
                  children: [
                    const Icon(Icons.quiz_rounded,
                        color: AppColors.primary, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      isArabic ? 'نتائج الاختبارات' : 'Quizzes Results',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (student.quizzes.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          isDark ? AppColors.backgroundDark : AppColors.grey50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isArabic
                          ? 'لم يخض أي اختبارات بعد'
                          : 'No quizzes taken yet',
                      style: TextStyle(
                          color:
                              isDark ? AppColors.grey400 : AppColors.grey600),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ...student.quizzes.map((q) => _QuizItem(quiz: q)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseProgressItem extends StatelessWidget {
  final StudentCourseData course;

  const _CourseProgressItem({required this.course});

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final title = isArabic ? course.titleAr : course.titleEn;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${course.progress}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (course.instructorName != null || course.enrolledAt != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (course.instructorName != null) ...[
                  const Icon(Icons.person_outline,
                      size: 14, color: AppColors.grey500),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      course.instructorName!,
                      style: const TextStyle(fontSize: 12, color: AppColors.grey600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                if (course.enrolledAt != null) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.calendar_today_outlined,
                      size: 14, color: AppColors.grey500),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat.yMMMd(context.locale.languageCode)
                        .format(course.enrolledAt!),
                    style: const TextStyle(fontSize: 12, color: AppColors.grey600),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: course.progress / 100,
            backgroundColor: AppColors.grey200,
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(4),
            minHeight: 6,
          ),
        ],
      ),
    );
  }
}

class _QuizItem extends StatelessWidget {
  final StudentQuizData quiz;

  const _QuizItem({required this.quiz});

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final courseTitle = isArabic ? quiz.courseTitleAr : quiz.courseTitleEn;
    final quizTitle = isArabic ? quiz.quizTitleAr : quiz.quizTitleEn;

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: quiz.isPassed
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: quiz.isPassed
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quizTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  courseTitle,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${quiz.score} / ${quiz.totalScore}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: quiz.isPassed ? Colors.green[700] : Colors.red[700],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(top: 4, bottom: 4),
                decoration: BoxDecoration(
                  color: quiz.isPassed ? Colors.green[700] : Colors.red[700],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  quiz.isPassed
                      ? (isArabic ? 'ناجح' : 'Passed')
                      : (isArabic ? 'راسب' : 'Failed'),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (quiz.completedAt != null)
                Text(
                  DateFormat.yMMMd(context.locale.languageCode)
                      .format(quiz.completedAt!),
                  style: TextStyle(
                    fontSize: 10,
                    color: quiz.isPassed ? Colors.green[700] : Colors.red[700],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
