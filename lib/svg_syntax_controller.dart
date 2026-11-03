import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  /// Cuts the selection, or the whole line under the cursor if nothing is selected.
  void cut() {
    if (!selection.isValid) return;
    var start = selection.start;
    var end = selection.end;
    if (selection.isCollapsed) {
      start = start == 0 ? 0 : text.lastIndexOf('\n', start - 1) + 1;
      final newline = text.indexOf('\n', end);
      end = newline == -1 ? text.length : newline + 1;
    }
    Clipboard.setData(ClipboardData(text: text.substring(start, end)));
    value = TextEditingValue(
      text: text.replaceRange(start, end, ''),
      selection: TextSelection.collapsed(offset: start),
    );
  }

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
