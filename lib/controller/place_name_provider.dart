import 'package:flutter/foundation.dart';

import '../models/place_name_model.dart';
import '../newtork_repos/remote_repo/api_repos/api_network_place_name_repos_impl.dart';

class PlaceNameProvider with ChangeNotifier {
  final ApiNetworkPlaceNameReposImpl _api = ApiNetworkPlaceNameReposImpl();

  List<PlaceNameModel> _placeNames = [];
  List<String> _placeNameStrings = [];
  bool _isLoading = false;
  String? _error;

  List<PlaceNameModel> get placeNames => _placeNames;
  List<String> get placeNameStrings => _placeNameStrings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAllPlaceNames() async {
    _setLoading(true);
    try {
      _placeNames = await _api.getAllPlaceNames();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchPlaceNameStrings() async {
    _setLoading(true);
    try {
      _placeNameStrings = await _api.getAllPlaceNameStrings();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addPlaceName(String placeName) async {
    _setLoading(true);
    try {
      final newPlace = await _api.addPlaceName(placeName);
      _placeNames.add(newPlace);
      _placeNameStrings.add(newPlace.placeName);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updatePlaceName(int id, String placeName) async {
    _setLoading(true);
    try {
      final updatedPlace = await _api.updatePlaceName(id, placeName);
      final index = _placeNames.indexWhere((p) => p.id == id);
      if (index != -1) {
        _placeNames[index] = updatedPlace;
      }
      final stringIndex = _placeNameStrings.indexOf(placeName);
      if (stringIndex != -1) {
        _placeNameStrings[stringIndex] = placeName;
      }
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deletePlaceName(int id) async {
    _setLoading(true);
    try {
      final place = _placeNames.firstWhere((p) => p.id == id);
      await _api.deletePlaceName(id);
      _placeNames.removeWhere((p) => p.id == id);
      _placeNameStrings.remove(place.placeName);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
