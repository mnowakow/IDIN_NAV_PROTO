import 'package:flutter/material.dart';
import 'package:idin_nav_prototype/filtered_view.dart';
import 'package:idin_nav_prototype/miniview.dart';
import 'package:idin_nav_prototype/scroll_notifier.dart';

enum SidebarPosition { top, bottom, left, right }

enum SideBarWidget { pageOne, miniView, bookmarks, colorPalette }

class ExpandableSidebar extends StatefulWidget {
  final SidebarPosition position;
  final ScrollNotifier scrollNotifier;

  const ExpandableSidebar({
    Key? key,
    required this.position,
    required this.scrollNotifier,
  }) : super(key: key);

  @override
  State<ExpandableSidebar> createState() => _ExpandableSidebarState();
}

class _ExpandableSidebarState extends State<ExpandableSidebar> {
  bool expanded = false;
  SideBarWidget selectedWidget = SideBarWidget.miniView;
  double contentWidth = 0;
  double barWidth = 0;

  @override
  Widget build(BuildContext context) {
    Widget sidebarContent = Container(
      decoration: BoxDecoration(
        color: Colors.amber,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(2, 2)),
        ],
      ),
      width:
          widget.position == SidebarPosition.left ||
                  widget.position == SidebarPosition.right
              ? (expanded ? (470) : 70)
              : double.infinity,
      height:
          widget.position == SidebarPosition.top ||
                  widget.position == SidebarPosition.bottom
              ? (expanded ? 400 : 40)
              : double.infinity,
      child: Row(
        textDirection:
            widget.position == SidebarPosition.right
                ? TextDirection.rtl
                : TextDirection.ltr,
        children: [
          // Main sidebar column - feste Breite
          Container(
            width: 70,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    IconButton(
                      iconSize: 40,
                      icon: Icon(Icons.first_page_rounded, size: 40),
                      onPressed:
                          () => setState(() {
                            expanded = expanded;
                            //selectedWidget = SideBarWidget.pageOne;
                            widget.scrollNotifier.scrollToPage(1);
                          }),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        decoration: BoxDecoration(color: Colors.amber),
                        child: Text(
                          '1',
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                IconButton(
                  iconSize: 40,
                  icon: Icon(Icons.auto_awesome_mosaic, size: 40),
                  onPressed:
                      () => setState(() {
                        if (selectedWidget == SideBarWidget.miniView) {
                          expanded = !expanded;
                        }
                        selectedWidget = SideBarWidget.miniView;
                      }),
                ),
                SizedBox(height: 24),
                IconButton(
                  iconSize: 40,
                  icon: Icon(Icons.bookmark, size: 40),
                  onPressed:
                      () => setState(() {
                        if (selectedWidget == SideBarWidget.bookmarks) {
                          expanded = !expanded;
                        }
                        selectedWidget = SideBarWidget.bookmarks;
                      }),
                ),
                SizedBox(height: 24),
                // IconButton(
                //   iconSize: 40,
                //   icon: Icon(Icons.color_lens, size: 40),
                //   onPressed:
                //       () => setState(() {
                //         if (selectedWidget == SideBarWidget.colorPalette) {
                //           expanded = !expanded;
                //         }
                //         selectedWidget = SideBarWidget.colorPalette;
                //       }),
                // ),
              ],
            ),
          ),
          // Content column - nur wenn expanded
          if (expanded)
            Container(
              width: 400, // Feste Breite für Content
              child: Column(
                children: [
                  Expanded(
                    child:
                        selectedWidget == SideBarWidget.miniView
                            ? MiniView(
                              pdfAssetPath: "assets/pdfs/lafiamma.pdf",
                              scrollNotifier: widget.scrollNotifier,
                            )
                            : selectedWidget == SideBarWidget.bookmarks
                            ? FilteredView(
                              isMiniView: true,
                              scrollNotifier: widget.scrollNotifier,
                            )
                            : selectedWidget == SideBarWidget.colorPalette
                            ? Container() //ColorPaletteView()
                            : Container(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );

    switch (widget.position) {
      case SidebarPosition.left:
        return Align(alignment: Alignment.centerLeft, child: sidebarContent);
      case SidebarPosition.right:
        return Align(alignment: Alignment.centerRight, child: sidebarContent);
      case SidebarPosition.top:
        return Align(alignment: Alignment.topCenter, child: sidebarContent);
      case SidebarPosition.bottom:
        return Align(alignment: Alignment.bottomCenter, child: sidebarContent);
    }
  }
}
