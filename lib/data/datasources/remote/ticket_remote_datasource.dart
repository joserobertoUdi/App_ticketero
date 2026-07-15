import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../models/ticket_model.dart';

class TicketRemoteDataSource {
  final ApiClient _client;

  TicketRemoteDataSource(this._client);

  Future<TicketModel> createTicket(int areaId, {int? servicioId, int? tipoTicketId, int? prioridadId, String? descripcion}) async {
    final data = <String, dynamic>{'areaId': areaId};
    if (servicioId != null) data['servicioId'] = servicioId;
    if (tipoTicketId != null) data['tipoTicketId'] = tipoTicketId;
    if (prioridadId != null) data['prioridadId'] = prioridadId;
    if (descripcion != null) data['descripcion'] = descripcion;
    final response = await _client.post(
      ApiConstants.ticketsEndpoint,
      data: data,
    );
    return TicketModel.fromJson(response.data);
  }

  Future<TicketModel> getTicketById(int id) async {
    final response = await _client.get('${ApiConstants.ticketsEndpoint}/$id');
    return TicketModel.fromJson(response.data);
  }

  Future<List<TicketModel>> getPendingTickets(int areaId) async {
    final response = await _client.get(
      '${ApiConstants.ticketsEndpoint}/pending',
      queryParams: {'areaId': areaId},
    );
    final list = response.data['tickets'] as List;
    return list.map((e) => TicketModel.fromJson(e)).toList();
  }

  Future<TicketModel> callTicket(int ticketId, int userId) async {
    final response = await _client.post(
      '${ApiConstants.ticketsEndpoint}/$ticketId/call',
      data: {'userId': userId},
    );
    return TicketModel.fromJson(response.data);
  }

  Future<TicketModel> startAttention(int ticketId, int userId, {int puestoId = 1}) async {
    final response = await _client.post(
      '${ApiConstants.ticketsEndpoint}/$ticketId/start-attention',
      data: {'userId': userId, 'puestoId': puestoId},
    );
    return TicketModel.fromJson(response.data);
  }

  Future<TicketModel> completeTicket(
      int ticketId, int userId, String? observacion) async {
    final response = await _client.post(
      '${ApiConstants.ticketsEndpoint}/$ticketId/complete',
      data: {'userId': userId, 'observacion': observacion},
    );
    return TicketModel.fromJson(response.data);
  }

  Future<void> deriveTicket(int ticketId, int atencionId, int targetAreaId, String? observacion) async {
    await _client.post(
      '${ApiConstants.ticketsEndpoint}/$ticketId/derivar',
      data: {
        'atencionId': atencionId,
        'areaDestinoId': targetAreaId,
        'observacion': observacion,
      },
    );
  }

  Future<TicketModel> cancelTicket(int ticketId, String? motivo) async {
    final response = await _client.post(
      '${ApiConstants.ticketsEndpoint}/$ticketId/cancel',
      data: {'motivo': motivo},
    );
    return TicketModel.fromJson(response.data);
  }

  Future<TicketModel?> getCurrentTicket(int userId) async {
    final response = await _client.get(
      '${ApiConstants.ticketsEndpoint}/current/$userId',
    );
    if (response.statusCode == 204) return null;
    return TicketModel.fromJson(response.data);
  }

  Future<Map<String, dynamic>> getHistory(int userId, DateTime fecha) async {
    final response = await _client.get(
      '${ApiConstants.ticketsEndpoint}/history',
      queryParams: {
        'userId': userId,
        'fecha': fecha.toIso8601String().split('T').first,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}
