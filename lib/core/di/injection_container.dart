import 'package:get_it/get_it.dart';
import '../../domain/repositories/i_cloud_repository.dart';
import '../../data/repositories/supabase_repository_impl.dart';

final sl = GetIt.instance;

Future<void> initDI() async {
  if (!sl.isRegistered<ICloudRepository>()) {
    sl.registerLazySingleton<ICloudRepository>(() => SupabaseRepositoryImpl());
  }
}