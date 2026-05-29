import '../../../models/place_name_model.dart';

abstract class ApiNetworkPlaceNameRepos {
  Future<List<PlaceNameModel>> getAllPlaceNames();

  Future<PlaceNameModel> getPlaceNameById(int id);

  Future<List<String>> getAllPlaceNameStrings();

  Future<PlaceNameModel> addPlaceName(String placeName);

  Future<PlaceNameModel> updatePlaceName(int id, String placeName);

  Future<void> deletePlaceName(int id);
}
