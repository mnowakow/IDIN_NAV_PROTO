import 'dart:ui';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:idin_nav_prototype/filter_notifier.dart';
import 'package:idin_nav_prototype/pdf_document_provider.dart';
import 'package:pdfrx/pdfrx.dart' as pdfrx;
import 'package:provider/provider.dart';

import 'side_bar.dart';
import 'scroll_notifier.dart';

class SimplePdfViewer extends StatefulWidget {
  final String pdfAssetPath;
  final bool isMiniview;
  final List<int>? filter;
  final ValueChanged<int>? onPageTap;
  ScrollNotifier? scrollNotifier;
  final Axis? scrollDirection;
  final String pageName;

  SimplePdfViewer({
    super.key,
    required this.pdfAssetPath,
    required this.isMiniview,
    this.filter,
    this.onPageTap,
    this.scrollNotifier,
    this.scrollDirection,
    required this.pageName,
  });

  @override
  State<SimplePdfViewer> createState() => _SimplePdfViewerState();
}

class _SimplePdfViewerState extends State<SimplePdfViewer> {
  final GlobalKey _scrollViewKey = GlobalKey();
  final GlobalKey pageKeyLeft = GlobalKey();
  final GlobalKey pageKeyRight = GlobalKey();
  late final ScrollController _internalScrollController;
  var ownPageSize = 0.0;

  void initStuff() {
    context.read<PdfDocumentProvider>().load(widget.pdfAssetPath);
    _internalScrollController = ScrollController();

    widget.scrollNotifier?.addListener(() {
      _onScrollChanged();
    });
  }

  @override
  void initState() {
    super.initState();
    initStuff();
    if (!widget.isMiniview) return;
  }

  @override
  void didUpdateWidget(covariant SimplePdfViewer oldWidget) {
    // TODO: implement didUpdateWidget
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listener neu setzen, falls sie verloren gegangen sind
    if (widget.scrollNotifier != null && !widget.scrollNotifier!.hasListeners) {
      widget.scrollNotifier!.addListener(_onScrollChanged);
    }
  }

  void _onScrollChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? renderBoxLeft =
          pageKeyLeft.currentContext?.findRenderObject() as RenderBox?;
      final RenderBox? renderBoxRight =
          pageKeyRight.currentContext?.findRenderObject() as RenderBox?;
      if (renderBoxLeft != null) {
        ownPageSize = renderBoxLeft.size.height;
      } else if (renderBoxRight != null) {
        ownPageSize = renderBoxRight.size.height;
      } else {
        return;
      }
      _internalScrollController.jumpTo(
        ownPageSize * (widget.scrollNotifier?.targetPage ?? 0),
      );
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget view(
    itemCount,
    document,
    pageCount,
    annotations,
    transformationController,
  ) {
    return InteractiveViewer(
      transformationController: transformationController,
      panEnabled: true,
      scaleEnabled: true,
      minScale: 0.5,
      maxScale: 5.0,
      child: PdfView(
        key: _scrollViewKey,
        widget: widget,
        itemCount: itemCount,
        document: document,
        pageCount: pageCount,
        pageKeyLeft: pageKeyLeft,
        pageKeyRight: pageKeyRight,
        scrollController: _internalScrollController,
        //annotations: annotations,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pdfProvider = context.watch<PdfDocumentProvider>();
    final document = pdfProvider.document;

    if (document == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pageCount = document.pages.length;
    final itemCount = (pageCount + 1) ~/ 2;

    // List<Widget> viewList() {
    //   return List.generate(itemCount, (index) {
    //     int currentDoublePage = index + 1;
    //     // Erstelle individuelle Keys für jede Seite

    //     if (widget.filter != null &&
    //         !widget.filter!.contains(currentDoublePage)) {
    //       return SizedBox.shrink(); // Skip this item if filtered
    //     }
    //     final leftPage = index * 2 + 1;
    //     final rightPage = index * 2 + 2;
    //     return Padding(
    //       padding: const EdgeInsets.symmetric(vertical: 0),
    //       child: Stack(
    //         children: [
    //           Center(
    //             child: Row(
    //               mainAxisSize: MainAxisSize.min,
    //               crossAxisAlignment: CrossAxisAlignment.start,
    //               children: [
    //                 Expanded(
    //                   key: leftPage == 1 ? pageKeyLeft : null,
    //                   child: GestureDetector(
    //                     onTap: () {
    //                       if (widget.onPageTap != null) {
    //                         widget.onPageTap!(leftPage);
    //                       }
    //                       if (widget.isMiniview) {
    //                         // Prüfe erst nach einem Frame, ob der Key einen Context hat

    //                         widget.scrollNotifier?.scrollToPage(leftPage);
    //                       }
    //                     },
    //                     child: Stack(
    //                       alignment: Alignment.topCenter,
    //                       children: [
    //                         pdfrx.PdfPageView(
    //                           document: document,
    //                           pageNumber: leftPage,
    //                         ),
    //                         if (widget.isMiniview)
    //                           PageNumberBadge(pageNumber: leftPage),
    //                       ],
    //                     ),
    //                   ),
    //                 ),
    //                 if (rightPage <= pageCount)
    //                   Expanded(
    //                     key: rightPage == 2 ? pageKeyRight : null,
    //                     child: GestureDetector(
    //                       onTap: () {
    //                         if (widget.onPageTap != null) {
    //                           widget.onPageTap!(rightPage);
    //                         }
    //                         if (widget.isMiniview) {
    //                           widget.scrollNotifier?.scrollToPage(rightPage);
    //                         }
    //                       },
    //                       child: Stack(
    //                         alignment: Alignment.topCenter,
    //                         children: [
    //                           pdfrx.PdfPageView(
    //                             document: document,
    //                             pageNumber: rightPage,
    //                           ),
    //                           if (widget.isMiniview)
    //                             PageNumberBadge(pageNumber: rightPage),
    //                         ],
    //                       ),
    //                     ),
    //                   ),
    //               ],
    //             ),
    //           ),
    //           if (!widget.isMiniview && widget.filter == null) ...[
    //             BookmarkBadge(pageNumber: currentDoublePage),
    //           ],
    //         ],
    //       ),
    //     );
    //   });
    // }

    // return Scaffold(
    //   body: SingleChildScrollView(
    //     key: PageStorageKey(widget.pageName),
    //     scrollDirection: widget.scrollDirection ?? Axis.vertical,
    //     controller: _internalScrollController,
    //     //widget.isMiniview ? null : widget.scrollNotifier?.scrollController,
    //     child:
    //         widget.scrollDirection == Axis.horizontal
    //             ? Row(mainAxisSize: MainAxisSize.min, children: viewList())
    //             : Column(mainAxisSize: MainAxisSize.min, children: viewList()),
    //   ),
    // );
    return Scaffold(
      body: view(
        itemCount,
        document,
        pageCount,
        [],
        TransformationController(),
      ),
    );
  }
}

class PdfView extends StatelessWidget {
  final SimplePdfViewer widget;
  final int itemCount;
  final pdfrx.PdfDocument? document;
  final int pageCount;
  final GlobalKey pageKeyLeft;
  final GlobalKey pageKeyRight;
  final ScrollController scrollController;
  //final List<Annotation> annotations;

  const PdfView({
    super.key,
    required this.widget,
    required this.itemCount,
    required this.document,
    required this.pageCount,
    required this.pageKeyLeft,
    required this.pageKeyRight,
    required this.scrollController,
    //required this.annotations,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        // Disable scrolling when using stylus
        if (scrollNotification is ScrollStartNotification) {
          final dragDetails = scrollNotification.dragDetails;
          if (dragDetails != null &&
              dragDetails.kind == PointerDeviceKind.stylus) {
            return true; // Consume the notification to prevent scrolling
          }
        }
        return false;
      },
      child: SingleChildScrollView(
        controller: scrollController,
        child: Stack(
          children: [
            Column(
              children: List.generate(itemCount, (index) {
                int currentDoublePage = index + 1;
                if (widget.filter != null &&
                    !widget.filter!.contains(currentDoublePage)) {
                  return SizedBox.shrink(); // Skip this item if filtered
                }
                final leftPage = index * 2 + 1;
                final rightPage = index * 2 + 2;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 0),
                  child: Stack(
                    children: [
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              key: leftPage == 1 ? pageKeyLeft : null,
                              child: GestureDetector(
                                onTap: () {
                                  if (widget.onPageTap != null) {
                                    widget.onPageTap!(leftPage);
                                  }
                                  if (widget.isMiniview) {
                                    // Prüfe erst nach einem Frame, ob der Key einen Context hat

                                    widget.scrollNotifier?.scrollToPage(
                                      leftPage,
                                    );
                                  }
                                },
                                child: Stack(
                                  alignment: Alignment.topCenter,
                                  children: [
                                    pdfrx.PdfPageView(
                                      document: document,
                                      pageNumber: leftPage,
                                    ),
                                    if (widget.isMiniview)
                                      PageNumberBadge(pageNumber: leftPage),
                                  ],
                                ),
                              ),
                            ),
                            if (rightPage <= pageCount)
                              Expanded(
                                key: rightPage == 2 ? pageKeyRight : null,
                                child: GestureDetector(
                                  onTap: () {
                                    if (widget.onPageTap != null) {
                                      widget.onPageTap!(rightPage);
                                    }
                                    if (widget.isMiniview) {
                                      widget.scrollNotifier?.scrollToPage(
                                        rightPage,
                                      );
                                    }
                                  },
                                  child: Stack(
                                    alignment: Alignment.topCenter,
                                    children: [
                                      pdfrx.PdfPageView(
                                        document: document,
                                        pageNumber: rightPage,
                                      ),
                                      if (widget.isMiniview)
                                        PageNumberBadge(pageNumber: rightPage),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (!widget.isMiniview && widget.filter == null) ...[
                        BookmarkBadge(pageNumber: currentDoublePage),
                      ],
                    ],
                  ),
                );
              }),
            ),
            //Positioned.fill(child: Stack(children: annotations)),
          ],
        ),
      ),
    );
  }
}

class PageNumberBadge extends StatelessWidget {
  final int pageNumber;

  const PageNumberBadge({Key? key, required this.pageNumber}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      left: 8,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$pageNumber',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class BookmarkBadge extends StatefulWidget {
  final int pageNumber;

  const BookmarkBadge({Key? key, required this.pageNumber}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _BookmarkState();
}

class _BookmarkState extends State<BookmarkBadge> {
  bool isBookmarked = false;
  final FilterNotifier filterNotifier = FilterNotifier.instance;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      left: 0,
      right: 0,
      child: Center(
        child: FloatingActionButton(
          heroTag: null,
          backgroundColor: isBookmarked ? Colors.red : Colors.black54,
          onPressed: () {
            setState(() {
              isBookmarked = !isBookmarked;
              if (isBookmarked) {
                filterNotifier.addPage(widget.pageNumber);
              } else {
                filterNotifier.removePage(widget.pageNumber);
              }
            });
          },
          child: Icon(
            isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
