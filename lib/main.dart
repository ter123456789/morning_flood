import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/env.dart';
import 'data/asset_waterway_repository.dart';
import 'data/geolocator_location_service.dart';
import 'data/open_meteo_wind_repository.dart';
import 'data/supabase_flood_report_repository.dart';
import 'data/thaiwater_flood_repository.dart';
import 'domain/flood_report_repository.dart';
import 'domain/flood_repository.dart';
import 'domain/location_service.dart';
import 'domain/waterway_repository.dart';
import 'domain/wind_repository.dart';
import 'presentation/bloc/flood_map_cubit.dart';
import 'presentation/bloc/flood_report_cubit.dart';
import 'presentation/bloc/map_layers_cubit.dart';
import 'presentation/flood_map_page.dart';

Future<void> main() async {
  if (Env.missingKeys.isNotEmpty) {
    throw StateError(
      'Missing ${Env.missingKeys.join(', ')}. '
      'Run with --dart-define-from-file=env.json',
    );
  }
  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabasePublishableKey,
  );
  runApp(
    FloodApp(
      repository: ThaiWaterFloodRepository(),
      reportRepository: SupabaseFloodReportRepository(Supabase.instance.client),
      locationService: GeolocatorLocationService(),
      waterwayRepository: AssetWaterwayRepository(),
      windRepository: OpenMeteoWindRepository(),
    ),
  );
}

class FloodApp extends StatelessWidget {
  const FloodApp({
    super.key,
    required this.repository,
    required this.reportRepository,
    required this.locationService,
    required this.waterwayRepository,
    required this.windRepository,
  });

  final FloodRepository repository;
  final FloodReportRepository reportRepository;
  final LocationService locationService;
  final WaterwayRepository waterwayRepository;
  final WindRepository windRepository;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<FloodRepository>.value(value: repository),
        RepositoryProvider<FloodReportRepository>.value(
          value: reportRepository,
        ),
        RepositoryProvider<LocationService>.value(value: locationService),
        RepositoryProvider<WaterwayRepository>.value(value: waterwayRepository),
        RepositoryProvider<WindRepository>.value(value: windRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => FloodMapCubit(
              context.read<FloodRepository>(),
              context.read<LocationService>(),
            )..load(),
          ),
          BlocProvider(
            create: (context) =>
                FloodReportCubit(context.read<FloodReportRepository>())
                  ..start(),
          ),
          BlocProvider(
            create: (context) => MapLayersCubit(
              context.read<WaterwayRepository>(),
              context.read<WindRepository>(),
              context.read<LocationService>(),
            )..loadWaterways(),
          ),
        ],
        child: MaterialApp(
          title: 'Flood Watch',
          theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.blue)),
          home: const FloodMapPage(),
        ),
      ),
    );
  }
}
