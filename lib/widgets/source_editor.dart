import 'package:flutter/material.dart';

/// Monospace SVG source field. Without [wrap], it grows to its longest line
/// and scrolls sideways.
class SourceEditor extends StatelessWidget {
  const SourceEditor({super.key, required this.controller, required this.wrap});

  final TextEditingController controller;
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    final editor = TextField(
      controller: controller,
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
    if (wrap) return editor;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: IntrinsicWidth(child: editor),
        ),
      ),
    );
  }
}
