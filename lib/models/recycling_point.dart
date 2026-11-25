class RecyclingPoint {
  const RecyclingPoint({
    required this.id,
    required this.osmType,
    required this.latitude,
    required this.longitude,
    this.name,
    this.recyclingType,
    this.tags = const {},
  });

  final int id;
  final String osmType;
  final double latitude, longitude;
  final String? name, recyclingType;
  final Map<String, String> tags;

  String get key => '$osmType/$id';
  bool get isContainer => recyclingType == 'container';
  String get title {
    final osmName = name?.trim();
    if (osmName != null && osmName.isNotEmpty) return osmName;
    if (isContainer) {
      final known =
          materialCodes
              .where(materialNames.containsKey)
              .map((code) => materialNames[code]!)
              .toSet()
              .toList()
            ..sort();
      if (known.length == 1) return 'Cassonetto · ${known.first}';
      if (known.length > 1) return 'Cassonetto · Multi-materiale';
      return 'Cassonetto';
    }
    return recyclingType == 'centre'
        ? 'Centro di raccolta'
        : 'Punto di riciclo';
  }

  String? get address {
    final street = tags['addr:street'];
    if (street == null || street.trim().isEmpty) return null;
    return [street, tags['addr:housenumber']].whereType<String>().join(' ');
  }

  // Keep specific OSM material categories distinct for compatible alternatives.
  static const materialNames = <String, String>{
    'paper': 'Carta',
    'cardboard': 'Cartone',
    'plastic': 'Plastica',
    'plastic_bottles': 'Bottiglie di plastica',
    'plastic_packaging': 'Imballaggi in plastica',
    'glass': 'Vetro',
    'glass_bottles': 'Bottiglie di vetro',
    'cans': 'Lattine',
    'aluminium': 'Alluminio',
    'aluminum': 'Alluminio',
    'metal': 'Metalli',
    'scrap_metal': 'Rottami metallici',
    'steel': 'Acciaio',
    'organic': 'Organico',
    'green_waste': 'Sfalci e potature',
    'clothes': 'Abiti',
    'shoes': 'Scarpe',
    'textiles': 'Tessili',
    'batteries': 'Pile',
    'car_batteries': 'Batterie per auto',
    'electrical_items': 'RAEE',
    'small_appliances': 'Piccoli elettrodomestici',
    'waste': 'Indifferenziato',
    'cooking_oil': 'Olio alimentare',
    'engine_oil': 'Olio motore',
    'wood': 'Legno',
    'furniture': 'Mobili',
    'books': 'Libri',
    'newspaper': 'Giornali',
    'beverage_cartons': 'Cartoni per bevande',
    'fluorescent_tubes': 'Tubi fluorescenti',
    'light_bulbs': 'Lampadine',
    'paint': 'Vernici',
    'tyres': 'Pneumatici',
    'construction_waste': 'Rifiuti edili',
    'cork': 'Sughero',
    'caps': 'Tappi',
    'medicines': 'Medicinali',
    'printer_cartridges': 'Cartucce per stampanti',
  };

  List<String> get materialCodes =>
      tags.entries
          .where(
            (entry) =>
                entry.key.startsWith('recycling:') &&
                entry.key.length > 10 &&
                entry.value == 'yes',
          )
          .map((entry) => entry.key.substring(10))
          .toSet()
          .toList()
        ..sort();

  List<String> get materials =>
      materialCodes
          .map((code) => materialNames[code] ?? 'Materiale OSM: $code')
          .toSet()
          .toList()
        ..sort();

  factory RecyclingPoint.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final type = json['type'];
    final coordinates = type == 'node' ? json : json['center'];
    final lat = coordinates is Map ? coordinates['lat'] : null;
    final lon = coordinates is Map ? coordinates['lon'] : null;
    if (id is! int ||
        type is! String ||
        !['node', 'way', 'relation'].contains(type) ||
        lat is! num ||
        lon is! num ||
        !lat.isFinite ||
        !lon.isFinite ||
        lat.abs() > 90 ||
        lon.abs() > 180) {
      throw const FormatException('Invalid Overpass recycling point.');
    }
    final raw = json['tags'];
    final tags = <String, String>{};
    if (raw is Map) {
      for (final e in raw.entries) {
        if (e.key is String && e.value is String) {
          tags[e.key as String] = e.value as String;
        }
      }
    }
    final name = tags['name']?.trim();
    return RecyclingPoint(
      id: id,
      osmType: type,
      latitude: lat.toDouble(),
      longitude: lon.toDouble(),
      name: name == null || name.isEmpty ? null : name,
      recyclingType: tags['recycling_type'],
      tags: Map.unmodifiable(tags),
    );
  }
}
