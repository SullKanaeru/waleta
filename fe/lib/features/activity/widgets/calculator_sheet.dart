import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';

class CalculatorSheet extends StatefulWidget {
  const CalculatorSheet({super.key});

  @override
  State<CalculatorSheet> createState() => _CalculatorSheetState();
}

class _CalculatorSheetState extends State<CalculatorSheet> {
  String _display = '0';
  String _expression = '';
  double? _firstOperand;
  String? _operator;
  bool _shouldResetDisplay = false;
  bool _hasResult = false;

  void _onNumber(String num) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_shouldResetDisplay || _display == '0') {
        _display = num;
        _shouldResetDisplay = false;
      } else {
        if (_display.length < 12) _display += num;
      }
    });
  }

  void _onDecimal() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_shouldResetDisplay) {
        _display = '0.';
        _shouldResetDisplay = false;
      } else if (!_display.contains('.')) {
        _display += '.';
      }
    });
  }

  void _onOperator(String op) {
    HapticFeedback.mediumImpact();
    setState(() {
      if (_firstOperand != null && !_shouldResetDisplay) {
        _calculate();
      }
      _firstOperand = double.tryParse(_display);
      _operator = op;
      _expression = '${_formatNum(_firstOperand!)} $op';
      _shouldResetDisplay = true;
      _hasResult = false;
    });
  }

  void _calculate() {
    if (_firstOperand == null || _operator == null) return;
    final second = double.tryParse(_display) ?? 0;
    double result;
    switch (_operator) {
      case '+':
        result = _firstOperand! + second;
        break;
      case '-':
        result = _firstOperand! - second;
        break;
      case '×':
        result = _firstOperand! * second;
        break;
      case '÷':
        result = second == 0 ? 0 : _firstOperand! / second;
        break;
      default:
        return;
    }
    setState(() {
      _expression = '${_formatNum(_firstOperand!)} $_operator ${_formatNum(second)} =';
      _display = _formatResult(result);
      _firstOperand = result;
      _operator = null;
      _shouldResetDisplay = true;
      _hasResult = true;
    });
  }

  void _onEquals() {
    HapticFeedback.mediumImpact();
    if (_firstOperand == null || _operator == null) return;
    _calculate();
  }

  void _onClear() {
    HapticFeedback.lightImpact();
    setState(() {
      _display = '0';
      _expression = '';
      _firstOperand = null;
      _operator = null;
      _shouldResetDisplay = false;
      _hasResult = false;
    });
  }

  void _onBackspace() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_display.length > 1) {
        _display = _display.substring(0, _display.length - 1);
        if (_display == '-') _display = '0';
      } else {
        _display = '0';
      }
    });
  }

  void _onToggleSign() {
    HapticFeedback.selectionClick();
    setState(() {
      final val = double.tryParse(_display);
      if (val != null) _display = _formatResult(-val);
    });
  }

  void _onPercent() {
    HapticFeedback.selectionClick();
    setState(() {
      final val = double.tryParse(_display);
      if (val != null) _display = _formatResult(val / 100);
    });
  }

  String _formatResult(double val) {
    if (val == val.truncateToDouble()) return val.toInt().toString();
    return val.toStringAsFixed(4).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  String _formatNum(double val) {
    if (val == val.truncateToDouble()) return val.toInt().toString();
    return val.toStringAsFixed(2);
  }

  void _onNext() {
    final amount = double.tryParse(_display);
    if (amount == null || amount == 0) return;
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CalculatorResultSheet(amount: amount.abs()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final surfaceAlt = isDark ? AppColors.darkSurfaceAlt : AppColors.lightMuted;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  const Icon(LucideIcons.calculator, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('Kalkulator', style: theme.textTheme.titleMedium),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _onNext,
                    icon: const Icon(LucideIcons.arrowRight, size: 16),
                    label: const Text('Gunakan'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  ),
                ],
              ),
            ),

            // Expression display
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _expression.isEmpty ? ' ' : _expression,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Main display
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _display,
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontSize: 52,
                      fontWeight: FontWeight.w700,
                      color: _hasResult ? AppColors.primary : theme.textTheme.displayLarge?.color,
                    ),
                  ),
                ),
              ),
            ),

            const Divider(height: 1),
            const SizedBox(height: 8),

            // Keypad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  _buildRow(surfaceAlt, theme, [
                    _CalcKey('AC', onTap: _onClear, type: _KeyType.function),
                    _CalcKey('+/-', onTap: _onToggleSign, type: _KeyType.function),
                    _CalcKey('%', onTap: _onPercent, type: _KeyType.function),
                    _CalcKey('÷', onTap: () => _onOperator('÷'), type: _KeyType.operator, isActive: _operator == '÷'),
                  ]),
                  _buildRow(surfaceAlt, theme, [
                    _CalcKey('7', onTap: () => _onNumber('7')),
                    _CalcKey('8', onTap: () => _onNumber('8')),
                    _CalcKey('9', onTap: () => _onNumber('9')),
                    _CalcKey('×', onTap: () => _onOperator('×'), type: _KeyType.operator, isActive: _operator == '×'),
                  ]),
                  _buildRow(surfaceAlt, theme, [
                    _CalcKey('4', onTap: () => _onNumber('4')),
                    _CalcKey('5', onTap: () => _onNumber('5')),
                    _CalcKey('6', onTap: () => _onNumber('6')),
                    _CalcKey('-', onTap: () => _onOperator('-'), type: _KeyType.operator, isActive: _operator == '-'),
                  ]),
                  _buildRow(surfaceAlt, theme, [
                    _CalcKey('1', onTap: () => _onNumber('1')),
                    _CalcKey('2', onTap: () => _onNumber('2')),
                    _CalcKey('3', onTap: () => _onNumber('3')),
                    _CalcKey('+', onTap: () => _onOperator('+'), type: _KeyType.operator, isActive: _operator == '+'),
                  ]),
                  _buildRow(surfaceAlt, theme, [
                    _CalcKey('⌫', onTap: _onBackspace, type: _KeyType.function),
                    _CalcKey('0', onTap: () => _onNumber('0')),
                    _CalcKey('.', onTap: _onDecimal),
                    _CalcKey('=', onTap: _onEquals, type: _KeyType.equals),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(Color surfaceAlt, ThemeData theme, List<_CalcKey> keys) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: keys.map((k) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildKey(k, surfaceAlt, theme),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildKey(_CalcKey key, Color surfaceAlt, ThemeData theme) {
    Color bg;
    Color fg;
    switch (key.type) {
      case _KeyType.operator:
        bg = key.isActive ? AppColors.primary : AppColors.primary.withValues(alpha: 0.12);
        fg = key.isActive ? Colors.white : AppColors.primary;
        break;
      case _KeyType.equals:
        bg = AppColors.primary;
        fg = Colors.white;
        break;
      case _KeyType.function:
        bg = surfaceAlt;
        fg = AppColors.primaryDark;
        break;
      default:
        bg = surfaceAlt;
        fg = theme.textTheme.bodyLarge?.color ?? Colors.black;
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: key.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 56,
          alignment: Alignment.center,
          child: Text(
            key.label,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: fg),
          ),
        ),
      ),
    );
  }
}

enum _KeyType { number, operator, equals, function }

class _CalcKey {
  final String label;
  final VoidCallback onTap;
  final _KeyType type;
  final bool isActive;

  const _CalcKey(this.label, {required this.onTap, this.type = _KeyType.number, this.isActive = false});
}

/// Bottom sheet to select income or expense after calculator result
class _CalculatorResultSheet extends StatefulWidget {
  final double amount;

  const _CalculatorResultSheet({required this.amount});

  @override
  State<_CalculatorResultSheet> createState() => _CalculatorResultSheetState();
}

class _CalculatorResultSheetState extends State<_CalculatorResultSheet> {
  String? _selectedType; // 'income' or 'expense'

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)),
            ),
            Text('Gunakan Hasil Kalkulator', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Rp ${_formatAmount(widget.amount)}',
              style: theme.textTheme.displayMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 24),
            Text('Catat sebagai:', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TypeButton(
                    label: 'Pemasukan',
                    icon: LucideIcons.arrowDownLeft,
                    color: AppColors.income,
                    isSelected: _selectedType == 'income',
                    onTap: () => setState(() => _selectedType = 'income'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TypeButton(
                    label: 'Pengeluaran',
                    icon: LucideIcons.arrowUpRight,
                    color: AppColors.expense,
                    isSelected: _selectedType == 'expense',
                    onTap: () => setState(() => _selectedType = 'expense'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedType == null ? null : () {
                  Navigator.pop(context);
                  final route = _selectedType == 'income' ? '/income' : '/expense';
                  context.push(route, extra: {'prefillAmount': widget.amount});
                },
                icon: const Icon(LucideIcons.arrowRight),
                label: Text(_selectedType == null ? 'Pilih jenis transaksi' : 'Lanjutkan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    final parts = amount.toStringAsFixed(0).split('').reversed.toList();
    final result = <String>[];
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && i % 3 == 0) result.add('.');
      result.add(parts[i]);
    }
    return result.reversed.join();
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : Colors.transparent,
          border: Border.all(color: isSelected ? color : Theme.of(context).dividerColor, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Theme.of(context).textTheme.bodyMedium?.color, size: 24),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: isSelected ? color : null, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
