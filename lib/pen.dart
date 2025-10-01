import 'package:flutter/material.dart';
import 'dart:typed_data';


class Pen extends CustomPainter {
  final List totalList;
  final Offset scrollOffset;
  final List<Offset> moveOffset;
  final int selectedObjectIndex;
  final List<Rect> boundingBoxes;
  final List<double> scale;
  final int buttonState;

  final List otherTotalList;
  final List<Offset> otherMoveOffset;
  final List otherScale;
  final int otherSelectedObjectIndex;

  Pen(this.totalList, this.scrollOffset, this.moveOffset, 
      this.selectedObjectIndex, this.boundingBoxes, this.scale, 
      this.buttonState, this.otherTotalList, this.otherMoveOffset, this.otherScale, this.otherSelectedObjectIndex);

  @override
  void paint(Canvas canvas, Size size) {
    List l;
    for(int i = 0; i < otherTotalList.length; i++){
      l = otherTotalList[i];
      if(l.isEmpty) continue;
      if(l[0].runtimeType.toString() == "_NativePath"){
        canvas.drawPath(l[0].transform(Float64List.fromList([
          otherScale[i], 0, 0, 0,
          0, otherScale[i], 0, 0,
          0, 0, 1, 0,
          l[1].dx + otherMoveOffset[i].dx, l[1].dy - scrollOffset.dy + otherMoveOffset[i].dy, 0, 1,
        ]),), 
          Paint()
          ..color = Colors.blue
          ..strokeWidth = 1.0,
        );
      }
    }
    
    for(int j = 0; j < totalList.length; j++){
      l = totalList[j];
      if(l.isEmpty) continue;
      if(l[0].runtimeType == Offset){
        for(int i = 0; i < l.length - 1; i++){
        canvas.drawLine(
          l.elementAt(i) - scrollOffset + moveOffset[j], 
          l.elementAt(i + 1) - scrollOffset + moveOffset[j], 
          Paint() 
          ..color = Colors.black
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 5.0,
        );
        }
      }
      if(l[0].runtimeType.toString() == "_NativePath"){
        canvas.drawPath(l[0].transform(Float64List.fromList([
          scale[j], 0, 0, 0,
          0, scale[j], 0, 0,
          0, 0, 1, 0,
          l[1].dx + moveOffset[j].dx, l[1].dy - scrollOffset.dy + moveOffset[j].dy, 0, 1,
        ]),), 
          Paint()
          ..color = Colors.black
          ..strokeWidth = 1.0,
        );
      }
    }

    if(otherSelectedObjectIndex != -1 && (buttonState == 2)){
      Path p = otherTotalList[otherSelectedObjectIndex][0];
      Offset specMoveOffset = otherTotalList[otherSelectedObjectIndex][1];
      Offset moveOffset = otherMoveOffset[otherSelectedObjectIndex];
      Rect r = p.getBounds();

      Offset topLeft = r.topLeft - scrollOffset + specMoveOffset + moveOffset;
      Offset bottomRight = r.bottomRight - scrollOffset + specMoveOffset + moveOffset;

      canvas.drawRect(
         Rect.fromPoints(topLeft, bottomRight),
        Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.blueAccent
        ..strokeWidth = 1.0,
      );
    }

    if(selectedObjectIndex != -1 && (buttonState == 2)){
      Offset specMoveOffset = moveOffset[selectedObjectIndex];
      Offset topLeft = boundingBoxes[selectedObjectIndex].topLeft - scrollOffset + specMoveOffset;
      Offset bottomRight = Offset(topLeft.dx + (boundingBoxes[selectedObjectIndex].width * scale[selectedObjectIndex]),
      topLeft.dy + (boundingBoxes[selectedObjectIndex].height * scale[selectedObjectIndex]));
      
      canvas.drawRect(
        Rect.fromPoints(topLeft, bottomRight),
        Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.blueAccent
        ..strokeWidth = 1.0,
      );

      if(totalList[selectedObjectIndex][0].runtimeType.toString() == "_NativePath"){
        canvas.drawRect(
          Rect.fromCenter(center: bottomRight, width: 15, height: 15),
          Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.white
          ..strokeWidth = 1.0,
        );

        canvas.drawRect(
          Rect.fromCenter(center: bottomRight, width: 15, height: 15),
          Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.blueAccent
          ..strokeWidth = 1.0,
        );
      }
    }
  }

  @override
  bool shouldRepaint(Pen oldDelegate){
    return oldDelegate.totalList != totalList;
  }
}
