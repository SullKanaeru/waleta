import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/ocr_result.dart';

class OCRService {
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final _imagePicker = ImagePicker();

  /// Pick image from camera
  Future<File?> pickImageFromCamera() async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    return pickedFile != null ? File(pickedFile.path) : null;
  }

  /// Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    return pickedFile != null ? File(pickedFile.path) : null;
  }

  /// Legacy method kept for compatibility
  Future<File?> pickImage() => pickImageFromCamera();

  Future<OCRResult?> processImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);

    String text = recognizedText.text;
    final lines =
        text.split('\n').where((line) => line.trim().isNotEmpty).toList();

    double? totalAmount = _extractTotal(text, lines);
    String date = _extractDate(text);
    String merchantName = _extractMerchant(lines);
    List<Map<String, dynamic>> items = _extractItems(lines);

    if (totalAmount == null) return null;

    return OCRResult(
      totalAmount: totalAmount,
      date: date,
      merchantName: merchantName,
      items: items,
    );
  }

  // ──────────────────────────────────────────────
  // MERCHANT EXTRACTION
  // ──────────────────────────────────────────────

  String _extractMerchant(List<String> lines) {
    // Skip common header noise patterns
    final noisePatterns = RegExp(
      r'(?:struk|receipt|nota|invoice|faktur|kwitansi|copy|customer|pelanggan|kasir|cashier|print|cetak)',
      caseSensitive: false,
    );

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.length < 3 || trimmed.length > 50) continue;

      // Skip lines that are mostly numbers (dates, phone numbers, etc.)
      final digitCount = trimmed.replaceAll(RegExp(r'[^\d]'), '').length;
      if (digitCount > trimmed.length * 0.5) continue;

      // Skip total/price/date keywords
      if (RegExp(
        r'(?:total|amount|bayar|grand|tanggal|tgl|date|tunai|cash|kembalian|change|diskon|discount|subtotal|sub\s*total|pajak|tax|ppn|dpp|jumlah|qty|harga|price|\d{2}[/\-]\d{2})',
        caseSensitive: false,
      ).hasMatch(trimmed)) continue;

      // Skip noise patterns
      if (noisePatterns.hasMatch(trimmed)) continue;

      // Skip lines that are just dashes or symbols
      if (RegExp(r'^[\-=*_\.]+$').hasMatch(trimmed)) continue;

      return trimmed;
    }
    return '';
  }

  // ──────────────────────────────────────────────
  // ITEM EXTRACTION
  // ──────────────────────────────────────────────

  List<Map<String, dynamic>> _extractItems(List<String> lines) {
    final items = <Map<String, dynamic>>[];
    for (var line in lines) {
      final totalMatch = RegExp(r'([\d,.]+)\s*$').firstMatch(line);
      if (totalMatch == null) continue;

      final priceStr = totalMatch.group(1)!;
      final price = _parseIndonesianNumber(priceStr);
      if (price == null || price <= 0) continue;

      // Skip summary lines
      if (RegExp(
        r'(?:total|amount|grand|bayar|diskon|subtotal|sub\s*total|tunai|cash|kembalian|change|pajak|tax|ppn|dpp|jumlah)',
        caseSensitive: false,
      ).hasMatch(line)) continue;

      final name = line.replaceAll(totalMatch.group(0)!, '').trim();
      if (name.isEmpty) continue;
      items.add({'name': name, 'price': price});
    }
    return items;
  }

  // ──────────────────────────────────────────────
  // TOTAL EXTRACTION — Multi-Pass Approach
  // ──────────────────────────────────────────────

  double? _extractTotal(String text, List<String> lines) {
    // Pass 1: Keyword-based extraction with comprehensive Indonesian receipt keywords
    final pass1Result = _extractTotalByKeyword(text);
    if (pass1Result != null) return pass1Result;

    // Pass 2: Line-by-line keyword search (handles OCR line-break issues)
    final pass2Result = _extractTotalByLineKeyword(lines);
    if (pass2Result != null) return pass2Result;

    // Pass 3: Fallback — find the largest number >= 1000 in the text
    // On a receipt, the total is almost always the largest number
    final pass3Result = _extractLargestNumber(text);
    if (pass3Result != null) return pass3Result;

    return null;
  }

  /// Pass 1: Full-text keyword matching with expanded Indonesian keywords
  double? _extractTotalByKeyword(String text) {
    // Normalize: collapse multiple spaces, handle "T O T A L" spaced-out text
    final normalized = text
        .replaceAll(RegExp(r'T\s+O\s+T\s+A\s+L', caseSensitive: false), 'TOTAL')
        .replaceAll(RegExp(r'J\s+U\s+M\s+L\s+A\s+H', caseSensitive: false), 'JUMLAH');

    // Keywords sorted by specificity (most specific first)
    final keywords = [
      r'Grand\s*Total',
      r'Total\s*Bayar',
      r'Total\s*Belanja',
      r'Total\s*Harga',
      r'Total\s*Pembayaran',
      r'Total\s*Penjualan',
      r'Total\s*Tagihan',
      r'Total\s*Akhir',
      r'Total\s*Transaksi',
      r'DPP\s*\+?\s*PPN',
      r'Nominal\s*Bayar',
      r'Jumlah\s*Bayar',
      r'Jumlah\s*Total',
      r'TUNAI',
      r'CASH',
      r'Total',
      r'JUMLAH',
      r'Bayar',
      r'Pembayaran',
      r'Nominal',
      r'Amount',
    ];

    for (final keyword in keywords) {
      final regex = RegExp(
        '$keyword'
        r'[\s:=]*'
        r'(?:R[pP]\.?\s*|IDR\s*)?'
        r'([\d]+(?:[.,]\d{3})*(?:[.,]\d{1,2})?)',
        caseSensitive: false,
      );

      final matches = regex.allMatches(normalized);
      for (final match in matches) {
        final parsed = _parseIndonesianNumber(match.group(1)!);
        if (parsed != null && parsed >= 100 && parsed < 100000000) return parsed;
      }
    }
    return null;
  }

  /// Pass 2: Line-by-line keyword search
  double? _extractTotalByLineKeyword(List<String> lines) {
    final keywordRegex = RegExp(
      r'(?:total|grand\s*total|tunai|cash|bayar|jumlah|pembayaran|nominal|amount)',
      caseSensitive: false,
    );

    // Also check for "Rp" followed by a number on keyword lines
    final rpNumberRegex = RegExp(
      r'(?:R[pP]\.?\s*)([\d]+(?:[.,]\d{3})*(?:[.,]\d{1,2})?)',
      caseSensitive: false,
    );

    final plainNumberRegex = RegExp(
      r'([\d]+(?:[.,]\d{3})*(?:[.,]\d{1,2})?)\s*$',
    );

    // Scan from bottom to top — total is usually near the bottom of a receipt
    for (int i = lines.length - 1; i >= 0; i--) {
      final line = lines[i].trim();
      if (!keywordRegex.hasMatch(line)) continue;

      // Skip "kembalian" (change) and "diskon" (discount) lines
      if (RegExp(r'(?:kembalian|change|kembali|diskon|discount)', caseSensitive: false)
          .hasMatch(line)) continue;

      // Try Rp-prefixed number first
      var match = rpNumberRegex.firstMatch(line);
      if (match != null) {
        final parsed = _parseIndonesianNumber(match.group(1)!);
        if (parsed != null && parsed >= 100 && parsed < 100000000) return parsed;
      }

      // Try plain number at end of line
      match = plainNumberRegex.firstMatch(line);
      if (match != null) {
        final parsed = _parseIndonesianNumber(match.group(1)!);
        if (parsed != null && parsed >= 100 && parsed < 100000000) return parsed;
      }

      // Sometimes the number is on the next line
      if (i + 1 < lines.length) {
        final nextLine = lines[i + 1].trim();
        match = rpNumberRegex.firstMatch(nextLine);
        match ??= plainNumberRegex.firstMatch(nextLine);
        if (match != null) {
          final parsed = _parseIndonesianNumber(match.group(1)!);
          if (parsed != null && parsed >= 1000 && parsed < 100000000) return parsed;
        }
      }
    }
    return null;
  }

  /// Pass 3: Fallback — largest number >= 1000 in the full text
  double? _extractLargestNumber(String text) {
    final numberRegex = RegExp(r'\b([\d]+(?:[.,]\d{3})*(?:[.,]\d{1,2})?)\b');
    final matches = numberRegex.allMatches(text);

    double largest = 0;
    for (final match in matches) {
      final raw = match.group(1)!;
      // Skip strings that are too long without separators (like 16413520230802084636)
      if (raw.length > 8 && !raw.contains('.') && !raw.contains(',')) continue;

      final parsed = _parseIndonesianNumber(raw);
      // Skip ridiculously large numbers (e.g. >= 100 million) for a typical receipt
      if (parsed != null && parsed > largest && parsed < 100000000) {
        largest = parsed;
      }
    }

    return largest >= 1000 ? largest : null;
  }

  // ──────────────────────────────────────────────
  // INDONESIAN NUMBER PARSER
  // ──────────────────────────────────────────────

  /// Parse Indonesian-formatted numbers:
  /// - "26.500"     → 26500   (dot as thousands separator)
  /// - "26.500,00"  → 26500   (dot=thousands, comma=decimal)
  /// - "26,500"     → 26500   (comma as thousands if 3 digits follow)
  /// - "1.250.000"  → 1250000
  /// - "26500"      → 26500   (no separator)
  double? _parseIndonesianNumber(String input) {
    String s = input.trim();
    if (s.isEmpty) return null;

    // Prevent phone numbers (e.g. 0812...) from being parsed as large amounts
    if (s.startsWith('0') && s.length > 1 && !s.startsWith('0.') && !s.startsWith('0,')) {
      return null;
    }

    // Case 1: Has both dot and comma → determine which is thousands vs decimal
    if (s.contains('.') && s.contains(',')) {
      final lastDot = s.lastIndexOf('.');
      final lastComma = s.lastIndexOf(',');

      if (lastComma > lastDot) {
        // Format: 1.250.000,00 (dot=thousands, comma=decimal)
        s = s.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // Format: 1,250,000.00 (comma=thousands, dot=decimal) — rare in Indonesia
        s = s.replaceAll(',', '');
      }
    }
    // Case 2: Only dots
    else if (s.contains('.')) {
      final parts = s.split('.');
      final lastPart = parts.last;
      if (lastPart.length == 3 || parts.length > 2) {
        // "26.500" or "1.250.000" → dot is thousands separator
        s = s.replaceAll('.', '');
      }
      // else: "26.50" → dot is decimal (keep as-is)
    }
    // Case 3: Only commas
    else if (s.contains(',')) {
      final parts = s.split(',');
      final lastPart = parts.last;
      if (lastPart.length == 3 || parts.length > 2) {
        // "26,500" → comma is thousands separator
        s = s.replaceAll(',', '');
      } else {
        // "26,50" → comma is decimal
        s = s.replaceAll(',', '.');
      }
    }

    return double.tryParse(s);
  }

  // ──────────────────────────────────────────────
  // DATE EXTRACTION
  // ──────────────────────────────────────────────

  String _extractDate(String text) {
    // Try multiple date formats common in Indonesian receipts
    final patterns = [
      RegExp(r'(\d{2}/\d{2}/\d{4})'),           // 25/07/2026
      RegExp(r'(\d{2}-\d{2}-\d{4})'),           // 25-07-2026
      RegExp(r'(\d{4}/\d{2}/\d{2})'),           // 2026/07/25
      RegExp(r'(\d{4}-\d{2}-\d{2})'),           // 2026-07-25
      RegExp(r'(\d{1,2}\s+[a-zA-Z]{3,}\s+\d{4})', caseSensitive: false), // 31 Mar 2026, 12 Agustus 2023
      RegExp(r'(\d{1,2}\s+[-/]\s+\d{1,2}\s+[-/]\s+\d{4})'), // 25 - 07 - 2026
      RegExp(r'(\d{2}/\d{2}/\d{2})\b'),         // 25/07/26
      RegExp(r'(\d{2}-\d{2}-\d{2})\b'),         // 25-07-26
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) return match.group(0)!;
    }
    return 'Tanggal tidak terdeteksi';
  }

  void dispose() {
    textRecognizer.close();
  }
}
