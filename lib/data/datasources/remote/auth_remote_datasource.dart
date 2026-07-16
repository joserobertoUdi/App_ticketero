import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../models/auth_response_model.dart';

class AuthRemoteDataSource {
  final ApiClient _client;

  AuthRemoteDataSource(this._client);

  Future<AuthResponseModel> login(String correo, String password) async {
    final response = await _client.post(
      ApiConstants.loginEndpoint,
      data: {
        'correo': correo,
        'password': password,
      },
    );
    return AuthResponseModel.fromJson(response.data);
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await _client.post(
      ApiConstants.refreshEndpoint,
      data: {'refreshToken': refreshToken},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> openSession(int usuarioId, int puestoId) async {
    final response = await _client.post(
      ApiConstants.openSession(usuarioId),
      data: {'usuarioId': usuarioId, 'puestoId': puestoId},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> closeSession(int sesionOperadorId) async {
    await _client.post(
      ApiConstants.closeSession(sesionOperadorId),
    );
  }
}
