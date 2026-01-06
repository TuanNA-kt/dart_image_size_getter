import 'package:image_size_getter/image_size_getter.dart';

/// {@template image_size_getter.PngDecoder}
///
/// [PngDecoder] is a class for decoding PNG image.
///
/// {@endtemplate}
class PngDecoder extends BaseDecoder with SimpleTypeValidator {
  /// {@macro image_size_getter.PngDecoder}

  const PngDecoder({
    this.isStandardPng = false, // Default to lenient
  });

  final bool isStandardPng;

  @override
  String get decoderName => isStandardPng ? 'png' : 'non-standard-png';


  @override
  List<String> get supportedExtensions => List.unmodifiable(['png']);

  @override
  Size getSize(ImageInput input) {
    final widthList = input.getRange(0x10, 0x14);
    final heightList = input.getRange(0x14, 0x18);

    final width = convertRadix16ToInt(widthList);
    final height = convertRadix16ToInt(heightList);

    return Size(width, height);
  }

  @override
  Future<Size> getSizeAsync(AsyncImageInput input) async {
    final widthList = await input.getRange(0x10, 0x14);
    final heightList = await input.getRange(0x14, 0x18);
    final width = convertRadix16ToInt(widthList);
    final height = convertRadix16ToInt(heightList);
    return Size(width, height);
  }

  @override
  SimpleFileHeaderAndFooter get simpleFileHeaderAndFooter =>
      isStandardPng ? _StandardPngHeaders() : _NonStandardPngHeaders();
}

class _StandardPngHeaders with SimpleFileHeaderAndFooter {
  static const sig = [
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
  ];

  static const iend = [
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82
  ];

  @override
  List<int> get endBytes => iend;

  @override
  List<int> get startBytes => sig;
}

/// Non-standard PNG Info
///
/// Some PNG files have trailing bytes after the IEND chunk.
///
/// These files are technically invalid per PNG specification, but are
/// commonly produced by various tools and should be supported for
/// interoperability with other image libraries.
class _NonStandardPngHeaders with SimpleFileHeaderAndFooter {
  static const sig = [
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
  ];

  static const iend = <int>[];

  @override
  List<int> get endBytes => iend;

  @override
  List<int> get startBytes => sig;
}
