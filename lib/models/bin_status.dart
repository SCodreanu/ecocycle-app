import 'package:flutter/material.dart';

import 'recycling_point.dart';

enum BinStatus {
  normal('Normale', 'OK', Color(0xff267340), Icons.check),
  nearlyFull('Quasi pieno', '50+', Color(0xffad5500), Icons.hourglass_bottom),
  full(
    'Critico / pieno',
    '80+',
    Color(0xffb3261e),
    Icons.warning_amber_rounded,
  ),
  maintenance('Manutenzione', 'M', Color(0xff7551a1), Icons.build_outlined),
  unavailable('Fuori servizio', 'X', Color(0xff555d68), Icons.block);

  const BinStatus(this.label, this.shortLabel, this.color, this.icon);
  final String label, shortLabel;
  final Color color;
  final IconData icon;

  static BinStatus fromFill(
    int fill, {
    bool maintenance = false,
    bool unavailable = false,
  }) {
    if (unavailable) return BinStatus.unavailable;
    if (maintenance) return BinStatus.maintenance;
    if (fill >= 80) return BinStatus.full;
    if (fill >= 50) return BinStatus.nearlyFull;
    return BinStatus.normal;
  }
}

class BinStatusData {
  const BinStatusData({
    required this.fillLevel,
    required this.status,
    required this.temperature,
    required this.capacity,
    required this.weight,
    required this.gasReading,
  });
  final int fillLevel, capacity;
  final BinStatus status;
  final double temperature, weight, gasReading;

  factory BinStatusData.forPoint(RecyclingPoint point) {
    // Stable across process restarts; never use a rebuild-time random number.
    final seed = point.key.codeUnits.fold<int>(
      7,
      (value, char) => (value * 31 + char) % 104729,
    );
    final fill = seed % 101;
    return BinStatusData(
      fillLevel: fill,
      status: BinStatus.fromFill(
        fill,
        unavailable: seed % 23 == 0,
        maintenance: seed % 19 == 0,
      ),
      temperature: 15 + (seed % 240) / 10,
      capacity: [240, 360, 660, 1100][seed % 4],
      weight: (seed % 250) / 10 + fill * .35,
      gasReading: (seed % 21) / 10,
    );
  }
}
