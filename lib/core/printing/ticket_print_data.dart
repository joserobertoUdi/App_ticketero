class TicketPrintData {
  final String ticketCode;
  final String areaName;
  final String dateTime;
  final String estimatedWait;
  final String? barcodeData;
  final int copies;

  const TicketPrintData({
    required this.ticketCode,
    required this.areaName,
    required this.dateTime,
    this.estimatedWait = '5 min',
    this.barcodeData,
    this.copies = 1,
  });

  String get header => 'SISTEMA TICKETERO';
  String get footer => 'Gracias por su preferencia';
  String get instruction => 'PRESENTE SU TICKET AL SER LLAMADO';
}
