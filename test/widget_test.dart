import 'package:flutter_test/flutter_test.dart';
import 'package:image_viewer/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ImageViewerApp());
    expect(find.text('이미지 뷰어'), findsOneWidget);
  });
}
