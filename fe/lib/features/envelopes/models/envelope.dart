import 'package:flutter/material.dart';
import '../../activity/providers/transactions_provider.dart';
import 'pocket.dart';
export 'pocket.dart';

class Liability {
  final String id;
  final String name;
  final double amount;
  final String dueDate;

  Liability({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDate,
  });
}

class Envelope {
  final String id;
  final String name;
  final double allocatedAmount;
  final IconData iconData;
  final Color color;
  
  // Fitur Phase 5: Liquidity Sources & Liabilities
  final Map<String, double> sources;
  final List<Liability> liabilities;
  
  // Fitur Phase 8: Pockets
  final List<Pocket> pockets;
  
  // Fitur Phase 6: Pacing Modes
  final StsMode stsMode;
  final int? stsFrequencyTarget; // Untuk mode frequency
  final int resetDate; // Untuk mode daily (1-31)

  Envelope({
    required this.id,
    required this.name,
    required this.allocatedAmount,
    required this.iconData,
    required this.color,
    this.sources = const {},
    this.liabilities = const [],
    this.pockets = const [],
    this.stsMode = StsMode.daily,
    this.stsFrequencyTarget,
    this.resetDate = 1,
  });
  
  int _getRemainingDays() {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final remaining = lastDay - now.day + 1;
    return remaining > 0 ? remaining : 1;
  }

  // Perhitungan Granular Safe-to-Spend
  double get totalHeldAmount => liabilities.fold(0, (sum, item) => sum + item.amount);
  
  double safeToSpend(List<Transaction> allTxs) {
    if (id == 'tabungan' || stsMode == StsMode.locked) return 0.0;
    
    final remDays = _getRemainingDays();

    if (pockets.isNotEmpty) {
      final pocketsSts = pockets.fold(0.0, (sum, p) => sum + p.calculateSts(id, remDays, allTxs));
      return pocketsSts;
    }

    final available = allocatedAmount - totalHeldAmount;
    if (available <= 0) return 0.0;
    
    if (id == 'keinginan' || stsMode == StsMode.lumpSum) return available;

    return available / (remDays > 0 ? remDays : 1);
  }

  Envelope copyWith({
    String? id,
    String? name,
    double? allocatedAmount,
    IconData? iconData,
    Color? color,
    Map<String, double>? sources,
    List<Liability>? liabilities,
    List<Pocket>? pockets,
    StsMode? stsMode,
    int? stsFrequencyTarget,
    int? resetDate,
  }) {
    return Envelope(
      id: id ?? this.id,
      name: name ?? this.name,
      allocatedAmount: allocatedAmount ?? this.allocatedAmount,
      iconData: iconData ?? this.iconData,
      color: color ?? this.color,
      sources: sources ?? this.sources,
      liabilities: liabilities ?? this.liabilities,
      pockets: pockets ?? this.pockets,
      stsMode: stsMode ?? this.stsMode,
      stsFrequencyTarget: stsFrequencyTarget ?? this.stsFrequencyTarget,
      resetDate: resetDate ?? this.resetDate,
    );
  }
}
