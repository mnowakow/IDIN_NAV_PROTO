import 'package:flutter/material.dart';

class MenuNotifier extends ChangeNotifier{
  int _selectedMenuItem = -1;
  final List<String> _symbolPaths = ['u1D106.svg',	'u1D10E.svg',	'u1D12A.svg',	'u1D192.svg',	
      'uni266F.svg', 'u1D107.svg',	'u1D110.svg',	'u1D18F.svg',	
      'u1D193.svg', 'u1D10A.svg',	'u1D112.svg',	'u1D190.svg',	
      'uni266D.svg', 'u1D10B.svg',	'u1D120.svg',	'u1D191.svg',	
      'uni266E.svg'];

  int get selectedMenuItem => _selectedMenuItem;
  List<String> get symbolPaths => _symbolPaths;

  void updateSelectedMenuItem(int selectedMenuItem){
    _selectedMenuItem = selectedMenuItem;
    notifyListeners();
  }

  void addSymbolPath(String path){
    _symbolPaths.add(path);
  }
}