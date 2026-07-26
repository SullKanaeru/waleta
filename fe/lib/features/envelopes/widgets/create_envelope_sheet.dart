import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'dart:math';

import '../../../core/theme/app_colors.dart';
import '../models/envelope.dart';
import '../providers/envelope_provider.dart';

// Formatter ribuan
class ThousandsFormatter extends TextInputFormatter {
  static const separator = '.';

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    String newValueText = newValue.text.replaceAll(separator, '');
    if (int.tryParse(newValueText) == null) {
      return oldValue;
    }
    final int value = int.parse(newValueText);
    final formatter = NumberFormat('#,###', 'id_ID');
    String newText = formatter.format(value).replaceAll(',', separator);
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class CreateEnvelopeSheet extends ConsumerStatefulWidget {
  const CreateEnvelopeSheet({super.key});

  @override
  ConsumerState<CreateEnvelopeSheet> createState() =>
      _CreateEnvelopeSheetState();
}

class _CreateEnvelopeSheetState extends ConsumerState<CreateEnvelopeSheet> {
  int _currentStep = 0;

  // Step 1: Dasar
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  IconData _selectedIcon = LucideIcons.wallet;
  Color _selectedColor = AppColors.primary;

  // Step 2: STS Mode
  StsMode _selectedStsMode = StsMode.daily;
  final _resetDateController = TextEditingController(text: '25');
  final _frequencyController = TextEditingController(text: '4');

  // Step 3: Alokasi Rekening
  bool _usePercentage = false;

  // Mock Data Rekening
  final Map<String, double> _mockAccounts = {
    'BRI (Gaji)': 10000000.0,
    'Mandiri (Simpanan)': 5000000.0,
  };

  // controllers for allocation inputs (raw string value)
  final Map<String, TextEditingController> _allocationControllers = {};

  final List<IconData> _icons = [
    LucideIcons.wallet,
    LucideIcons.shoppingBag,
    LucideIcons.car,
    LucideIcons.home,
    LucideIcons.coffee,
    LucideIcons.heart,
    LucideIcons.plane,
    LucideIcons.book,
    LucideIcons.monitorPlay,
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
  ];

  @override
  void initState() {
    super.initState();
    for (var key in _mockAccounts.keys) {
      _allocationControllers[key] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _resetDateController.dispose();
    _frequencyController.dispose();
    for (var controller in _allocationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  double get _targetAmount {
    final text = _targetController.text.replaceAll('.', '');
    return double.tryParse(text) ?? 0.0;
  }

  double get _totalAllocated {
    double total = 0;
    for (var entry in _allocationControllers.entries) {
      final text = entry.value.text.replaceAll('.', '');
      final val = double.tryParse(text) ?? 0.0;
      if (_usePercentage) {
        total += (_targetAmount * (val / 100));
      } else {
        total += val;
      }
    }
    return total;
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_nameController.text.isEmpty || _targetAmount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mohon isi nama dan target nominal')),
        );
        return;
      }
    } else if (_currentStep == 1) {
      if (_selectedStsMode == StsMode.daily &&
          int.tryParse(_resetDateController.text) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tanggal reset tidak valid')),
        );
        return;
      }
      if (_selectedStsMode == StsMode.frequency &&
          int.tryParse(_frequencyController.text) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Target frekuensi tidak valid')),
        );
        return;
      }
    } else if (_currentStep == 2) {
      // Validate allocation
      if (_totalAllocated != _targetAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Total alokasi rekening harus sama persis dengan target amplop!',
            ),
          ),
        );
        return;
      }
      _saveEnvelope();
      return;
    }
    setState(() => _currentStep++);
  }

  void _saveEnvelope() {
    Map<String, double> finalSources = {};
    for (var entry in _allocationControllers.entries) {
      final text = entry.value.text.replaceAll('.', '');
      final val = double.tryParse(text) ?? 0.0;
      if (val > 0) {
        if (_usePercentage) {
          finalSources[entry.key] = _targetAmount * (val / 100);
        } else {
          finalSources[entry.key] = val;
        }
      }
    }

    final newEnvelope = Envelope(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      allocatedAmount: _targetAmount,
      iconData: _selectedIcon,
      color: _selectedColor,
      sources: finalSources,
      stsMode: _selectedStsMode,
      resetDate: int.tryParse(_resetDateController.text) ?? 1,
      stsFrequencyTarget: int.tryParse(_frequencyController.text),
      liabilities: [],
    );

    ref.read(envelopesProvider.notifier).updateEnvelope(newEnvelope);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Amplop Cerdas berhasil dibuat!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Buat Amplop (Tahap ${_currentStep + 1}/3)',
                style: theme.textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(LucideIcons.x),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_currentStep == 0) _buildStep1(theme),
          if (_currentStep == 1) _buildStep2(theme),
          if (_currentStep == 2) _buildStep3(theme, formatter),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentStep--),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Kembali'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      _currentStep == 2 ? 'Simpan Amplop' : 'Selanjutnya',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nama Amplop (mis. Kebutuhan, Tiket Konser)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _targetController,
          keyboardType: TextInputType.number,
          inputFormatters: [ThousandsFormatter()],
          decoration: const InputDecoration(
            labelText: 'Target Nominal (Rp)',
            border: OutlineInputBorder(),
            prefixText: 'Rp ',
          ),
        ),
        const SizedBox(height: 24),
        Text('Pilih Ikon', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _icons.map((icon) {
            final isSelected = icon == _selectedIcon;
            return GestureDetector(
              onTap: () => setState(() => _selectedIcon = icon),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _selectedColor.withValues(alpha: 0.2)
                      : theme.colorScheme.surface,
                  border: Border.all(
                    color: isSelected
                        ? _selectedColor
                        : theme.dividerColor.withValues(alpha: 0.1),
                    width: isSelected ? 2 : 1,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? _selectedColor : theme.iconTheme.color,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text('Pilih Warna', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _colors.map((color) {
            final isSelected = color == _selectedColor;
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = color),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: Colors.white, width: 3)
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStep2(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Atur Kecepatan Pengeluaran (Velocity of Money)',
          style: theme.textTheme.titleLarge?.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 16),
        _buildModeOption(
          theme,
          title: 'Daily Pacing (Mode Harian)',
          desc:
              'Cocok untuk kebutuhan sehari-hari seperti makan & bensin. STS dihitung per hari.',
          mode: StsMode.daily,
          icon: LucideIcons.calendar,
        ),
        if (_selectedStsMode == StsMode.daily)
          Padding(
            padding: const EdgeInsets.only(left: 48, top: 8, bottom: 16),
            child: TextField(
              controller: _resetDateController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Tanggal Reset Bulanan (1-31)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
        const SizedBox(height: 12),
        _buildModeOption(
          theme,
          title: 'Frequency Pacing (Frekuensi)',
          desc: 'Cocok untuk hobi, nongkrong, dll. STS dihitung per transaksi.',
          mode: StsMode.frequency,
          icon: LucideIcons.activity,
        ),
        if (_selectedStsMode == StsMode.frequency)
          Padding(
            padding: const EdgeInsets.only(left: 48, top: 8, bottom: 16),
            child: TextField(
              controller: _frequencyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Rencana jumlah transaksi dalam sebulan',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
        const SizedBox(height: 12),
        _buildModeOption(
          theme,
          title: 'Lump-Sum (Sekali Pakai)',
          desc:
              'Cocok untuk tabungan tiket atau event spesifik. Uang diamankan sepenuhnya.',
          mode: StsMode.lumpSum,
          icon: LucideIcons.box,
        ),
      ],
    );
  }

  Widget _buildModeOption(
    ThemeData theme, {
    required String title,
    required String desc,
    required StsMode mode,
    required IconData icon,
  }) {
    final isSelected = _selectedStsMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _selectedStsMode = mode),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : theme.dividerColor.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : Colors.grey),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.primary : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3(ThemeData theme, NumberFormat formatter) {
    final remaining = max(0.0, _targetAmount - _totalAllocated);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Target: ${formatter.format(_targetAmount)}',
              style: theme.textTheme.titleMedium,
            ),
            Text(
              'Kurang: ${formatter.format(remaining)}',
              style: TextStyle(
                color: remaining > 0 ? AppColors.error : AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              'Input dengan Persentase (%)',
              style: theme.textTheme.bodyMedium,
            ),
            const Spacer(),
            Switch(
              value: _usePercentage,
              onChanged: (val) {
                setState(() {
                  _usePercentage = val;
                  // clear inputs when switching modes
                  for (var c in _allocationControllers.values) {
                    c.clear();
                  }
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._mockAccounts.entries.map((entry) {
          final controller = _allocationControllers[entry.key]!;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.05),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Saldo: ${formatter.format(entry.value)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: _usePercentage
                        ? []
                        : [ThousandsFormatter()],
                    onChanged: (v) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: _usePercentage
                          ? 'Persentase (%)'
                          : 'Alokasi Nominal',
                      suffixText: _usePercentage ? '%' : null,
                      prefixText: _usePercentage ? null : 'Rp ',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
