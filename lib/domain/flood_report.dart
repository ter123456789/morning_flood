enum WaterDepth { none, ankle, knee, waist, aboveWaist }

class FloodReport {
  const FloodReport({
    required this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.depth,
    required this.createdAt,
    this.note,
  });

  final String id;
  final String userId;
  final double latitude;
  final double longitude;
  final WaterDepth depth;
  final String? note;
  final DateTime createdAt;
}

/// A report the user is about to submit (id, owner and time set by server).
class NewFloodReport {
  const NewFloodReport({
    required this.latitude,
    required this.longitude,
    required this.depth,
    this.note,
  });

  final double latitude;
  final double longitude;
  final WaterDepth depth;
  final String? note;
}
