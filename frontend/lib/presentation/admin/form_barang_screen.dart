import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
import '../../data/models/barang.dart';
import '../../providers/barang_provider.dart';
import '../widgets/common_widgets.dart';

/// Form tambah (barang == null) atau ubah barang.
/// Mengubah dropdown "Kondisi" = fitur Update Kondisi Barang.
class FormBarangScreen extends StatefulWidget {
  const FormBarangScreen({super.key, this.barang});
  final Barang? barang;

  @override
  State<FormBarangScreen> createState() => _FormBarangScreenState();
}

class _FormBarangScreenState extends State<FormBarangScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaCtrl;
  late final TextEditingController _kategoriCtrl;
  late final TextEditingController _stokCtrl;
  late String _kondisi;
  bool _saving = false;

  bool get _isEdit => widget.barang != null;

  @override
  void initState() {
    super.initState();
    final b = widget.barang;
    _namaCtrl = TextEditingController(text: b?.namaBarang ?? '');
    _kategoriCtrl = TextEditingController(text: b?.kategori ?? '');
    _stokCtrl = TextEditingController(text: b != null ? '${b.stok}' : '');
    _kondisi = b?.kondisi ?? 'Baik';
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _kategoriCtrl.dispose();
    _stokCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = Barang(
      idBarang: widget.barang?.idBarang ?? 0,
      namaBarang: _namaCtrl.text.trim(),
      kategori: _kategoriCtrl.text.trim(),
      stok: int.parse(_stokCtrl.text.trim()),
      kondisi: _kondisi,
    );
    final err = await context
        .read<BarangProvider>()
        .save(data, id: widget.barang?.idBarang);
    if (!mounted) return;
    setState(() => _saving = false);
    if (err != null) {
      showSnack(context, err, error: true);
      return;
    }
    showSnack(context,
        _isEdit ? 'Barang berhasil diperbarui.' : 'Barang berhasil ditambahkan.');
    context.go('/admin/barang');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.go('/admin/barang')),
          title: Text(_isEdit ? 'Ubah Barang' : 'Tambah Barang'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _namaCtrl,
                  maxLength: 100,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                      labelText: 'Nama barang', border: OutlineInputBorder()),
                  validator: (v) => Validators.required(v, 'Nama barang'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _kategoriCtrl,
                  maxLength: 50,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                      labelText: 'Kategori', border: OutlineInputBorder()),
                  validator: (v) => Validators.required(v, 'Kategori'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _stokCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Stok', border: OutlineInputBorder()),
                  validator: (v) => Validators.nonNegativeInt(v, 'Stok'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _kondisi,
                  decoration: const InputDecoration(
                      labelText: 'Kondisi', border: OutlineInputBorder()),
                  items: AppConstants.kondisiList
                      .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                      .toList(),
                  onChanged: (v) => setState(() => _kondisi = v ?? 'Baik'),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_isEdit ? 'Simpan Perubahan' : 'Simpan'),
                ),
              ],
            ),
          ),
        ),
      );
}
