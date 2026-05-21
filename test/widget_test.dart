import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_catering/main.dart';

void main() {
  testWidgets('muestra mensaje cuando Firebase no esta configurado',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(firebaseDisponible: false));

    expect(find.text('Inventario Catering'), findsOneWidget);
    expect(
      find.textContaining('Firebase no esta configurado para Android'),
      findsOneWidget,
    );
  });
}
