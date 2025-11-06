part of 'components.dart';

class SideBarRoute<T> extends PopupRoute<T> {
  SideBarRoute(
    this.widget, {
    this.showBarrier = true,
    this.useSurfaceTintColor = false,
    required this.width,
    this.addBottomPadding = true,
    this.addTopPadding = true,
  });

  final Widget widget;

  final bool showBarrier;

  final bool useSurfaceTintColor;

  final double width;

  final bool addTopPadding;

  final bool addBottomPadding;

  @override
  Color? get barrierColor => showBarrier ? Colors.black54 : Colors.transparent;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => "exit";

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    bool showSideBar = MediaQuery.of(context).size.width > width;

    Widget body = widget;

    if (addTopPadding) {
      body = Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: body,
        ),
      );
    }

    final sideBarWidth = math.min(width, MediaQuery.of(context).size.width);

    body = Container(
      clipBehavior: Clip.antiAlias,
      constraints: BoxConstraints(maxWidth: sideBarWidth),
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        borderRadius: showSideBar
            ? const BorderRadius.horizontal(left: Radius.circular(16))
            : null,
      ),
      child: ClipRRect(
        borderRadius: showSideBar
            ? const BorderRadius.horizontal(left: Radius.circular(16))
            : BorderRadius.zero,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 40.0, sigmaY: 40.0),
          child: Container(
            decoration: BoxDecoration(
              // 更强的毛玻璃效果 - 进一步降低透明度并添加多层渐变
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.55),
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.45),
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.35),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              border: showSideBar
                  ? Border(
                      left: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(-3, 0),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(-1, 0),
                ),
              ],
            ),
            child: GestureDetector(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    0,
                    0,
                    MediaQuery.of(context).padding.right,
                    addBottomPadding
                        ? MediaQuery.of(context).padding.bottom +
                              MediaQuery.of(context).viewInsets.bottom
                        : 0,
                  ),
                  child: body,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (App.isIOS) {
      body = IOSBackGestureDetector(
        enabledCallback: () => true,
        gestureWidth: 20.0,
        onStartPopGesture: () =>
            IOSBackGestureController(controller!, navigator!),
        child: body,
      );
    }

    return Align(alignment: Alignment.centerRight, child: body);
  }

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    var offset = Tween<Offset>(
      begin: const Offset(1, 0),
      end: const Offset(0, 0),
    );
    return SlideTransition(
      position: offset.animate(
        CurvedAnimation(parent: animation, curve: Curves.fastOutSlowIn),
      ),
      child: child,
    );
  }
}

Future<void> showSideBar(
  BuildContext context,
  Widget widget, {
  bool showBarrier = true,
  bool useSurfaceTintColor = false,
  double width = 500,
  bool addTopPadding = false,
}) {
  return Navigator.of(context).push(
    SideBarRoute(
      widget,
      showBarrier: showBarrier,
      useSurfaceTintColor: useSurfaceTintColor,
      width: width,
      addTopPadding: addTopPadding,
      addBottomPadding: true,
    ),
  );
}
