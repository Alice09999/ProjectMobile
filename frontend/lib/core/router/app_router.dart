import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/barang.dart';
import '../../presentation/admin/dashboard_admin_screen.dart';
import '../../presentation/admin/form_barang_screen.dart';
import '../../presentation/admin/kelola_barang_screen.dart';
import '../../presentation/admin/kelola_peminjaman_screen.dart';
import '../../presentation/admin/laporan_screen.dart';
import '../../presentation/auth/login_screen.dart';
import '../../presentation/karyawan/beranda_karyawan_screen.dart';
import '../../presentation/karyawan/form_pinjam_screen.dart';
import '../../presentation/karyawan/katalog_screen.dart';
import '../../presentation/karyawan/riwayat_screen.dart';
import '../../providers/auth_provider.dart';

GoRouter buildRouter(AuthProvider auth) => GoRouter(
      initialLocation: '/login',
      refreshListenable: auth,
      redirect: (context, state) {
        final loc = state.matchedLocation;
        if (!auth.initialized) return null;

        // Belum login -> paksa ke /login.
        if (!auth.isLoggedIn) return loc == '/login' ? null : '/login';

        final home = auth.isAdmin ? '/admin' : '/karyawan';
        // Sudah login tapi membuka /login atau rute role lain -> ke beranda role.
        if (loc == '/login') return home;
        if (loc.startsWith('/admin') && !auth.isAdmin) return home;
        if (loc.startsWith('/karyawan') && auth.isAdmin) return home;
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(
          path: '/admin',
          builder: (_, __) => const DashboardAdminScreen(),
          routes: [
            GoRoute(
              path: 'barang',
              builder: (_, __) => const KelolaBarangScreen(),
              routes: [
                GoRoute(
                  path: 'form',
                  builder: (_, state) =>
                      FormBarangScreen(barang: state.extra as Barang?),
                ),
              ],
            ),
            GoRoute(
                path: 'peminjaman',
                builder: (_, __) => const KelolaPeminjamanScreen()),
            GoRoute(
                path: 'laporan', builder: (_, __) => const LaporanScreen()),
          ],
        ),
        GoRoute(
          path: '/karyawan',
          builder: (_, __) => const BerandaKaryawanScreen(),
          routes: [
            GoRoute(
              path: 'pinjam/:idBarang',
              builder: (_, state) => FormPinjamScreen(
                  idBarang: int.tryParse(state.pathParameters['idBarang']!) ?? 0),
            ),
            GoRoute(
                path: 'katalog', builder: (_, __) => const KatalogScreen()),
            GoRoute(
                path: 'riwayat', builder: (_, __) => const RiwayatScreen()),
          ],
        ),
      ],
      errorBuilder: (_, __) =>
          const Scaffold(body: Center(child: Text('Halaman tidak ditemukan'))),
    );
