import 'package:equatable/equatable.dart';
import 'course_entity.dart';

class HomeCoursesEntity extends Equatable {
  final List<CourseEntity> featuredCourses;
  final List<CourseEntity> popularCourses;
  final List<CourseEntity> newCourses;
  final List<CourseEntity> flashSaleCourses;

  const HomeCoursesEntity({
    this.featuredCourses = const [],
    this.popularCourses = const [],
    this.newCourses = const [],
    this.flashSaleCourses = const [],
  });

  @override
  List<Object?> get props => [
        featuredCourses,
        popularCourses,
        newCourses,
        flashSaleCourses,
      ];
}
