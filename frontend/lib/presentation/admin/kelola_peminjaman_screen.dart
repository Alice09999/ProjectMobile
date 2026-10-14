import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/peminjaman.dart';
import '../../providers/barang_provider.dart';
import '../../providers/peminjaman_provider.dart';
import '../widgets/common_widgets.dart';

class KelolaPeminjamanScreen extends StatefulWidget {
  const KelolaPeminjamanScreen({super.key});

  @override
  State<KelolaPeminjamanScreen> createState() => _KelolaPeminjamanScreenState();
}

class _KelolaPeminjamanScreenState extends State<KelolaPeminjamanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<PeminjamanProvider>().load());
  }

  Future<void> _setujui(Peminjaman p) async {
    final err = await context.read<PeminjamanProvider>().setujui(p.idPinjam);
    if (!mounted) return;
    if (err == null) context.read<BarangProvider>().load(); // stok berubah
    showSnack(context, err ?? 'Pengajuan disetujui.', error: err != null);
  }

  Future<void> _tolak(Peminjaman p) async {
    final ok = await showConfirmDialog(context,
        title: 'Tolak pengajuan',
        message: 'Tolak pengajuan ${p.namaLengkap} untuk "${p.namaBarang}"?',
        confirmLabel: 'Tolak',
        destructive: true);
    if (!ok || !mounted) return;
    final err = await context.read<PeminjamanProvider>().tolak(p.idPinjam);
    if (!mounted) return;
    showSnack(context, err ?? 'Pengajuan ditolak.', error: err != null);
  }

  Future<void> _selesai(Peminjaman p) async {
    // Admin memeriksa kondisi barang saat dikembalikan.
    const keep = 'Tidak diubah';
    final pilihan = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Kondisi barang saat dikembalikan'),
        children: [
          SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'Baik'),
              child: const Text('Baik')),
          SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'Rusak'),
              child: const Text('Rusak')),
          SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, keep),
              child: const Text(keep)),
        ],
      ),
    );
    if (pilihan == null || !mounted) return;
    final err = await context.read<PeminjamanProvider>().selesai(p.idPinjam,
        kondisi: pilihan == keep ? null : pilihan);
    if (!mounted) return;
    if (err == null) context.read<BarangProvider>().load();
    showSnack(context, err ?? 'Pengembalian dikonfirmasi.', error: err != null);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PeminjamanProvider>();
    final menunggu = p.byStatus(StatusPeminjaman.menunggu);
    final kembali = p.byStatus(StatusPeminjaman.menungguPengembalian);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.go('/admin')),
          title: const Text('Kelola Peminjaman'),
          bottom: TabBar(tabs: [
            Tab(text: 'Pengajuan (${menunggu.length})'),
            Tab(text: 'Pengembalian (${kembali.length})'),
          ]),
        ),
        body: Builder(builder: (_) {
          if (p.loading && p.items.isEmpty) return const LoadingView();
          if (p.error != null && p.items.isEmpty) {
            return ErrorView(message: p.error!, onRetry: p.load);
          }
          return TabBarView(children: [
            _list(menunggu, 'Tidak ada pengajuan baru.',
                (x) => [
                      OutlinedButton(
                          onPressed: () => _tolak(x),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger),
                          child: const Text('Tolak')),
                      const SizedBox(width: 8),
                      FilledButton(
                          onPressed: () => _setujui(x),
                          child: const Text('Setujui')),
                    ]),
            _list(kembali, 'Tidak ada pengembalian menunggu.',
                (x) => [
                      FilledButton(
                          onPressed: () => _selesai(x),
                          child: const Text('Konfirmasi Pengembalian')),
                    ]),
          ]);
        }),
      ),
    );
  }

  Widget _list(List<Peminjaman> items, String empty,
      List<Widget> Function(Peminjaman) actions) {
    final p = context.read<PeminjamanProvider>();
    return RefreshIndicator(
      onRefresh: p.load,
      child: items.isEmpty
          ? EmptyView(empty, icon: Icons.task_alt)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (_, i) => PeminjamanCard(
                item: items[i],
                showPeminjam: true,
                actions: actions(items[i]),
              ),
            ),
    );
  }
}

/// Kartu peminjaman, dipakai admin (kelola & laporan) dan karyawan (riwayat).
class PeminjamanCard extends StatelessWidget {
  const PeminjamanCard({
    super.key,
    required this.item,
    this.showPeminjam = false,
    this.actions = const [],
  });

  final Peminjaman item;
  final bool showPeminjam;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: StatusBadge.colorFor(item.status)
                        .withOpacity(0.12),
                    child: Icon(Icons.inventory_2,
                        color: StatusBadge.colorFor(item.status)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.namaBarang,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        Text(item.kategori,
                            style:
                                const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  StatusBadge(item.status),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  _Info(Icons.numbers, 'No. ${item.idPinjam}'),
                  if (showPeminjam)
                    _Info(Icons.person, item.namaLengkap),
                  _Info(Icons.confirmation_number, '${item.jumlah} unit'),
                  _Info(Icons.calendar_today, formatTanggal(item.tanggalPinjam)),
                  if (item.tanggalKembali != null)
                    _Info(Icons.event_available,
                        'Kembali ${formatTanggal(item.tanggalKembali)}'),
                ],
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
              ],
            ],
          ),
        ),
      );
}

class _Info extends StatelessWidget {
  const _Info(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      );
}
