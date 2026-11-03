import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:svg_editor/main.dart';

void main() {
  testWidgets('shows editor and preview', (tester) async {
    await tester.pumpWidget(const SvgEditorApp());

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);
  });

  testWidgets('long lines do not wrap by default', (tester) async {
    await tester.pumpWidget(const SvgEditorApp());
    final field = find.byType(TextField);
    final width = tester.getSize(field).width;

    await tester.enterText(field, '<svg>${'x' * 500}</svg>');
    await tester.pump();

    expect(tester.getSize(field).width, greaterThan(width));
  });

  testWidgets('cmd+X with no selection cuts the current line', (tester) async {
    await tester.pumpWidget(const SvgEditorApp());
    final field = find.byType(TextField);
    await tester.enterText(field, 'a\nbb\nc');
    final controller = tester.widget<TextField>(field).controller!;
    controller.selection = const TextSelection.collapsed(offset: 3);
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    await tester.pump();

    expect(controller.text, 'a\nc');
    expect(controller.selection, const TextSelection.collapsed(offset: 2));
  });

  test('prettifySvg indents valid SVG and leaves invalid SVG alone', () {
    expect(
      prettifySvg('<svg><rect width="1"/></svg>'),
      '<svg>\n  <rect width="1"/>\n</svg>\n',
    );
    expect(prettifySvg('<svg><rect'), '<svg><rect');
  });

  test('highlightShapeAt outlines the shape under the cursor', () {
    const svg = '<svg viewBox="0 0 200 100"><circle r="5" fill="red"/></svg>';
    expect(
      highlightShapeAt(svg, svg.indexOf('circle')),
      '<svg viewBox="0 0 200 100"><circle r="5" fill="red"/>'
      '<circle r="5" fill="none" stroke="#ff2d55" stroke-width="2.0"/></svg>',
    );
    expect(highlightShapeAt(svg, 2), svg);
    expect(
      highlightShapeAt('<svg><circle r=5/></svg>', 8),
      '<svg><circle r=5/></svg>',
    );
  });
}
