import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import '../api/api_constants.dart';

class PaletteProvider extends ChangeNotifier {
  PaletteGenerator? _palette;

  Color get dominantColor =>
      _palette?.dominantColor?.color ?? Colors.grey.shade800;

  Color get vibrantColor => _palette?.vibrantColor?.color ?? Colors.redAccent;

  Color get lightVibrantColor =>
      _palette?.lightVibrantColor?.color ?? Colors.red;

  Color get darkVibrantColor =>
      _palette?.darkVibrantColor?.color ?? Colors.red.shade900;

  Color get mutedColor => _palette?.mutedColor?.color ?? Colors.grey.shade600;

  Color get lightMutedColor =>
      _palette?.lightMutedColor?.color ?? Colors.grey.shade400;

  Future<void> generatePalette(String posterPath) async {
    final imageProvider =
        CachedNetworkImageProvider('${ApiConstants.imageBaseUrl}$posterPath');
    try {
      _palette = await PaletteGenerator.fromImageProvider(imageProvider,
          size: const Size(100, 150));
      notifyListeners();
    } catch (e) {
      // Xử lý lỗi nếu không thể tạo palette
    }
  }

  void clearPalette() {
    _palette = null;
  }
}
