/// Helpers for reading the gzipped golden fixtures generated from caltib.
///
/// The fixtures live in `test/golden/` and are produced by
/// `tool/golden/gen_golden.py`; see `test/golden/README.md`.
library;

import 'dart:convert';
import 'dart:io';

/// Directory holding the golden fixtures, relative to the package root
/// (the working directory `dart test` runs in).
final Directory goldenDir = Directory('test/golden');

String _readGzText(String fileName) {
  final bytes = File('${goldenDir.path}/$fileName').readAsBytesSync();
  return utf8.decode(gzip.decode(bytes));
}

/// Returns the header line of a gzipped CSV fixture.
String goldenHeader(String fileName) =>
    const LineSplitter().convert(_readGzText(fileName)).first;

/// Returns the data rows (header excluded) of a gzipped CSV fixture, each row
/// split on commas.
List<List<String>> readGoldenCsv(String fileName) {
  final lines = const LineSplitter().convert(_readGzText(fileName));
  return [
    for (final line in lines.skip(1))
      if (line.isNotEmpty) line.split(','),
  ];
}

/// Returns the parsed `meta.json` written by the generator.
Map<String, dynamic> readGoldenMeta() =>
    jsonDecode(File('${goldenDir.path}/meta.json').readAsStringSync())
        as Map<String, dynamic>;
