import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../domain/flood_report.dart';
import '../domain/flood_station.dart';
import '../domain/location_service.dart';
import 'bloc/flood_map_cubit.dart';
import 'bloc/flood_map_state.dart';
import 'bloc/flood_report_cubit.dart';
import 'bloc/flood_report_state.dart';
import 'report_form_sheet.dart';

class FloodMapPage extends StatelessWidget {
  const FloodMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เฝ้าระวังน้ำท่วม'),
        actions: [
          const _ReportFilterDropdown(),
          IconButton(
            tooltip: 'รีเฟรช',
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<FloodMapCubit>().load(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _reportAtMyLocation(context),
        icon: const Icon(Icons.my_location),
        label: const Text('แจ้งที่ตำแหน่งฉัน'),
      ),
      body: BlocBuilder<FloodMapCubit, FloodMapState>(
        builder: (context, state) {
          final stations = state is FloodMapLoaded
              ? state.stations
              : const <FloodStation>[];
          return Stack(
            children: [
              _FloodMap(stations: stations),
              if (state is FloodMapLoading || state is FloodMapInitial)
                const LinearProgressIndicator(),
              if (state is FloodMapFailure)
                _ErrorBanner(
                  message: state.message,
                  onRetry: () => context.read<FloodMapCubit>().load(),
                ),
              const _ReportErrorBanner(),
              const Positioned(left: 8, bottom: 32, child: _Legend()),
            ],
          );
        },
      ),
    );
  }

  Future<void> _reportAtMyLocation(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final pos = await context.read<LocationService>().currentPosition();
      if (!context.mounted) return;
      await showReportFormSheet(
        context,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
    } on LocationException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class _FloodMap extends StatelessWidget {
  const _FloodMap({required this.stations});

  final List<FloodStation> stations;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: const LatLng(15.0, 101.0),
        initialZoom: 5.5,
        onLongPress: (_, point) => showReportFormSheet(
          context,
          latitude: point.latitude,
          longitude: point.longitude,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.worning_foold',
        ),
        MarkerLayer(
          markers: [
            for (final s in stations)
              Marker(
                point: LatLng(s.latitude, s.longitude),
                width: 36,
                height: 36,
                child: GestureDetector(
                  onTap: () => _showDetail(context, s),
                  child: Icon(
                    Icons.water_drop,
                    size: 36,
                    color: riskColor(s.risk),
                  ),
                ),
              ),
          ],
        ),
        const _ReportMarkerLayer(),
        const RichAttributionWidget(
          attributions: [
            TextSourceAttribution('© OpenStreetMap contributors'),
            TextSourceAttribution('Flood data: Open-Meteo / GloFAS'),
          ],
        ),
      ],
    );
  }

  void _showDetail(BuildContext context, FloodStation s) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'สถานะ: ${riskLabel(s.risk)}',
              style: TextStyle(color: riskColor(s.risk)),
            ),
            Text(
              'ปริมาณน้ำวันนี้: ${s.currentDischarge.toStringAsFixed(0)} m³/s',
            ),
            Text(
              'คาดการณ์สูงสุด 7 วัน: '
              '${s.peakForecastDischarge.toStringAsFixed(0)} m³/s '
              '(×${s.riseRatio.toStringAsFixed(2)})',
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      content: Text('โหลดข้อมูลไม่สำเร็จ: $message'),
      actions: [TextButton(onPressed: onRetry, child: const Text('ลองใหม่'))],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final r in FloodRisk.values)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 12, color: riskColor(r)),
                  const SizedBox(width: 6),
                  Text(riskLabel(r)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

Color riskColor(FloodRisk risk) => switch (risk) {
  FloodRisk.normal => Colors.green,
  FloodRisk.watch => Colors.orange,
  FloodRisk.high => Colors.red,
};

String riskLabel(FloodRisk risk) => switch (risk) {
  FloodRisk.normal => 'ปกติ',
  FloodRisk.watch => 'เฝ้าระวัง',
  FloodRisk.high => 'เสี่ยงสูง',
};

class _ReportFilterDropdown extends StatelessWidget {
  const _ReportFilterDropdown();

  static const _labels = {
    ReportFilter.all: 'รายงานทั้งหมด',
    ReportFilter.mine: 'เฉพาะของฉัน',
    ReportFilter.hidden: 'ซ่อนรายงาน',
  };

  @override
  Widget build(BuildContext context) {
    final filter = context.select((FloodReportCubit c) => c.state.filter);
    return DropdownButton<ReportFilter>(
      value: filter,
      underline: const SizedBox.shrink(),
      items: [
        for (final f in ReportFilter.values)
          DropdownMenuItem(value: f, child: Text(_labels[f]!)),
      ],
      onChanged: (f) {
        if (f != null) context.read<FloodReportCubit>().setFilter(f);
      },
    );
  }
}

class _ReportMarkerLayer extends StatelessWidget {
  const _ReportMarkerLayer();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FloodReportCubit>().state;
    return MarkerLayer(
      markers: [
        for (final r in state.visibleReports)
          Marker(
            point: LatLng(r.latitude, r.longitude),
            width: 32,
            height: 32,
            child: GestureDetector(
              onTap: () => _showReport(context, r, state.currentUserId),
              child: Icon(
                Icons.person_pin_circle,
                size: 32,
                color: waterDepthColor(r.depth),
              ),
            ),
          ),
      ],
    );
  }

  void _showReport(BuildContext context, FloodReport r, String? myId) {
    final local = r.createdAt.toLocal();
    final time =
        '${local.day}/${local.month} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              waterDepthLabel(r.depth),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: waterDepthColor(r.depth)),
            ),
            Text('แจ้งเมื่อ $time${r.userId == myId ? ' · รายงานของคุณ' : ''}'),
            if (r.note case final note?) ...[
              const SizedBox(height: 8),
              Text(note),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReportErrorBanner extends StatelessWidget {
  const _ReportErrorBanner();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FloodReportCubit>().state;
    if (state.status != FloodReportStatus.failure) {
      return const SizedBox.shrink();
    }
    return Align(
      alignment: Alignment.topCenter,
      child: MaterialBanner(
        content: Text('โหลดรายงานไม่สำเร็จ: ${state.errorMessage}'),
        actions: [
          TextButton(
            onPressed: () => context.read<FloodReportCubit>().start(),
            child: const Text('ลองใหม่'),
          ),
        ],
      ),
    );
  }
}
