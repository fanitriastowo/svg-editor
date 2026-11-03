import 'package:flutter/material.dart';
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

  test('prettifySvg indents valid SVG and leaves invalid SVG alone', () {
    expect(
      prettifySvg('<svg><rect width="1"/></svg>'),
      '<svg>\n  <rect width="1"/>\n</svg>\n',
    );
    expect(prettifySvg('<svg><rect'), '<svg><rect');
  });
}
