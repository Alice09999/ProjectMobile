import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/barang.dart';
import '../../providers/barang_provider.dart';
import '../widgets/common_widgets.dart';

class KelolaBarangScreen extends StatefulWidget {
  const KelolaBarangScreen({super.key});

  @override
  State<KelolaBarangScreen> createState() => _KelolaBarangScreenState();
}

class _KelolaBarangScreenState extends State<KelolaBarangScreen> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<BarangProvider>().load());
  }

  Future<void> _delete(Barang b) async {
    final ok = await showConfirmDialog(context,
        title: 'Hapus barang',
        message: 'Hapus "${b.namaBarang}"? Tindakan ini tidak dapat dibatalkan.',
        confirmLabel: 'Hapus',
        destructive: true);
    if (!ok || !mounted) return;
    final err = await context.read<BarangProvider>().remove(b.idBarang);
    if (!mounted) return;
    showSnack(context, err ?? 'Barang berhasil dihapus.', error: err != null);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<BarangProvider>();
    final q = _query.toLowerCase();
    final list = p.items
        .where((b) =>
            b.namaBarang.toLowerCase().contains(q) ||
            b.kategori.toLowerCase().contains(q))
        .toList();

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/admin')),
        title: const Text('Kelola Barang'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/admin/barang/form'),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Cari nama atau kategori…',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
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
                    ? const EmptyView('Belum ada barang.')
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        itemCount: list.length,
                        itemBuilder: (_, i) => _BarangCard(
                          barang: list[i],
                          onEdit: () => context.go('/admin/barang/form',
                              extra: list[i]),
                          onDelete: () => _delete(list[i]),
                        ),
                      ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _BarangCard extends StatelessWidget {
  const _BarangCard(
      {required this.barang, required this.onEdit, required this.onDelete});
  final Barang barang;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(barang.namaBarang,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('${barang.kategori} • Stok: ${barang.stok}',
                        style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    KondisiBadge(barang.kondisi),
                  ],
                ),
              ),
              IconButton(
                  tooltip: 'Ubah',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined)),
              IconButton(
                  tooltip: 'Hapus',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red)),
            ],
          ),
        ),
      );
}
