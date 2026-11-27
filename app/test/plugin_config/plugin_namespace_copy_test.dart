import 'package:dsh_app/l10n/l10n.dart';
import 'package:dsh_app/ui/engine_settings/namespace_copy.dart';
import 'package:dsh_app/ui/engine_settings/schema_fields.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => AppLocale.use(AppLocale.en));
  tearDown(() => AppLocale.use(AppLocale.en));

  test('English-only build: no Chinese namespace copy remains', () {
    final han = RegExp(r'[\u3400-\u9fff]');
    for (final title in namespaceTitles.values) {
      expect(han.hasMatch(title), isFalse, reason: title);
    }
    for (final fields in namespaceCopy.values) {
      for (final copy in fields.values) {
        expect(han.hasMatch(copy.label ?? ''), isFalse, reason: copy.label);
        for (final choice in copy.choices.values) {
          expect(han.hasMatch(choice), isFalse, reason: choice);
        }
      }
    }
    // Plugin namespaces that only had Chinese copy now fall back to the
    // schema's own English text instead of showing Chinese.
    expect(namespaceCopy['imagegen'], isNull);
    expect(copyOf('imagegen', ['promptModel']).label, isNull);
    expect(namespaceCopy['ui-chat'], isNotNull);
  });
}
