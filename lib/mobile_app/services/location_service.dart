import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationResult {
  final bool success;
  final String? address;
  final String? barangay;
  final String? municipality;
  final String? province;
  final double? latitude;
  final double? longitude;
  final String? errorMessage;
  final bool isPermanentlyDenied;

  LocationResult({
    required this.success,
    this.address,
    this.barangay,
    this.municipality,
    this.province,
    this.latitude,
    this.longitude,
    this.errorMessage,
    this.isPermanentlyDenied = false,
  });
}

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  /// Default fallback LocationIQ API key (or set in .env as LOCATIONIQ_API_KEY)
  static const String _defaultLocationIqApiKey = 'pk.236acad53770a6ae910ed6584124beff';

  /// Retrieves the active LocationIQ API key from .env or constant
  String get locationIqApiKey {
    try {
      final envKey = dotenv.env['LOCATIONIQ_API_KEY']?.trim();
      if (envKey != null && envKey.isNotEmpty) return envKey;
    } catch (_) {}
    return _defaultLocationIqApiKey;
  }

  /// Opens the device App Settings screen so the user can enable location permission
  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (e) {
      debugPrint('[LocationService] Error opening app settings: $e');
      return false;
    }
  }

  /// Explicitly requests location permission upfront (e.g. on first app launch after install).
  /// Returns true if permission is granted (whileInUse or always).
  Future<bool> requestPermissionUpfront() async {
    if (kIsWeb) return false;
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      debugPrint('[LocationService] Error requesting upfront location permission: $e');
      return false;
    }
  }

  /// Requests permission (if needed), fetches the device GPS position,
  /// and reverse-geocodes it into a human-readable Philippine address string
  /// with explicit focus on resolving the Barangay, Municipality, and Province.
  Future<LocationResult> getCurrentAddress({bool requestPermission = true}) async {
    try {
      // 1. Check if location services are enabled on the device
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult(
          success: false,
          errorMessage: 'Location services (GPS) are turned off on your device. Please turn them on.',
        );
      }

      // 2. Check and request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        if (!requestPermission) {
          return LocationResult(
            success: false,
            errorMessage: 'Location permission was denied.',
          );
        }
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationResult(
            success: false,
            errorMessage: 'Location permission was denied.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationResult(
          success: false,
          isPermanentlyDenied: true,
          errorMessage: 'Location permissions are permanently denied. Please enable them in your device Settings.',
        );
      }

      // 3. Get device coordinates
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            timeLimit: Duration(seconds: 15),
          ),
        );
      } catch (e) {
        debugPrint('[LocationService] getCurrentPosition timeout/error, trying last known position: $e');
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        return LocationResult(
          success: false,
          errorMessage: 'Unable to get GPS location. Please check your GPS signal.',
        );
      }

      final lat = position.latitude;
      final lng = position.longitude;
      debugPrint('[LocationService] Detected GPS: lat=$lat, lng=$lng');

      // 4. Reverse Geocode (Multi-tiered strategy)
      LocationResult? geocodeResult;

      // Tier 1: LocationIQ REST API (with zoom=14 for exact Barangay/Village level resolution)
      final apiKey = locationIqApiKey;
      if (apiKey.isNotEmpty) {
        geocodeResult = await _reverseGeocodeLocationIQ(lat, lng, apiKey);
      }

      // Tier 2: Native Android / iOS Geocoder fallback
      if (geocodeResult == null || geocodeResult.address == null || geocodeResult.address!.trim().isEmpty || geocodeResult.barangay == null) {
        final nativeResult = await _reverseGeocodeNative(lat, lng);
        if (nativeResult != null && nativeResult.address != null && nativeResult.address!.trim().isNotEmpty) {
          geocodeResult = nativeResult;
        }
      }

      // Tier 3: OpenStreetMap Nominatim fallback (zoom=14)
      if (geocodeResult == null || geocodeResult.address == null || geocodeResult.address!.trim().isEmpty) {
        geocodeResult = await _reverseGeocodeNominatim(lat, lng);
      }

      if (geocodeResult != null && geocodeResult.address != null && geocodeResult.address!.trim().isNotEmpty) {
        return LocationResult(
          success: true,
          address: geocodeResult.address,
          barangay: geocodeResult.barangay,
          municipality: geocodeResult.municipality,
          province: geocodeResult.province,
          latitude: lat,
          longitude: lng,
        );
      }

      // Tier 4: Fallback to Raw GPS Coordinates
      return LocationResult(
        success: true,
        address: 'Lat: ${lat.toStringAsFixed(4)}, Long: ${lng.toStringAsFixed(4)}',
        latitude: lat,
        longitude: lng,
      );
    } on MissingPluginException catch (e) {
      debugPrint('[LocationService] MissingPluginException: $e');
      return LocationResult(
        success: false,
        errorMessage: 'The new GPS plugin requires a full app restart. Please re-run the app.',
      );
    } on PlatformException catch (e) {
      debugPrint('[LocationService] PlatformException: $e');
      return LocationResult(
        success: false,
        errorMessage: e.message ?? 'Location permission error.',
      );
    } catch (e) {
      debugPrint('[LocationService] General error: $e');
      return LocationResult(
        success: false,
        errorMessage: 'Failed to detect location: ${e.toString()}',
      );
    }
  }

  /// Tier 1: LocationIQ REST API
  /// Documentation: https://locationiq.com/docs#reverse-geocoding
  Future<LocationResult?> _reverseGeocodeLocationIQ(double lat, double lon, String apiKey) async {
    try {
      final url = Uri.parse(
        'https://us1.locationiq.com/v1/reverse?key=$apiKey&lat=$lat&lon=$lon&format=json&zoom=14&addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'PiggyTrunkApp/1.0',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('[LocationService] LocationIQ response: ${data['display_name']}');
        final address = data['address'] as Map<String, dynamic>?;

        if (address != null) {
          final parts = <String>[];

          // Check all possible tags where Philippine Barangays are mapped
          final dynamic rawBrgy = address['suburb'] ??
              address['village'] ??
              address['quarter'] ??
              address['neighbourhood'] ??
              address['hamlet'] ??
              address['residential'] ??
              address['city_district'] ??
              address['subdistrict'] ??
              address['barangay'];

          String? formattedBrgy;
          if (rawBrgy != null && rawBrgy.toString().trim().isNotEmpty) {
            final b = rawBrgy.toString().trim();
            final cleanBrgy = b.replaceFirst(RegExp(r'^(Brgy\.?|Barangay)\s*', caseSensitive: false), '');
            formattedBrgy = 'Brgy. $cleanBrgy';
            parts.add(formattedBrgy);
          } else if (data['display_name'] != null) {
            // Regex match for Barangay in display_name
            final displayName = data['display_name'].toString();
            final match = RegExp(r'(?:Brgy\.?|Barangay)\s+([A-Za-z0-9\s\-]+?)(?:,|$)', caseSensitive: false).firstMatch(displayName);
            if (match != null && match.group(1) != null) {
              formattedBrgy = 'Brgy. ${match.group(1)!.trim()}';
              parts.add(formattedBrgy);
            }
          }

          // Municipality / City / Town
          final city = address['city'] ?? address['town'] ?? address['municipality'] ?? address['county'];
          String? municipality;
          if (city != null && city.toString().trim().isNotEmpty) {
            municipality = city.toString().trim();
            parts.add(municipality);
          }

          // Province / State
          final state = address['state'] ?? address['province'] ?? address['region'];
          String? province;
          if (state != null && state.toString().trim().isNotEmpty) {
            province = state.toString().trim();
            parts.add(province);
          }

          if (parts.isNotEmpty) {
            return LocationResult(
              success: true,
              address: parts.join(', '),
              barangay: formattedBrgy,
              municipality: municipality,
              province: province,
              latitude: lat,
              longitude: lon,
            );
          }
        }
      } else {
        debugPrint('[LocationService] LocationIQ HTTP status: ${response.statusCode}, body: ${response.body}');
      }
    } catch (e) {
      debugPrint('[LocationService] LocationIQ error: $e');
    }
    return null;
  }

  /// Tier 2: OpenStreetMap Nominatim with Enhanced Philippine Barangay extraction
  Future<LocationResult?> _reverseGeocodeNominatim(double lat, double lon) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=14&addressdetails=1',
      );
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'PiggyTrunkApp/1.0 (piggytrunk.app@gmail.com)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          final parts = <String>[];

          final dynamic rawBrgy = address['suburb'] ??
              address['village'] ??
              address['quarter'] ??
              address['neighbourhood'] ??
              address['hamlet'] ??
              address['residential'] ??
              address['city_district'] ??
              address['subdistrict'] ??
              address['barangay'];

          String? formattedBrgy;
          if (rawBrgy != null && rawBrgy.toString().trim().isNotEmpty) {
            final b = rawBrgy.toString().trim();
            final cleanBrgy = b.replaceFirst(RegExp(r'^(Brgy\.?|Barangay)\s*', caseSensitive: false), '');
            formattedBrgy = 'Brgy. $cleanBrgy';
            parts.add(formattedBrgy);
          } else if (data['display_name'] != null) {
            final displayName = data['display_name'].toString();
            final match = RegExp(r'(?:Brgy\.?|Barangay)\s+([A-Za-z0-9\s\-]+?)(?:,|$)', caseSensitive: false).firstMatch(displayName);
            if (match != null && match.group(1) != null) {
              formattedBrgy = 'Brgy. ${match.group(1)!.trim()}';
              parts.add(formattedBrgy);
            }
          }

          // Municipality / City / Town
          final city = address['city'] ?? address['town'] ?? address['municipality'] ?? address['county'];
          String? municipality;
          if (city != null && city.toString().trim().isNotEmpty) {
            municipality = city.toString().trim();
            parts.add(municipality);
          }

          // Province / State
          final state = address['state'] ?? address['province'] ?? address['region'];
          String? province;
          if (state != null && state.toString().trim().isNotEmpty) {
            province = state.toString().trim();
            parts.add(province);
          }

          if (parts.isNotEmpty) {
            return LocationResult(
              success: true,
              address: parts.join(', '),
              barangay: formattedBrgy,
              municipality: municipality,
              province: province,
              latitude: lat,
              longitude: lon,
            );
          }
        }

        // Display name fallback
        if (data['display_name'] != null) {
          final displayName = data['display_name'].toString();
          final split = displayName.split(',');
          if (split.length >= 3) {
            return LocationResult(
              success: true,
              address: split.take(3).map((s) => s.trim()).join(', '),
              latitude: lat,
              longitude: lon,
            );
          }
          return LocationResult(
            success: true,
            address: displayName,
            latitude: lat,
            longitude: lon,
          );
        }
      }
    } catch (e) {
      debugPrint('[LocationService] Nominatim fallback error: $e');
    }
    return null;
  }

  /// Tier 3: Native Android / iOS Geocoder
  Future<LocationResult?> _reverseGeocodeNative(double lat, double lon) async {
    try {
      final placemarks = await Geocoding().placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        debugPrint('[LocationService] Native Placemark: subLocality="${p.subLocality}", name="${p.name}", street="${p.street}", locality="${p.locality}", subAdmin="${p.subAdministrativeArea}", admin="${p.administrativeArea}"');
        final parts = <String>[];

        String? formattedBrgy;
        // Sub-locality / Barangay
        if (p.subLocality != null && p.subLocality!.trim().isNotEmpty) {
          final sl = p.subLocality!.trim();
          final clean = sl.replaceFirst(RegExp(r'^(Brgy\.?|Barangay)\s*', caseSensitive: false), '');
          formattedBrgy = 'Brgy. $clean';
          parts.add(formattedBrgy);
        } else if (p.name != null &&
            (p.name!.toLowerCase().contains('brgy') || p.name!.toLowerCase().contains('barangay'))) {
          final clean = p.name!.trim().replaceFirst(RegExp(r'^(Brgy\.?|Barangay)\s*', caseSensitive: false), '');
          formattedBrgy = 'Brgy. $clean';
          parts.add(formattedBrgy);
        } else if (p.thoroughfare != null &&
            p.thoroughfare!.trim().isNotEmpty &&
            !p.thoroughfare!.toLowerCase().contains('unnamed')) {
          parts.add(p.thoroughfare!.trim());
        }

        // Locality (City or Municipality)
        String? municipality;
        if (p.locality != null && p.locality!.trim().isNotEmpty) {
          municipality = p.locality!.trim();
          parts.add(municipality);
        } else if (p.subAdministrativeArea != null && p.subAdministrativeArea!.trim().isNotEmpty) {
          municipality = p.subAdministrativeArea!.trim();
          parts.add(municipality);
        }

        // Administrative Area (Province)
        String? province;
        if (p.administrativeArea != null && p.administrativeArea!.trim().isNotEmpty) {
          province = p.administrativeArea!.trim();
          parts.add(province);
        }

        if (parts.isNotEmpty) {
          return LocationResult(
            success: true,
            address: parts.join(', '),
            barangay: formattedBrgy,
            municipality: municipality,
            province: province,
            latitude: lat,
            longitude: lon,
          );
        }
      }
    } catch (e) {
      debugPrint('[LocationService] Native Geocoder failed: $e');
    }
    return null;
  }
}
