import 'package:flutter/material.dart';
import 'package:idin_nav_prototype/filter_notifier.dart';
import 'package:idin_nav_prototype/filtered_view.dart';
import 'package:idin_nav_prototype/pdf_document_provider.dart';
import 'package:idin_nav_prototype/scroll_notifier.dart';
import 'package:provider/provider.dart';

class MultiViewButton extends StatelessWidget {
  final ScrollNotifier scrollNotifier;
  const MultiViewButton({Key? key, required this.scrollNotifier})
    : super(key: key);

  void _navigateToAnotherPage(BuildContext context) {
    Navigator.pushNamed(context, '/multiview');
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.amber,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton(
            icon: const Icon(Icons.bookmarks),
            color: Colors.white,
            onPressed: () => _navigateToAnotherPage(context),
            tooltip: 'Go to Bookmarks Page',
          ),
        ),
      ),
    );
  }
}

class MultiViewPage extends StatefulWidget {
  final ScrollNotifier scrollNotifier;
  const MultiViewPage({Key? key, required this.scrollNotifier})
    : super(key: key);

  @override
  State<MultiViewPage> createState() => _MultiViewPageState();
}

class _MultiViewPageState extends State<MultiViewPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarked View')),
      body: Stack(
        children: [
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.5,
              child: FilteredView(
                isMiniView: false,
                scrollNotifier: widget.scrollNotifier,
                scrollDirection: Axis.vertical,
              ),
            ),
          ),
          PageSidebar(
            pdfAssetPath: "assets/pdfs/lafiamma.pdf",
            filteredPages: FilterNotifier.instance.pages,
            scrollNotifier: widget.scrollNotifier,
          ),
        ],
      ),
    );
  }
}

class PageSidebar extends StatefulWidget {
  final String pdfAssetPath;
  final List<int> filteredPages;
  final ScrollNotifier scrollNotifier;
  final ValueChanged<int>? onSectionTap;

  const PageSidebar({
    Key? key,
    required this.pdfAssetPath,
    required this.filteredPages,
    this.onSectionTap,
    required this.scrollNotifier,
  }) : super(key: key);

  @override
  State<PageSidebar> createState() => _PageSidebarState();
}

class _PageSidebarState extends State<PageSidebar> {
  int documentLength = 0;
  int foundSection = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<PdfDocumentProvider>().load(widget.pdfAssetPath);
    final pdfProvider = context.watch<PdfDocumentProvider>();
    final document = pdfProvider.document;
    final documentLength = document?.pages.length ?? 0;
    setState(() {
      this.documentLength = documentLength ~/ 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final sectionWidth = documentLength > 0 ? width / documentLength : width;

    return Align(
      alignment: Alignment(0.0, 0.9),
      child: Container(
        width: width,
        height: 150,
        child: Row(
          children: List.generate(documentLength, (index) {
            final isFiltered = widget.filteredPages.contains(index + 1);
            var mappedSectionIndex = 0;

            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                if (isFiltered) {
                  setState(() {
                    foundSection = index + 1;
                    mappedSectionIndex =
                        widget.filteredPages.indexOf(foundSection) + 1;
                  });
                  print(
                    "isFiltered: $foundSection, ceil: ${(foundSection * 2).ceil()}",
                  );
                  widget.scrollNotifier.scrollToPage(
                    (mappedSectionIndex * 2).ceil(),
                  ); // Call "ScrollTo" -> calls notifyListeners() -> call function in pdfView to render
                } else {
                  // Find nearest filtered page within 5 sections
                  int? nearestFilteredPage;
                  int minDistance = 10; // Start with distance greater than 5

                  for (int filteredPage in widget.filteredPages) {
                    int distance = (filteredPage - (index + 1)).abs();
                    if (distance <= 9 && distance < minDistance) {
                      minDistance = distance;
                      nearestFilteredPage = filteredPage;
                    }
                  }
                  setState(() {
                    foundSection = nearestFilteredPage ?? foundSection;
                  });

                  final mappedSectionIndex =
                      widget.filteredPages.indexOf(foundSection) + 1;
                  if (nearestFilteredPage != null) {
                    widget.scrollNotifier.scrollToPage(
                      (mappedSectionIndex * 2).ceil(),
                    );
                  }
                }
              },
              child: Container(
                width: sectionWidth,
                height: 400,
                decoration: BoxDecoration(
                  color:
                      foundSection == index + 1
                          ? Colors.red
                          : isFiltered
                          ? Colors.amberAccent
                          : Colors.transparent,
                  border: Border(
                    right: BorderSide(
                      color: Colors.black45,
                      width: index == documentLength - 1 ? 0 : 1,
                    ),
                  ),
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: sectionWidth / 2,
                    height: 400,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border(
                        left: BorderSide(
                          color: Colors.black45,
                          width: index == documentLength - 1 ? 0 : 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
