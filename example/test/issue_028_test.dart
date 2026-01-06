import 'dart:io';

import 'package:image_size_getter/file_input.dart';
import 'package:image_size_getter/image_size_getter.dart';
import 'package:test/test.dart';

void main() {
  group('PNG with trailing bytes test', () {
    late List<File> pngFiles;

    setUpAll(() {
      final dir = Directory('asset/issue28');
      pngFiles = dir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.png'))
          .toList();

      expect(pngFiles.isNotEmpty, true,
          reason: 'No PNG files found in asset/issue28/');

      print('Found ${pngFiles.length} PNG files to test');
    });

    test('all PNG files should work with non-standard mode', () {
      final nonStandardDecoder = PngDecoder(isStandardPng: false);
      ImageSizeGetter.registerDecoder(nonStandardDecoder);

      for (final file in pngFiles) {
        print('\nTesting: ${file.path}');

        final fileInput = FileInput(file);
        final result = ImageSizeGetter.getSizeResult(
          fileInput,
        );

        print('  Size: ${result.size.width}x${result.size.height}');
        print('  Decoded by: ${result.decoder.decoderName}');

        expect(result.size.width, greaterThan(0));
        expect(result.size.height, greaterThan(0));
        expect(result.decoder.decoderName, 'non-standard-png');
      }
    });

    test('PNG with trailing bytes should fail in standard mode', () {
      final standardDecoder = PngDecoder(isStandardPng: true);
      ImageSizeGetter.registerDecoder(standardDecoder);
      // Find the bug PNG (the one with trailing bytes)
      final bugPng = pngFiles.firstWhere(
            (f) => f.path.contains('bug') || f.path.contains('trailing'),
        orElse: () => pngFiles.last, // Assume last one is the bug
      );

      print('\nTesting bug PNG with standard mode: ${bugPng.path}');

      // Standard mode should reject it
      expect(
            () => ImageSizeGetter.getSizeResult(
          FileInput(bugPng),
        ),
        throwsA(isA<UnsupportedError>()),
        reason: 'Standard mode should reject PNG with trailing bytes',
      );

      print('  ✓ Correctly rejected by standard mode');
    });

    test('same PNG should succeed with non-standard mode', () {
      final nonStandardDecoder = PngDecoder(isStandardPng: false);
      ImageSizeGetter.registerDecoder(nonStandardDecoder);
      // Find the bug PNG
      final bugPng = pngFiles.firstWhere(
            (f) => f.path.contains('bug') || f.path.contains('trailing'),
        orElse: () => pngFiles.last,
      );

      print('\nTesting bug PNG with non-standard mode: ${bugPng.path}');

      // Non-standard mode should accept it
      final result = ImageSizeGetter.getSizeResult(
        FileInput(bugPng)
      );

      print('  Size: ${result.size.width}x${result.size.height}');
      print('  ✓ Successfully decoded');

      expect(result.size.width, greaterThan(0));
      expect(result.size.height, greaterThan(0));
    });

    test('default PngDecoder should use non-standard mode', () {
      // When no parameter is passed, should default to non-standard (lenient)
      final defaultDecoder = PngDecoder();
      ImageSizeGetter.registerDecoder(defaultDecoder);
      for (final file in pngFiles) {
        final result = ImageSizeGetter.getSizeResult(
          FileInput(file),
        );

        expect(result.size.width, greaterThan(0));
        expect(result.decoder.decoderName, 'non-standard-png');
      }
    });

    test('verify decoder names', () {
      final standard = PngDecoder(isStandardPng: true);
      final nonStandard = PngDecoder(isStandardPng: false);

      expect(standard.decoderName, 'png');
      expect(nonStandard.decoderName, 'non-standard-png');
    });
  });
}