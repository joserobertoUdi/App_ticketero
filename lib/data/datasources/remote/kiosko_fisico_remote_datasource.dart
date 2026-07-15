import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../models/kiosko_fisico_model.dart';

class KioskoFisicoRemoteDataSource {
  final ApiClient _client;

  KioskoFisicoRemoteDataSource(this._client);

  Future<Map<String, dynamic>> autoRegistrar(Map<String, dynamic> data) async {
    final response = await _client.post(ApiConstants.autoRegistrarEndpoint, data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> detectarIp() async {
    final response = await _client.post(ApiConstants.detectarIpEndpoint);
    return response.data as Map<String, dynamic>;
  }

  Future<List<KioskoFisicoModel>> getAll() async {
    final response = await _client.get(ApiConstants.kioskosFisicosEndpoint);
    final list = response.data as List;
    return list.map((e) => KioskoFisicoModel.fromJson(e)).toList();
  }

  Future<KioskoFisicoModel> getById(int id) async {
    final response = await _client.get('${ApiConstants.kioskosFisicosEndpoint}/$id');
    return KioskoFisicoModel.fromJson(response.data);
  }

  Future<KioskoFisicoModel> create(Map<String, dynamic> data) async {
    final response = await _client.post(ApiConstants.kioskosFisicosEndpoint, data: data);
    return KioskoFisicoModel.fromJson(response.data);
  }

  Future<KioskoFisicoModel> update(int id, Map<String, dynamic> data) async {
    final response = await _client.put(
      '${ApiConstants.kioskosFisicosEndpoint}/$id',
      data: data,
    );
    return KioskoFisicoModel.fromJson(response.data);
  }

  Future<void> delete(int id) async {
    await _client.delete('${ApiConstants.kioskosFisicosEndpoint}/$id');
  }

  Future<Map<String, dynamic>> getPrinterConfig(int kioskoId) async {
    final response = await _client.get(ApiConstants.printerConfigEndpoint(kioskoId));
    return response.data as Map<String, dynamic>;
  }

  Future<void> updatePrinterConfig(int kioskoId, Map<String, dynamic> data) async {
    await _client.put(ApiConstants.printerConfigEndpoint(kioskoId), data: data);
  }
}
