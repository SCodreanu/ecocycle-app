import 'package:url_launcher/url_launcher.dart';

import '../models/recycling_point.dart';

class NavigationService {
  static Future<bool> openDirections(RecyclingPoint point) async {
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${point.latitude},${point.longitude}',
      'travelmode': 'walking',
    });

    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
