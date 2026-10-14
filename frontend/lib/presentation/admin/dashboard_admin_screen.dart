import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../providers/barang_provider.dart';
import '../../providers/peminjaman_provider.dart';
import '../widgets/common_widgets.dart';

class DashboardAdminScreen extends StatefulWidget {
  const DashboardAdminScreen({super.key});

  @override
  State<DashboardAdminScreen> createState() => _DashboardAdminScreenState();
}

class _DashboardAdminScreenState extends State<DashboardAdminScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<BarangProvider>().load(),
      context.read<PeminjamanProvider>().load(),
    ]);
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
    final barang = context.watch<BarangProvider>();
    final pinjam = context.watch<PeminjamanProvider>();
    final recent = pinjam.items.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        actions: [
          IconButton(
              tooltip: 'Keluar',
              onPressed: _logout,
              icon: const Icon(Icons.logout)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
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
                  const Text('Ringkasan inventaris hari ini',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  const SectionHeader('Statistik Inventaris'),
                  _StatGrid(
                    stats: [
                      _Stat('Jenis Barang', '${barang.totalJenis}',
                          Icons.category, AppColors.primary),
                      _Stat('Total Stok', '${barang.totalStok}',
                          Icons.inventory, AppColors.success),
                      _Stat('Barang Rusak', '${barang.totalRusak}',
                          Icons.build_circle, AppColors.danger),
                      _Stat('Pengajuan Baru', '${pinjam.jumlahMenunggu}',
                          Icons.pending_actions, AppColors.warning),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader('Perlu Perhatian'),
                  _AttentionPanel(
                    menunggu: pinjam.jumlahMenunggu,
                    pengembalian: pinjam.jumlahMenungguPengembalian,
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader('Menu'),
                  const _MenuGrid(),
                  const SizedBox(height: 20),
                  SectionHeader(
                    'Aktivitas Terbaru',
                    trailing: TextButton(
                      onPressed: () => context.go('/admin/peminjaman'),
                      child: const Text('Lihat semua'),
                    ),
                  ),
                  if (pinjam.loading && pinjam.items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (recent.isEmpty)
                    const EmptyView('Belum ada aktivitas peminjaman.',
                        icon: Icons.inbox_outlined)
                  else
                    Card(
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (var i = 0; i < recent.length; i++) ...[
                            ListTile(
                              dense: i != 0,
                              leading: CircleAvatar(
                                backgroundColor: StatusBadge.colorFor(
                                        recent[i].status)
                                    .withOpacity(0.12),
                                child: Icon(Icons.swap_horiz,
                                    color: StatusBadge.colorFor(
                                        recent[i].status)),
                              ),
                              title: Text(recent[i].namaBarang,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                  '${recent[i].namaLengkap} • ${recent[i].jumlah} unit • ${formatTanggal(recent[i].tanggalPinjam)}'),
                              trailing: StatusBadge(recent[i].status),
                              onTap: () => context.go('/admin/peminjaman'),
                            ),
                            if (i != recent.length - 1) const Divider(height: 1),
                          ],
                        ],
                      ),
                    ),
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

class _Stat {
  const _Stat(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats});
  final List<_Stat> stats;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final columns = c.maxWidth >= 720 ? 4 : 2;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: columns == 4 ? 2.8 : 1.9,
          children: [
            for (final s in stats)
              Card(
                elevation: 0,
                color: s.color.withOpacity(0.08),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: s.color.withOpacity(0.15),
                        child: Icon(s.icon, color: s.color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.value,
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: s.color)),
                            Text(s.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      });
}

class _AttentionPanel extends StatelessWidget {
  const _AttentionPanel({required this.menunggu, required this.pengembalian});
  final int menunggu;
  final int pengembalian;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _AttentionTile(
                icon: Icons.pending_actions,
                color: AppColors.warning,
                title: '$menunggu pengajuan peminjaman baru',
                subtitle: 'Menunggu persetujuan Anda',
                enabled: menunggu > 0,
                onTap: () => context.go('/admin/peminjaman'),
              ),
              const Divider(),
              _AttentionTile(
                icon: Icons.assignment_return,
                color: Colors.deepPurple,
                title: '$pengembalian pengembalian menunggu konfirmasi',
                subtitle: 'Periksa kondisi barang sebelum konfirmasi',
                enabled: pengembalian > 0,
                onTap: () => context.go('/admin/peminjaman'),
              ),
            ],
          ),
        ),
      );
}

class _AttentionTile extends StatelessWidget {
  const _AttentionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(enabled ? 0.15 : 0.06),
          child: Icon(icon,
              color: enabled ? color : Colors.grey.shade400),
        ),
        title: Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: enabled ? null : Colors.grey)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: enabled
            ? FilledButton.tonal(onPressed: onTap, child: const Text('Buka'))
            : null,
        onTap: enabled ? onTap : null,
      );
}

class _MenuGrid extends StatelessWidget {
  const _MenuGrid();

  @override
  Widget build(BuildContext context) {
    final menus = [
      _Menu(Icons.inventory_2, 'Kelola Barang',
          'Tambah, ubah, hapus, dan update kondisi barang', AppColors.primary,
          () => context.go('/admin/barang')),
      _Menu(Icons.fact_check, 'Kelola Peminjaman',
          'Setujui/tolak pengajuan dan konfirmasi pengembalian',
          AppColors.info, () => context.go('/admin/peminjaman')),
      _Menu(Icons.history, 'Laporan',
          'Riwayat peminjaman dan pengembalian barang', AppColors.success,
          () => context.go('/admin/laporan')),
    ];

    return LayoutBuilder(builder: (context, c) {
      final columns = c.maxWidth >= 900 ? 3 : 1;
      if (columns == 1) {
        return Column(
            children: [for (final m in menus) _MenuCard(menu: m)]);
      }
      return GridView.count(
        crossAxisCount: columns,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
        children: [for (final m in menus) _MenuCard(menu: m)],
      );
    });
  }
}

class _Menu {
  const _Menu(this.icon, this.title, this.subtitle, this.color, this.onTap);
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.menu});
  final _Menu menu;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: menu.onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                    backgroundColor: menu.color.withOpacity(0.12),
                    child: Icon(menu.icon, color: menu.color)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(menu.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(menu.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      );
}
