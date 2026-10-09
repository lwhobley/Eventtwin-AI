import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'layout_engine.dart';
import 'model.dart';

class LayoutCanvas extends StatefulWidget {
  const LayoutCanvas({
    super.key,
    required this.space,
    required this.tables,
    this.onMoved,
  });
  final Space space;
  final List<TablePosition> tables;
  final void Function(int, TablePosition)? onMoved;
  @override
  State<LayoutCanvas> createState() => _LayoutCanvasState();
}

class _LayoutCanvasState extends State<LayoutCanvas> {
  int? selected;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = math.min(constraints.maxWidth, 900.0);
      final height =
          width * widget.space.heightMeters / widget.space.widthMeters;
      return SizedBox(
        width: width,
        height: height,
        child: GestureDetector(
          onPanStart: widget.onMoved == null
              ? null
              : (details) {
                  final point = details.localPosition;
                  final x = point.dx / width * widget.space.widthMeters;
                  final y = point.dy / height * widget.space.heightMeters;
                  var distance = double.infinity;
                  int? nearest;
                  for (var i = 0; i < widget.tables.length; i++) {
                    final d = math.sqrt(
                      math.pow(widget.tables[i].x - x, 2) +
                          math.pow(widget.tables[i].y - y, 2),
                    );
                    if (d < tableDiameterMeters && d < distance) {
                      distance = d;
                      nearest = i;
                    }
                  }
                  selected = nearest;
                },
          onPanUpdate: widget.onMoved == null
              ? null
              : (details) {
                  if (selected == null) return;
                  widget.onMoved!(
                    selected!,
                    TablePosition(
                      details.localPosition.dx /
                          width *
                          widget.space.widthMeters,
                      details.localPosition.dy /
                          height *
                          widget.space.heightMeters,
                    ),
                  );
                },
          onPanEnd: widget.onMoved == null ? null : (_) => selected = null,
          child: CustomPaint(
            painter: _RoomPainter(widget.space, widget.tables),
            size: Size(width, height),
          ),
        ),
      );
    },
  );
}

class _RoomPainter extends CustomPainter {
  _RoomPainter(this.space, this.tables);
  final Space space;
  final List<TablePosition> tables;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = const Color(0xff10283c)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    final scale = size.width / space.widthMeters;
    for (var i = 0; i < tables.length; i++) {
      final center = Offset(tables[i].x * scale, tables[i].y * scale);
      canvas.drawCircle(
        center,
        tableDiameterMeters / 2 * scale,
        Paint()..color = const Color(0xffb78c58),
      );
      canvas.drawCircle(
        center,
        tableDiameterMeters / 2 * scale,
        Paint()
          ..color = const Color(0xff10283c)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      final text = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: const TextStyle(color: Colors.white, fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, center - Offset(text.width / 2, text.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _RoomPainter oldDelegate) =>
      oldDelegate.tables != tables || oldDelegate.space != space;
}

Future<void> exportPdf(
  Space space,
  EventRecord event,
  LayoutPlan layout,
  List<TablePosition> tables,
) async {
  final doc = pw.Document();
  const planWidth = 480.0;
  final planHeight = planWidth * space.heightMeters / space.widthMeters;
  final scale = planWidth / space.widthMeters;
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'EventTwin AI | Planning draft',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('${event.name} · ${layout.name} · Version ${layout.version}'),
          pw.Text(
            '${space.name}: ${metersToFeet(space.widthMeters).toStringAsFixed(1)} × ${metersToFeet(space.heightMeters).toStringAsFixed(1)} ft',
          ),
          pw.Text(
            '${tables.length} round tables · ${tables.length * seatsPerTable} seats',
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            width: planWidth,
            height: planHeight,
            decoration: pw.BoxDecoration(border: pw.Border.all()),
            child: pw.Stack(
              children: [
                for (var i = 0; i < tables.length; i++)
                  pw.Positioned(
                    left: tables[i].x * scale - tableDiameterMeters / 2 * scale,
                    top: tables[i].y * scale - tableDiameterMeters / 2 * scale,
                    child: pw.Container(
                      width: tableDiameterMeters * scale,
                      height: tableDiameterMeters * scale,
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        color: PdfColors.brown300,
                      ),
                      alignment: pw.Alignment.center,
                      child: pw.Text('${i + 1}'),
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Measurements are based on user-verified room dimensions. Exits and fixed features are not modeled; this is not a final safety or code-compliance approval.',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    ),
  );
  await Printing.layoutPdf(
    onLayout: (_) => doc.save(),
    name: 'eventtwin-${event.id}-${layout.version}.pdf',
  );
}
