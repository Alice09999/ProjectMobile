import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/barang.dart';
import '../../providers/auth_provider.dart';
import '../../providers/barang_provider.dart';
import '../../providers/peminjaman_provider.dart';
import '../widgets/common_widgets.dart';

class KatalogScreen extends StatefulWidget {
  const KatalogScreen({super.key});

  @override
  State<KatalogScreen> createState() => _KatalogScreenState();
}

class _KatalogScreenState extends State<KatalogScreen> {
  String _query = '';
  String _kategori = 'Semua';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<BarangProvider>().load());
  }

  Future<void> _logout() async {
    final ok = await showConfirmDialog(context,
        title: 'Keluar', message: 'Yakin ingin keluar dari akun?',
        confirmLabel: 'Keluar');
    if (ok && mounted) {
      context.read<PeminjamanProvider>().clear();
      await context.read<AuthProvider>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<BarangProvider>();
    final user = context.watch<AuthProvider>().user;
    final q = _query.toLowerCase();

    final kategoriList = <String>{
      for (final b in p.items) b.kategori,
    }.toList()
      ..sort();
    final list = p.items
        .where((b) =>
            (_kategori == 'Semua' || b.kategori == _kategori) &&
            (b.namaBarang.toLowerCase().contains(q) ||
                b.kategori.toLowerCase().contains(q)))
        .toList();

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/karyawan')),
        title: const Text('Katalog Barang'),
        actions: [
          IconButton(
              tooltip: 'Riwayat saya',
              onPressed: () => context.go('/karyawan/riwayat'),
              icon: const Icon(Icons.history)),
          IconButton(
              tooltip: 'Keluar',
              onPressed: _logout,
              icon: const Icon(Icons.logout)),
        ],
      ),
      body: Column(
        children: [
          PageWrap(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Halo, ${user?.namaLengkap ?? ''}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('Temukan barang yang ingin kamu pinjam',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Cari nama atau kategori…',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
                if (kategoriList.length > 1) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final k in ['Semua', ...kategoriList])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(k),
                              selected: _kategori == k,
                              onSelected: (_) =>
                                  setState(() => _kategori = k),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: Builder(builder: (_) {
              if (p.loading && p.items.isEmpty) return const LoadingView();
              if (p.error != null && p.items.isEmpty) {
                return ErrorView(message: p.error!, onRetry: p.load);
              }
              return RefreshIndicator(
                onRefresh: p.load,
                child: list.isEmpty
                    ? const EmptyView('Tidak ada barang ditemukan.',
                        icon: Icons.search_off)
                    : PageWrap(
                        maxWidth: 1100,
                        padding: const EdgeInsets.all(16),
                        child: LayoutBuilder(builder: (context, c) {
                          // Grid di layar lebar, daftar biasa di HP.
                          final columns = c.maxWidth >= 900
                              ? (c.maxWidth >= 1300 ? 3 : 2)
                              : 0;
                          if (columns == 0) {
                            return Column(
                              children: [
                                for (final b in list)
                                  _KatalogCard(
                                    barang: b,
                                    onPinjam: () => context
                                        .go('/karyawan/pinjam/${b.idBarang}'),
                                  ),
                              ],
                            );
                          }
                          return GridView.count(
                            crossAxisCount: columns,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 2.4,
                            children: [
                              for (final b in list)
                                _KatalogCard(
                                  barang: b,
                                  onPinjam: () => context
                                      .go('/karyawan/pinjam/${b.idBarang}'),
                                ),
                            ],
                          );
                        }),
                      ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _KatalogCard extends StatelessWidget {
  const _KatalogCard({required this.barang, required this.onPinjam});
  final Barang barang;
  final VoidCallback onPinjam;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    (barang.isRusak ? AppColors.danger : AppColors.primary)
                        .withOpacity(0.12),
                child: Icon(Icons.inventory_2,
                    color: barang.isRusak
                        ? AppColors.danger
                        : AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(barang.namaBarang,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('${barang.kategori} • Tersedia: ${barang.stok}',
                        style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    KondisiBadge(barang.kondisi),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: barang.bisaDipinjam ? onPinjam : null,
                child: Text(barang.bisaDipinjam ? 'Pinjam' : 'Habis'),
              ),
            ],
          ),
        ),
      );
}
