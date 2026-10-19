import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopsphere/core/widgets/scroll_navigation_scaffold.dart';

void main() {
  testWidgets('navigation hides on scroll down and returns on scroll up',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ScrollNavigationScaffold(
        branchIndex: 0,
        navigationBar: const SizedBox(
            height: 72, child: Center(child: Text('Navigation'))),
        body: ListView.builder(
          itemCount: 100,
          itemExtent: 70,
          itemBuilder: (_, index) => Text('Product $index'),
        ),
      ),
    ));
    expect(find.text('Navigation').hitTestable(), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Navigation').hitTestable(), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, 150));
    await tester.pumpAndSettle();
    expect(find.text('Navigation').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
