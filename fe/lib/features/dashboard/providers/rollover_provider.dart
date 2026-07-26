import 'package:flutter_riverpod/flutter_riverpod.dart';

class RolloverState {
  final bool isNewMonth;
  final double savedAmount;
  final bool hasShownDialog;

  RolloverState({
    required this.isNewMonth,
    required this.savedAmount,
    required this.hasShownDialog,
  });
}

class RolloverNotifier extends Notifier<RolloverState> {
  // In a real app, this would read from SharedPreferences
  // to check the last opened month.
  static int? _lastOpenedMonth;

  @override
  RolloverState build() {
    final now = DateTime.now();
    
    // Simulate detecting a new month for demonstration purposes
    // If _lastOpenedMonth is null, we assume it's the first time and just set it.
    // For testing, we could force it to true, but let's keep it safe.
    bool isNewMonth = false;
    double savedAmount = 0.0;
    
    if (_lastOpenedMonth != null && _lastOpenedMonth != now.month) {
      isNewMonth = true;
      // Mock saved amount for demonstration. Real app would calculate leftover from Kebutuhan & Keinginan.
      savedAmount = 350000; 
    }
    
    _lastOpenedMonth = now.month; // Update to current

    // MOCK FOR DEMO: Let's force it to true if you want to see it, but here we keep it clean.
    // isNewMonth = true;
    // savedAmount = 450000;

    return RolloverState(
      isNewMonth: isNewMonth,
      savedAmount: savedAmount,
      hasShownDialog: false,
    );
  }

  void markAsShown() {
    state = RolloverState(
      isNewMonth: state.isNewMonth,
      savedAmount: state.savedAmount,
      hasShownDialog: true,
    );
  }
}

final rolloverProvider = NotifierProvider<RolloverNotifier, RolloverState>(
  RolloverNotifier.new,
);
