import 'package:flutter/material.dart';

class JfxNavBarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final GestureTapCallback onTap;
  final bool selected;
  const JfxNavBarButton({
    required this.onTap,
    required this.icon,
    required this.label,
    super.key,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).size.width < 1100) {
      return JfxNavBarButtonSmall(
          icon: icon, label: label, selected: selected, onTap: onTap);
    } else {
      return JfxNavBarButtonLarge(
          icon: icon, label: label, selected: selected, onTap: onTap);
    }
  }
}

class JfxNavBarButtonLarge extends StatelessWidget {
  final IconData icon;
  final String label;
  final GestureTapCallback onTap;
  final bool selected;
  const JfxNavBarButtonLarge({
    required this.onTap,
    required this.icon,
    required this.label,
    super.key,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        child: Material(
          color: selected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
              : Colors.white.withOpacity(0.05),
          //color: Theme.of(context).navigationRailTheme.indicatorColor,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            onTap: onTap,
            overlayColor: WidgetStateProperty.all(
                Theme.of(context).colorScheme.primary.withOpacity(0.3)),
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Icon(icon),
                  const SizedBox(
                    width: 15,
                  ),
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodyLarge,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class JfxNavBarButtonSmall extends StatelessWidget {
  final IconData icon;
  final String label;
  final GestureTapCallback onTap;
  final bool selected;

  const JfxNavBarButtonSmall({
    required this.onTap,
    required this.icon,
    required this.label,
    super.key,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 72,
        height: 72,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Material(
              color: selected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                  : Colors.white.withOpacity(0.05),
              child: IconButton(
                onPressed: onTap,
                icon: Icon(icon),
                style: ButtonStyle(
                    overlayColor: WidgetStateProperty.all(
                        Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ))),
              ),
            ),
          ),
        ));
  }
}

class JfxNavBarMenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<PopupMenuEntry<String>> items;
  final bool selected;
  final VoidCallback onOpened;
  final VoidCallback onCanceled;
  final Future Function(String)? onSelected;

  const JfxNavBarMenuButton(
      {required this.icon,
      required this.label,
      required this.items,
      required this.onOpened,
      required this.onCanceled,
      required this.onSelected,
      required this.selected,
      super.key});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).size.width < 1100) {
      return JfxNavBarMenuButtonSmall(
          icon: icon,
          label: label,
          items: items,
          selected: selected,
          onOpened: onOpened,
          onCanceled: onCanceled,
          onSelected: onSelected);
    } else {
      return JfxNavBarMenuButtonLarge(
          icon: icon,
          label: label,
          items: items,
          selected: selected,
          onOpened: onOpened,
          onCanceled: onCanceled,
          onSelected: onSelected);
    }
  }
}

class JfxNavBarMenuButtonLarge extends StatefulWidget {
  final List<PopupMenuEntry<String>> items;
  final IconData icon;
  final String label;
  final Future Function(String)? onSelected;
  final VoidCallback? onCanceled;
  final VoidCallback? onOpened;
  final bool selected;

  const JfxNavBarMenuButtonLarge({
    required this.items,
    required this.onSelected,
    required this.onOpened,
    required this.onCanceled,
    required this.icon,
    required this.label,
    super.key,
    this.selected = false,
  });

  @override
  JfxNavBarMenuButtonLargeState createState() =>
      JfxNavBarMenuButtonLargeState();
}

class JfxNavBarMenuButtonLargeState extends State<JfxNavBarMenuButtonLarge> {
  bool menuOpen = false;

  void showButtonMenu() {
    const offset = Offset(200, 0);
    final RenderBox button = context.findRenderObject()! as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(offset, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero) + offset,
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    if (widget.items.isNotEmpty) {
      widget.onOpened?.call();
      setState(() {
        menuOpen = true;
      });
      showMenu<String?>(
              context: context, items: widget.items, position: position)
          .then<void>((String? newValue) {
        setState(() {
          menuOpen = false;
        });
        if (!mounted) {
          return null;
        }
        if (newValue == null) {
          widget.onCanceled?.call();
          return null;
        }
        widget.onSelected?.call(newValue);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        child: Material(
          color: widget.selected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            onTap: showButtonMenu,
            overlayColor: WidgetStateProperty.all(
                Theme.of(context).colorScheme.primary.withOpacity(0.3)),
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Icon(widget.icon),
                  const SizedBox(
                    width: 15,
                  ),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: Theme.of(context).textTheme.bodyLarge,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class JfxNavBarMenuButtonSmall extends StatefulWidget {
  final List<PopupMenuEntry<String>> items;
  final IconData icon;
  final String label;
  final Future Function(String)? onSelected;
  final VoidCallback? onCanceled;
  final VoidCallback? onOpened;
  final bool selected;

  const JfxNavBarMenuButtonSmall({
    required this.items,
    required this.onSelected,
    required this.onOpened,
    required this.onCanceled,
    required this.icon,
    required this.label,
    super.key,
    this.selected = false,
  });

  @override
  JfxNavBarMenuButtonSmallState createState() =>
      JfxNavBarMenuButtonSmallState();
}

class JfxNavBarMenuButtonSmallState extends State<JfxNavBarMenuButtonSmall> {
  bool menuOpen = false;

  void showButtonMenu() {
    const offset = Offset(72, 0);
    final RenderBox button = context.findRenderObject()! as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(offset, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero) + offset,
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    if (widget.items.isNotEmpty) {
      widget.onOpened?.call();
      setState(() {
        menuOpen = true;
      });
      showMenu<String?>(
              context: context, items: widget.items, position: position)
          .then<void>((String? newValue) {
        setState(() {
          menuOpen = false;
        });
        if (!mounted) {
          return null;
        }
        if (newValue == null) {
          widget.onCanceled?.call();
          return null;
        }
        widget.onSelected?.call(newValue);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 72,
        height: 72,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Material(
              color: widget.selected || menuOpen
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                  : Colors.white.withOpacity(0.05),
              child: IconButton(
                onPressed: showButtonMenu,
                icon: Icon(widget.icon),
                style: ButtonStyle(
                    overlayColor: WidgetStateProperty.all(
                        Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ))),
              ),
            ),
          ),
        ));
  }
}
