import 'package:dsh_app/state/chat_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldAutoResume', () {
    test('interrupted turns resume, at most twice', () {
      expect(shouldAutoResume('interrupted', 0), isTrue);
      expect(shouldAutoResume('interrupted', 1), isTrue);
      expect(shouldAutoResume('interrupted', 2), isFalse);
      expect(shouldAutoResume('interrupted', 3), isFalse);
    });

    test('other endings never resume', () {
      expect(shouldAutoResume('error', 0), isFalse);
      expect(shouldAutoResume('aborted', 0), isFalse);
      expect(shouldAutoResume('completed', 0), isFalse);
    });
  });
}
