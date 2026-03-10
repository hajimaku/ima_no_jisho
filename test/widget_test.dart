import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ima_no_jisho/main.dart';

void main() {
  testWidgets('アプリが起動する', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ImaNoJishoApp()));
    expect(find.text('「今」の辞書'), findsOneWidget);
  });
}
