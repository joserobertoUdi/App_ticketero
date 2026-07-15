import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_ticketero/app.dart';

void main() {
  testWidgets('App loads ticket selection screen', (WidgetTester tester) async {
    await tester.pumpWidget(const TicketeroApp());
    expect(find.text('Bienvenido al Sistema de Tickets'), findsOneWidget);
  });
}
