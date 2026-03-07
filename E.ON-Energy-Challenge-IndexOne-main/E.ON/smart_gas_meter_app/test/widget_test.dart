import 'package:flutter_test/flutter_test.dart';
import 'package:smart_gas_meter_app/main.dart';

void main() {

  testWidgets('App loads correctly', (WidgetTester tester) async {

    await tester.pumpWidget(const GasMeterApp());

    expect(find.byType(GasMeterApp), findsOneWidget);

  });

}