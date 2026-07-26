import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../models/envelope.dart';
import '../providers/envelope_provider.dart';
import 'create_envelope_sheet.dart'; // for ThousandsFormatter

class CreatePocketSheet extends ConsumerStatefulWidget {
  final Envelope masterEnvelope;
  final double maxAllocatable;
  final Pocket? existingPocket;

  const CreatePocketSheet({
    super.key,
    required this.masterEnvelope,
    required this.maxAllocatable,
    this.existingPocket,
  });

  @override
  ConsumerState<CreatePocketSheet> createState() => _CreatePocketSheetState();
}

class _CreatePocketSheetState extends ConsumerState<CreatePocketSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _periodDaysController = TextEditingController();

  IconData _selectedIcon = LucideIcons.shoppingBag;
  Color _selectedColor = AppColors.primary;
  StsMode _selectedStsMode = StsMode.daily;
  bool _isSubmitting = false;

  final List<IconData> _icons = [
    LucideIcons.shoppingBag,
    LucideIcons.car,
    LucideIcons.home,
    LucideIcons.coffee,
    LucideIcons.heart,
    LucideIcons.plane,
    LucideIcons.book,
    LucideIcons.monitorPlay,
    LucideIcons.music,
  ];

  final List<Color> _colors = [
    AppColors.primary,
    AppColors.accentAmber,
    AppColors.error,
    AppColors.warning,
    Colors.teal,
    Colors.indigo,
    Colors.deepOrange,
    Colors.pink,
    Colors.purple,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingPocket != null) {
      _nameController.text = widget.existingPocket!.name;
      _selectedIcon = widget.existingPocket!.iconData;
      _selectedColor = widget.existingPocket!.color;
      _selectedStsMode = widget.existingPocket!.stsMode;
      if (widget.existingPocket!.stsPeriodDays != null &&
          widget.existingPocket!.stsPeriodDays! > 0) {
        _periodDaysController.text = widget.existingPocket!.stsPeriodDays!
            .toString();
      }
      final double amt = widget.existingPocket!.allocatedAmount;
      _amountController.text = NumberFormat(
        '#,###',
        'id_ID',
      ).format(amt.toInt());
    } else {
      if (widget.masterEnvelope.id == 'keinginan') {
        _selectedStsMode = StsMode.lumpSum;
      } else if (widget.masterEnvelope.id == 'tabungan') {
        _selectedStsMode = StsMode.locked;
      } else {
        _selectedStsMode = StsMode.daily;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _periodDaysController.dispose();
    super.dispose();
  }

  void _savePocket() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nama Saku harus diisi')));
      return;
    }

    if (_selectedStsMode == StsMode.customPeriod) {
      final days = int.tryParse(_periodDaysController.text) ?? 0;
      if (days <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Masukkan jumlah hari periode yang valid (misal: 10)',
            ),
          ),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    final textAmount = _amountController.text.replaceAll('.', '');
    final amount = double.tryParse(textAmount) ?? 0.0;

    if (amount <= 0 || amount > widget.maxAllocatable) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nominal tidak valid atau melebihi batas alokasi'),
        ),
      );
      return;
    }

    bool success = false;
    if (widget.existingPocket != null) {
      final updated = widget.existingPocket!.copyWith(
        name: _nameController.text,
        allocatedAmount: amount,
        iconData: _selectedIcon,
        color: _selectedColor,
        stsMode: _selectedStsMode,
        stsPeriodDays: _selectedStsMode == StsMode.customPeriod
            ? (int.tryParse(_periodDaysController.text) ?? 0)
            : 0,
      );
      success = await ref
          .read(envelopesProvider.notifier)
          .updatePocket(updated);
    } else {
      final iconName = getIconName(_selectedIcon);
      final colorName = getColorName(_selectedColor);

      success = await ref
          .read(envelopesProvider.notifier)
          .createPocket(
            widget.masterEnvelope.id,
            _nameController.text,
            amount,
            iconName,
            colorName,
            stsMode: _selectedStsMode,
            stsPeriodDays: _selectedStsMode == StsMode.customPeriod
                ? (int.tryParse(_periodDaysController.text) ?? 0)
                : 0,
          );
    }

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      final action = widget.existingPocket != null ? 'diperbarui' : 'dibuat';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saku "${_nameController.text}" berhasil $action!'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan saku. Silakan coba lagi.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final isEdit = widget.existingPocket != null;
    final isTabungan = widget.masterEnvelope.id == 'tabungan';

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit ? 'Edit Saku' : 'Buat Saku',
                  style: theme.textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Batas Alokasi Dompet: ${formatter.format(widget.maxAllocatable)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Saku (mis. Bensin, Skincare)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsFormatter()],
              decoration: InputDecoration(
                labelText: 'Alokasi Nominal',
                border: const OutlineInputBorder(),
                prefixText: 'Rp ',
                helperText:
                    'Maksimal ${formatter.format(widget.maxAllocatable)}',
              ),
            ),
            if (!isTabungan) ...[
              const SizedBox(height: 24),
              Text('Aturan Safe-to-Spend', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: Text('Bebas', style: theme.textTheme.titleSmall),
                    selected: _selectedStsMode == StsMode.lumpSum,
                    onSelected: (val) =>
                        setState(() => _selectedStsMode = StsMode.lumpSum),
                  ),
                  ChoiceChip(
                    label: Text('Harian', style: theme.textTheme.titleSmall),
                    selected: _selectedStsMode == StsMode.daily,
                    onSelected: (val) =>
                        setState(() => _selectedStsMode = StsMode.daily),
                  ),
                  ChoiceChip(
                    label: Text('Custom', style: theme.textTheme.titleSmall),
                    selected: _selectedStsMode == StsMode.customPeriod,
                    onSelected: (val) =>
                        setState(() => _selectedStsMode = StsMode.customPeriod),
                  ),
                ],
              ),
              if (_selectedStsMode == StsMode.customPeriod) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _periodDaysController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Periode Hari',
                    helperText:
                        'Sisa saldo akan kembali ke dompet di hari akhir',
                    border: OutlineInputBorder(),
                    suffixText: 'Hari',
                  ),
                ),
              ],
            ],
            const SizedBox(height: 24),
            Text('Pilih Ikon & Warna', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _icons.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final icon = _icons[index];
                  final color = _colors[index];
                  final isSelected = _selectedIcon == icon;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIcon = icon;
                        _selectedColor = color;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.2)
                            : theme.colorScheme.surface,
                        border: Border.all(
                          color: isSelected
                              ? color
                              : theme.dividerColor.withValues(alpha: 0.1),
                          width: isSelected ? 2 : 1,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: isSelected ? color : theme.iconTheme.color,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _savePocket,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.masterEnvelope.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(isEdit ? 'Simpan Perubahan' : 'Buat Saku'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
