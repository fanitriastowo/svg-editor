import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../svg_utils.dart';

/// Live, pan/zoomable render of [controller]'s text, outlining the shape
/// under the cursor.
class SvgPreview extends StatelessWidget {
  const SvgPreview({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => InteractiveViewer(
        maxScale: 10,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SvgPicture.string(
            highlightShapeAt(controller.text, controller.selection.baseOffset),
            errorBuilder: (context, error, stackTrace) =>
                const Center(child: Text('Invalid SVG')),
          ),
        ),
      ),
    );
  }
}
