import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:svg_path_parser/svg_path_parser.dart';
import 'package:idin_nav_prototype/paint_objects_notifier.dart';
import 'dart:io';
import 'dart:math' as math;

class PaintObjects {
  final List _totalList = [];
  final List<String> _svgPaths = [];
  List _currentObject = <Offset>[];
  final List<Offset> _moveOffset = <Offset>[];
  final List<Rect> _boundingBoxes = <Rect>[];
  final List<double> _scale = <double>[];
  bool isScaling = false;

  PaintObjectsNotifier pNotifier;
  Offset scrollOffset;
  int buttonState;
  int selectedObjectIndex;
  int selectedMenuItem;
  List<String> symbolPaths;

  PaintObjects(
    this.pNotifier,
    this.scrollOffset,
    this.buttonState,
    this.selectedObjectIndex,
    this.selectedMenuItem,
    this.symbolPaths,
  );

  int onPointerDown(PointerDownEvent details) {
    if (buttonState == 1) {
      selectedObjectIndex = _totalList.length;
      _currentObject = <Offset>[];
      _moveOffset.add(Offset(0.0, 0.0));
      _totalList.add(_currentObject);
      _scale.add(1.0);
    }
    if (buttonState == 2) {
      selectedObjectIndex = objectSelected(details.localPosition);
      if (selectedObjectIndex != -1 && inScaleBoxAndisPath(details))
        isScaling = true;
    }
    if (buttonState == 3 && selectedMenuItem != -1) {
      selectedObjectIndex = _totalList.length;
      String pathname = symbolPaths[selectedMenuItem];
      if (pathname.contains('/User')) {
        addSVG(pathname, details);
      } else {
        addSVG('assets/symbols/$pathname', details);
      }
      _scale.add(1.0);
    }
    return selectedObjectIndex;
  }

  void onPointerMove(PointerMoveEvent details) {
    if (buttonState == 1) {
      _currentObject.add(details.localPosition + scrollOffset);
    }
    if (buttonState == 2) {
      if (selectedObjectIndex >= 0) {
        if (isScaling) {
          setScale(details);
        } else {
          _moveOffset[selectedObjectIndex] += details.delta;
        }
      }
    }
  }

  void onPointerUp() {
    if (buttonState == 1) {
      addPathfromCurrObj();
    }
    if (buttonState == 2) {
      if (isScaling) {
        pNotifier.scalingObject();
        isScaling = false;
      } else {
        pNotifier.movingObject();
      }
    }
  }

  void updateStates(
    Offset scrollOffset,
    int buttonState,
    int selectedObjectIndex,
    int selectedMenuItem,
  ) {
    this.scrollOffset = scrollOffset;
    this.buttonState = buttonState;
    this.selectedObjectIndex = selectedObjectIndex;
    this.selectedMenuItem = selectedMenuItem;
  }

  bool inScaleBox(int i, Offset selectedPoint) {
    Offset specMoveOffset = _moveOffset[i];
    Offset topLeft = _boundingBoxes[i].topLeft - scrollOffset + specMoveOffset;
    Offset bottomRight = Offset(
      topLeft.dx + (_boundingBoxes[i].width * _scale[i]),
      topLeft.dy + (_boundingBoxes[i].height * _scale[i]),
    );
    Rect r = Rect.fromCenter(center: bottomRight, width: 15, height: 15);

    return r.contains(selectedPoint);
  }

  bool inScaleBoxAndisPath(PointerDownEvent details) {
    return inScaleBox(selectedObjectIndex, details.localPosition) &&
        _totalList[selectedObjectIndex][0].runtimeType.toString() ==
            '_NativePath';
  }

  void setScale(PointerMoveEvent details) {
    double width = _boundingBoxes[selectedObjectIndex].width;

    double distToBotLeft =
        (details.localPosition -
                (_boundingBoxes[selectedObjectIndex].bottomLeft +
                    _moveOffset[selectedObjectIndex]))
            .dx;

    double scale = distToBotLeft / width;

    _scale[selectedObjectIndex] = scale;
  }

  int objectSelected(Offset selectedPoint) {
    List<int> possibleObjects = <int>[];
    double closestDistance = 0.0;
    double currDistance = 0.0;
    int currObjectIndex = 0;
    int possibleObjectIndex = -1;

    Rect adjustedBox = Rect.zero;
    Offset bottomRight = Offset(0.0, 0.0);

    for (int i = 0; i < _totalList.length; i++) {
      bottomRight = Offset(
        _boundingBoxes[i].topLeft.dx + (_boundingBoxes[i].width * _scale[i]),
        _boundingBoxes[i].topLeft.dy + (_boundingBoxes[i].height * _scale[i]),
      );

      adjustedBox = Rect.fromPoints(_boundingBoxes[i].topLeft, bottomRight);
      if (adjustedBox.contains(selectedPoint + scrollOffset - _moveOffset[i]) ||
          inScaleBox(i, selectedPoint)) {
        possibleObjects.add(i);
      }
    }

    if (possibleObjects.isEmpty) return -1;
    if (possibleObjects.length == 1) {
      return possibleObjects[0];
    }

    int numOffsets = 0;

    for (int i = 0; i < possibleObjects.length; i++) {
      if (_totalList[i][0].runtimeType != 'Offset') {
        continue;
      }
      numOffsets++;
      currObjectIndex = possibleObjects[i];
      currDistance = smallestDistanceToObject(currObjectIndex, selectedPoint);
      if (numOffsets == 1 || currDistance < closestDistance) {
        closestDistance = currDistance;
        possibleObjectIndex = currObjectIndex;
        continue;
      }
    }

    if (numOffsets == 0) return possibleObjects[0];

    return possibleObjectIndex;
  }

  double smallestDistanceToObject(int i, Offset selectedPoint) {
    List l = _totalList[i];
    double closestDistanceSquared = 0.0;

    double yDistance = 0.0;
    double xDistance = 0.0;
    double currDistanceSquared = 0.0;
    int listIndex = 0;

    Offset closestOffset = Offset(0.0, 0.0);

    for (Offset o in l) {
      xDistance = o.dx + _moveOffset[i].dx - selectedPoint.dx;
      yDistance = o.dy - scrollOffset.dy + _moveOffset[i].dy - selectedPoint.dy;

      currDistanceSquared = Offset(xDistance, yDistance).distanceSquared;

      if (listIndex == 0 || currDistanceSquared < closestDistanceSquared) {
        closestDistanceSquared = currDistanceSquared;
        listIndex++;
        closestOffset = o;
      }
    }

    return closestDistanceSquared;
  }

  int deleteSelectedObject() {
    _totalList.removeAt(selectedObjectIndex);
    _svgPaths.removeAt(selectedObjectIndex);
    _moveOffset.removeAt(selectedObjectIndex);
    _boundingBoxes.removeAt(selectedObjectIndex);
    _scale.removeAt(selectedObjectIndex);
    pNotifier.deleteObject();
    return -1;
  }

  Rect findBoundingBox() {
    double minX = 0.0;
    double minY = 0.0;
    double maxX = 0.0;
    double maxY = 0.0;

    double offsetX = 0.0;
    double offsetY = 0.0;

    int i = 0;

    for (Offset o in _currentObject) {
      offsetX = o.dx;
      offsetY = o.dy;

      if (i == 0) {
        minX = o.dx;
        minY = o.dy;
        i++;
      }

      if (offsetX < minX) minX = offsetX;
      if (offsetX > maxX) maxX = offsetX;
      if (offsetY < minY) minY = offsetY;
      if (offsetY > maxY) maxY = offsetY;
    }

    return Rect.fromPoints(Offset(minX, minY), Offset(maxX, maxY));
  }

  Rect findBoundingBoxforPath(double picWidth, double picHeight) {
    Offset o = _totalList.last[1];
    return Rect.fromPoints(o, o + Offset(picWidth, picHeight));
  }

  void addSVG(String filepath, PointerDownEvent details) async {
    String svg = '';
    if (filepath.contains('/User')) {
      svg = await File(filepath).readAsString();
    } else {
      svg = await rootBundle.loadString(filepath);
    }

    final String? d = RegExp('d="(.|\\n)*?"').stringMatch(svg);
    Path path = stringToScaledAndTransPath(d!.substring(3, d.length - 1));
    Rect bBox = path.getBounds();

    _totalList.add([path, details.localPosition + scrollOffset]);
    _moveOffset.add(Offset(0.0, 0.0));
    _svgPaths.add(
      'Scaling and Translation Needed, ${d.substring(3, d.length - 1)}',
    );
    _boundingBoxes.add(findBoundingBoxforPath(bBox.width, bBox.height));
    pNotifier.addObject();
  }

  void addPathfromCurrObj() {
    List svgPoints = createSvgPoints(_currentObject);
    Path p = createPath(svgPoints);

    Rect bBox = p.getBounds();
    p = transformPath(p);

    _svgPaths.add(offsetsListToPath(svgPoints, bBox.topLeft));
    _totalList.removeLast();
    _totalList.add([p, bBox.topLeft + scrollOffset]);
    _boundingBoxes.add(findBoundingBox());
    pNotifier.addObject();
  }

  Path transformPath(Path p) {
    Rect bBox = p.getBounds();

    return p.transform(
      Float64List.fromList([
        1.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
        (-bBox.left),
        -bBox.top,
        0.0,
        1.0,
      ]),
    );
  }

  Path createPath(List svgPoints) {
    Path p = Path();

    for (int i = 0; i < svgPoints.length; i++) {
      if (i == 0) {
        p.moveTo(svgPoints[0][0].dx, svgPoints[0][0].dy);
      }
      p.addPolygon([
        svgPoints[i][0],
        svgPoints[i][1],
        svgPoints[i][2],
        svgPoints[i][3],
      ], true);
    }

    return p;
  }

  List createSvgPoints(List offsets) {
    Offset o = Offset(0.0, 0.0);
    Offset o2 = Offset(0.0, 0.0);
    Offset pOffset = Offset(0.0, 0.0);

    List svgPoints = [];

    for (int i = 0; i < offsets.length - 1; i++) {
      o = offsets[i] - scrollOffset;
      o2 = offsets[i + 1] - scrollOffset;
      pOffset = calculateLineOffset(o, o2);
      svgPoints.add([o - pOffset, o + pOffset, o2 + pOffset, o2 - pOffset]);
    }

    return svgPoints;
  }

  String offsetsListToPath(List svgPoints, Offset topLeft) {
    String path = '';
    for (int i = 0; i < svgPoints.length; i++) {
      path =
          path +
          polyToPath(
            svgPoints[i][0] - topLeft,
            svgPoints[i][1] - topLeft,
            svgPoints[i][2] - topLeft,
            svgPoints[i][3] - topLeft,
          );
    }
    return path;
  }

  String polyToPath(Offset one, Offset two, Offset three, Offset four) {
    return 'M${one.dx} ${one.dy} L${two.dx} ${two.dy} L${three.dx} ${three.dy} L${four.dx} ${four.dy} L${one.dx} ${one.dy} ';
  }

  Offset calculateLineOffset(Offset start, Offset end) {
    double startX = start.dx;
    double startY = start.dy;
    double endX = end.dx;
    double endY = end.dy;

    if (startY - endY == 0) return Offset(0.0, 2.5);
    if (startX - endX == 0) return Offset(2.5, 0.0);

    double intersectingSlope = -(startX - endX) / (startY - endY);
    double x = math.sqrt(6.25 / (1 + (intersectingSlope * intersectingSlope)));
    double y = intersectingSlope * x;
    return Offset(x, y);
  }

  Path stringToPath(String str) {
    return parseSvgPath(str);
  }

  Path stringToScaledAndTransPath(String str) {
    double scale = 0.1;
    Path path = parseSvgPath(str);
    Rect bBox = path.getBounds();
    Offset topRight = bBox.topRight;
    double picWidth = bBox.width;

    path = path.transform(
      Float64List.fromList([
        scale,
        0.0,
        0.0,
        0.0,
        0.0,
        scale,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
        (picWidth - topRight.dx) * scale,
        -topRight.dy * scale,
        0.0,
        1.0,
      ]),
    );

    return path;
  }

  void setUpDatafromDirectory(List data) {
    String editMessage = 'Scaling and Translation Needed, ';
    String svgData = '';
    Path p = Path();

    List<String> rectOffsets = <String>[];
    List<String> offsetPoints = <String>[];
    List<String> offsetPointsB = <String>[];
    Offset offset = Offset(0.0, 0.0);
    Offset offsetB = Offset(0.0, 0.0);

    for (int i = 0; i < data.length; i++) {
      //processing path
      svgData = data[i][0];
      if (svgData.contains(editMessage)) {
        p = stringToScaledAndTransPath(svgData.substring(editMessage.length));
      } else {
        p = stringToPath(svgData);
      }

      //processing scrollOffset + localOffset
      offsetPoints = data[i][1].split(',');
      offset = Offset(
        double.parse(offsetPoints[0]),
        double.parse(offsetPoints[1]),
      );

      //adding path to total list and svgPath
      _svgPaths.add(svgData);
      _totalList.add([p, offset]);

      //processing + adding move offset
      offsetPoints = data[i][2].split(',');
      offset = Offset(
        double.parse(offsetPoints[0]),
        double.parse(offsetPoints[1]),
      );
      _moveOffset.add(offset);

      //processing + adding bounding box
      rectOffsets = data[i][3].split('|');
      offsetPoints = rectOffsets[0].split(',');
      offsetPointsB = rectOffsets[1].split(',');

      offset = Offset(
        double.parse(offsetPoints[0]),
        double.parse(offsetPoints[1]),
      );
      offsetB = Offset(
        double.parse(offsetPointsB[0]),
        double.parse(offsetPointsB[1]),
      );
      _boundingBoxes.add(Rect.fromPoints(offset, offsetB));

      //processing + adding scale
      _scale.add(double.parse(data[i][4]));
    }
  }

  List<String> returnSvgPaths(List data) {
    List<String> l = [];

    for (int i = 0; i < data.length; i++) {
      l.add(data[i][0]);
    }

    return l;
  }

  List returnSvgData(List data) {
    String editMessage = 'Scaling and Translation Needed, ';
    String svgData = '';
    Path p = Path();
    List paths = [];

    List<String> offsetPoints = <String>[];
    Offset offset = Offset(0.0, 0.0);

    for (int i = 0; i < data.length; i++) {
      svgData = data[i][0];
      if (svgData.contains(editMessage)) {
        p = stringToScaledAndTransPath(svgData.substring(editMessage.length));
      } else {
        p = stringToPath(svgData);
      }

      offsetPoints = data[i][1].split(',');
      offset = Offset(
        double.parse(offsetPoints[0]),
        double.parse(offsetPoints[1]),
      );

      paths.add([p, offset]);
    }

    return paths;
  }

  List<Offset> returnMoveOffsetData(List data) {
    List<Offset> moveOffsets = [];
    List offsetPoints = [];
    Offset offset = Offset(0.0, 0.0);

    for (int i = 0; i < data.length; i++) {
      offsetPoints = data[i][2].split(',');
      offset = Offset(
        double.parse(offsetPoints[0]),
        double.parse(offsetPoints[1]),
      );
      moveOffsets.add(offset);
    }

    return moveOffsets;
  }

  List returnScaleData(List data) {
    List scale = [];
    for (int i = 0; i < data.length; i++) {
      scale.add(double.parse(data[i][4]));
    }
    return scale;
  }

  List getTotalList() {
    return _totalList;
  }

  List<String> getSvgPaths() {
    return _svgPaths;
  }

  List getCurrentObject() {
    return _currentObject;
  }

  List<Offset> getMoveOffset() {
    return _moveOffset;
  }

  List<Rect> getBoundingBoxes() {
    return _boundingBoxes;
  }

  List<double> getScale() {
    return _scale;
  }
}
