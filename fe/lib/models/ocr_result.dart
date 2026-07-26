class OCRResult {
  final double totalAmount;
  final String date;
  final String merchantName;
  final List<Map<String, dynamic>> items;

  OCRResult({
    required this.totalAmount,
    required this.date,
    this.merchantName = '',
    this.items = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'total_amount': totalAmount,
      'date': date,
      'merchant_name': merchantName,
      'items': items,
    };
  }
}