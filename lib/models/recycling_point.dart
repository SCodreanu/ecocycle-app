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
  String get title =>
      name ??
      (isContainer
          ? 'Cassonetto'
          : recyclingType == 'centre'
          ? 'Centro di raccolta'
          : 'Punto di riciclo');
  String? get address {
    final street = tags['addr:street'];
    if (street == null || street.trim().isEmpty) return null;
    return [street, tags['addr:housenumber']].whereType<String>().join(' ');
  }

  static const materialNames = {
    'paper': 'Carta',
    'cardboard': 'Cartone',
    'plastic': 'Plastica',
    'plastic_bottles': 'Bottiglie di plastica',
    'plastic_packaging': 'Imballaggi in plastica',
    'glass': 'Vetro',
    'glass_bottles': 'Bottiglie di vetro',
    'cans': 'Lattine',
    'metal': 'Metalli',
    'scrap_metal': 'Rottami metallici',
    'organic': 'Organico',
    'green_waste': 'Sfalci e potature',
    'clothes': 'Abiti',
    'shoes': 'Scarpe',
    'batteries': 'Pile',
    'electrical_items': 'RAEE',
    'small_appliances': 'Piccoli elettrodomestici',
    'waste': 'Indifferenziato',
    'cooking_oil': 'Olio alimentare',
  };
  List<String> get materials =>
      tags.entries
          .where((e) => e.key.startsWith('recycling:') && e.value == 'yes')
          .map(
            (e) =>
                materialNames[e.key.substring(10)] ??
                e.key.substring(10).replaceAll('_', ' '),
          )
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
        if (e.key is String && e.value is String)
          tags[e.key as String] = e.value as String;
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
