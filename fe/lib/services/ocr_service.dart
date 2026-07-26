import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/ocr_result.dart';

class OCRService {
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final _imagePicker = ImagePicker();

  Future<File?> pickImage() async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    return pickedFile != null ? File(pickedFile.path) : null;
  }

  Future<OCRResult?> processImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

    String text = recognizedText.text;
    final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();

    double? totalAmount = _extractTotal(text);
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

  String _extractMerchant(List<String> lines) {
    for (var line in lines) {
      if (_isMerchantLine(line)) {
        return line.trim();
      }
    }
    return '';
  }

  bool _isMerchantLine(String line) {
    final trimmed = line.trim();
    if (trimmed.length < 3 || trimmed.length > 50) return false;
    if (RegExp(r'\d').hasMatch(trimmed)) return false;
    if (RegExp(r'(?:total|amount|bayar|grand|tanggal|tgl|date|\d{2}/\d{2})', caseSensitive: false).hasMatch(trimmed)) {
      return false;
    }
    return true;
  }

  List<Map<String, dynamic>> _extractItems(List<String> lines) {
    final items = <Map<String, dynamic>>[];
    for (var line in lines) {
      final totalMatch = RegExp(r'(\d+[\d,.]*)\s*$').firstMatch(line);
      if (totalMatch == null) continue;
      final priceStr = totalMatch.group(1)!.replaceAll('.', '').replaceAll(',', '.');
      final price = double.tryParse(priceStr);
      if (price == null || price <= 0) continue;
      if (RegExp(r'(?:total|amount|grand|bayar|diskon|subtotal)', caseSensitive: false).hasMatch(line)) {
        continue;
      }
      final name = line.replaceAll(totalMatch.group(0)!, '').trim();
      if (name.isEmpty) continue;
      items.add({'name': name, 'price': price});
    }
    return items;
  }

  double? _extractTotal(String text) {
    final regex = RegExp(
      r'(?:Total|Total\s*Rp\s*|Grand Total|Amount|Bayar|Total:\s*)\s*([\d,.]+)',
      caseSensitive: false,
    );
    final match = regex.firstMatch(text);
    if (match != null) {
      String value = match.group(1)!.replaceAll('.', '').replaceAll(',', '.');
      return double.tryParse(value);
    }
    return null;
  }

  String _extractDate(String text) {
    final regex = RegExp(r'(\d{2}/\d{2}/\d{4}|\d{2}-\d{2}-\d{4})');
    final match = regex.firstMatch(text);
    return match?.group(0) ?? 'Tanggal tidak terdeteksi';
  }

  void dispose() {
    textRecognizer.close();
  }
}