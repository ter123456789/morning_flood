import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/env.dart';
import 'data/geolocator_location_service.dart';
import 'data/open_meteo_flood_repository.dart';
import 'data/supabase_flood_report_repository.dart';
import 'domain/flood_report_repository.dart';
import 'domain/flood_repository.dart';
import 'domain/location_service.dart';
import 'presentation/bloc/flood_map_cubit.dart';
import 'presentation/bloc/flood_report_cubit.dart';
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
      repository: OpenMeteoFloodRepository(),
      reportRepository: SupabaseFloodReportRepository(Supabase.instance.client),
      locationService: GeolocatorLocationService(),
    ),
  );
}

class FloodApp extends StatelessWidget {
  const FloodApp({
    super.key,
    required this.repository,
    required this.reportRepository,
    required this.locationService,
  });

  final FloodRepository repository;
  final FloodReportRepository reportRepository;
  final LocationService locationService;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<FloodRepository>.value(value: repository),
        RepositoryProvider<FloodReportRepository>.value(
          value: reportRepository,
        ),
        RepositoryProvider<LocationService>.value(value: locationService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                FloodMapCubit(context.read<FloodRepository>())..load(),
          ),
          BlocProvider(
            create: (context) =>
                FloodReportCubit(context.read<FloodReportRepository>())
                  ..start(),
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
