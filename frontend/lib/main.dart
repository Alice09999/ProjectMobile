import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/barang_repository.dart';
import 'data/repositories/peminjaman_repository.dart';
import 'data/services/api_service.dart';
import 'providers/auth_provider.dart';
import 'providers/barang_provider.dart';
import 'providers/peminjaman_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');

  final api = ApiService();
  final auth = AuthProvider(AuthRepository(api), api);
  await auth.init(); // pulihkan sesi login tersimpan

  runApp(MyApp(api: api, auth: auth));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.api, required this.auth});
  final ApiService api;
  final AuthProvider auth;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router = buildRouter(widget.auth);

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: widget.auth),
          ChangeNotifierProvider(
              create: (_) => BarangProvider(BarangRepository(widget.api))),
          ChangeNotifierProvider(
              create: (_) =>
                  PeminjamanProvider(PeminjamanRepository(widget.api))),
        ],
        child: MaterialApp.router(
          title: 'Inventaris Barang Kantor',
          debugShowCheckedModeBanner: false,
          routerConfig: _router,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
            appBarTheme: const AppBarTheme(centerTitle: false),
          ),
        ),
      );
}
