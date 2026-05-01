import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';

class HomeController extends ChangeNotifier {
  final LocationService _locationService = LocationService();

  LatLng _currentPosition = const LatLng(-23.550520, -46.633308); // Padrão: São Paulo
  LatLng get currentPosition => _currentPosition;

  bool _isLoadingLocation = true;
  bool get isLoadingLocation => _isLoadingLocation;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> loadDeviceLocation() async {
    _isLoadingLocation = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentPosition = await _locationService.getCurrentLocation();
    } catch (e) {
      _errorMessage = 'Não foi possível obter sua localização: $e';
    } finally {
      _isLoadingLocation = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
