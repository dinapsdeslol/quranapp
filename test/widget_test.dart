import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_player/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const QuranPlayerApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
