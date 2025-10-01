import 'package:flutter/material.dart';

class TemplateCreatorNotifier extends ChangeNotifier {
  List<Offset> _points = [];

  List<Offset> get points => _points;

  void submitPoints(List<Offset> points){
    _points = points;
    notifyListeners();
  }
}