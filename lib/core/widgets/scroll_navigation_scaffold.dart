import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Makes room for content while scrolling down; restores navigation on scroll up.
class ScrollNavigationScaffold extends StatefulWidget {
  const ScrollNavigationScaffold({
    super.key,
    required this.body,
    required this.navigationBar,
    required this.branchIndex,
  });

  final Widget body;
  final Widget navigationBar;
  final int branchIndex;

  @override
  State<ScrollNavigationScaffold> createState() =>
      _ScrollNavigationScaffoldState();
}

class _ScrollNavigationScaffoldState extends State<ScrollNavigationScaffold> {
  bool _visible = true;

  @override
  void didUpdateWidget(covariant ScrollNavigationScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.branchIndex != widget.branchIndex) _visible = true;
  }

  bool _onScroll(UserScrollNotification notification) {
    if (notification.depth != 0 ||
        notification.metrics.axis != Axis.vertical ||
        notification.direction == ScrollDirection.idle) {
      return false;
    }
    final visible = notification.direction == ScrollDirection.forward;
    if (_visible != visible) setState(() => _visible = visible);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NotificationListener<UserScrollNotification>(
        onNotification: _onScroll,
        child: widget.body,
      ),
      bottomNavigationBar: ClipRect(
        child: AnimatedAlign(
          alignment: Alignment.topCenter,
          heightFactor: _visible ? 1 : 0,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: IgnorePointer(
            ignoring: !_visible,
            child: ExcludeSemantics(
              excluding: !_visible,
              child: widget.navigationBar,
            ),
          ),
        ),
      ),
    );
  }
}
