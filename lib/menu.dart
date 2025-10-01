import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:idin_nav_prototype/menu_notifier.dart';
import 'dart:io';

class Menu extends StatefulWidget {
  final MenuNotifier menuNotifier;

  const Menu(this.menuNotifier, {super.key});

  @override
  State<StatefulWidget> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  List<String> symbolPaths = <String>[];
  List<Widget> symbolSVGs = <Widget>[];

  bool isVisible = true;

  int selectedMenuButton = -1;

  @override
  Widget build(BuildContext context) {
    return Scrollbar(thickness: 10, child: ListView(children: buttonRows()));
  }

  Icon windowIcon() {
    if (isVisible) return Icon(Icons.minimize);
    return Icon(Icons.maximize);
  }

  void initializePaths() {
    symbolPaths = widget.menuNotifier.symbolPaths;
    symbolPaths.sort();
  }

  void initializeSVGs() {
    symbolSVGs.clear();
    for (String pathname in symbolPaths) {
      if (pathname.contains('/Users')) {
        symbolSVGs.add(
          SvgPicture.file(File(pathname), width: 75.0, height: 75.0),
        );
      } else {
        symbolSVGs.add(
          SvgPicture.asset(
            'assets/symbols/$pathname',
            width: 75.0,
            height: 75.0,
          ),
        );
      }
    }
  }

  Widget symbolButton(int i) {
    return OutlinedButton(
      onPressed: () {
        setState(() {
          selectedMenuButton = i;
          widget.menuNotifier.updateSelectedMenuItem(selectedMenuButton);
        });
      },
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: sideColor(i), width: 3.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        fixedSize: Size(125.0, 125.0),
        backgroundColor: Colors.white,
      ),
      child: symbolSVGs[i],
    );
  }

  Color sideColor(int targetButton) {
    if (selectedMenuButton == targetButton) {
      return Colors.amberAccent;
    } else {
      return Colors.black;
    }
  }

  Widget symbolButtonRow(int i, List<List<Widget>> symbolButtonRowList) {
    return Row(children: symbolButtonRowList[i]);
  }

  List<Widget> buttonRows() {
    List<List<Widget>> symbolButtonRowList = <List<Widget>>[];
    List<Widget> symbolButtonRows = <Widget>[];
    List currRow = [];

    initializePaths();
    initializeSVGs();

    for (int i = 0; i < symbolSVGs.length; i++) {
      if (i % 4 == 0) {
        symbolButtonRowList.add([]);
        currRow = symbolButtonRowList.last;
      }
      currRow.add(symbolButton(i));
    }

    for (int i = 0; i < symbolButtonRowList.length; i++) {
      symbolButtonRows.add(symbolButtonRow(i, symbolButtonRowList));
    }

    return symbolButtonRows;
  }
}
