import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/flood_report.dart';
import 'bloc/flood_report_cubit.dart';

String waterDepthLabel(WaterDepth depth) => switch (depth) {
  WaterDepth.none => 'ไม่ท่วม',
  WaterDepth.ankle => 'ระดับข้อเท้า',
  WaterDepth.knee => 'ระดับเข่า',
  WaterDepth.waist => 'ระดับเอว',
  WaterDepth.aboveWaist => 'สูงกว่าเอว',
};

Color waterDepthColor(WaterDepth depth) => switch (depth) {
  WaterDepth.none => Colors.teal,
  WaterDepth.ankle => Colors.lightBlue,
  WaterDepth.knee => Colors.blue,
  WaterDepth.waist => Colors.indigo,
  WaterDepth.aboveWaist => Colors.purple,
};

Future<void> showReportFormSheet(
  BuildContext context, {
  required double latitude,
  required double longitude,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => BlocProvider.value(
      value: context.read<FloodReportCubit>(),
      child: ReportFormSheet(latitude: latitude, longitude: longitude),
    ),
  );
}

class ReportFormSheet extends StatefulWidget {
  const ReportFormSheet({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  @override
  State<ReportFormSheet> createState() => _ReportFormSheetState();
}

class _ReportFormSheetState extends State<ReportFormSheet> {
  final _noteController = TextEditingController();
  WaterDepth? _depth;
  bool _submitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final depth = _depth;
    if (depth == null) return;
    setState(() => _submitting = true);

    final error = await context.read<FloodReportCubit>().submit(
      NewFloodReport(
        latitude: widget.latitude,
        longitude: widget.longitude,
        depth: depth,
        note: _noteController.text,
      ),
    );
    if (!mounted) return;

    setState(() => _submitting = false);
    final messenger = ScaffoldMessenger.of(context);
    if (error == null) {
      Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(content: Text('ส่งรายงานแล้ว')));
    } else {
      messenger.showSnackBar(SnackBar(content: Text('ส่งไม่สำเร็จ: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'แจ้งสถานการณ์น้ำท่วม',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            '${widget.latitude.toStringAsFixed(5)}, '
            '${widget.longitude.toStringAsFixed(5)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<WaterDepth>(
            initialValue: _depth,
            decoration: const InputDecoration(
              labelText: 'ระดับน้ำ',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final d in WaterDepth.values)
                DropdownMenuItem(value: d, child: Text(waterDepthLabel(d))),
            ],
            onChanged: (d) => setState(() => _depth = d),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            maxLength: 500,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'รายละเอียดเพิ่มเติม (ไม่บังคับ)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _depth == null || _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('ส่งรายงาน'),
          ),
        ],
      ),
    );
  }
}
