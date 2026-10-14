import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/peminjaman_provider.dart';
import '../admin/kelola_peminjaman_screen.dart' show PeminjamanCard;
import '../widgets/common_widgets.dart';

/// Beranda karyawan: ringkasan peminjaman pribadi + menu cepat.
class BerandaKaryawanScreen extends StatefulWidget {
  const BerandaKaryawanScreen({super.key});

  @override
  State<BerandaKaryawanScreen> createState() => _BerandaKaryawanScreenState();
}

class _BerandaKaryawanScreenState extends State<BerandaKaryawanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<PeminjamanProvider>().load());
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
    final user = context.watch<AuthProvider>().user;
    final p = context.watch<PeminjamanProvider>();
    final dipinjam = p.byStatus(StatusPeminjaman.dipinjam).length;
    final menunggu = p.jumlahMenunggu;
    final pengembalian = p.jumlahMenungguPengembalian;
    final selesai = p.byStatus(StatusPeminjaman.selesai).length;
    final terakhir = p.items.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
        actions: [
          IconButton(
              tooltip: 'Keluar',
              onPressed: _logout,
              icon: const Icon(Icons.logout)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: p.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            PageWrap(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text('Halo, ${user?.namaLengkap ?? ''} 👋',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Pantau peminjaman barang kantor kamu di sini',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  const SectionHeader('Ringkasan Peminjaman Saya'),
                  _SummaryGrid(
                    dipinjam: dipinjam,
                    menunggu: menunggu,
                    pengembalian: pengembalian,
                    selesai: selesai,
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader('Menu'),
                  _MenuCard(
                    icon: Icons.inventory_2,
                    color: AppColors.primary,
                    title: 'Katalog Barang',
                    subtitle: 'Lihat dan pinjam barang yang tersedia',
                    onTap: () => context.go('/karyawan/katalog'),
                  ),
                  _MenuCard(
                    icon: Icons.history,
                    color: AppColors.info,
                    title: 'Riwayat Saya',
                    subtitle: 'Pantau pengajuan, peminjaman & pengembalian',
                    onTap: () => context.go('/karyawan/riwayat'),
                  ),
                  if (p.loading && p.items.isEmpty) ...[
                    const SizedBox(height: 24),
                    const Center(child: CircularProgressIndicator()),
                  ],
                  if (!p.loading && terakhir.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    SectionHeader(
                      'Pengajuan Terakhir',
                      trailing: TextButton(
                        onPressed: () => context.go('/karyawan/riwayat'),
                        child: const Text('Lihat semua'),
                      ),
                    ),
                    ...terakhir.map((item) => PeminjamanCard(item: item)),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({
    required this.dipinjam,
    required this.menunggu,
    required this.pengembalian,
    required this.selesai,
  });

  final int dipinjam;
  final int menunggu;
  final int pengembalian;
  final int selesai;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SummaryCard('Menunggu', menunggu, Icons.hourglass_top, AppColors.warning),
      _SummaryCard('Dipinjam', dipinjam, Icons.inventory, AppColors.info),
      _SummaryCard(
          'Siap Dikembalikan', pengembalian, Icons.assignment_return, Colors.deepPurple),
      _SummaryCard('Selesai', selesai, Icons.task_alt, AppColors.success),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 720 ? 4 : 2;
      final ratio = columns == 4 ? 2.6 : 1.9;
      return GridView.count(
        crossAxisCount: columns,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: ratio,
        children: cards,
      );
    });
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(this.label, this.value, this.icon, this.color);
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        color: color.withOpacity(0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$value',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: color)),
                    Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color)),
          title: Text(title,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
}
