import 'package:flutter/material.dart';
import '../core/constants.dart';

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  const ResponsiveWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        return ColoredBox(
          color: theme.scaffoldBackgroundColor,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth <= AppConstants.breakpointTablet
                    ? double.infinity
                    : AppConstants.maxContentWidth,
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
