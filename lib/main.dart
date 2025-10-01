import 'package:flutter/material.dart';
import 'package:idin_nav_prototype/pdf_document_provider.dart';
import 'package:idin_nav_prototype/login_page.dart';
import 'package:idin_nav_prototype/multiview.dart';
import 'package:idin_nav_prototype/scroll_notifier.dart';
import 'package:idin_nav_prototype/side_bar.dart';
import 'package:idin_nav_prototype/simple_pdf_viewer.dart';

import 'package:idin_nav_prototype/login_page_notifier.dart';
import "package:provider/provider.dart";

//import 'dart:io' as io;

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => PdfDocumentProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  MyApp({super.key});
  final GlobalKey<NavigatorState> nav = GlobalKey<NavigatorState>();
  final LoginPageNotifier lpNotifier = LoginPageNotifier();
  final ScrollNotifier scrollNotifier = ScrollNotifier();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: nav,
      title: 'IDIN Navigation Prototype',
      routes: {
        '/multiview':
            (context) => MultiViewPage(scrollNotifier: scrollNotifier),
      },
      home: Stack(
        children: [
          SimplePdfViewer(
            pdfAssetPath: 'assets/pdfs/lafiamma.pdf',
            isMiniview: false,
            filter: null,
            scrollNotifier: scrollNotifier,
            pageName: "main_pdf_viewer",
          ),
          ExpandableSidebar(
            position: SidebarPosition.right,
            scrollNotifier: scrollNotifier,
          ),
          MultiViewButton(scrollNotifier: scrollNotifier),
        ],
      ),
    );
  }
}
