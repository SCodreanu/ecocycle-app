import 'package:flutter/material.dart';

import 'recycling_point.dart';

enum BinStatus {
  normal('Disponibile', 'OK', Color(0xff267340), Icons.check),
  nearlyFull('Quasi pieno', '70+', Color(0xffad5500), Icons.hourglass_bottom),
  full('Pieno', '90+', Color(0xffb3261e), Icons.warning_amber_rounded),
  maintenance('Manutenzione', 'M', Color(0xff7551a1), Icons.build_outlined),
  unavailable('Fuori servizio', 'X', Color(0xff555d68), Icons.block);

  const BinStatus(this.label, this.shortLabel, this.color, this.icon);

  final String label, shortLabel;
  final Color color;
  final IconData icon;

  String get description => switch (this) {
    BinStatus.normal => 'Riempimento da 0% a 69%',
    BinStatus.nearlyFull => 'Riempimento da 70% a 89%',
    BinStatus.full => 'Riempimento da 90% a 100%',
    BinStatus.maintenance => 'Manutenzione simulata',
    BinStatus.unavailable => 'Temporaneamente fuori servizio',
  };

  static BinStatus fromFill(
    int fill, {
    bool maintenance = false,
    bool unavailable = false,
  }) {
    if (unavailable) {
      return BinStatus.unavailable;
    }

    if (maintenance) {
      return BinStatus.maintenance;
    }

    if (fill >= 90) {
      return BinStatus.full;
    }

    if (fill >= 70) {
      return BinStatus.nearlyFull;
    }

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
    // Generate stable demo telemetry from the OSM identifier.
    final seed = point.key.codeUnits.fold<int>(
      7,
      (value, char) => (value * 31 + char) % 104729,
    );

    final fill = seed % 101;
    final capacity = _capacityForPoint(point);
    final density = _densityForPoint(point);

    final occupiedVolume = capacity * (fill / 100);
    final weight = occupiedVolume * density;

    return BinStatusData(
      fillLevel: fill,
      status: BinStatus.fromFill(
        fill,
        unavailable: seed % 23 == 0,
        maintenance: seed % 19 == 0,
      ),
      temperature: 15 + (seed % 160) / 10,
      capacity: capacity,
      weight: double.parse(weight.toStringAsFixed(1)),
      gasReading: (seed % 21) / 10,
    );
  }

  // Illustrative capacities in litres, not measured OSM data.
  static int _capacityForPoint(RecyclingPoint point) {
    final materials = point.materials;

    if (materials.contains('Pile')) {
      return 60;
    }

    if (materials.contains('Olio alimentare')) {
      return 120;
    }

    if (materials.contains('Organico')) {
      return 240;
    }

    if (materials.contains('Abiti') || materials.contains('Scarpe')) {
      return 1100;
    }

    if (materials.contains('Vetro') ||
        materials.contains('Bottiglie di vetro')) {
      return 1100;
    }

    if (materials.contains('Carta') || materials.contains('Cartone')) {
      return 1100;
    }

    return 660;
  }

  // Illustrative bulk densities in kilograms per litre.
  static double _densityForPoint(RecyclingPoint point) {
    final materials = point.materials;

    if (materials.contains('Pile')) {
      return 1.0;
    }

    if (materials.contains('Olio alimentare')) {
      return 0.90;
    }

    if (materials.contains('Vetro') ||
        materials.contains('Bottiglie di vetro')) {
      return 0.30;
    }

    if (materials.contains('Organico')) {
      return 0.45;
    }

    if (materials.contains('Carta') || materials.contains('Cartone')) {
      return 0.08;
    }

    if (materials.contains('Abiti') || materials.contains('Scarpe')) {
      return 0.12;
    }

    if (materials.contains('Plastica') ||
        materials.contains('Bottiglie di plastica') ||
        materials.contains('Imballaggi in plastica')) {
      return 0.04;
    }

    return 0.10;
  }
}
