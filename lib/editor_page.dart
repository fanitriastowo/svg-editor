import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'svg_syntax_controller.dart';
import 'svg_utils.dart';
import 'widgets/source_editor.dart';
import 'widgets/svg_preview.dart';

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

  @override
  Widget build(BuildContext context) {
    final fileName = _path?.split(Platform.pathSeparator).last ?? 'Untitled';
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyO, meta: true): _open,
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): _save,
        const SingleActivator(LogicalKeyboardKey.keyX, meta: true):
            _controller.cut,
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
                child: SourceEditor(controller: _controller, wrap: _wrap),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: SvgPreview(controller: _controller)),
            ],
          ),
        ),
      ),
    );
  }
}
