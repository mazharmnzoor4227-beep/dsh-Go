import 'package:dsh_app/companion/companion_voice_source.dart';
import 'package:dsh_app/companion/kokoro_voice.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('kokoroLangFor', () {
    test('Devanagari reads as Hindi', () {
      expect(kokoroLangFor('नमस्ते, कैसे हो?'), 'hi');
    });

    test('Latin text reads as English', () {
      expect(kokoroLangFor('Hello, how are you?'), 'en-us');
    });

    test('Urdu script is left to the phone voice', () {
      expect(kokoroLangFor('السلام علیکم'), isNull);
    });
  });

  test('Kokoro voice choice survives saving', () {
    const settings = CompanionVoiceSettings(source: CompanionVoiceSource.kokoro, kokoroVoice: 33);
    final restored = CompanionVoiceSettings.fromPlain(settings.plain());
    expect(restored.source, CompanionVoiceSource.kokoro);
    expect(restored.kokoroVoice, 33);
    expect(restored.configured, isTrue);
  });
}
