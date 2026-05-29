import '../../../models/place_name_model.dart';
import 'api_network_place_name_repos.dart';
import 'dio_client.dart';

class ApiNetworkPlaceNameReposImpl implements ApiNetworkPlaceNameRepos {
  static final ApiNetworkPlaceNameReposImpl instance =
      ApiNetworkPlaceNameReposImpl._();
  final DioClient _client = DioClient();

  ApiNetworkPlaceNameReposImpl._();

  factory ApiNetworkPlaceNameReposImpl() => instance;

  @override
  Future<List<PlaceNameModel>> getAllPlaceNames() async {
    final response = await _client.dio.get('/place-items');
    return (response.data as List)
        .map((json) => PlaceNameModel.fromJson(json))
        .toList();
  }

  @override
  Future<PlaceNameModel> getPlaceNameById(int id) async {
    final response = await _client.dio.get('/place-items/$id');
    return PlaceNameModel.fromJson(response.data);
  }

  @override
  Future<List<String>> getAllPlaceNameStrings() async {
    final response = await _client.dio.get('/place-items/names');
    return (response.data as List).map((e) => e.toString()).toList();
  }

  @override
  Future<PlaceNameModel> addPlaceName(String placeName) async {
    final response = await _client.dio.post('/place-items', data: {
      'placeName': placeName,
    });
    return PlaceNameModel.fromJson(response.data);
  }

  @override
  Future<PlaceNameModel> updatePlaceName(int id, String placeName) async {
    final response = await _client.dio.put('/place-items/$id', data: {
      'placeName': placeName,
    });
    return PlaceNameModel.fromJson(response.data);
  }

  @override
  Future<void> deletePlaceName(int id) async {
    await _client.dio.delete('/place-items/$id');
  }
}
