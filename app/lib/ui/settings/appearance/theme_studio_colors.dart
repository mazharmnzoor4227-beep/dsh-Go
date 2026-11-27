// The Theme Studio's full colour list: every colour a pack can override, for light and dark, with a HEX field
// and a picker per row.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../common/app_sheet.dart';
import '../../common/segmented_pill.dart';
import '../../theme/app_icons.dart';
import '../../theme/theme.dart';
import 'hue_slider.dart';
import 'theme_studio_controller.dart';
import 'theme_studio_controls.dart';

typedef _Token = ({String key, String zh, String en, String useZh, String useEn});

const List<(String zh, String en, List<_Token> tokens)> _colorGroups = [
  (
    'Backdrop & glow',
    'Backdrop & glow',
    [
      (key: 'backdropTop', zh: 'Backdrop top', en: 'Backdrop top', useZh: 'Top of the page gradient', useEn: 'Top of the page gradient'),
      (
        key: 'backdropBottom',
        zh: 'Backdrop bottom', en: 'Backdrop bottom',
        useZh: 'Bottom of the page gradient', useEn: 'Bottom of the page gradient',
      ),
      (key: 'glowPrimary', zh: 'Main glow', en: 'Main glow', useZh: 'The first glow in the backdrop', useEn: 'The first glow in the backdrop'),
      (key: 'glowSecondary', zh: 'Second glow', en: 'Second glow', useZh: 'The second glow in the backdrop', useEn: 'The second glow in the backdrop'),
      (key: 'patternInk', zh: 'Pattern', en: 'Pattern', useZh: 'Dots and lines of the backdrop pattern', useEn: 'Dots and lines of the backdrop pattern'),
    ],
  ),
  (
    'Surfaces & lines',
    'Surfaces & lines',
    [
      (key: 'surface', zh: 'Surface', en: 'Surface', useZh: 'Base colour of pages and panels', useEn: 'Base colour of pages and panels'),
      (key: 'cardFill', zh: 'Cards', en: 'Cards', useZh: 'Card fill; may be translucent', useEn: 'Card fill; may be translucent'),
      (
        key: 'chromeFill',
        zh: 'Top bar & composer', en: 'Top bar & composer',
        useZh: 'Fill of the top bar and composer layer', useEn: 'Fill of the top bar and composer layer',
      ),
      (key: 'sheetFill', zh: 'Sheets', en: 'Sheets', useZh: 'Panels that rise from the bottom', useEn: 'Panels that rise from the bottom'),
      (
        key: 'hairline',
        zh: 'Hairline', en: 'Hairline',
        useZh: 'Thin edge of cards, bars and sheets', useEn: 'Thin edge of cards, bars and sheets',
      ),
      (key: 'outline', zh: 'Outline', en: 'Outline', useZh: 'Stronger borders and dividers', useEn: 'Stronger borders and dividers'),
      (
        key: 'outlineVariant',
        zh: 'Soft outline', en: 'Soft outline',
        useZh: 'Softer borders and dividers', useEn: 'Softer borders and dividers',
      ),
    ],
  ),
  (
    'Text',
    'Text',
    [
      (key: 'onSurface', zh: 'Body text', en: 'Body text', useZh: 'Body text and titles', useEn: 'Body text and titles'),
      (key: 'onSurfaceVariant', zh: 'Secondary text', en: 'Secondary text', useZh: 'Descriptions and icons', useEn: 'Descriptions and icons'),
      (
        key: 'textTertiary',
        zh: 'Faint text', en: 'Faint text',
        useZh: 'Times, hints and other faint text', useEn: 'Times, hints and other faint text',
      ),
      (key: 'heading', zh: 'Reply headings', en: 'Reply headings', useZh: 'Headings inside replies', useEn: 'Headings inside replies'),
      (key: 'link', zh: 'Links', en: 'Links', useZh: 'Links inside replies', useEn: 'Links inside replies'),
    ],
  ),
  (
    'Accent',
    'Accent',
    [
      (key: 'primary', zh: 'Accent', en: 'Accent', useZh: 'Buttons, switches and selection', useEn: 'Buttons, switches and selection'),
      (key: 'onPrimary', zh: 'On accent', en: 'On accent', useZh: 'Text and icons on accent buttons', useEn: 'Text and icons on accent buttons'),
      (
        key: 'primaryContainer',
        zh: 'Accent tint', en: 'Accent tint',
        useZh: 'Tinted fill of selected items and tags', useEn: 'Tinted fill of selected items and tags',
      ),
      (
        key: 'onPrimaryContainer',
        zh: 'On accent tint', en: 'On accent tint',
        useZh: 'Text on the tinted fill', useEn: 'Text on the tinted fill',
      ),
      (
        key: 'rule',
        zh: 'Rule', en: 'Rule',
        useZh: 'Reply side rule, heading marker and similar lines', useEn: 'Reply side rule, heading marker and similar lines',
      ),
    ],
  ),
  (
    'Messages',
    'Messages',
    [
      (key: 'userBubble', zh: 'My bubble', en: 'My bubble', useZh: 'Fill of the messages you send', useEn: 'Fill of the messages you send'),
      (
        key: 'onUserBubble',
        zh: 'My bubble text', en: 'My bubble text',
        useZh: 'Text of the messages you send', useEn: 'Text of the messages you send',
      ),
      (
        key: 'userBubbleBorder',
        zh: 'My bubble border', en: 'My bubble border',
        useZh: 'Edge of the outlined bubble', useEn: 'Edge of the outlined bubble',
      ),
      (
        key: 'assistantBubble',
        zh: 'Reply card', en: 'Reply card',
        useZh: 'Fill of replies shown as cards', useEn: 'Fill of replies shown as cards',
      ),
      (key: 'onAssistantBubble', zh: 'Reply text', en: 'Reply text', useZh: 'Text of replies', useEn: 'Text of replies'),
      (
        key: 'assistantBorder',
        zh: 'Reply card border', en: 'Reply card border',
        useZh: 'Edge of card and quote replies', useEn: 'Edge of card and quote replies',
      ),
    ],
  ),
  (
    'Composer & send',
    'Composer & send',
    [
      (key: 'composerFill', zh: 'Composer fill', en: 'Composer fill', useZh: 'Fill of the composer', useEn: 'Fill of the composer'),
      (key: 'composerBorder', zh: 'Composer border', en: 'Composer border', useZh: 'Edge of the composer', useEn: 'Edge of the composer'),
      (key: 'sendButton', zh: 'Send button', en: 'Send button', useZh: 'Fill when a message can be sent', useEn: 'Fill when a message can be sent'),
      (key: 'onSendButton', zh: 'Send icon', en: 'Send icon', useZh: 'Arrow when a message can be sent', useEn: 'Arrow when a message can be sent'),
    ],
  ),
  (
    'Code',
    'Code',
    [
      (key: 'codeWellBg', zh: 'Code block', en: 'Code block', useZh: 'Fill of code blocks', useEn: 'Fill of code blocks'),
      (
        key: 'codeWellHeader',
        zh: 'Code header', en: 'Code header',
        useZh: 'The bar with the language name', useEn: 'The bar with the language name',
      ),
      (key: 'codeWellFg', zh: 'Code text', en: 'Code text', useZh: 'Text inside code blocks', useEn: 'Text inside code blocks'),
      (key: 'codeWellBorder', zh: 'Code border', en: 'Code border', useZh: 'Edge of code blocks', useEn: 'Edge of code blocks'),
      (
        key: 'inlineCodeBg',
        zh: 'Inline code', en: 'Inline code',
        useZh: 'Fill of code inside a sentence', useEn: 'Fill of code inside a sentence',
      ),
      (
        key: 'inlineCodeFg',
        zh: 'Inline code text', en: 'Inline code text',
        useZh: 'Text of code inside a sentence', useEn: 'Text of code inside a sentence',
      ),
      (
        key: 'syntaxKeyword',
        zh: 'Keywords', en: 'Keywords',
        useZh: 'Words like if, return, class', useEn: 'Words like if, return, class',
      ),
      (key: 'syntaxString', zh: 'Strings', en: 'Strings', useZh: 'Text inside quotes', useEn: 'Text inside quotes'),
      (key: 'syntaxNumber', zh: 'Numbers', en: 'Numbers', useZh: 'Numbers and constants', useEn: 'Numbers and constants'),
      (key: 'syntaxComment', zh: 'Comments', en: 'Comments', useZh: 'Notes written for people', useEn: 'Notes written for people'),
      (key: 'syntaxFunction', zh: 'Functions', en: 'Functions', useZh: 'Names of functions and methods', useEn: 'Names of functions and methods'),
      (key: 'syntaxType', zh: 'Types', en: 'Types', useZh: 'Names of classes and types', useEn: 'Names of classes and types'),
    ],
  ),
  (
    'Status',
    'Status',
    [
      (key: 'success', zh: 'Success', en: 'Success', useZh: 'Done and passed', useEn: 'Done and passed'),
      (key: 'warning', zh: 'Warning', en: 'Warning', useZh: 'Needs attention', useEn: 'Needs attention'),
      (key: 'danger', zh: 'Danger', en: 'Danger', useZh: 'Errors and deletion', useEn: 'Errors and deletion'),
      (key: 'info', zh: 'Info', en: 'Info', useZh: 'Neutral notices', useEn: 'Neutral notices'),
    ],
  ),
];

/// The name the colour list gives [key]; null for a key it has no name for.
String? studioColorName(String key, {required bool english}) {
  for (final (_, _, tokens) in _colorGroups) {
    for (final token in tokens) {
      if (token.key == key) return english ? token.en : token.zh;
    }
  }
  return null;
}

/// The highlighter's own colour for a syntax role.
const _syntaxScopes = {
  'syntaxKeyword': 'keyword',
  'syntaxString': 'string',
  'syntaxNumber': 'number',
  'syntaxComment': 'comment',
  'syntaxFunction': 'title',
  'syntaxType': 'type',
};

/// The colour [key] shows in [theme] when the pack leaves it alone, where that can be told from the theme.
Color? _defaultColor(String key, ThemeData theme, ThemePack pack) {
  final scheme = theme.colorScheme;
  final surfaces = theme.extension<DshSurfaces>()!;
  final colors = theme.extension<DshColors>()!;
  final style = theme.extension<DshThemeStyle>();
  final send = pack.components.sendButtonStyle;
  return switch (key) {
    'backdropTop' => surfaces.backdropTop,
    'backdropBottom' => surfaces.backdropBottom,
    'glowPrimary' => surfaces.glowPrimary,
    'glowSecondary' => surfaces.glowSecondary,
    'surface' => scheme.surface,
    'onSurface' || 'heading' || 'patternInk' => scheme.onSurface,
    'onSurfaceVariant' => scheme.onSurfaceVariant,
    'outline' => scheme.outline,
    'outlineVariant' || 'userBubbleBorder' || 'assistantBorder' => scheme.outlineVariant,
    'primary' || 'link' || 'rule' => scheme.primary,
    'onPrimary' => scheme.onPrimary,
    'primaryContainer' => scheme.primaryContainer,
    'onPrimaryContainer' => scheme.onPrimaryContainer,
    'userBubble' => surfaces.userBubble,
    'onUserBubble' => surfaces.onUserBubble,
    'assistantBubble' => style?.assistantBubble ?? surfaces.card.fill,
    'onAssistantBubble' => style?.onAssistantBubble ?? scheme.onSurface,
    'codeWellBg' => colors.codeWellBg,
    'codeWellHeader' => colors.codeWellHeader,
    'codeWellFg' => colors.codeWellFg,
    'codeWellBorder' => colors.codeWellBorder,
    'composerFill' || 'chromeFill' => surfaces.chrome.fill,
    'composerBorder' || 'hairline' => surfaces.chrome.hairline,
    'sendButton' => switch (send) {
      ThemeSendButtonStyle.ink => scheme.onSurface,
      ThemeSendButtonStyle.tonal => scheme.primaryContainer,
      ThemeSendButtonStyle.outlined => Colors.transparent,
      ThemeSendButtonStyle.primary => scheme.primary,
    },
    'onSendButton' => switch (send) {
      ThemeSendButtonStyle.ink => scheme.surface,
      ThemeSendButtonStyle.tonal => scheme.onPrimaryContainer,
      ThemeSendButtonStyle.outlined => scheme.primary,
      ThemeSendButtonStyle.primary => scheme.onPrimary,
    },
    'cardFill' => surfaces.card.fill,
    'sheetFill' => surfaces.sheet.fill,
    'textTertiary' => colors.textTertiary,
    'success' => colors.success,
    'warning' => colors.warning,
    'danger' => colors.danger,
    'info' => colors.info,
    'inlineCodeBg' => colors.codeWellBg,
    'inlineCodeFg' => colors.codeWellFg,
    _ => dshHighlightTheme(theme.brightness, surfaces.accent)[_syntaxScopes[key]]?.color,
  };
}

/// The draft as a theme for one brightness, colours only (no loaded fonts).
ThemeData studioThemeOf(ThemePack pack, {required bool dark}) {
  // Under its own ID the draft would pick up the special-cased accent of the built-in it started from.
  final draft = pack.copyWith(id: 'draft-preview');
  final accent = AppAccent.fromThemePack(draft);
  return dark ? buildDarkTheme(accent: accent, themePack: draft) : buildLightTheme(accent: accent, themePack: draft);
}

/// The colour [key] has in the draft: the pack's own, or else what [theme] falls back to.
Color? studioTokenColor(String key, ThemeData theme, ThemePack pack) {
  final overrides = theme.brightness == Brightness.dark ? pack.palette.dark : pack.palette.light;
  final own = overrides[key];
  return own != null ? Color(own) : _defaultColor(key, theme, pack);
}

class ThemeStudioColorsSheet extends StatefulWidget {
  const ThemeStudioColorsSheet({super.key, required this.controller, this.startDark = false});

  final ThemeStudioController controller;
  final bool startDark;

  @override
  State<ThemeStudioColorsSheet> createState() => _ThemeStudioColorsSheetState();
}

class _ThemeStudioColorsSheetState extends State<ThemeStudioColorsSheet> {
  late bool _dark = widget.startDark;

  Future<void> _pick(String key, Color from) async {
    final picked = await showStudioColorPicker(context, initial: from);
    if (picked != null) widget.controller.setColor(key, picked, dark: _dark);
  }

  @override
  Widget build(BuildContext context) {
    final english = AppLocale.isEnglish;
    final theme = Theme.of(context);
    final known = {
      for (final (_, _, tokens) in _colorGroups)
        for (final token in tokens) token.key,
    };
    // Tokens the model gains later still get a row, under their own key.
    final rest = [
      for (final key in ThemeColorOverrides.tokenKeys)
        if (!known.contains(key)) (key: key, zh: key, en: key, useZh: '', useEn: ''),
    ];
    return Column(
      children: [
        SheetHeader('All Colors'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: SegmentedPill<bool>(
            segments: [PillSegment(false, 'Light'), PillSegment(true, 'Dark')],
            selected: _dark,
            onChanged: (dark) => setState(() => _dark = dark),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Text(
            'Colours left empty follow the accent and material. The grey value is what is used now.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) {
              final pack = widget.controller.pack;
              final resolved = studioThemeOf(pack, dark: _dark);
              final overrides = _dark ? pack.palette.dark : pack.palette.light;
              final mode = _dark ? 'dark' : 'light';
              return ListView(
                padding: EdgeInsets.fromLTRB(16, 0, 8, 24 + MediaQuery.viewInsetsOf(context).bottom),
                children: [
                  for (final (zh, en, tokens) in [..._colorGroups, if (rest.isNotEmpty) ('Other', 'Other', rest)]) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 4),
                      child: Text(
                        english ? en : zh,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    for (final token in tokens)
                      _ColorRow(
                        key: ValueKey('theme-color-row-$mode-${token.key}'),
                        id: '$mode-${token.key}',
                        name: english ? token.en : token.zh,
                        use: english ? token.useEn : token.useZh,
                        value: overrides[token.key],
                        fallback: _defaultColor(token.key, resolved, pack),
                        onChanged: (argb) => widget.controller.setColor(token.key, argb, dark: _dark),
                        onPick: (from) => unawaited(_pick(token.key, from)),
                      ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    super.key,
    required this.id,
    required this.name,
    required this.use,
    required this.value,
    required this.fallback,
    required this.onChanged,
    required this.onPick,
  });

  final String id;
  final String name;
  final String use;
  final int? value;
  final Color? fallback;
  final ValueChanged<int?> onChanged;
  final ValueChanged<Color> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shown = value != null ? Color(value!) : fallback;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Pick $name',
            child: InkResponse(
              key: ValueKey('theme-color-swatch-$id'),
              radius: 22,
              onTap: () => onPick(shown ?? scheme.primary),
              child: SizedBox.square(
                dimension: 32,
                // A colour of the pack's own fills the disc; one that is only followed sits small inside the ring.
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: value != null ? shown : null,
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: value == null && shown != null
                      ? Center(
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: shown, shape: BoxShape.circle),
                            child: const SizedBox.square(dimension: 14),
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.bodyMedium),
                if (use.isNotEmpty)
                  Text(use, style: theme.textTheme.bodySmall?.copyWith(color: DshColors.of(context).textTertiary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 128,
            child: StudioHexField(
              key: ValueKey('theme-color-$id'),
              value: value,
              onChanged: onChanged,
              hint: fallback == null ? '#RRGGBB' : formatThemeHexColor(fallback!.toARGB32()),
              dense: true,
            ),
          ),
          SizedBox.square(
            dimension: 40,
            child: value == null
                ? null
                : IconButton(
                    key: ValueKey('theme-color-clear-$id'),
                    tooltip: 'Follow the default',
                    icon: Icon(AppIcons.clear, size: 18, color: scheme.onSurfaceVariant),
                    onPressed: () => onChanged(null),
                  ),
          ),
        ],
      ),
    );
  }
}

/// A small picker over hue, lightness, chroma and opacity. Resolves to the ARGB picked, or null when dismissed.
/// [opacity] off is for a colour that has to stay solid.
Future<int?> showStudioColorPicker(BuildContext context, {required Color initial, bool opacity = true}) =>
    showAppSheet<int>(
      context,
      isScrollControlled: true,
      builder: (_) => _ColorPicker(initial: initial, opacity: opacity),
    );

class _ColorPicker extends StatefulWidget {
  const _ColorPicker({required this.initial, required this.opacity});

  final Color initial;
  final bool opacity;

  @override
  State<_ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<_ColorPicker> {
  late Oklch _color = Oklch.fromColor(widget.initial);
  late double _alpha = widget.opacity ? widget.initial.a : 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _color.toColor(alpha: _alpha);
    final ink = ThemeData.estimateBrightnessForColor(color) == Brightness.dark && _alpha > 0.5
        ? Colors.white
        : theme.colorScheme.onSurface;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetHeader('Pick a Color'),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DecoratedBox(
                  decoration: ShapeDecoration(
                    color: color,
                    shape: SquircleBorder(
                      borderRadius: AppShape.radiusMd,
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                  ),
                  child: SizedBox(
                    height: 56,
                    child: Center(
                      child: Text(formatThemeHexColor(color.toARGB32()), style: AppType.mono(size: 14, color: ink)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                HueSlider(
                  hue: _color.h,
                  brightness: theme.brightness,
                  onChanged: (hue) => setState(() => _color = _color.copyWith(h: hue)),
                ),
                const SizedBox(height: 6),
                StudioSlider(
                  label: 'Lightness',
                  value: _color.l.clamp(0.0, 1.0).toDouble(),
                  min: 0,
                  max: 1,
                  step: 0.01,
                  fallback: _color.l.clamp(0.0, 1.0).toDouble(),
                  format: StudioSlider.percent,
                  onChanged: (v) => setState(() => _color = _color.copyWith(l: v)),
                ),
                StudioSlider(
                  label: 'Vividness',
                  value: _color.c.clamp(0.0, 0.32).toDouble(),
                  min: 0,
                  max: 0.32,
                  step: 0.01,
                  fallback: _color.c.clamp(0.0, 0.32).toDouble(),
                  format: (v) => StudioSlider.percent(v / 0.32),
                  onChanged: (v) => setState(() => _color = _color.copyWith(c: v)),
                ),
                if (widget.opacity)
                  StudioSlider(
                    label: 'Opacity',
                    value: _alpha,
                    min: 0,
                    max: 1,
                    step: 0.01,
                    fallback: _alpha,
                    format: StudioSlider.percent,
                    onChanged: (v) => setState(() => _alpha = v ?? 1),
                  ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(color.toARGB32()),
                  child: Text('Use This Color'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
