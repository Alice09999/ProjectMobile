import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/peminjaman.dart';
import '../../providers/peminjaman_provider.dart';
import '../admin/kelola_peminjaman_screen.dart' show PeminjamanCard;
import '../widgets/common_widgets.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  /// Status terpilih untuk filter; null = semua.
  String? _filter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<PeminjamanProvider>().load());
  }

  Future<void> _ajukanKembali(Peminjaman p) async {
    final ok = await showConfirmDialog(context,
        title: 'Ajukan pengembalian',
        message: 'Ajukan pengembalian "${p.namaBarang}" sebanyak ${p.jumlah}?',
        confirmLabel: 'Ajukan');
    if (!ok || !mounted) return;
    final err =
        await context.read<PeminjamanProvider>().ajukanKembali(p.idPinjam);
    if (!mounted) return;
    showSnack(context, err ?? 'Pengajuan pengembalian terkirim.',
        error: err != null);
  }

  String _emptyText() {
    if (_filter == null) return 'Kamu belum pernah mengajukan peminjaman.';
    return 'Tidak ada peminjaman berstatus "$_filter".';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PeminjamanProvider>();
    final items = _filter == null ? p.items : p.byStatus(_filter!);

    final chips = <(String, int)>[
      ('Semua', p.items.length),
      for (final s in StatusPeminjaman.semua) (s, p.byStatus(s).length),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/karyawan')),
        title: const Text('Riwayat Saya'),
      ),
      body: Builder(builder: (_) {
        if (p.loading && p.items.isEmpty) return const LoadingView();
        if (p.error != null && p.items.isEmpty) {
          return ErrorView(message: p.error!, onRetry: p.load);
        }
        return RefreshIndicator(
          onRefresh: p.load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              PageWrap(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    const SectionHeader('Filter Status'),
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final (label, count) in chips)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text('$label ($count)'),
                                selected: _filter == label ||
                                    (label == 'Semua' && _filter == null),
                                onSelected: (_) => setState(() =>
                                    _filter = label == 'Semua' ? null : label),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (items.isEmpty)
                      EmptyView(_emptyText(), icon: Icons.history)
                    else
                      ...items.map((item) => PeminjamanCard(
                            item: item,
                            actions: item.status == StatusPeminjaman.dipinjam
                                ? [
                                    FilledButton.tonal(
                                      onPressed: () => _ajukanKembali(item),
                                      child:
                                          const Text('Ajukan Pengembalian'),
                                    )
                                  ]
                                : const [],
                          )),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
