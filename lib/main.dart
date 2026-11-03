import 'package:flutter/material.dart';

import 'editor_page.dart';

void main() => runApp(const SvgEditorApp());

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
