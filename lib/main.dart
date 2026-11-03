import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:xml/xml.dart';

const sampleSvg =
    '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">
  <rect x="20" y="20" width="160" height="160" rx="24" fill="#4f46e5"/>
  <circle cx="100" cy="100" r="50" fill="#facc15"/>
</svg>
''';

const svgTypeGroup = XTypeGroup(
  label: 'SVG',
  extensions: ['svg'],
  uniformTypeIdentifiers: ['public.svg-image'],
);

void main() => runApp(const SvgEditorApp());

/// Re-indents [source]. Returns it unchanged if it isn't valid XML.
String prettifySvg(String source) {
  try {
    final pretty = XmlDocument.parse(source).toXmlString(
      pretty: true,
      indent: '  ',
      // Reflowing <text> content would change how it renders.
      preserveWhitespace: (node) =>
          node is XmlElement && node.name.local == 'text',
    );
    return '$pretty\n';
  } on XmlException {
    return source;
  }
}

final _shapeTag = RegExp(
  r'<(path|rect|circle|ellipse|line|polyline|polygon)\b[^>]*/>',
);
final _viewBox = RegExp(r'''viewBox\s*=\s*["']([^"']*)["']''');

/// Returns [source] with an outlined copy of the shape tag at [offset]
/// inserted right after it, or [source] unchanged if there is none.
String highlightShapeAt(String source, int offset) {
  final match = _shapeTag
      .allMatches(source)
      .where((m) => m.start <= offset && offset <= m.end)
      .firstOrNull;
  if (match == null) return source;

  final XmlElement copy;
  try {
    copy = XmlDocument.parse(match[0]!).rootElement;
  } on XmlException {
    return source;
  }
  for (final name in const [
    'fill',
    'stroke',
    'stroke-width',
    'style',
    'opacity',
    'fill-opacity',
    'stroke-opacity',
    'id',
    'class',
  ]) {
    copy.removeAttribute(name);
  }
  // Scale the outline to the drawing so it looks the same at any viewBox size.
  final box = _viewBox.firstMatch(source)?[1]?.trim().split(RegExp(r'[\s,]+'));
  final size = box?.length == 4
      ? [
          double.tryParse(box![2]) ?? 0,
          double.tryParse(box[3]) ?? 0,
        ].reduce((a, b) => a > b ? a : b)
      : 0.0;
  copy
    ..setAttribute('fill', 'none')
    ..setAttribute('stroke', '#ff2d55')
    ..setAttribute('stroke-width', size > 0 ? '${size / 100}' : '2');

  return source.replaceRange(match.end, match.end, copy.toXmlString());
}

/// Text controller that colors SVG/XML syntax.
class SvgSyntaxController extends TextEditingController {
  SvgSyntaxController({super.text});

  // Groups: comment, tag start, tag end, attribute name, quoted value.
  static final _token = RegExp(
    r'''(<!--[\s\S]*?-->)|(<[/?!]?[\w:.-]+)|([/?]?>)|([\w:.-]+(?=\s*=))|("[^"]*"|'[^']*')''',
  );
  static const _colors = [
    Color(0xFF8E8E93), // comment
    Color(0xFF3949AB), // tag start
    Color(0xFF3949AB), // tag end
    Color(0xFFB45309), // attribute name
    Color(0xFF15803D), // quoted value
  ];

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final spans = <TextSpan>[];
    var last = 0;
    for (final m in _token.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      final group = [1, 2, 3, 4, 5].firstWhere((g) => m[g] != null);
      spans.add(
        TextSpan(
          text: m[0],
          style: TextStyle(color: _colors[group - 1]),
        ),
      );
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return TextSpan(style: style, children: spans);
  }
}

class SvgEditorApp extends StatelessWidget {
  const SvgEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SVG Editor',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const EditorPage(),
    );
  }
}

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final _controller = SvgSyntaxController(text: sampleSvg);
  String? _path;
  bool _wrap = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final file = await openFile(acceptedTypeGroups: [svgTypeGroup]);
    if (file == null) return;
    await _load(file);
  }

  Future<void> _onDrop(DropDoneDetails details) async {
    final svgs = details.files.where(
      (f) => f.path.toLowerCase().endsWith('.svg'),
    );
    if (svgs.isEmpty) return;
    await _load(svgs.first);
  }

  Future<void> _load(XFile file) async {
    _controller.text = prettifySvg(await file.readAsString());
    setState(() => _path = file.path);
  }

  Future<void> _save() async {
    var path = _path;
    if (path == null) {
      final location = await getSaveLocation(
        acceptedTypeGroups: [svgTypeGroup],
        suggestedName: 'untitled.svg',
      );
      if (location == null) return;
      path = location.path;
    }
    await File(path).writeAsString(_controller.text);
    setState(() => _path = path);
  }

  /// Cuts the selection, or the whole line under the cursor if nothing is selected.
  void _cut() {
    final text = _controller.text;
    final selection = _controller.selection;
    if (!selection.isValid) return;
    var start = selection.start;
    var end = selection.end;
    if (selection.isCollapsed) {
      start = start == 0 ? 0 : text.lastIndexOf('\n', start - 1) + 1;
      final newline = text.indexOf('\n', end);
      end = newline == -1 ? text.length : newline + 1;
    }
    Clipboard.setData(ClipboardData(text: text.substring(start, end)));
    _controller.value = TextEditingValue(
      text: text.replaceRange(start, end, ''),
      selection: TextSelection.collapsed(offset: start),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fileName = _path?.split(Platform.pathSeparator).last ?? 'Untitled';
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyO, meta: true): _open,
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): _save,
        const SingleActivator(LogicalKeyboardKey.keyX, meta: true): _cut,
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(fileName),
          actions: [
            IconButton(
              tooltip: 'Wrap lines',
              isSelected: _wrap,
              icon: const Icon(Icons.wrap_text),
              onPressed: () => setState(() => _wrap = !_wrap),
            ),
            IconButton(
              tooltip: 'Open (⌘O)',
              icon: const Icon(Icons.folder_open),
              onPressed: _open,
            ),
            IconButton(
              tooltip: 'Save (⌘S)',
              icon: const Icon(Icons.save),
              onPressed: _save,
            ),
          ],
        ),
        body: DropTarget(
          onDragDone: _onDrop,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final editor = TextField(
                      controller: _controller,
                      autofocus: true,
                      expands: true,
                      maxLines: null,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(fontFamily: 'Menlo', fontSize: 13),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                      ),
                    );
                    if (_wrap) return editor;
                    // Size the field to its longest line and scroll sideways.
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                        ),
                        child: IntrinsicWidth(child: editor),
                      ),
                    );
                  },
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) => InteractiveViewer(
                    maxScale: 10,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SvgPicture.string(
                        highlightShapeAt(
                          _controller.text,
                          _controller.selection.baseOffset,
                        ),
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(child: Text('Invalid SVG')),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
