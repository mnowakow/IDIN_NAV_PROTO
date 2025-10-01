import 'package:flutter/material.dart';

class TemplateCreatorPen extends CustomPainter {

  final List<Offset> points;

  TemplateCreatorPen(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    for(int i = 0; i < points.length - 1; i++){
      canvas.drawLine(
        points[i], 
        points[i + 1],
        Paint()
          ..color = Colors.black
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 5.0,
      );
    }
  }
  
  @override
  bool shouldRepaint(TemplateCreatorPen oldDelegate){
    return oldDelegate.points != points;
  }
}