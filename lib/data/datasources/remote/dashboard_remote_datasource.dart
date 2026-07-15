import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../models/dashboard_stats_model.dart';

class DashboardRemoteDataSource {
  final ApiClient _client;

  DashboardRemoteDataSource(this._client);

  Future<DashboardStatsModel> getSummary({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    final response = await _client.get(
      '${ApiConstants.dashboardEndpoint}/summary',
      queryParams: {
        'fechaInicio': fechaInicio.toIso8601String().split('T').first,
        'fechaFin': fechaFin.toIso8601String().split('T').first,
      },
    );
    return DashboardStatsModel.fromJson(response.data);
  }

  Future<Map<String, dynamic>> getByArea({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    final response = await _client.get(
      '${ApiConstants.dashboardEndpoint}/by-area',
      queryParams: {
        'fechaInicio': fechaInicio.toIso8601String().split('T').first,
        'fechaFin': fechaFin.toIso8601String().split('T').first,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getByUser({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    final response = await _client.get(
      '${ApiConstants.dashboardEndpoint}/by-user',
      queryParams: {
        'fechaInicio': fechaInicio.toIso8601String().split('T').first,
        'fechaFin': fechaFin.toIso8601String().split('T').first,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getHourlyBreakdown(DateTime fecha) async {
    final response = await _client.get(
      '${ApiConstants.dashboardEndpoint}/hourly-breakdown',
      queryParams: {
        'fecha': fecha.toIso8601String().split('T').first,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getPuestosStatus() async {
    final response = await _client.get(ApiConstants.dashboardPuestosStatus);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getUserStats(int userId) async {
    final response = await _client.get(
      '${ApiConstants.dashboardUserStats}/$userId',
    );
    return response.data as Map<String, dynamic>;
  }

  Future<List<int>> getExportPdf({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    final response = await _client.get(
      ApiConstants.dashboardExportPdf,
      queryParams: {
        'fechaInicio': fechaInicio.toIso8601String().split('T').first,
        'fechaFin': fechaFin.toIso8601String().split('T').first,
      },
      responseType: ResponseType.bytes,
    );
    return List<int>.from(response.data);
  }
}
