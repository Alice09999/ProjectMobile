import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../providers/barang_provider.dart';
import '../../providers/peminjaman_provider.dart';
import '../widgets/common_widgets.dart';

class FormPinjamScreen extends StatefulWidget {
  const FormPinjamScreen({super.key, required this.idBarang});
  final int idBarang;

  @override
  State<FormPinjamScreen> createState() => _FormPinjamScreenState();
}

class _FormPinjamScreenState extends State<FormPinjamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _jumlahCtrl = TextEditingController(text: '1');
  DateTime _tanggal = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _jumlahCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _tanggal = picked);
  }

  Future<void> _submit(int stok) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final err = await context.read<PeminjamanProvider>().ajukan(
          idBarang: widget.idBarang,
          jumlah: int.parse(_jumlahCtrl.text.trim()),
          tanggalPinjam: toIsoDate(_tanggal),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (err != null) {
      showSnack(context, err, error: true);
      return;
    }
    showSnack(context, 'Pengajuan terkirim. Menunggu persetujuan admin.');
    context.go('/karyawan/riwayat');
  }

  @override
  Widget build(BuildContext context) {
    final barangList = context.watch<BarangProvider>().items;
    final matches = barangList.where((b) => b.idBarang == widget.idBarang);
    final barang = matches.isEmpty ? null : matches.first;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/karyawan')),
        title: const Text('Form Peminjaman'),
      ),
      body: barang == null
          ? ErrorView(
              message: 'Data barang tidak ditemukan.',
              onRetry: () => context.go('/karyawan'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.inventory_2),
                        title: Text(barang.namaBarang,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            '${barang.kategori} • Stok tersedia: ${barang.stok}'),
                        trailing: KondisiBadge(barang.kondisi),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _jumlahCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Jumlah (maks. ${barang.stok})',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          Validators.positiveInt(v, 'Jumlah', max: barang.stok),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Tanggal pinjam',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(formatTanggal(toIsoDate(_tanggal))),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _saving || !barang.bisaDipinjam
                          ? null
                          : () => _submit(barang.stok),
                      style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Ajukan Peminjaman'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
