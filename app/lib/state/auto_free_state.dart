// Auto (Free): the app picks the best free model across the connected
// providers and keeps it as the default. Only free models are ever picked:
// OpenRouter `:free` variants and Gemini's free-tier Flash models. Grok and
// the DeepSeek API have no free tier (paid per token), so they never enter
// Auto; a custom server's chat models count as free (the person's own box).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ui/providers/quick_connect.dart' show QuickProvider, bestModelId, isFreeModel, matchQuickProvider;
import 'models_state.dart';
import 'providers_state.dart';

const _autoFreeKey = 'auto_free_model';

/// Whether Auto (Free) is on. On by default once a key connects.
final autoFreeProvider = NotifierProvider<AutoFreeNotifier, bool>(AutoFreeNotifier.new);

class AutoFreeNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return true;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(_autoFreeKey);
    if (value != null && value != state) state = value;
  }

  Future<void> set(bool on) async {
    state = on;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoFreeKey, on);
  }
}

/// One free model Auto can use, best first.
typedef AutoCandidate = ({String providerId, String model, QuickProvider kind});

/// Every free model across the connected providers, best first: Gemini's
/// free Flash line, then OpenRouter's strong `:free` models, then a custom
/// server's chat models. Providers the engine reports unhealthy go last.
List<AutoCandidate> autoFreeCandidates(ProvidersSnapshot? snapshot) {
  if (snapshot == null) return const [];
  final out = <AutoCandidate>[];
  for (final kind in const [QuickProvider.gemini, QuickProvider.openrouter, QuickProvider.custom]) {
    final providers = kind == QuickProvider.custom
        ? [
            for (final p in snapshot.providers)
              if (matchQuickProvider(snapshot, QuickProvider.gemini)?.id != p.id &&
                  matchQuickProvider(snapshot, QuickProvider.openrouter)?.id != p.id &&
                  matchQuickProvider(snapshot, QuickProvider.grok)?.id != p.id &&
                  matchQuickProvider(snapshot, QuickProvider.deepseek)?.id != p.id)
                p,
          ]
        : [?matchQuickProvider(snapshot, kind)];
    for (final provider in providers) {
      if (!snapshot.keyStored(provider)) continue;
      final free = [
        for (final m in provider.models)
          if (isFreeModel(kind, m.id)) m.id,
      ];
      final best = bestModelId(kind, free);
      final ordered = [
        if (best != null) best,
        for (final id in free)
          if (id != best) id,
      ];
      for (final id in ordered) {
        out.add((providerId: provider.id, model: id, kind: kind));
      }
    }
  }
  final healthy = [
    for (final c in out)
      if (snapshot.healthOf(snapshot.byId(c.providerId)!) == ProviderHealth.ready) c,
  ];
  return [...healthy, for (final c in out) if (!healthy.contains(c)) c];
}

/// The model Auto uses now, or null when no free model is connected.
ModelSelection? autoFreePick(ProvidersSnapshot? snapshot) {
  final candidates = autoFreeCandidates(snapshot);
  if (candidates.isEmpty) return null;
  final first = candidates.first;
  return ModelSelection(provider: first.providerId, model: first.model);
}

/// The next Auto candidate after [current] (for fallback), or null.
ModelSelection? autoFreeNext(ProvidersSnapshot? snapshot, ModelSelection? current) {
  final candidates = autoFreeCandidates(snapshot);
  for (final c in candidates) {
    if (current == null || c.providerId != current.provider || c.model != current.model) {
      return ModelSelection(provider: c.providerId, model: c.model);
    }
  }
  return null;
}
