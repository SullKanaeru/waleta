import 'package:flutter/material.dart';
import '../../activity/providers/transactions_provider.dart';

enum StsMode { daily, frequency, customPeriod, lumpSum, locked }

class Pocket {
  final String id;
  final String name;
  final double allocatedAmount;
  final IconData iconData;
  final Color color;
  final double balance;
  final StsMode stsMode;
  final int? stsPeriodDays;
  final String? stsStartDate;

  Pocket({
    required this.id,
    required this.name,
    required this.allocatedAmount,
    required this.iconData,
    required this.color,
    this.balance = 0.0,
    this.stsMode = StsMode.daily,
    this.stsPeriodDays,
    this.stsStartDate,
  });

  int getPocketRemainingDays(int remainingDaysInMonth) {
    if (stsMode == StsMode.customPeriod &&
        (stsPeriodDays ?? 0) > 0 &&
        stsStartDate != null &&
        stsStartDate!.length >= 10) {
      try {
        final start = DateTime.parse(stsStartDate!.substring(0, 10));
        final now = DateTime.now();
        final diff = DateTime(now.year, now.month, now.day)
            .difference(DateTime(start.year, start.month, start.day))
            .inDays;
        final rem = stsPeriodDays! - diff;
        return rem > 0 ? rem : 1;
      } catch (_) {
        return stsPeriodDays!;
      }
    }
    return remainingDaysInMonth;
  }

  double calculateSts(
    String masterId,
    int remainingDaysInMonth,
    List<Transaction> allTxs,
  ) {
    if (masterId == 'tabungan' || stsMode == StsMode.locked) return 0.0;
    if (allocatedAmount <= 0) return 0.0;
    if (stsMode == StsMode.lumpSum) return allocatedAmount;

    final remDays = getPocketRemainingDays(remainingDaysInMonth);
    return allocatedAmount / (remDays > 0 ? remDays : 1);
  }

  Pocket copyWith({
    String? id,
    String? name,
    double? allocatedAmount,
    IconData? iconData,
    Color? color,
    double? balance,
    StsMode? stsMode,
    int? stsPeriodDays,
    String? stsStartDate,
  }) {
    return Pocket(
      id: id ?? this.id,
      name: name ?? this.name,
      allocatedAmount: allocatedAmount ?? this.allocatedAmount,
      iconData: iconData ?? this.iconData,
      color: color ?? this.color,
      balance: balance ?? this.balance,
      stsMode: stsMode ?? this.stsMode,
      stsPeriodDays: stsPeriodDays ?? this.stsPeriodDays,
      stsStartDate: stsStartDate ?? this.stsStartDate,
    );
  }
}
