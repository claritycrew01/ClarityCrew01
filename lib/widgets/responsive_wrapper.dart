import 'package:flutter/material.dart';
import '../core/constants.dart';

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  const ResponsiveWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= AppConstants.breakpointTablet) {
          return child;
        }
        final theme = Theme.of(context);
        return ColoredBox(
          color: theme.scaffoldBackgroundColor,
          child: Center(
            child: SizedBox(
              width: AppConstants.maxContentWidth,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
