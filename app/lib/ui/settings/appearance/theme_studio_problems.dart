// Turns the pack parser's messages ("shapes.cornerScale must be between 0.0 and 1.6") into the Theme Studio's
// own words: the field by the name its control carries, the rule in a short sentence.

import '../../../l10n/l10n.dart';
import 'theme_studio_colors.dart' show studioColorName;

/// A field's path in theme.json → the name on its control, Chinese then English.
const _fieldNames = <String, (String, String)>{
  'id': ('Theme ID', 'Theme ID'),
  'name': ('Theme name', 'Theme name'),
  'description': ('Summary', 'Summary'),
  'title': ('Name', 'Name'),
  'title.zh': ('Chinese name', 'Chinese name'),
  'title.en': ('English name', 'English name'),
  'tags': ('Tags', 'Tags'),
  'tag': ('Tag', 'Tag'),
  'author': ('Author', 'Author'),
  'license': ('License', 'License'),
  'source': ('Source link', 'Source link'),
  'palette.seed': ('Accent', 'Accent'),
  'palette.seedDark': ('Accent in dark mode', 'Accent in dark mode'),
  'palette.tintHue': ('Tint of backgrounds and text', 'Tint of backgrounds and text'),
  'palette.tintChroma': ('Tint strength', 'Tint strength'),
  'palette.glowOpacity': ('Glow strength', 'Glow strength'),
  'surfaces.preset': ('Material', 'Material'),
  'surfaces.chromeBlur': ('Top bar blur', 'Top bar blur'),
  'surfaces.sheetBlur': ('Sheet blur', 'Sheet blur'),
  'surfaces.cardOpacity': ('Card opacity', 'Card opacity'),
  'surfaces.pillOpacity': ('Pill opacity', 'Pill opacity'),
  'surfaces.hairlineWidth': ('Edge width', 'Edge width'),
  'surfaces.rimOpacity': ('Edge highlight', 'Edge highlight'),
  'surfaces.shadowOpacity': ('Shadow', 'Shadow'),
  'surfaces.backdropImage': ('Backdrop', 'Backdrop'),
  'surfaces.backdropOpacity': ('Backdrop opacity', 'Backdrop opacity'),
  'surfaces.backdropRepeat': ('Tile the image', 'Tile the image'),
  'surfaces.backdropAnimate': ('Keep animated images playing', 'Keep animated images playing'),
  'surfaces.backdropBlur': ('Backdrop blur', 'Backdrop blur'),
  'surfaces.backdropAlign': ('Backdrop alignment', 'Backdrop alignment'),
  'surfaces.pattern': ('Backdrop pattern', 'Backdrop pattern'),
  'surfaces.patternOpacity': ('Pattern strength', 'Pattern strength'),
  'surfaces.patternScale': ('Pattern spacing', 'Pattern spacing'),
  'surfaces.glowLayout': ('Glow position', 'Glow position'),
  'typography.uiFont': ('Interface font', 'Interface font'),
  'typography.readingFont': ('Reply font', 'Reply font'),
  'typography.headingFont': ('Heading font', 'Heading font'),
  'typography.codeFont': ('Code font', 'Code font'),
  'typography.readingScale': ('Reply size', 'Reply size'),
  'typography.readingLineHeight': ('Reply line spacing', 'Reply line spacing'),
  'typography.readingLetterSpacing': ('Reply letter spacing', 'Reply letter spacing'),
  'typography.headingScale': ('Heading size', 'Heading size'),
  'typography.headingLetterSpacing': ('Heading letter spacing', 'Heading letter spacing'),
  'typography.headingWeight': ('Heading weight', 'Heading weight'),
  'typography.codeScale': ('Code size', 'Code size'),
  'shapes.cornerScale': ('Overall roundness', 'Overall roundness'),
  'shapes.cornerStyle': ('Corner style', 'Corner style'),
  'shapes.bubbleCorners': ('Bubble corners', 'Bubble corners'),
  'shapes.bubbleRadius': ('Bubble radius', 'Bubble radius'),
  'shapes.cardRadius': ('Card radius', 'Card radius'),
  'shapes.codeRadius': ('Code block radius', 'Code block radius'),
  'shapes.composerRadius': ('Composer radius', 'Composer radius'),
  'shapes.bubblePadH': ('Bubble side padding', 'Bubble side padding'),
  'shapes.bubblePadV': ('Bubble top and bottom padding', 'Bubble top and bottom padding'),
  'shapes.borderWidth': ('Border width', 'Border width'),
  'shapes.turnGap': ('Between turns', 'Between turns'),
  'shapes.inTurnGap': ('Within a turn', 'Within a turn'),
  'shapes.gutter': ('Side margin', 'Side margin'),
  'components.headerStyle': ('Top bar', 'Top bar'),
  'components.composerStyle': ('Composer', 'Composer'),
  'components.sendButtonStyle': ('Send button', 'Send button'),
  'components.sendButtonShape': ('Send button shape', 'Send button shape'),
  'components.userBubbleStyle': ('My messages', 'My messages'),
  'components.assistantStyle': ('Replies', 'Replies'),
  'components.codeBlockStyle': ('Code blocks', 'Code blocks'),
  'components.codeHeaderStyle': ('Code block header', 'Code block header'),
  'components.turnDivider': ('Divider between turns', 'Divider between turns'),
  'components.headingStyle': ('Headings in replies', 'Headings in replies'),
  'components.bulletStyle': ('List bullets', 'List bullets'),
  'components.headerTitleFont': ('Top bar title font', 'Top bar title font'),
  'components.suggestionCardStyle': ('Suggestion card style', 'Suggestion card style'),
  'components.useReadingFontForReply': ('Use the reply font for replies', 'Use the reply font for replies'),
  'components.userLabel': ('My label', 'My label'),
  'components.assistantLabel': ('Assistant label', 'Assistant label'),
  'components.composerHint': ('Composer hint', 'Composer hint'),
  'components.assistantAvatar': ('Assistant avatar', 'Assistant avatar'),
  'components.userAvatar': ('My avatar', 'My avatar'),
  'emptyState.layout': ('New chat layout', 'New chat layout'),
  'emptyState.heroStyle': ('Hero', 'Hero'),
  'emptyState.heroImage': ('Hero image', 'Hero image'),
  'emptyState.heroGlyph': ('Hero characters', 'Hero characters'),
  'emptyState.heroScale': ('Hero size', 'Hero size'),
  'emptyState.greeting': ('Greeting', 'Greeting'),
  'emptyState.subtitle': ('Subtitle', 'Subtitle'),
  'emptyState.useReadingFontForGreeting': ('Use the reply font for the greeting', 'Use the reply font for the greeting'),
  'emptyState.showConnectedSubtitle': ('Show the subtitle once connected', 'Show the subtitle once connected'),
  'emptyState.suggestionsDisplay': ('Suggestions', 'Suggestions'),
};

/// The control's name for [path], or null when no control edits it.
String? _fieldName(String path, bool english) {
  String? pick((String, String)? names) => names == null ? null : (english ? names.$2 : names.$1);
  if (pick(_fieldNames[path]) case final name?) return name;
  for (final (mode, zh, en) in const [('light', 'Light', 'Light'), ('dark', 'Dark', 'Dark')]) {
    final prefix = 'palette.$mode.';
    if (!path.startsWith(prefix)) continue;
    final color = studioColorName(path.substring(prefix.length), english: english);
    return color == null ? null : '${english ? en : zh} · $color';
  }
  // One half of a text the pack supplies in two languages.
  for (final (suffix, en) in const [('.zh', 'Chinese'), ('.en', 'English')]) {
    if (!path.endsWith(suffix)) continue;
    final base = pick(_fieldNames[path.substring(0, path.length - suffix.length)]);
    return base == null ? null : ('$base ($en)');
  }
  return null;
}


/// [message] from the pack parser, said the way the studio's controls are labelled. A message in a form this
/// does not know comes back as it was.
String studioProblemText(String message) {
  final english = AppLocale.isEnglish;
  final unknown = RegExp(r'^Unknown theme\.json field: (.+)$').firstMatch(message);
  if (unknown != null) {
    return 'There is no field called "${unknown[1]}".';
  }
  final text = message.startsWith('theme.json ') ? message.substring('theme.json '.length) : message;
  final space = text.indexOf(' ');
  if (space <= 0) return message;
  final path = text.substring(0, space);
  final rule = text.substring(space + 1);
  final known = _fieldName(path, english);
  return known == null ? message : '$known $rule';
}
