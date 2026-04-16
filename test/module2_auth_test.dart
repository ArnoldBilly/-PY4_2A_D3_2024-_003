import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logbook_app_001/features/auth/controller/login_controller.dart';
import 'package:logbook_app_001/features/auth/view/login_view.dart';

void main() {

  group('Module 2 - Authentikasi (3 Test)', () {
    test('Login berhasil dengan kredensial yang benar', () {
      final controller = LoginController();
      
      final result = controller.login("admin", "admin123");
      
      expect(result, isNotNull);
      expect(result!['username'], "admin");
      expect(result['role'], "Ketua");
    });

    test('Login gagal dengan kredensial yang salah', () {
      final controller = LoginController();
      final result = controller.login("admin", "password_salah");
      expect(result, isNull);
    });

    testWidgets('Menampilkan SnackBar saat login gagal di UI', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginView()));
      await tester.enterText(find.byType(TextField).at(0), 'user_ngawur');
      await tester.enterText(find.byType(TextField).at(1), 'pass_ngawur');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(find.text("Login Gagal! Check Username/Password"), findsOneWidget);
    });
  });

}