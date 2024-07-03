import 'package:flutter/material.dart';

class JfxNavBarTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final GestureTapCallback onTap;
  final bool selected;
  const JfxNavBarTile({
    required this.onTap,
    required this.icon,
    required this.label,
    super.key,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).size.width < 1100) {
      return JfxNavBarTileSmall(
          icon: icon, label: label, selected: selected, onTap: onTap);
    } else {
      return JfxNavBarTileLarge(
          icon: icon, label: label, selected: selected, onTap: onTap);
    }
  }
}

class JfxNavBarTileLarge extends StatelessWidget {
  final IconData icon;
  final String label;
  final GestureTapCallback onTap;
  final bool selected;
  const JfxNavBarTileLarge({
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

class JfxNavBarTileSmall extends StatelessWidget {
  final IconData icon;
  final String label;
  final GestureTapCallback onTap;
  final bool selected;

  const JfxNavBarTileSmall({
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
      child: Padding(
        padding: const EdgeInsets.all(5),
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
              child: Icon(icon),
            ),
          ),
        ),
      ),
    );
  }
}

class JfxNavBarPopupMenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<PopupMenuEntry<String>> items;
  final bool selected;
  final VoidCallback onOpened;
  final VoidCallback onCanceled;
  final VoidCallback onSelected;

  const JfxNavBarPopupMenuButton(
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
      return JfxNavBarPopupMenuButtonSmall(
          icon: icon,
          label: label,
          items: items,
          selected: selected,
          onOpened: onOpened,
          onCanceled: onCanceled,
          onSelected: onSelected);
    } else {
      return JfxNavBarPopupMenuButtonLarge(
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

class JfxNavBarPopupMenuButtonLarge extends StatefulWidget {
  final IconData icon;
  final String label;
  final List<PopupMenuEntry<String>> items;
  final bool selected;
  final VoidCallback onOpened;
  final VoidCallback onCanceled;
  final VoidCallback onSelected;

  const JfxNavBarPopupMenuButtonLarge({
    required this.icon,
    required this.label,
    required this.items,
    required this.onOpened,
    required this.onCanceled,
    required this.onSelected,
    this.selected = false,
    super.key,
  });

  @override
  JfxNavBarPopupMenuButtonLargeState createState() =>
      JfxNavBarPopupMenuButtonLargeState();
}

class JfxNavBarPopupMenuButtonLargeState
    extends State<JfxNavBarPopupMenuButtonLarge> {
  bool menuOpen = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 200,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Material(
              color: widget.selected || menuOpen
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                  : Colors.white.withOpacity(0.05),
              child: InkWell(
                onTap: () {},
                overlayColor: WidgetStateProperty.all(
                    Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                customBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: TooltipVisibility(
                  visible: false,
                  child: PopupMenuButton<String>(
                    onSelected: (value) {
                      widget.onSelected();
                      setState(() {
                        menuOpen = false;
                      });
                    },
                    onOpened: () {
                      setState(() {
                        menuOpen = true;
                      });
                    },
                    onCanceled: () {
                      setState(() {
                        menuOpen = false;
                      });
                    },
                    itemBuilder: (BuildContext context) => widget.items,
                    offset: const Offset(200, 0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15.0, vertical: 10.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Icon(widget.icon),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              widget.label,
                              style: Theme.of(context).textTheme.bodyLarge,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ));
  }
}

class JfxNavBarPopupMenuButtonSmall extends StatefulWidget {
  final IconData icon;
  final String label;
  final List<PopupMenuEntry<String>> items;
  final bool selected;
  final VoidCallback onOpened;
  final VoidCallback onCanceled;
  final VoidCallback onSelected;

  const JfxNavBarPopupMenuButtonSmall({
    required this.icon,
    required this.label,
    required this.items,
    required this.onOpened,
    required this.onCanceled,
    required this.onSelected,
    this.selected = false,
    super.key,
  });

  @override
  JfxNavBarPopupMenuButtonSmallState createState() =>
      JfxNavBarPopupMenuButtonSmallState();
}

class JfxNavBarPopupMenuButtonSmallState
    extends State<JfxNavBarPopupMenuButtonSmall> {
  bool menuOpen = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 72,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Material(
              color: widget.selected || menuOpen
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                  : Colors.white.withOpacity(0.05),
              child: InkWell(
                onTap: () {},
                overlayColor: WidgetStateProperty.all(
                    Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                customBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: TooltipVisibility(
                  visible: false,
                  child: PopupMenuButton<String>(
                    onSelected: (value) {
                      widget.onSelected();
                      setState(() {
                        menuOpen = false;
                      });
                    },
                    onOpened: () {
                      setState(() {
                        menuOpen = true;
                      });
                    },
                    onCanceled: () {
                      setState(() {
                        menuOpen = false;
                      });
                    },
                    itemBuilder: (BuildContext context) => widget.items,
                    offset: const Offset(72, 0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15.0, vertical: 10.0),
                      child: Icon(widget.icon),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ));
  }
}
