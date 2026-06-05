import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/services/app_logger.dart';
import '../../../../../core/shared_widgets/empty_state.dart';
import '../../../../../core/shared_widgets/loading_state.dart';
import '../../../../quizzes/domain/entities/quiz_entity.dart';
import '../../../../quizzes/domain/repositories/quizzes_repository.dart';

/// Quizzes Section Widget - Shows all quizzes for the course
class QuizzesSection extends StatefulWidget {
  final bool isDark;
  final String courseId;
  final QuizzesRepository repository;
  final Function(QuizEntity quiz) onQuizTap;

  const QuizzesSection({
    super.key,
    required this.isDark,
    required this.courseId,
    required this.repository,
    required this.onQuizTap,
  });

  @override
  State<QuizzesSection> createState() => _QuizzesSectionState();
}

class _QuizzesSectionState extends State<QuizzesSection> {
  late Future<List<QuizEntity>> _quizzesFuture;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  void _loadQuizzes() {
    _quizzesFuture = _fetchQuizzes();
  }

  Future<List<QuizEntity>> _fetchQuizzes() async {
    AppLogger.i(
        '📝 [QuizzesSection] Loading quizzes for course: ${widget.courseId}');
    final result =
        await widget.repository.getCourseQuizzes(courseId: widget.courseId);
    return result.fold(
      (failure) {
        AppLogger.e('[QuizzesSection] Failed: ${failure.message}');
        return [];
      },
      (quizzes) {
        AppLogger.success('[QuizzesSection] Loaded ${quizzes.length} quizzes');
        return quizzes;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<QuizEntity>>(
      future: _quizzesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: AppLoadingState.section(),
          );
        }

        final quizzes = snapshot.data ?? [];
        if (quizzes.isEmpty) return _buildEmptyState();

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: quizzes.length,
          itemBuilder: (_, index) => _buildQuizItem(quizzes[index]),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: EmptyState(
        type: EmptyStateType.quizzes,
      ),
    );
  }

  Widget _buildQuizItem(QuizEntity quiz) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onQuizTap(quiz),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildQuizIcon(quiz),
                const SizedBox(width: 12),
                Expanded(child: _buildQuizInfo(quiz)),
                _buildQuizStatus(quiz),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuizIcon(QuizEntity quiz) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.quiz,
        color: AppColors.primary,
        size: 24,
      ),
    );
  }

  Widget _buildQuizInfo(QuizEntity quiz) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          quiz.titleAr,
          style: TextStyle(
            color: widget.isDark ? AppColors.white : AppColors.textMainLight,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.help_outline,
              size: 14,
              color: widget.isDark ? AppColors.grey400 : AppColors.grey600,
            ),
            const SizedBox(width: 4),
            Text(
              '${quiz.totalQuestions} ${'course_player.questions'.tr()}',
              style: TextStyle(
                color: widget.isDark ? AppColors.grey400 : AppColors.grey600,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.timer_outlined,
              size: 14,
              color: widget.isDark ? AppColors.grey400 : AppColors.grey600,
            ),
            const SizedBox(width: 4),
            Text(
              '${quiz.timeLimit ?? 0} ${'course_player.minutes'.tr()}',
              style: TextStyle(
                color: widget.isDark ? AppColors.grey400 : AppColors.grey600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${'course_player.passing_score'.tr()}: ${quiz.passingScore}%',
          style: TextStyle(
            color: widget.isDark ? AppColors.grey400 : AppColors.grey600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildQuizStatus(QuizEntity quiz) {
    // TODO: Check if quiz is completed from attempts
    return Icon(
      Icons.chevron_right,
      color: widget.isDark ? AppColors.grey400 : AppColors.grey600,
    );
  }
}
