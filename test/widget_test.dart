import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:okane_kore/main.dart';

void main() {
  testWidgets('OkaneKoreApp builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: OkaneKoreApp()),
    );

    // Initial frame renders the loading state while providers resolve.
    expect(find.byType(OkaneKoreApp), findsOneWidget);
  });
}
