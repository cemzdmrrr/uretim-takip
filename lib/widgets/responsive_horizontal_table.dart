import 'package:flutter/material.dart';

/// Masaustunde tabloyu kullanilabilir alanin tamaminda gosterir; tablo icin
/// gereken alan dar ekrana sigmadiginda yatay kaydirmayi korur.
class ResponsiveHorizontalTable extends StatefulWidget {
  final Widget child;
  final double minWidth;
  final bool showScrollbar;
  final ScrollController? controller;

  const ResponsiveHorizontalTable({
    super.key,
    required this.child,
    required this.minWidth,
    this.showScrollbar = false,
    this.controller,
  });

  @override
  State<ResponsiveHorizontalTable> createState() =>
      _ResponsiveHorizontalTableState();
}

class _ResponsiveHorizontalTableState extends State<ResponsiveHorizontalTable> {
  ScrollController? _internalController;

  ScrollController get _controller =>
      widget.controller ?? (_internalController ??= ScrollController());

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < widget.minWidth
            ? widget.minWidth
            : constraints.maxWidth;
        final scrollView = SingleChildScrollView(
          controller: _controller,
          primary: false,
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: width, child: widget.child),
        );

        if (!widget.showScrollbar) return scrollView;
        return Scrollbar(
          controller: _controller,
          thumbVisibility: true,
          child: scrollView,
        );
      },
    );
  }
}
