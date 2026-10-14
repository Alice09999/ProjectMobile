// Smoke test sederhana: pastikan layar login bisa dibangun.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:inventaris_frontend/data/repositories/auth_repository.dart';
import 'package:inventaris_frontend/data/services/api_service.dart';
import 'package:inventaris_frontend/presentation/auth/login_screen.dart';
import 'package:inventaris_frontend/providers/auth_provider.dart';

void main() {
  testWidgets('Login screen tampil', (WidgetTester tester) async {
    final api = ApiService();
    final auth = AuthProvider(AuthRepository(api), api);

    await tester.pumpWidget(ChangeNotifierProvider<AuthProvider>.value(
      value: auth,
      child: const MaterialApp(home: LoginScreen()),
    ));

    expect(find.text('Inventaris Barang Kantor'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
  });
}
