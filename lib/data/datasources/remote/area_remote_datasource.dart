import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../models/area_model.dart';

class AreaRemoteDataSource {
  final ApiClient _client;

  AreaRemoteDataSource(this._client);

  Future<List<AreaModel>> getAllActive() async {
    final response = await _client.get(ApiConstants.areasEndpoint);
    final list = response.data as List;
    return list.map((e) => AreaModel.fromJson(e)).toList();
  }

  Future<AreaModel> create(Map<String, dynamic> data) async {
    final response = await _client.post(ApiConstants.areasEndpoint, data: data);
    return AreaModel.fromJson(response.data);
  }

  Future<AreaModel> update(int id, Map<String, dynamic> data) async {
    final response = await _client.put(
      '${ApiConstants.areasEndpoint}/$id',
      data: data,
    );
    return AreaModel.fromJson(response.data);
  }

  Future<void> delete(int id) async {
    await _client.delete('${ApiConstants.areasEndpoint}/$id');
  }
}
