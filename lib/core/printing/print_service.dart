import 'ticket_print_data.dart';

abstract class PrintService {
  Future<PrintResult> printTicket(TicketPrintData data);
  Future<PrintResult> printRaw(List<int> bytes);

  Future<bool> testConnection();
}

class PrintResult {
  final bool success;
  final String? errorMessage;

  const PrintResult({required this.success, this.errorMessage});

  static const PrintResult ok = PrintResult(success: true);

  factory PrintResult.error(String message) =>
      PrintResult(success: false, errorMessage: message);
}
