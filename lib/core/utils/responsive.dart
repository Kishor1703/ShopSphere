import 'package:flutter/widgets.dart';

class Breakpoints {
  const Breakpoints._();

  static const medium = 600.0;
  static const expanded = 1024.0;
}

enum ScreenSize { compact, medium, expanded }

ScreenSize screenSizeForWidth(double width) {
  if (width < Breakpoints.medium) return ScreenSize.compact;
  if (width <= Breakpoints.expanded) return ScreenSize.medium;
  return ScreenSize.expanded;
}

extension ScreenSizeContext on BuildContext {
  ScreenSize get screenSize =>
      screenSizeForWidth(MediaQuery.sizeOf(this).width);
}
