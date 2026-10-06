import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
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
              ? state.visibleStations
              : const <FloodStation>[];
          return Stack(
            children: [
              _FloodMap(stations: stations),
              if (state is FloodMapLoaded)
                Positioned(
                  top: 8,
                  right: 8,
                  child: _ProvinceSelector(state: state),
                ),
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

class _FloodMap extends StatefulWidget {
  const _FloodMap({required this.stations});

  final List<FloodStation> stations;

  @override
  State<_FloodMap> createState() => _FloodMapState();
}

class _FloodMapState extends State<_FloodMap> {
  final _controller = MapController();
  var _ready = false;
  var _pendingFit = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // The map is built before data arrives, so a fit requested before
  // onMapReady is deferred until then.
  void _fitToStations() {
    if (!_ready) {
      _pendingFit = true;
      return;
    }
    final points = [
      for (final s in widget.stations) LatLng(s.latitude, s.longitude),
    ];
    if (points.isEmpty) return;
    _controller.fitCamera(
      CameraFit.coordinates(
        coordinates: points,
        padding: const EdgeInsets.all(48),
        maxZoom: 12,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stations = widget.stations;
    return BlocListener<FloodMapCubit, FloodMapState>(
      listenWhen: (prev, curr) =>
          curr is FloodMapLoaded &&
          (prev is! FloodMapLoaded || prev.province != curr.province),
      // Wait a frame so widget.stations reflects the new state.
      listener: (_, _) =>
          WidgetsBinding.instance.addPostFrameCallback((_) => _fitToStations()),
      child: _buildMap(context, stations),
    );
  }

  Widget _buildMap(BuildContext context, List<FloodStation> stations) {
    return FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCenter: const LatLng(15.0, 101.0),
        initialZoom: 5.5,
        onMapReady: () {
          _ready = true;
          if (_pendingFit) {
            _pendingFit = false;
            _fitToStations();
          }
        },
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
        MarkerClusterLayerWidget(
          options: MarkerClusterLayerOptions(
            maxClusterRadius: 60,
            size: const Size(40, 40),
            showPolygon: false,
            markers: [
              for (final s in stations)
                Marker(
                  key: ValueKey(s),
                  point: LatLng(s.latitude, s.longitude),
                  width: 36,
                  height: 36,
                  child: Icon(
                    Icons.water_drop,
                    size: 36,
                    color: riskColor(s.risk),
                  ),
                ),
            ],
            onMarkerTap: (m) => _showDetail(context, _stationOf(m)),
            builder: (context, markers) => _ClusterBadge(
              count: markers.length,
              risk: markers
                  .map((m) => _stationOf(m).risk)
                  .reduce((a, b) => a.index >= b.index ? a : b),
            ),
          ),
        ),
        const _ReportMarkerLayer(),
        const RichAttributionWidget(
          attributions: [
            TextSourceAttribution('© OpenStreetMap contributors'),
            TextSourceAttribution('ข้อมูลระดับน้ำ: สสน. (ThaiWater)'),
          ],
        ),
      ],
    );
  }

  static FloodStation _stationOf(Marker m) =>
      (m.key! as ValueKey<FloodStation>).value;

  void _showDetail(BuildContext context, FloodStation s) {
    final local = s.observedAt.toLocal();
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
            Text(s.name, style: Theme.of(context).textTheme.titleLarge),
            if (s.location.isNotEmpty) Text(s.location),
            const SizedBox(height: 8),
            Text(
              'สถานะ: ${riskLabel(s.risk)}',
              style: TextStyle(color: riskColor(s.risk)),
            ),
            if (s.waterLevelMsl case final level?)
              Text('ระดับน้ำ: ${level.toStringAsFixed(2)} ม.รทก.'),
            if (s.capacityPercent case final percent?)
              Text('ความจุลำน้ำ: ${percent.toStringAsFixed(0)}%'),
            Text('วัดเมื่อ $time'),
          ],
        ),
      ),
    );
  }
}

/// Cluster bubble colored by the worst risk among its stations.
class _ClusterBadge extends StatelessWidget {
  const _ClusterBadge({required this.count, required this.risk});

  final int count;
  final FloodRisk risk;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: riskColor(risk),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _ProvinceSelector extends StatelessWidget {
  const _ProvinceSelector({required this.state});

  final FloodMapLoaded state;

  // DropdownMenu can't show a label for a null selection, so the whole
  // country is represented by an empty string here.
  static const _wholeCountry = '';

  @override
  Widget build(BuildContext context) {
    return Card(
      child: DropdownMenu<String>(
        key: ValueKey(state.province),
        initialSelection: state.province ?? _wholeCountry,
        width: 200,
        menuHeight: 400,
        enableFilter: true,
        requestFocusOnTap: true,
        leadingIcon: const Icon(Icons.search),
        hintText: 'ค้นหาจังหวัด',
        inputDecorationTheme: const InputDecorationTheme(
          border: InputBorder.none,
        ),
        dropdownMenuEntries: [
          const DropdownMenuEntry(value: _wholeCountry, label: 'ทั้งประเทศ'),
          for (final p in state.provinces)
            DropdownMenuEntry(value: p, label: p),
        ],
        onSelected: (p) => context.read<FloodMapCubit>().selectProvince(
          p == null || p == _wholeCountry ? null : p,
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
  FloodRisk.normal => 'น้ำปกติ',
  FloodRisk.watch => 'น้ำมาก',
  FloodRisk.high => 'ล้นตลิ่ง',
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
