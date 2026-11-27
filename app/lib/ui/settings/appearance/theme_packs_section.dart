// The theme pack list in appearance settings: pick, import and export packs, and the way into the Theme Studio
// (theme_studio_sheet.dart) and the Workshop.

import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../l10n/l10n.dart';
import '../../../state/appearance_state.dart';
import '../../../state/artifacts.dart' show filesChannelProvider;
import '../../../state/workshop_catalog_state.dart';
import '../../../themes/theme_library.dart';
import '../../common/app_sheet.dart';
import '../../common/brief_notice.dart';
import '../../common/list_page_row.dart';
import '../../theme/app_icons.dart';
import '../../theme/theme.dart';
import '../../workshop/workshop_screen.dart';
import 'theme_studio_sheet.dart';

export 'theme_studio_sheet.dart' show ThemeStudioSheet;

final themePackPickerProvider = Provider<Future<File?> Function()>(
  (ref) => () async {
    final picked = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: const ['zip']);
    if (picked == null) return null;
    final temp = File(
      '${(await getTemporaryDirectory()).path}/theme-import-${DateTime.now().microsecondsSinceEpoch}.zip',
    );
    final sink = temp.openWrite();
    try {
      await sink.addStream(picked.readAsByteStream());
    } finally {
      await sink.close();
    }
    return temp;
  },
);

String themeImportProblemText(ThemeImportException error, {required bool english}) => switch (error.problem) {
  ThemeImportProblem.notAZip => 'Selected file is not a valid ZIP archive.',
  ThemeImportProblem.noPack => 'No theme.json found in the archive.',
  ThemeImportProblem.badPack =>
    'Invalid theme.json (${error.detail ?? 'schema'}).',
  ThemeImportProblem.missingAsset =>
    'Missing referenced asset: ${error.detail ?? ''}.',
  ThemeImportProblem.badAsset =>
    'Invalid image or font asset: ${error.detail ?? ''}.',
  ThemeImportProblem.tooLarge => 'Theme pack or asset exceeds size limits.',
  ThemeImportProblem.storage => 'Could not write theme pack to local storage.',
};

class ThemePacksSection extends ConsumerStatefulWidget {
  const ThemePacksSection({super.key});

  @override
  ConsumerState<ThemePacksSection> createState() => _ThemePacksSectionState();
}

class _ThemePacksSectionState extends ConsumerState<ThemePacksSection> {
  bool _busy = false;

  Future<void> _selectPack(String? id) async {
    await ThemeRevealHost.run(context, () => ref.read(appearanceProvider.notifier).selectThemePack(id));
  }

  Future<void> _importZip() async {
    if (_busy) return;
    final english = AppLocale.isEnglish;
    File? zip;
    setState(() => _busy = true);
    try {
      zip = await ref.read(themePackPickerProvider)();
      if (zip == null || !mounted) return;
      final (:id, :replaced) = await ref.read(themeLibraryProvider).install(zip, replaceExisting: true);
      ref.invalidate(userThemesProvider);
      ref.invalidate(themePackByIdProvider(id));
      ref.invalidate(themeLoadedFontsProvider(id));
      if (!mounted) return;
      await _selectPack(id);
      if (!mounted) return;
      showBriefNotice(
        context,
        replaced
            ? ('Theme pack updated and applied.')
            : ('Theme pack imported and applied.'),
      );
    } on ThemeImportException catch (error) {
      if (mounted) {
        showBriefNotice(context, themeImportProblemText(error, english: english));
      }
    } on Object {
      if (mounted) {
        showBriefNotice(context, 'Failed to import theme pack.');
      }
    } finally {
      if (zip != null) {
        unawaited(zip.delete().then((_) {}, onError: (_) {}));
      }
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportZip(ThemePack pack) async {
    if (_busy) return;
    final english = AppLocale.isEnglish;
    setState(() => _busy = true);
    Directory? tempDir;
    try {
      final root = await getTemporaryDirectory();
      tempDir = await root.createTemp('dsh-theme-export-');
      final fileName = '${pack.publicId}.zip';
      final dest = File('${tempDir.path}/$fileName');
      await ref.read(themeLibraryProvider).exportZip(pack.id, dest, publicId: pack.publicId);
      final where = await ref
          .read(filesChannelProvider)
          .saveToDownloads(dest.path, name: fileName, mime: 'application/zip');
      if (!mounted) return;
      showBriefNotice(context, 'Exported $fileName ($where)');
    } on ThemeImportException catch (error) {
      if (mounted) {
        showBriefNotice(context, themeImportProblemText(error, english: english));
      }
    } on Object {
      if (mounted) {
        showBriefNotice(context, 'Failed to export theme pack.');
      }
    } finally {
      if (tempDir != null) {
        unawaited(tempDir.delete(recursive: true).then((_) {}, onError: (_) {}));
      }
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removePack(ThemePack pack) async {
    final activeId = ref.read(appearanceProvider).themePackId;
    await ref.read(themeLibraryProvider).remove(pack.id);
    ref.invalidate(userThemesProvider);
    ref.invalidate(themePackByIdProvider(pack.id));
    ref.invalidate(themeLoadedFontsProvider(pack.id));
    if (activeId == pack.id) {
      await ref.read(appearanceProvider.notifier).selectThemePack(null);
    }
    if (!mounted) return;
    showBriefNotice(context, 'Removed "${pack.displayName('en')}".');
  }

  Future<void> _openStudio([ThemePack? initial, bool editing = false]) async {
    final existing = ref.read(userThemesProvider).value ?? const <ThemePack>[];
    final existingIds = {for (final t in existing) t.publicId};
    final saved = await showAppSheet<ThemePack>(
      context,
      isScrollControlled: true,
      builder: (_) => ThemeStudioSheet(initial: initial, editing: editing, existingIds: existingIds),
    );
    if (saved == null || !mounted) return;
    ref.invalidate(userThemesProvider);
    ref.invalidate(themePackByIdProvider(saved.id));
    ref.invalidate(themeLoadedFontsProvider(saved.id));
    await _selectPack(saved.id);
    if (!mounted) return;
    showBriefNotice(
      context,
      'Saved and applied "${saved.displayName('en')}".',
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = 'en';
    final activeId = ref.watch(appearanceProvider.select((s) => s.themePackId));
    final userThemes = ref.watch(userThemesProvider).value ?? const <ThemePack>[];
    final workshopAvailable = ref.watch(workshopAvailableProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListPageRow(
          key: const ValueKey('theme-pack-default'),
          icon: AppIcons.theme,
          title: 'Mist Glass (Default)',
          subtitle: 'Translucent glass chrome with ambient hue glow',
          trailing: activeId == null
              ? Icon(AppIcons.selected, size: 18, color: Theme.of(context).colorScheme.primary)
              : null,
          onTap: () => unawaited(_selectPack(null)),
        ),
        for (final pack in ThemePack.builtIns) ...[
          const SizedBox(height: 2),
          _ThemePackRow(
            key: ValueKey('theme-pack-${pack.id}'),
            pack: pack,
            languageCode: lang,
            selected: activeId == pack.id,
            onTap: () => unawaited(_selectPack(pack.id)),
            onCustomize: () => unawaited(_openStudio(pack)),
            onExport: () => unawaited(_exportZip(pack)),
          ),
        ],
        for (final pack in userThemes) ...[
          const SizedBox(height: 2),
          _ThemePackRow(
            key: ValueKey('theme-pack-${pack.id}'),
            pack: pack,
            languageCode: lang,
            selected: activeId == pack.id,
            onTap: () => unawaited(_selectPack(pack.id)),
            onCustomize: () => unawaited(_openStudio(pack, true)),
            onExport: () => unawaited(_exportZip(pack)),
            onDelete: () => unawaited(_removePack(pack)),
          ),
        ],
        const SizedBox(height: 2),
        ListPageRow(
          key: const ValueKey('theme-pack-studio'),
          icon: AppIcons.color,
          title: 'Create Custom Theme Pack',
          subtitle: 'Live preview · any color, surface, local font & artwork',
          chevron: true,
          onTap: () => unawaited(_openStudio(ref.read(activeThemePackProvider))),
        ),
        const SizedBox(height: 2),
        ListPageRow(
          key: const ValueKey('theme-pack-import'),
          icon: AppIcons.download,
          title: 'Import Theme Pack (.zip)',
          subtitle: 'Load a declarative theme.json archive with fonts or artwork',
          onTap: _busy ? null : () => unawaited(_importZip()),
        ),
        if (workshopAvailable) ...[
          const SizedBox(height: 2),
          ListPageRow(
            key: const ValueKey('theme-pack-workshop'),
            icon: AppIcons.workshop,
            title: 'Theme Workshop',
            subtitle: 'Discover community themes or publish your own',
            chevron: true,
            onTap: () {
              ref.read(workshopCatalogProvider.notifier).setKind(WorkshopKindFilter.theme);
              unawaited(Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const WorkshopScreen())));
            },
          ),
        ],
      ],
    );
  }
}

enum _PackMenuAction { customize, exportZip, delete }

class _ThemePackRow extends StatelessWidget {
  const _ThemePackRow({
    super.key,
    required this.pack,
    required this.languageCode,
    required this.selected,
    required this.onTap,
    required this.onCustomize,
    required this.onExport,
    this.onDelete,
  });

  final ThemePack pack;
  final String languageCode;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onCustomize;
  final VoidCallback onExport;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppAccent.fromThemePack(pack);
    final seed = accent.seedFor(Theme.of(context).brightness);
    final bgOverride = dark ? pack.palette.dark.backdropTop : pack.palette.light.backdropTop;
    final bgDot = bgOverride != null
        ? Color(bgOverride)
        : (dark ? NeutralTones.forAccent(accent).night : NeutralTones.forAccent(accent).mist);
    final subtitle = pack.description.isNotEmpty
        ? pack.description
        : [
            pack.surfaces.preset.name,
            if (pack.typography.readingFont != 'system') pack.typography.readingFont,
            ...pack.tags,
          ].join(' · ');

    return ListPageRow(
      leading: SizedBox(
        width: 24,
        height: 24,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: bgDot,
            shape: BoxShape.circle,
            border: Border.all(color: seed, width: 2.5),
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: seed, shape: BoxShape.circle),
            ),
          ),
        ),
      ),
      title: pack.displayName(languageCode),
      subtitle: subtitle,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(AppIcons.selected, size: 18, color: scheme.primary),
            ),
          PopupMenuButton<_PackMenuAction>(
            icon: Icon(AppIcons.more, size: 18, color: scheme.onSurfaceVariant),
            tooltip: 'More actions',
            onSelected: (action) => switch (action) {
              _PackMenuAction.customize => onCustomize(),
              _PackMenuAction.exportZip => onExport(),
              _PackMenuAction.delete => onDelete?.call(),
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: _PackMenuAction.customize, child: Text('Edit / Remix')),
              PopupMenuItem(value: _PackMenuAction.exportZip, child: Text('Export ZIP')),
              if (onDelete != null)
                PopupMenuItem(
                  value: _PackMenuAction.delete,
                  child: Text('Remove', style: TextStyle(color: scheme.error)),
                ),
            ],
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
