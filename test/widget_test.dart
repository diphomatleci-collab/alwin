import 'package:flutter_test/flutter_test.dart';
import 'package:smart_school/main.dart';

void main() {
  testWidgets('Smart School menampilkan halaman utama', (tester) async {
    await tester.pumpWidget(const SmartSchoolApp());
    await tester.pumpAndSettle();
    expect(find.text('Smart School'), findsOneWidget);
    expect(find.text('Mata Pelajaran'), findsOneWidget);
  });
}
