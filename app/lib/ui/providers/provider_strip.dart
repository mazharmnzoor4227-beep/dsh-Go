// Provider strip on the chat screen: Gemini, Grok, OpenRouter, DeepSeek and
// Custom are always visible above the composer. One tap on a connected
// provider makes its best free/standard model the active one; one tap on an
// unconnected one opens a single key field — paste the key, tap Connect, and
// models are fetched, the best free one is chosen, and the chat runs on it.

import 'dart:async';

import 'package:dsh_client/dsh_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/chat_state.dart';
import '../../state/composer_insert.dart';
import '../../state/engine_settings_state.dart';
import '../../state/model_defaults_state.dart';
import '../../state/models_state.dart';
import '../../state/providers_state.dart';
import '../../state/read_list_identity.dart';
import '../common/app_sheet.dart';

enum QuickProvider { gemini, grok, openrouter, deepseek, antigravity, custom }

extension QuickProviderInfo on QuickProvider {
  String get label => switch (this) {
    QuickProvider.gemini => 'Gemini',
    QuickProvider.grok => 'Grok',
    QuickProvider.openrouter => 'OpenRouter',
    QuickProvider.deepseek => 'DeepSeek',
    QuickProvider.antigravity => 'Antigravity',
    QuickProvider.custom => 'Custom',
  };

  String get baseUrl => switch (this) {
    QuickProvider.gemini => 'https://generativelanguage.googleapis.com/v1beta/openai/',
    QuickProvider.grok => 'https://api.x.ai/v1',
    QuickProvider.openrouter => 'https://openrouter.ai/api/v1',
    QuickProvider.deepseek => 'https://api.deepseek.com',
    QuickProvider.antigravity => '',
    QuickProvider.custom => '',
  };

  String get hostHint => switch (this) {
    QuickProvider.gemini => 'generativelanguage.googleapis.com',
    QuickProvider.grok => 'api.x.ai',
    QuickProvider.openrouter => 'openrouter.ai',
    QuickProvider.deepseek => 'api.deepseek.com',
    QuickProvider.antigravity => '',
    QuickProvider.custom => '',
  };
}

/// The configured route for [kind], matched by endpoint host.
CustomProvider? matchQuickProvider(ProvidersSnapshot? snapshot, QuickProvider kind) {
  if (snapshot == null) return null;
  for (final p in snapshot.providers) {
    if (kind == QuickProvider.custom) continue;
    if (p.host.toLowerCase().contains(kind.hostHint)) return p;
  }
  return null;
}

bool _isChatModel(String id) {
  final lower = id.toLowerCase();
  return !lower.contains('embedding') &&
      !lower.contains('tts') &&
      !lower.contains('image') &&
      !lower.contains('imagen') &&
      !lower.contains('veo') &&
      !lower.contains('whisper') &&
      !lower.contains('audio');
}

/// Best free/standard model id for [kind] out of [ids]; null when none.
String? bestModelId(QuickProvider kind, List<String> ids) {
  final chat = [for (final id in ids) if (_isChatModel(id)) id];
  if (chat.isEmpty) return ids.isEmpty ? null : ids.first;
  String? pick(bool Function(String) test) {
    for (final id in chat) {
      if (test(id.toLowerCase())) return id;
    }
    return null;
  }

  return switch (kind) {
    QuickProvider.openrouter =>
      pick((id) => id.endsWith(':free') && id.contains('deepseek')) ??
          pick((id) => id.endsWith(':free') && id.contains('llama-3.3-70b')) ??
          pick((id) => id.endsWith(':free') && id.contains('gemini')) ??
          pick((id) => id.endsWith(':free') && id.contains('qwen')) ??
          pick((id) => id.endsWith(':free')) ??
          chat.first,
    QuickProvider.gemini =>
      pick((id) => id == 'gemini-2.5-flash') ??
          pick((id) => id.contains('gemini-2.5-flash') && !id.contains('lite') && !id.contains('preview')) ??
          pick((id) => id.contains('gemini-2.0-flash')) ??
          pick((id) => id.contains('flash')) ??
          chat.first,
    QuickProvider.grok =>
      pick((id) => id.contains('grok-4-fast')) ??
          pick((id) => id.contains('grok-3-mini')) ??
          pick((id) => id.contains('grok-4')) ??
          pick((id) => id.contains('grok-3')) ??
          chat.first,
    QuickProvider.deepseek =>
      pick((id) => id == 'deepseek-chat') ?? pick((id) => id.contains('deepseek-chat')) ?? chat.first,
    QuickProvider.antigravity => chat.first,
    QuickProvider.custom => chat.first,
  };
}

/// Models to store for [kind]: free ones first for OpenRouter, best first,
/// capped so the picker stays readable.
List<ProviderModelSpec> rankedSpecs(QuickProvider kind, List<DiscoveredModel> models) {
  final specs = [for (final m in models) m.toSpec()];
  final best = bestModelId(kind, [for (final m in models) m.id]);
  specs.sort((a, b) {
    if (a.id == best) return -1;
    if (b.id == best) return 1;
    if (kind == QuickProvider.openrouter) {
      final af = a.id.endsWith(':free'), bf = b.id.endsWith(':free');
      if (af != bf) return af ? -1 : 1;
    }
    return 0;
  });
  return specs.take(50).toList();
}

class ProviderStrip extends ConsumerWidget {
  const ProviderStrip({super.key, this.sessionId});

  final String? sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(customProvidersProvider).value;
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final kind in QuickProvider.values) ...[
              _chip(context, ref, kind, snapshot, colors),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, WidgetRef ref, QuickProvider kind, ProvidersSnapshot? snapshot, ColorScheme colors) {
    final provider = matchQuickProvider(snapshot, kind);
    final connected = provider != null && snapshot!.keyStored(provider) && provider.models.isNotEmpty;
    return Material(
      color: connected ? colors.primary : colors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => unawaited(_tap(context, ref, kind, provider, connected)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(connected ? Icons.check_circle : Icons.key, size: 15, color: connected ? colors.onPrimary : colors.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                kind.label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: connected ? colors.onPrimary : colors.onSurface),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _tap(BuildContext context, WidgetRef ref, QuickProvider kind, CustomProvider? provider, bool connected) async {
    if (kind == QuickProvider.antigravity) {
      await showAppSheet<void>(context, builder: (_) => _AntigravitySheet(sessionId: sessionId));
      return;
    }
    if (connected && provider != null) {
      final best = bestModelId(kind, [for (final m in provider.models) m.id]);
      if (best != null) await _activate(ref, provider.id, best);
      return;
    }
    await showAppSheet<void>(
      context,
      builder: (_) => _QuickConnectSheet(kind: kind, existing: provider, onConnected: (id, model) => _activate(ref, id, model)),
    );
  }

  /// Makes [model] of [providerId] the default for new chats and, when a
  /// chat is open, its current model too.
  Future<void> _activate(WidgetRef ref, String providerId, String model) async {
    final selection = ModelSelection(provider: providerId, model: model);
    final id = sessionId;
    if (id != null) {
      await ref.read(chatProvider(id).notifier).setModel(selection);
    }
    final settings = ref.read(engineSettingsProvider).value;
    if (settings == null || !canEditDefaultModel(settings)) return;
    if (!isValidModelSelection(ref.read(currentModelCatalogProvider), selection)) return;
    final editor = ref.read(engineSettingsProvider.notifier).edit(settings);
    if (!editor.active || ref.read(readListLiveConnectionProvider) == null) return;
    await editor.write(defaultModelSettingsNs, defaultModelOps(selection), fields: defaultModelSelectionFields);
  }
}

class _QuickConnectSheet extends ConsumerStatefulWidget {
  const _QuickConnectSheet({required this.kind, required this.existing, required this.onConnected});

  final QuickProvider kind;
  final CustomProvider? existing;
  final Future<void> Function(String providerId, String model) onConnected;

  @override
  ConsumerState<_QuickConnectSheet> createState() => _QuickConnectSheetState();
}

class _QuickConnectSheetState extends ConsumerState<_QuickConnectSheet> {
  final _key = TextEditingController();
  late final _url = TextEditingController(text: widget.existing?.baseUrl ?? widget.kind.baseUrl);
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _key.dispose();
    _url.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final key = _key.text.trim();
    final url = _url.text.trim();
    if (key.isEmpty || url.isEmpty) {
      setState(() => _error = widget.kind == QuickProvider.custom ? 'Enter the server URL and API key.' : 'Paste your API key first.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final actions = ref.read(providerActionsProvider);
      final result = await actions.discover(api: ProviderApi.openaiCompletions, baseUrl: url, apiKey: key, existingId: widget.existing?.id);
      if (result.models.isEmpty) throw const ProviderFailure('No models found for this key.');
      final specs = rankedSpecs(widget.kind, result.models);
      final id = await actions.save(
        ProviderDraft(name: widget.kind.label, api: ProviderApi.openaiCompletions, baseUrl: result.baseUrl, apiKey: key, models: specs),
        existing: widget.existing,
      );
      final best = bestModelId(widget.kind, [for (final m in result.models) m.id]) ?? specs.first.id;
      await widget.onConnected(id, best);
      if (mounted) Navigator.of(context).pop();
    } on ProviderFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } catch (error) {
      if (mounted) setState(() => _error = describeProviderError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Connect ${widget.kind.label}', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: colors.onSurface)),
          const SizedBox(height: 6),
          Text(
            'Paste your API key. Models connect automatically and the best free one is selected.',
            style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          if (widget.kind == QuickProvider.custom) ...[
            TextField(controller: _url, decoration: const InputDecoration(labelText: 'Server URL')),
            const SizedBox(height: 10),
          ],
          TextField(controller: _key, obscureText: true, decoration: const InputDecoration(labelText: 'API key')),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: TextStyle(fontSize: 13, color: colors.error)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : () => unawaited(_connect()),
            child: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Connect'),
          ),
        ],
      ),
    );
  }
}

/// Antigravity connection: installs Google's agy CLI inside the app's Linux
/// runtime and walks through Google sign-in. The install runs through the
/// bundled antigravity-cli skill in chat, so the sign-in link appears there.
class _AntigravitySheet extends ConsumerWidget {
  const _AntigravitySheet({required this.sessionId});

  final String? sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Connect Antigravity', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: colors.onSurface)),
          const SizedBox(height: 8),
          Text(
            '1. Tap Install & sign in below.\n2. The app installs the Antigravity CLI (agy) inside its Linux runtime.\n3. A Google sign-in link appears in chat — open it and sign in with your Google account.\n4. After sign-in, ask in chat to run Antigravity tasks.',
            style: TextStyle(fontSize: 13.5, height: 1.5, color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              ref.read(composerInsertProvider.notifier).request(ComposerInsert.skill('antigravity-cli', sessionId: sessionId));
              Navigator.of(context).pop();
            },
            child: const Text('Install & sign in'),
          ),
        ],
      ),
    );
  }
}
