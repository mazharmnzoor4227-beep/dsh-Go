import 'package:dsh_app/state/auto_free_state.dart';
import 'package:dsh_app/state/providers_state.dart';
import 'package:dsh_client/dsh_client.dart';
import 'package:flutter_test/flutter_test.dart';

CustomProvider _provider(String id, String host, List<String> models) => CustomProvider(
  id: id,
  displayName: id,
  baseUrl: 'https://$host/v1',
  apiKeyEnv: 'KEY_$id',
  models: [for (final m in models) ProviderModelSpec(id: m, name: m)],
);

ProvidersSnapshot _snapshot() => ProvidersSnapshot(
  supported: true,
  providers: [
    _provider('gemini', 'generativelanguage.googleapis.com', ['gemini-2.5-flash', 'gemini-2.5-flash-lite']),
    _provider('openrouter', 'openrouter.ai', ['deepseek/deepseek-chat-v3-0324:free', 'meta-llama/llama-3.3-70b-instruct:free']),
    _provider('deepseek', 'api.deepseek.com', ['deepseek-chat']),
  ],
  credentials: const {
    'KEY_gemini': CredentialStatus(configured: true, writable: true),
    'KEY_openrouter': CredentialStatus(configured: true, writable: true),
    'KEY_deepseek': CredentialStatus(configured: true, writable: true),
  },
);

void main() {
  group('isRetryableModelFailure', () {
    test('balance, quota and 503 failures retry on another free model', () {
      expect(isRetryableModelFailure(const LlmFailure(message: 'Insufficient balance', code: 'INSUFFICIENT_BALANCE')), isTrue);
      expect(isRetryableModelFailure(const LlmFailure(message: 'payment required', code: 'X', status: 402)), isTrue);
      expect(isRetryableModelFailure(const LlmFailure(message: 'quota exceeded', code: 'RESOURCE_EXHAUSTED', status: 429)), isTrue);
      expect(
        isRetryableModelFailure(
          const LlmFailure(message: 'This model is currently experiencing high demand', code: 'UNAVAILABLE', status: 503),
        ),
        isTrue,
      );
      expect(isRetryableModelFailure(const LlmFailure(message: 'overloaded', code: 'X', status: 529)), isTrue);
    });

    test('request errors do not retry', () {
      expect(isRetryableModelFailure(const LlmFailure(message: 'bad request', code: 'INVALID', status: 400)), isFalse);
      expect(isRetryableModelFailure(const LlmFailure(message: 'invalid api key', code: 'UNAUTHORIZED', status: 401)), isFalse);
      expect(isRetryableModelFailure(null), isFalse);
    });
  });

  group('autoFreeFallbackChain', () {
    test('skips the failed model and never offers paid DeepSeek', () {
      final chain = autoFreeFallbackChain(_snapshot(), const ModelSelection(provider: 'gemini', model: 'gemini-2.5-flash'), {});
      expect(chain, isNotEmpty);
      expect(chain.any((c) => c.provider == 'deepseek'), isFalse);
      expect(chain.any((c) => c.provider == 'gemini' && c.model == 'gemini-2.5-flash'), isFalse);
      expect(chain.first.provider, 'gemini');
    });

    test('tried candidates are skipped and the chain ends', () {
      final snapshot = _snapshot();
      final tried = <String>{};
      var current = autoFreePick(snapshot);
      var steps = 0;
      while (true) {
        final chain = autoFreeFallbackChain(snapshot, current, tried);
        if (chain.isEmpty) break;
        current = chain.first;
        tried.add('${current.provider}|${current.model}');
        steps++;
        expect(steps, lessThan(20));
      }
      // Every free candidate was reachable exactly once, then it stops.
      expect(steps, autoFreeCandidates(snapshot).length - 1);
    });
  });
}
