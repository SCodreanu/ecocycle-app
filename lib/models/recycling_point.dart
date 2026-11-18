class RecyclingPoint {
  const RecyclingPoint({
    required this.id,
    required this.osmType,
    required this.latitude,
    required this.longitude,
    this.name,
    this.recyclingType,
  });

  final int id;
  final String osmType;
  final double latitude;
  final double longitude;
  final String? name;
  final String? recyclingType;

  factory RecyclingPoint.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final osmType = json['type'];

    final coordinates = osmType == 'node' ? json : json['center'];
    final latitude = coordinates is Map ? coordinates['lat'] : null;
    final longitude = coordinates is Map ? coordinates['lon'] : null;

    if (id is! int ||
        osmType is! String ||
        (osmType != 'node' &&
            osmType != 'way' &&
            osmType != 'relation') ||
        latitude is! num ||
        longitude is! num) {
      throw const FormatException('Invalid Overpass recycling point.');
    }

    final tags = json['tags'];
    final name = tags is Map ? tags['name'] : null;
    final recyclingType =
        tags is Map ? tags['recycling_type'] : null;

    return RecyclingPoint(
      id: id,
      osmType: osmType,
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
      name: name is String && name.trim().isNotEmpty
          ? name.trim()
          : null,
      recyclingType:
          recyclingType is String ? recyclingType : null,
    );
  }
}