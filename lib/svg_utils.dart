import 'package:file_selector/file_selector.dart';
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
