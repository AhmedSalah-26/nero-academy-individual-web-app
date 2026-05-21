/// Instructor Dashboard Feature
library instructor_dashboard;

// Data Layer
export 'data/datasources/instructor_data_sources.dart';
export 'data/models/instructor_models.dart';
export 'data/repositories/instructor_repository_impl.dart';

// Domain Layer
export 'domain/entities/instructor_entities.dart';
export 'domain/repositories/instructor_repository.dart';

// Presentation Layer
export 'presentation/cubit/instructor_cubits.dart';
export 'presentation/screens/instructor_dashboard_screen.dart';
