import 'dart:io';

import 'package:test/test.dart';

/// The public library must expose only the documented API, not the
/// fixed-point constants and specs the engines use internally. Checked by
/// running the analyzer on a probe that references the internals through the
/// public import: each reference must be an error.
void main() {
  test(
    'internal constants and specs are not exported',
    () async {
      final probe = File('test/_public_api_probe.dart');
      probe.writeAsStringSync('''
import 'package:kharag_calendar/kharag_calendar.dart';

void main() {
  print(meanScale);
  print(sunTurn);
  print(moonTurn);
  print(phugpaSpec);
  print(bhutanSpec);
  print(mongolSpec);
  TraditionSpec? spec;
  LeapLabeling? labeling;
  print([spec, labeling, Tradition.phugpa.spec]);
}
''');
      try {
        final result = await Process.run(Platform.resolvedExecutable, [
          'analyze',
          '--no-fatal-warnings',
          probe.path,
        ]);
        final errors = '${result.stdout}'
            .split('\n')
            .where((l) => l.trimLeft().startsWith('error'))
            .toList();
        for (final name in [
          'meanScale',
          'sunTurn',
          'moonTurn',
          'phugpaSpec',
          'bhutanSpec',
          'mongolSpec',
          'TraditionSpec',
          'LeapLabeling',
          "'spec'",
        ]) {
          expect(
            errors.any((l) => l.contains(name)),
            isTrue,
            reason:
                '$name is reachable from the public library\n'
                '${result.stdout}',
          );
        }
      } finally {
        if (probe.existsSync()) probe.deleteSync();
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
