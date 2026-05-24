import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/app_logger.dart';
import '../../domain/entities/banner_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/course_entity.dart';
import '../../domain/usecases/get_banners_usecase.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/get_home_courses_usecase.dart';
import 'home_state.dart';

/// Home Cubit - Manages Home Screen State
class HomeCubit extends Cubit<HomeState> {
  final GetBannersUseCase getBannersUseCase;
  final GetCategoriesUseCase getCategoriesUseCase;
  final GetHomeCoursesUseCase getHomeCoursesUseCase;

  HomeCubit({
    required this.getBannersUseCase,
    required this.getCategoriesUseCase,
    required this.getHomeCoursesUseCase,
  }) : super(const HomeState());

  /// Load all home data
  Future<void> loadHomeData() async {
    emit(state.copyWith(status: HomeStatus.loading));

    final bannersFuture = getBannersUseCase();
    final categoriesFuture = getCategoriesUseCase();
    final homeCoursesFuture = getHomeCoursesUseCase(
      const GetHomeCoursesParams(limit: 10),
    );

    final bannersResult = await bannersFuture;
    final categoriesResult = await categoriesFuture;
    final homeCoursesResult = await homeCoursesFuture;

    // Check for any errors
    String? errorMessage;
    bannersResult.fold((f) => errorMessage ??= f.message, (_) {});
    categoriesResult.fold((f) => errorMessage ??= f.message, (_) {});
    homeCoursesResult.fold((f) => errorMessage ??= f.message, (_) {});

    final homeCourses = homeCoursesResult.fold((_) => null, (c) => c);

    emit(state.copyWith(
      status: errorMessage != null ? HomeStatus.error : HomeStatus.loaded,
      banners: bannersResult.fold((_) => <BannerEntity>[], (b) => b),
      categories: categoriesResult.fold((_) => <CategoryEntity>[], (c) => c),
      featuredCourses: homeCourses?.featuredCourses ?? <CourseEntity>[],
      popularCourses: homeCourses?.popularCourses ?? <CourseEntity>[],
      newCourses: homeCourses?.newCourses ?? <CourseEntity>[],
      flashSaleCourses: homeCourses?.flashSaleCourses ?? <CourseEntity>[],
      errorMessage: errorMessage,
    ));
  }

  /// Refresh home data
  Future<void> refreshHomeData() async {
    try {
      emit(state.copyWith(isRefreshing: true));
      await loadHomeData();
    } catch (e) {
      AppLogger.e('[HomeCubit] Error refreshing home data', e);
    } finally {
      emit(state.copyWith(isRefreshing: false));
    }
  }

  /// Select category filter
  void selectCategory(String? categoryId) {
    emit(state.copyWith(selectedCategoryId: categoryId));
  }

  /// Clear error
  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }
}
