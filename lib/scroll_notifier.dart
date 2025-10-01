import 'package:flutter/material.dart';

class ScrollNotifier extends ChangeNotifier {
  final ScrollController sc = ScrollController();
  ScrollController get scrollController => sc;

  int page = 0;
  int get targetPage => (page / 2).ceil() - 1; // adjusted for double page

  void scrollToPage(int index) {
    page = index;
    notifyListeners();
  }
}
