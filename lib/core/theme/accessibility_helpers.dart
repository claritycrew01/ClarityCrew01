import 'package:flutter/material.dart';

extension SemanticsExtension on Widget {
  Widget withSemantics({
    String? label,
    String? hint,
    bool? isButton,
    bool? isHeader,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: isButton,
      header: isHeader,
      child: this,
    );
  }

  Widget withLargeTapTarget({double minSize = 48}) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
      child: this,
    );
  }
}

class ReducedMotionWrapper extends StatelessWidget {
  final Widget child;
  const ReducedMotionWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
