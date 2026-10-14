import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/peminjaman_provider.dart';
import '../widgets/common_widgets.dart';
import 'kelola_peminjaman_screen.dart' show PeminjamanCard;

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  String? _filter; // null = semua

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<PeminjamanProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PeminjamanProvider>();
    final list = _filter == null
        ? p.items
        : p.items.where((e) => e.status == _filter).toList();

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/admin')),
        title: const Text('Laporan Peminjaman'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _chip('Semua', null),
                for (final s in StatusPeminjaman.semua) _chip(s, s),
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
                    ? const EmptyView('Belum ada data peminjaman.',
                        icon: Icons.history)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: list.length,
                        itemBuilder: (_, i) =>
                            PeminjamanCard(item: list[i], showPeminjam: true),
                      ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String? value) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: _filter == value,
          onSelected: (_) => setState(() => _filter = value),
        ),
      );
}
