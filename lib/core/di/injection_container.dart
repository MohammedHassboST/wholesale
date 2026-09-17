import 'package:get_it/get_it.dart';
import '../../domain/repositories/i_cloud_repository.dart';
import '../../data/repositories/supabase_repository_impl.dart';
import '../../data/datasources/realtime_service.dart';

final sl = GetIt.instance;

Future<void> initDI() async {
  if (!sl.isRegistered<RealtimeService>()) {
    sl.registerLazySingleton<RealtimeService>(() => RealtimeService());
  }

  if (!sl.isRegistered<ICloudRepository>()) {
    sl.registerLazySingleton<ICloudRepository>(() => SupabaseRepositoryImpl());
  }
}