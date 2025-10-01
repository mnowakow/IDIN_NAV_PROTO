import 'package:flutter/material.dart';
import 'package:idin_nav_prototype/scroll_notifier.dart';
import 'package:idin_nav_prototype/simple_pdf_viewer.dart';

class MiniView extends StatelessWidget {
  final String pdfAssetPath;
  final ScrollNotifier scrollNotifier;

  MiniView({Key? key, required this.pdfAssetPath, required this.scrollNotifier})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SimplePdfViewer(
      pdfAssetPath: pdfAssetPath,
      isMiniview: true,
      filter: null,
      scrollNotifier: scrollNotifier,
      pageName: "mini_viewer",
    );
  }
}
