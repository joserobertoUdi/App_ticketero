import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../models/user_model.dart';

class UserRemoteDataSource {
  final ApiClient _client;

  UserRemoteDataSource(this._client);

  Future<List<UserModel>> getAll() async {
    final response = await _client.get(ApiConstants.usersEndpoint);
    final list = response.data as List;
    return list.map((e) => UserModel.fromJson(e)).toList();
  }

  Future<UserModel> create(Map<String, dynamic> data) async {
    final response = await _client.post(ApiConstants.usersEndpoint, data: data);
    return UserModel.fromJson(response.data);
  }

  Future<UserModel> update(int id, Map<String, dynamic> data) async {
    final response = await _client.put(
      '${ApiConstants.usersEndpoint}/$id',
      data: data,
    );
    return UserModel.fromJson(response.data);
  }

  Future<void> delete(int id) async {
    await _client.delete('${ApiConstants.usersEndpoint}/$id');
  }
}
