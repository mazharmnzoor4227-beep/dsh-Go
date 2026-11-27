// The Theme Studio's groups. Each shows the handful of choices most themes need and folds the rest of its part
// of the pack behind 「更多选项」, so every field can be reached without the sheet opening as a wall of knobs.

import 'dart:async';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../../common/app_sheet.dart';
import '../../common/capsule_chip.dart';
import '../../theme/app_icons.dart';
import '../../theme/theme.dart';
import 'hue_slider.dart';
import 'theme_studio_colors.dart';
import 'theme_studio_controller.dart';
import 'theme_studio_controls.dart';

String _t(String zh, String en) => studioText(zh, en);

String? _blankToNull(String text) => text.trim().isEmpty ? null : text;

abstract class _Group extends StatelessWidget {
  const _Group({super.key, required this.c, required this.open, required this.onToggle});

  final ThemeStudioController c;
  final bool open;
  final VoidCallback onToggle;
}

class StudioInfoGroup extends _Group {
  const StudioInfoGroup({super.key, required super.c, required super.open, required super.onToggle});

  static List<String> _readTags(String text) => [
    for (final tag in text.split(RegExp('[,，、]')))
      if (tag.trim().isNotEmpty) tag.trim(),
  ];

  @override
  Widget build(BuildContext context) {
    final p = c.pack;
    return StudioGroup(
      id: 'info',
      title: 'Basics',
      open: open,
      onToggle: onToggle,
      basics: [
        StudioField.text(
          key: const ValueKey('theme-studio-name'),
          value: p.name,
          onChanged: c.setName,
          label: 'Theme name',
          hint: 'e.g. Warm Paper',
        ),
        StudioField.text(
          key: const ValueKey('theme-studio-id'),
          value: p.id,
          onChanged: (text) => c.update(c.pack.copyWith(id: text)),
          label: 'Theme ID (lower-case letters, digits, hyphens)',
          hint: 'warm-paper',
        ),
        StudioField.text(
          key: const ValueKey('theme-studio-description'),
          value: p.description,
          onChanged: (text) => c.update(c.pack.copyWith(description: text)),
          label: 'Summary (optional)',
        ),
      ],
      more: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: StudioField.text(
                value: p.titleZh ?? '',
                onChanged: (text) => c.setMeta(titleZh: () => _blankToNull(text)),
                label: 'Chinese name',
                hint: 'Defaults to the theme name',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StudioField.text(
                value: p.titleEn ?? '',
                onChanged: (text) => c.setMeta(titleEn: () => _blankToNull(text)),
                label: 'English name',
                hint: 'Defaults to the theme name',
              ),
            ),
          ],
        ),
        StudioField<List<String>>(
          value: p.tags,
          read: _readTags,
          show: (tags) => tags.join(', '),
          same: listEquals,
          onChanged: (tags) => c.update(c.pack.copyWith(tags: tags)),
          label: 'Tags (comma separated, up to 8)',
        ),
        StudioField.text(
          value: p.author ?? '',
          onChanged: (text) => c.setMeta(author: () => _blankToNull(text)),
          label: 'Author',
        ),
        StudioField.text(
          value: p.license ?? '',
          onChanged: (text) => c.setMeta(license: () => _blankToNull(text)),
          label: 'License',
          hint: 'CC-BY-4.0',
        ),
        StudioField.text(
          value: p.source ?? '',
          onChanged: (text) => c.setMeta(source: () => _blankToNull(text)),
          label: 'Source link',
          hint: 'https://',
        ),
      ],
    );
  }
}

class StudioColorGroup extends _Group {
  const StudioColorGroup({
    super.key,
    required super.c,
    required super.open,
    required super.onToggle,
    required this.previewDark,
  });

  final bool previewDark;

  static const _seeds = <(int, String, String, double)>[
    (0xFFA14732, 'Terracotta', 'Terracotta', 74),
    (0xFF2B6A58, 'Celadon', 'Celadon', 162),
    (0xFF4B67B4, 'Mist Blue', 'Mist Blue', 260),
    (0xFF0D736A, 'Matrix Teal', 'Matrix Teal', 192),
    (0xFF9A5B1F, 'Amber', 'Amber', 52),
    (0xFF5F7A55, 'Moss', 'Moss', 140),
    (0xFF726291, 'Dusk', 'Dusk', 295),
    (0xFFB85A7C, 'Sakura', 'Sakura', 342),
    (0xFF4E525B, 'Graphite', 'Graphite', 262),
  ];

  /// What [token] looks like in the draft now, set or not.
  Color _now(String token, {bool dark = false}) =>
      studioTokenColor(token, studioThemeOf(c.pack, dark: dark), c.pack) ?? Color(c.pack.palette.seed);

  Future<void> _pick(BuildContext context, Color from, ValueChanged<int> apply, {bool opacity = true}) async {
    final picked = await showStudioColorPicker(context, initial: from, opacity: opacity);
    if (picked != null) apply(picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = c.pack.palette;
    final changed = ThemeColorOverrides.tokenKeys
        .where((key) => palette.light[key] != null || palette.dark[key] != null)
        .length;
    final hue = palette.tintHue;
    return StudioGroup(
      id: 'colors',
      title: 'Colors',
      open: open,
      onToggle: onToggle,
      basics: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (rgb, zh, en, tint) in _seeds)
              CapsuleChoiceChip(
                label: _t(zh, en),
                selected: palette.seed == rgb,
                onSelected: () => c.setSeed(rgb, tintHue: tint),
              ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: StudioHexField(
                key: const ValueKey('theme-studio-seed-hex'),
                value: palette.seed,
                // The accent cannot be empty: clearing the field leaves it as it was.
                onChanged: (argb) {
                  if (argb != null) c.setSeed(argb);
                },
                label: 'Custom accent',
                onPick: () => unawaited(_pick(context, Color(palette.seed), c.setSeed, opacity: false)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StudioHexField(
                key: const ValueKey('theme-studio-bubble-hex'),
                value: palette.light.userBubble,
                onChanged: c.setUserBubble,
                label: 'My bubble (optional)',
                hint: '#ECE8E2',
                onPick: () => unawaited(_pick(context, _now('userBubble'), c.setUserBubble)),
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: StudioHexField(
                key: const ValueKey('theme-studio-light-bg-hex'),
                value: palette.light.backdropTop,
                onChanged: (argb) => c.setBackdropColor(argb, dark: false),
                label: 'Light page (optional)',
                hint: '#F7F4EC',
                onPick: () =>
                    unawaited(_pick(context, _now('backdropTop'), (argb) => c.setBackdropColor(argb, dark: false))),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StudioHexField(
                key: const ValueKey('theme-studio-dark-bg-hex'),
                value: palette.dark.backdropTop,
                onChanged: (argb) => c.setBackdropColor(argb, dark: true),
                label: 'Dark page (optional)',
                hint: '#181614',
                onPick: () => unawaited(
                  _pick(context, _now('backdropTop', dark: true), (argb) => c.setBackdropColor(argb, dark: true)),
                ),
              ),
            ),
          ],
        ),
        StudioChoice<double>(
          label: 'Backdrop glow',
          items: [(0.0, 'None'), (0.45, 'Soft'), (1.0, 'Full')],
          value: palette.glowOpacity,
          onChanged: (v) => c.palette((p) => p.copyWith(glowOpacity: v)),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            key: const ValueKey('theme-studio-all-colors'),
            icon: const Icon(AppIcons.color, size: 16),
            label: Text(
              changed == 0 ? 'All colors' : 'All colors · $changed changed',
            ),
            onPressed: () => unawaited(
              showAppSheet<void>(
                context,
                heightFactor: 0.92,
                builder: (_) => ThemeStudioColorsSheet(controller: c, startDark: previewDark),
              ),
            ),
          ),
        ),
      ],
      more: [
        StudioHexField(
          value: palette.seedDark,
          onChanged: (argb) => c.palette((p) => p.copyWith(seedDark: () => argb)),
          label: 'Accent in dark mode (derived when empty)',
          onPick: () => unawaited(
            _pick(
              context,
              _now('primary', dark: true),
              (argb) => c.palette((p) => p.copyWith(seedDark: () => argb)),
              opacity: false,
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 30,
              child: Row(
                children: [
                  Expanded(
                    child: Text('Tint of backgrounds and text', style: theme.textTheme.bodyMedium),
                  ),
                  Text(
                    hue == null ? 'Follows the accent' : '${hue.round()}°',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  if (hue != null)
                    TextButton(
                      onPressed: () => c.palette((p) => p.copyWith(tintHue: () => null)),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text('Follow the accent'),
                    ),
                ],
              ),
            ),
            HueSlider(
              hue: hue ?? Oklch.fromColor(Color(palette.seed)).h,
              brightness: theme.brightness,
              onChanged: (h) => c.palette((p) => p.copyWith(tintHue: () => h.roundToDouble())),
            ),
          ],
        ),
        StudioSlider(
          label: 'Tint strength',
          value: palette.tintChroma,
          min: 0,
          max: 2,
          fallback: 1,
          format: StudioSlider.times,
          onChanged: (v) => c.palette((p) => p.copyWith(tintChroma: v)),
        ),
        StudioSlider(
          label: 'Glow strength',
          value: palette.glowOpacity,
          min: 0,
          max: 1,
          fallback: 1,
          format: StudioSlider.percent,
          onChanged: (v) => c.palette((p) => p.copyWith(glowOpacity: v)),
        ),
      ],
    );
  }
}

class StudioSurfaceGroup extends _Group {
  const StudioSurfaceGroup({
    super.key,
    required super.c,
    required super.open,
    required super.onToggle,
    required this.resolved,
  });

  /// The draft as a theme: where an untouched tuning value is read from.
  final ThemeData resolved;

  @override
  Widget build(BuildContext context) {
    final s = c.pack.surfaces;
    final hasImage = s.backdropImage != null;
    final glass = resolved.extension<DshSurfaces>()!;
    Widget tune(
      String label,
      double? value,
      double max,
      double effective,
      ThemeSurfaceSpec Function(double? v) write, {
      double step = 0.05,
      String Function(double)? format,
    }) => StudioSlider(
      label: label,
      value: value,
      min: 0,
      max: max,
      effective: effective,
      follows: 'Follows material',
      step: step,
      format: format,
      onChanged: (v) => c.surfaces((_) => write(v)),
    );
    return StudioGroup(
      id: 'surfaces',
      title: 'Material & backdrop',
      open: open,
      onToggle: onToggle,
      basics: [
        StudioChoice<ThemeSurfacePreset>(
          label: 'Material',
          items: [
            (ThemeSurfacePreset.glass, 'Frosted glass'),
            (ThemeSurfacePreset.paper, 'Solid paper'),
            (ThemeSurfacePreset.flat, 'Flat'),
            (ThemeSurfacePreset.outlined, 'Outlined'),
          ],
          value: s.preset,
          onChanged: c.setPreset,
        ),
        StudioAssetRow(
          title: 'Backdrop',
          pickLabel: 'Pick a backdrop (PNG / WebP / GIF)',
          fileName: s.backdropImage,
          missing: c.isMissing(s.backdropImage),
          onPick: () => unawaited(c.pickImage(ThemeImageSlot.backdrop)),
          onClear: () => c.setImage(ThemeImageSlot.backdrop, null),
        ),
        if (hasImage) ...[
          StudioSlider(
            label: 'Backdrop opacity',
            value: s.backdropOpacity,
            min: 0,
            max: 1,
            fallback: 0.18,
            step: 0.01,
            format: StudioSlider.percent,
            onChanged: (v) => c.surfaces((s) => s.copyWith(backdropOpacity: v)),
          ),
          StudioSwitch(
            label: 'Tile the image',
            value: s.backdropRepeat,
            onChanged: (v) => c.surfaces((s) => s.copyWith(backdropRepeat: v)),
          ),
        ],
      ],
      more: [
        if (hasImage) ...[
          StudioSlider(
            label: 'Backdrop blur',
            value: s.backdropBlur,
            min: 0,
            max: 40,
            fallback: 0,
            step: 1,
            onChanged: (v) => c.surfaces((s) => s.copyWith(backdropBlur: v)),
          ),
          StudioChoice<ThemeBackdropAlign>(
            label: 'Backdrop alignment',
            items: [
              (ThemeBackdropAlign.center, 'Center'),
              (ThemeBackdropAlign.top, 'Top'),
              (ThemeBackdropAlign.bottom, 'Bottom'),
            ],
            value: s.backdropAlign,
            onChanged: (v) => c.surfaces((s) => s.copyWith(backdropAlign: v)),
          ),
          StudioSwitch(
            label: 'Keep animated images playing',
            value: s.backdropAnimate,
            onChanged: (v) => c.surfaces((s) => s.copyWith(backdropAnimate: v)),
          ),
        ],
        StudioChoice<ThemeBackdropPattern>(
          label: 'Backdrop pattern',
          items: [
            (ThemeBackdropPattern.none, 'None'),
            (ThemeBackdropPattern.dots, 'Dots'),
            (ThemeBackdropPattern.grid, 'Grid'),
            (ThemeBackdropPattern.lines, 'Lines'),
            (ThemeBackdropPattern.diagonal, 'Diagonal'),
            (ThemeBackdropPattern.grain, 'Grain'),
          ],
          value: s.pattern,
          onChanged: (v) => c.surfaces((s) => s.copyWith(pattern: v)),
        ),
        if (s.pattern != ThemeBackdropPattern.none) ...[
          StudioSlider(
            label: 'Pattern strength',
            value: s.patternOpacity,
            min: 0,
            max: 1,
            fallback: 0.06,
            step: 0.01,
            format: StudioSlider.percent,
            onChanged: (v) => c.surfaces((s) => s.copyWith(patternOpacity: v)),
          ),
          StudioSlider(
            label: 'Pattern spacing',
            value: s.patternScale,
            min: 0.5,
            max: 3,
            fallback: 1,
            step: 0.1,
            format: StudioSlider.times,
            onChanged: (v) => c.surfaces((s) => s.copyWith(patternScale: v)),
          ),
        ],
        StudioChoice<ThemeGlowLayout>(
          label: 'Glow position',
          items: [
            (ThemeGlowLayout.corners, 'Corners'),
            (ThemeGlowLayout.top, 'Top'),
            (ThemeGlowLayout.bottom, 'Bottom'),
            (ThemeGlowLayout.center, 'Center'),
          ],
          value: s.glowLayout,
          onChanged: (v) => c.surfaces((s) => s.copyWith(glowLayout: v)),
        ),
        StudioCaption('Material tuning (untouched values follow the material)'),
        tune(
          'Top bar blur',
          s.chromeBlur,
          40,
          glass.chrome.blurSigma,
          (v) => s.copyWith(chromeBlur: () => v),
          step: 1,
        ),
        tune(
          'Sheet blur',
          s.sheetBlur,
          40,
          glass.sheet.blurSigma,
          (v) => s.copyWith(sheetBlur: () => v),
          step: 1,
        ),
        tune(
          'Card opacity',
          s.cardOpacity,
          1,
          glass.card.fill.a,
          (v) => s.copyWith(cardOpacity: () => v),
          format: StudioSlider.percent,
        ),
        tune(
          'Pill opacity',
          s.pillOpacity,
          1,
          glass.pill.fill.a,
          (v) => s.copyWith(pillOpacity: () => v),
          format: StudioSlider.percent,
        ),
        tune(
          'Edge width',
          s.hairlineWidth,
          3,
          glass.chrome.hairlineWidth,
          (v) => s.copyWith(hairlineWidth: () => v),
          step: 0.1,
        ),
        // The last two scale what the material has: untouched is all of it.
        tune(
          'Edge highlight',
          s.rimOpacity,
          1,
          1,
          (v) => s.copyWith(rimOpacity: () => v),
          format: StudioSlider.percent,
        ),
        tune(
          'Shadow',
          s.shadowOpacity,
          1,
          1,
          (v) => s.copyWith(shadowOpacity: () => v),
          format: StudioSlider.percent,
        ),
      ],
    );
  }
}

/// One font role: a built-in face, a font file already in the pack, or a new file.
class _FontChoice extends StatelessWidget {
  const _FontChoice({required this.c, required this.role, required this.label});

  final ThemeStudioController c;
  final ThemeFontRole role;
  final String label;

  @override
  Widget build(BuildContext context) {
    final code = role == ThemeFontRole.code;
    final current = c.fontOf(role);
    // 'mono', 'monospace' and 'JetBrainsMono' are all accepted everywhere; each role offers the ones it tells apart.
    final shown = code
        ? (current == 'mono' ? 'monospace' : current)
        : (current == 'monospace' || current == 'JetBrainsMono' ? 'mono' : current);
    final builtIn = code
        ? [('JetBrainsMono', 'JetBrains Mono'), ('monospace', 'System mono')]
        : [('system', 'System'), ('serif', 'Serif'), ('mono', 'Mono')];
    final files = {...c.fontFiles, if (ThemeTypographySpec.isCustomFontAsset(current)) current};
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StudioCaption(label),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final (value, name) in builtIn)
              CapsuleChoiceChip(label: name, selected: shown == value, onSelected: () => c.chooseFont(role, value)),
            for (final file in files)
              CapsuleChoiceChip(
                label: file,
                icon: AppIcons.files,
                selected: current == file,
                onSelected: () => c.chooseFont(role, file),
              ),
            ActionChip(
              key: ValueKey('theme-studio-font-${role.name}'),
              avatar: const Icon(AppIcons.add, size: 14),
              label: Text('Pick a font file'),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: const StadiumBorder(),
              onPressed: () => unawaited(c.pickFont(role)),
            ),
          ],
        ),
        if (ThemeTypographySpec.isCustomFontAsset(current) && c.isMissing(current)) StudioMissingNote(current),
      ],
    );
  }
}

class StudioTypographyGroup extends _Group {
  const StudioTypographyGroup({super.key, required super.c, required super.open, required super.onToggle});

  @override
  Widget build(BuildContext context) {
    final t = c.pack.typography;
    return StudioGroup(
      id: 'typography',
      title: 'Fonts',
      open: open,
      onToggle: onToggle,
      basics: [
        _FontChoice(
          c: c,
          role: ThemeFontRole.reading,
          label: 'Reply font (.ttf / .otf work too)',
        ),
        StudioChoice<double>(
          label: 'Reply line spacing',
          items: [(1.45, 'Compact'), (1.55, 'Standard'), (1.68, 'Open')],
          value: t.readingLineHeight,
          onChanged: (v) => c.typography((t) => t.copyWith(readingLineHeight: v)),
        ),
      ],
      more: [
        _FontChoice(c: c, role: ThemeFontRole.ui, label: 'Interface font'),
        _FontChoice(c: c, role: ThemeFontRole.heading, label: 'Heading font'),
        _FontChoice(c: c, role: ThemeFontRole.code, label: 'Code font'),
        StudioSwitch(
          label: 'Use the reply font for replies',
          value: c.pack.components.useReadingFontForReply,
          onChanged: (v) => c.components((p) => p.copyWith(useReadingFontForReply: v)),
        ),
        StudioSlider(
          label: 'Reply size',
          value: t.readingScale,
          min: 0.85,
          max: 1.25,
          fallback: 1,
          step: 0.01,
          format: StudioSlider.times,
          onChanged: (v) => c.typography((t) => t.copyWith(readingScale: v)),
        ),
        StudioSlider(
          label: 'Reply line spacing (exact)',
          value: t.readingLineHeight,
          min: 1.2,
          max: 2,
          fallback: 1.55,
          step: 0.01,
          onChanged: (v) => c.typography((t) => t.copyWith(readingLineHeight: v)),
        ),
        StudioSlider(
          label: 'Reply letter spacing',
          value: t.readingLetterSpacing,
          min: -0.5,
          max: 2,
          fallback: 0,
          step: 0.1,
          onChanged: (v) => c.typography((t) => t.copyWith(readingLetterSpacing: v)),
        ),
        StudioSlider(
          label: 'Heading size',
          value: t.headingScale,
          min: 0.85,
          max: 1.35,
          fallback: 1,
          step: 0.01,
          format: StudioSlider.times,
          onChanged: (v) => c.typography((t) => t.copyWith(headingScale: v)),
        ),
        StudioSlider(
          label: 'Heading letter spacing',
          value: t.headingLetterSpacing,
          min: -1,
          max: 4,
          fallback: 0,
          step: 0.1,
          onChanged: (v) => c.typography((t) => t.copyWith(headingLetterSpacing: v)),
        ),
        StudioChoice<int?>(
          label: 'Heading weight',
          items: [
            (null, 'Default'),
            for (final weight in const [300, 400, 500, 600, 700, 800, 900]) (weight, '$weight'),
          ],
          value: t.headingWeight,
          onChanged: (v) => c.typography((t) => t.copyWith(headingWeight: () => v)),
        ),
        StudioSlider(
          label: 'Code size',
          value: t.codeScale,
          min: 0.85,
          max: 1.2,
          fallback: 1,
          step: 0.01,
          format: StudioSlider.times,
          onChanged: (v) => c.typography((t) => t.copyWith(codeScale: v)),
        ),
      ],
    );
  }
}

class StudioShapeGroup extends _Group {
  const StudioShapeGroup({
    super.key,
    required super.c,
    required super.open,
    required super.onToggle,
    required this.resolved,
  });

  /// The draft as a theme: where a radius that follows the overall roundness is read from.
  final ThemeData resolved;

  @override
  Widget build(BuildContext context) {
    final s = c.pack.shapes;
    final style = resolved.extension<DshThemeStyle>()!;
    Widget radius(String label, double? value, double effective, ThemeShapeSpec Function(double? v) write) =>
        StudioSlider(
          label: label,
          value: value,
          min: 0,
          max: 36,
          step: 1,
          effective: effective,
          follows: 'Follows overall',
          onChanged: (v) => c.shapes((_) => write(v)),
        );
    return StudioGroup(
      id: 'shapes',
      title: 'Shape & spacing',
      open: open,
      onToggle: onToggle,
      basics: [
        StudioChoice<double>(
          label: 'Corners',
          items: [
            (0.28, 'Sharp'),
            (0.85, 'Gentle'),
            (1.0, 'Standard'),
            (1.32, 'Soft'),
          ],
          value: s.cornerScale,
          onChanged: (v) => c.shapes((s) => s.copyWith(cornerScale: v)),
        ),
        StudioChoice<double>(
          label: 'Density',
          items: [(16.0, 'Compact'), (24.0, 'Standard'), (30.0, 'Airy')],
          value: s.turnGap,
          // One choice sets all three gaps; each has its own slider under 「更多选项」.
          onChanged: (v) => c.shapes(
            (s) => s.copyWith(
              turnGap: v,
              inTurnGap: v <= 18 ? 6.0 : (v >= 28 ? 10.0 : 8.0),
              gutter: v <= 18 ? 14.0 : 16.0,
            ),
          ),
        ),
      ],
      more: [
        StudioChoice<ThemeCornerStyle>(
          label: 'Corner style',
          items: [
            (ThemeCornerStyle.squircle, 'Smooth'),
            (ThemeCornerStyle.round, 'Round'),
            (ThemeCornerStyle.bevel, 'Bevel'),
          ],
          value: s.cornerStyle,
          onChanged: (v) => c.shapes((s) => s.copyWith(cornerStyle: v)),
        ),
        StudioChoice<ThemeBubbleCorners>(
          label: 'Bubble corners',
          items: [
            (ThemeBubbleCorners.uniform, 'Even'),
            (ThemeBubbleCorners.tail, 'Tail'),
            (ThemeBubbleCorners.leaf, 'Leaf'),
          ],
          value: s.bubbleCorners,
          onChanged: (v) => c.shapes((s) => s.copyWith(bubbleCorners: v)),
        ),
        StudioSlider(
          label: 'Overall roundness',
          value: s.cornerScale,
          min: 0,
          max: 1.6,
          fallback: 1,
          step: 0.01,
          format: StudioSlider.times,
          onChanged: (v) => c.shapes((s) => s.copyWith(cornerScale: v)),
        ),
        radius(
          'Bubble radius',
          s.bubbleRadius,
          style.bubbleRadius,
          (v) => s.copyWith(bubbleRadius: () => v),
        ),
        radius('Card radius', s.cardRadius, style.cardRadius, (v) => s.copyWith(cardRadius: () => v)),
        radius(
          'Code block radius',
          s.codeRadius,
          style.codeRadius,
          (v) => s.copyWith(codeRadius: () => v),
        ),
        radius(
          'Composer radius',
          s.composerRadius,
          style.composerRadius,
          (v) => s.copyWith(composerRadius: () => v),
        ),
        StudioSlider(
          label: 'Bubble side padding',
          value: s.bubblePadH,
          min: 10,
          max: 24,
          fallback: 16,
          step: 1,
          onChanged: (v) => c.shapes((s) => s.copyWith(bubblePadH: v)),
        ),
        StudioSlider(
          label: 'Bubble top and bottom padding',
          value: s.bubblePadV,
          min: 6,
          max: 16,
          fallback: 8,
          step: 1,
          onChanged: (v) => c.shapes((s) => s.copyWith(bubblePadV: v)),
        ),
        StudioSlider(
          label: 'Border width',
          value: s.borderWidth,
          min: 0,
          max: 2.5,
          fallback: 0.5,
          step: 0.1,
          onChanged: (v) => c.shapes((s) => s.copyWith(borderWidth: v)),
        ),
        StudioSlider(
          label: 'Between turns',
          value: s.turnGap,
          min: 12,
          max: 40,
          fallback: 24,
          step: 1,
          onChanged: (v) => c.shapes((s) => s.copyWith(turnGap: v)),
        ),
        StudioSlider(
          label: 'Within a turn',
          value: s.inTurnGap,
          min: 4,
          max: 20,
          fallback: 8,
          step: 1,
          onChanged: (v) => c.shapes((s) => s.copyWith(inTurnGap: v)),
        ),
        StudioSlider(
          label: 'Side margin',
          value: s.gutter,
          min: 10,
          max: 28,
          fallback: 16,
          step: 1,
          onChanged: (v) => c.shapes((s) => s.copyWith(gutter: v)),
        ),
      ],
    );
  }
}

class StudioComponentGroup extends _Group {
  const StudioComponentGroup({super.key, required super.c, required super.open, required super.onToggle});

  @override
  Widget build(BuildContext context) {
    final p = c.pack.components;
    return StudioGroup(
      id: 'components',
      title: 'Components',
      open: open,
      onToggle: onToggle,
      basics: [
        StudioChoice<ThemeHeaderStyle>(
          label: 'Top bar',
          items: [
            (ThemeHeaderStyle.glass, 'Glass'),
            (ThemeHeaderStyle.ghost, 'Ghost'),
            (ThemeHeaderStyle.outlined, 'Outlined'),
            (ThemeHeaderStyle.minimal, 'Minimal'),
          ],
          value: p.headerStyle,
          onChanged: (v) => c.components((p) => p.copyWith(headerStyle: v)),
        ),
        StudioChoice<ThemeComposerStyle>(
          label: 'Composer',
          items: [
            (ThemeComposerStyle.floatingGlass, 'Glass'),
            (ThemeComposerStyle.solidPaper, 'Solid paper'),
            (ThemeComposerStyle.outlined, 'Outlined'),
          ],
          value: p.composerStyle,
          onChanged: (v) => c.components((p) => p.copyWith(composerStyle: v)),
        ),
        StudioChoice<ThemeSendButtonStyle>(
          label: 'Send button',
          items: [
            (ThemeSendButtonStyle.primary, 'Accent'),
            (ThemeSendButtonStyle.ink, 'Ink'),
            (ThemeSendButtonStyle.tonal, 'Tonal'),
            (ThemeSendButtonStyle.outlined, 'Outlined'),
          ],
          value: p.sendButtonStyle,
          onChanged: (v) => c.components((p) => p.copyWith(sendButtonStyle: v)),
        ),
        StudioChoice<ThemeUserBubbleStyle>(
          label: 'My messages',
          items: [
            (ThemeUserBubbleStyle.soft, 'Soft'),
            (ThemeUserBubbleStyle.outlined, 'Outlined'),
            (ThemeUserBubbleStyle.accent, 'Accent'),
            (ThemeUserBubbleStyle.minimal, 'Side rule'),
          ],
          value: p.userBubbleStyle,
          onChanged: (v) => c.components((p) => p.copyWith(userBubbleStyle: v)),
        ),
        StudioChoice<ThemeAssistantStyle>(
          label: 'Replies',
          items: [
            (ThemeAssistantStyle.plain, 'Plain'),
            (ThemeAssistantStyle.card, 'Card'),
            (ThemeAssistantStyle.leftRule, 'Side rule'),
            (ThemeAssistantStyle.quote, 'Quote'),
          ],
          value: p.assistantStyle,
          onChanged: (v) => c.components((p) => p.copyWith(assistantStyle: v)),
        ),
        StudioChoice<ThemeCodeBlockStyle>(
          label: 'Code blocks',
          items: [
            (ThemeCodeBlockStyle.well, 'Well'),
            (ThemeCodeBlockStyle.outlined, 'Outlined'),
            (ThemeCodeBlockStyle.card, 'Card'),
          ],
          value: p.codeBlockStyle,
          onChanged: (v) => c.components((p) => p.copyWith(codeBlockStyle: v)),
        ),
      ],
      more: [
        StudioChoice<ThemeSendButtonShape>(
          label: 'Send button shape',
          items: [
            (ThemeSendButtonShape.circle, 'Circle'),
            (ThemeSendButtonShape.squircle, 'Rounded'),
            (ThemeSendButtonShape.square, 'Square'),
          ],
          value: p.sendButtonShape,
          onChanged: (v) => c.components((p) => p.copyWith(sendButtonShape: v)),
        ),
        StudioChoice<ThemeCodeHeaderStyle>(
          label: 'Code block header',
          items: [
            (ThemeCodeHeaderStyle.bar, 'Filled'),
            (ThemeCodeHeaderStyle.plain, 'Text only'),
          ],
          value: p.codeHeaderStyle,
          onChanged: (v) => c.components((p) => p.copyWith(codeHeaderStyle: v)),
        ),
        StudioChoice<ThemeTurnDivider>(
          label: 'Divider between turns',
          items: [
            (ThemeTurnDivider.none, 'None'),
            (ThemeTurnDivider.hairline, 'Hairline'),
            (ThemeTurnDivider.dashed, 'Dashed'),
            (ThemeTurnDivider.dots, 'Dots'),
          ],
          value: p.turnDivider,
          onChanged: (v) => c.components((p) => p.copyWith(turnDivider: v)),
        ),
        StudioChoice<ThemeHeadingStyle>(
          label: 'Headings in replies',
          items: [
            (ThemeHeadingStyle.plain, 'Plain'),
            (ThemeHeadingStyle.accent, 'Coloured'),
            (ThemeHeadingStyle.underline, 'Underlined'),
            (ThemeHeadingStyle.marker, 'Marker'),
          ],
          value: p.headingStyle,
          onChanged: (v) => c.components((p) => p.copyWith(headingStyle: v)),
        ),
        StudioChoice<ThemeBulletStyle>(
          label: 'List bullets',
          items: [
            (ThemeBulletStyle.dot, 'Dot •'),
            (ThemeBulletStyle.dash, 'Dash –'),
            (ThemeBulletStyle.diamond, 'Diamond ◆'),
            (ThemeBulletStyle.arrow, 'Arrow ›'),
            (ThemeBulletStyle.square, 'Square ▪'),
          ],
          value: p.bulletStyle,
          onChanged: (v) => c.components((p) => p.copyWith(bulletStyle: v)),
        ),
        StudioChoice<ThemeHeaderTitleFont>(
          label: 'Top bar title font',
          items: [
            (ThemeHeaderTitleFont.ui, 'Interface'),
            (ThemeHeaderTitleFont.heading, 'Heading'),
            (ThemeHeaderTitleFont.code, 'Code'),
          ],
          value: p.headerTitleFont,
          onChanged: (v) => c.components((p) => p.copyWith(headerTitleFont: v)),
        ),
        StudioLocalizedText(
          label: 'My label',
          value: p.userLabel,
          maxLength: 16,
          onChanged: (v) => c.components((p) => p.copyWith(userLabel: () => v)),
        ),
        StudioLocalizedText(
          label: 'Assistant label',
          value: p.assistantLabel,
          maxLength: 16,
          onChanged: (v) => c.components((p) => p.copyWith(assistantLabel: () => v)),
        ),
        StudioLocalizedText(
          label: 'Composer hint',
          value: p.composerHint,
          maxLength: 30,
          onChanged: (v) => c.components((p) => p.copyWith(composerHint: () => v)),
        ),
        StudioAssetRow(
          title: 'Assistant avatar',
          pickLabel: 'Pick an assistant avatar',
          fileName: p.assistantAvatar,
          missing: c.isMissing(p.assistantAvatar),
          onPick: () => unawaited(c.pickImage(ThemeImageSlot.assistantAvatar)),
          onClear: () => c.setImage(ThemeImageSlot.assistantAvatar, null),
        ),
        StudioAssetRow(
          title: 'My avatar',
          pickLabel: 'Pick my avatar',
          fileName: p.userAvatar,
          missing: c.isMissing(p.userAvatar),
          onPick: () => unawaited(c.pickImage(ThemeImageSlot.userAvatar)),
          onClear: () => c.setImage(ThemeImageSlot.userAvatar, null),
        ),
      ],
    );
  }
}

class StudioEmptyStateGroup extends _Group {
  const StudioEmptyStateGroup({super.key, required super.c, required super.open, required super.onToggle});

  @override
  Widget build(BuildContext context) {
    final e = c.pack.emptyState;
    final drawsGlyph = e.heroStyle == ThemeHeroStyle.glyph || e.heroStyle == ThemeHeroStyle.seal;
    return StudioGroup(
      id: 'empty',
      title: 'New chat page',
      open: open,
      onToggle: onToggle,
      basics: [
        StudioChoice<ThemeEmptyLayout>(
          label: 'Layout',
          items: [
            (ThemeEmptyLayout.centered, 'Centered'),
            (ThemeEmptyLayout.editorial, 'Left aligned'),
            (ThemeEmptyLayout.compact, 'Compact'),
          ],
          value: e.layout,
          onChanged: (v) => c.emptyState((e) => e.copyWith(layout: v)),
        ),
        StudioChoice<ThemeHeroStyle>(
          label: 'Hero',
          items: [
            (ThemeHeroStyle.whale, 'Whale'),
            (ThemeHeroStyle.badge, 'Badge'),
            (ThemeHeroStyle.glyph, 'Glyph'),
            (ThemeHeroStyle.seal, 'Seal'),
            (ThemeHeroStyle.customImage, 'Own image'),
            (ThemeHeroStyle.hidden, 'Hidden'),
          ],
          value: e.heroStyle,
          // Without an image yet, the choice only takes once one is picked.
          onChanged: (v) => v == ThemeHeroStyle.customImage && e.heroImage == null
              ? unawaited(c.pickImage(ThemeImageSlot.hero))
              : c.emptyState((e) => e.copyWith(heroStyle: v)),
        ),
        if (drawsGlyph)
          StudioField.text(
            key: const ValueKey('theme-studio-hero-glyph'),
            value: e.heroGlyph ?? '',
            onChanged: (text) => c.emptyState((e) => e.copyWith(heroGlyph: () => _blankToNull(text))),
            label: 'Hero characters (1–4)',
            maxLength: 4,
            errorText: e.heroGlyph == null ? 'Required' : null,
          ),
        if (e.heroStyle == ThemeHeroStyle.customImage)
          StudioAssetRow(
            title: 'Hero image',
            pickLabel: 'Pick a hero image (PNG / WebP / GIF)',
            fileName: e.heroImage,
            missing: c.isMissing(e.heroImage),
            onPick: () => unawaited(c.pickImage(ThemeImageSlot.hero)),
            onClear: () => c.setImage(ThemeImageSlot.hero, null),
          ),
        StudioChoice<ThemeSuggestionsDisplay>(
          label: 'Suggestions',
          items: [
            (ThemeSuggestionsDisplay.expanded, 'Expanded'),
            (ThemeSuggestionsDisplay.grid, 'Two columns'),
            (ThemeSuggestionsDisplay.collapsible, 'Collapsed'),
          ],
          value: e.suggestionsDisplay,
          // The collapsed list is a quieter page: no connection subtitle, paper cards.
          onChanged: (v) => c.update(
            c.pack.copyWith(
              emptyState: c.pack.emptyState.copyWith(
                suggestionsDisplay: v,
                showConnectedSubtitle: v != ThemeSuggestionsDisplay.collapsible,
              ),
              components: v == ThemeSuggestionsDisplay.collapsible
                  ? c.pack.components.copyWith(suggestionCardStyle: ThemeSuggestionCardStyle.paper)
                  : null,
            ),
          ),
        ),
      ],
      more: [
        StudioSlider(
          label: 'Hero size',
          value: e.heroScale,
          min: 0.6,
          max: 2,
          fallback: 1,
          format: StudioSlider.times,
          onChanged: (v) => c.emptyState((e) => e.copyWith(heroScale: v)),
        ),
        StudioLocalizedText(
          label: 'Greeting',
          value: e.greeting,
          maxLength: 40,
          onChanged: (v) => c.emptyState((e) => e.copyWith(greeting: () => v)),
        ),
        StudioLocalizedText(
          label: 'Subtitle',
          value: e.subtitle,
          maxLength: 60,
          onChanged: (v) => c.emptyState((e) => e.copyWith(subtitle: () => v)),
        ),
        StudioSwitch(
          label: 'Use the reply font for the greeting',
          value: e.useReadingFontForGreeting,
          onChanged: (v) => c.emptyState((e) => e.copyWith(useReadingFontForGreeting: v)),
        ),
        StudioSwitch(
          label: 'Show the subtitle once connected',
          value: e.showConnectedSubtitle,
          onChanged: (v) => c.emptyState((e) => e.copyWith(showConnectedSubtitle: v)),
        ),
        StudioChoice<ThemeSuggestionCardStyle>(
          label: 'Suggestion card style',
          items: [
            (ThemeSuggestionCardStyle.glass, 'Glass'),
            (ThemeSuggestionCardStyle.paper, 'Paper'),
            (ThemeSuggestionCardStyle.outlined, 'Outlined'),
            (ThemeSuggestionCardStyle.minimal, 'Minimal'),
          ],
          value: c.pack.components.suggestionCardStyle,
          onChanged: (v) => c.components((p) => p.copyWith(suggestionCardStyle: v)),
        ),
      ],
    );
  }
}
