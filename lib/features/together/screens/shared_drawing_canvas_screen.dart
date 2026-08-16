import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../memories/repositories/memories_repository.dart';

class DrawnPoint {
  final Offset point;
  final Paint paint;

  DrawnPoint(this.point, this.paint);
}

class SharedDrawingCanvasScreen extends StatefulWidget {
  final String relationshipId;
  final String partnerName;

  const SharedDrawingCanvasScreen({
    super.key,
    this.relationshipId = 'demo_couple_space',
    this.partnerName = 'Maya',
  });

  @override
  State<SharedDrawingCanvasScreen> createState() => _SharedDrawingCanvasScreenState();
}

class _SharedDrawingCanvasScreenState extends State<SharedDrawingCanvasScreen> {
  final List<DrawnPoint?> _points = [];
  Color _selectedColor = AppColors.champagne;
  double _strokeWidth = 3.5;
  bool _isEraser = false;

  final List<Color> _colors = [
    AppColors.champagne,
    AppColors.roseDust,
    const Color(0xFFE63946),
    const Color(0xFF457B9D),
    const Color(0xFF52B788),
    Colors.white,
  ];

  void _clearCanvas() {
    setState(() => _points.clear());
  }

  void _undo() {
    if (_points.isNotEmpty) {
      setState(() {
        while (_points.isNotEmpty && _points.last != null) {
          _points.removeLast();
        }
        if (_points.isNotEmpty) _points.removeLast();
      });
    }
  }

  void _saveToMemories() {
    final repo = MemoriesRepository();
    repo.createMemory(
      relationshipId: widget.relationshipId,
      title: 'Our Live Love Canvas Doodle 🎨',
      description: 'Drawn together in real-time with ${widget.partnerName} on our private couple canvas.',
      memoryDate: DateTime.now(),
      category: 'Milestone',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Doodle saved to Memories with ${widget.partnerName}! 🎨✨'),
        backgroundColor: AppColors.champagneDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F121C) : const Color(0xFFF7F5F0),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Shared Canvas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(
              'Private with ${widget.partnerName}',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.champagne : AppColors.champagneDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo_rounded, size: 22),
            tooltip: 'Undo',
            onPressed: _undo,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, size: 22),
            tooltip: 'Clear',
            onPressed: _clearCanvas,
          ),
          IconButton(
            icon: const Icon(Icons.save_alt_rounded, color: AppColors.champagne, size: 22),
            tooltip: 'Save to Memories',
            onPressed: _saveToMemories,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Drawing Surface
            Expanded(
              child: ClipRect(
                child: SizedBox.expand(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (details) {
                      final paint = Paint()
                        ..color = _isEraser ? (isDark ? const Color(0xFF0F121C) : const Color(0xFFF7F5F0)) : _selectedColor
                        ..strokeCap = StrokeCap.round
                        ..strokeWidth = _isEraser ? _strokeWidth * 3 : _strokeWidth
                        ..isAntiAlias = true;

                      setState(() {
                        _points.add(DrawnPoint(details.localPosition, paint));
                      });
                    },
                    onPanUpdate: (details) {
                      final paint = Paint()
                        ..color = _isEraser ? (isDark ? const Color(0xFF0F121C) : const Color(0xFFF7F5F0)) : _selectedColor
                        ..strokeCap = StrokeCap.round
                        ..strokeWidth = _isEraser ? _strokeWidth * 3 : _strokeWidth
                        ..isAntiAlias = true;

                      setState(() {
                        _points.add(DrawnPoint(details.localPosition, paint));
                      });
                    },
                    onPanEnd: (_) {
                      setState(() {
                        _points.add(null);
                      });
                    },
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _CanvasPainter(_points),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 2. Bottom Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -3)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Palette & Eraser
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: _colors.map((c) {
                          final isSelected = !_isEraser && _selectedColor == c;
                          return GestureDetector(
                            onTap: () => setState(() {
                              _selectedColor = c;
                              _isEraser = false;
                            }),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? (isDark ? Colors.white : Colors.black) : Colors.black26,
                                  width: isSelected ? 2.5 : 1,
                                ),
                              ),
                              child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.black) : null,
                            ),
                          );
                        }).toList(),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.cleaning_services_rounded,
                          color: _isEraser ? AppColors.champagne : Colors.grey,
                        ),
                        tooltip: 'Eraser',
                        onPressed: () => setState(() => _isEraser = !_isEraser),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Slider & Send Button
                  Row(
                    children: [
                      const Icon(Icons.line_weight_rounded, size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            activeTrackColor: AppColors.champagne,
                            thumbColor: AppColors.champagne,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          ),
                          child: Slider(
                            value: _strokeWidth,
                            min: 1.5,
                            max: 12.0,
                            onChanged: (val) => setState(() => _strokeWidth = val),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Doodle flashed to ${widget.partnerName}\'s screen! 💕🕊️'),
                              backgroundColor: AppColors.champagneDark,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.champagne,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.send_rounded, size: 14, color: Colors.black),
                              SizedBox(width: 4),
                              Text('Send 💕', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final List<DrawnPoint?> points;

  _CanvasPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!.point, points[i + 1]!.point, points[i]!.paint);
      } else if (points[i] != null && points[i + 1] == null) {
        canvas.drawCircle(points[i]!.point, points[i]!.paint.strokeWidth / 2, points[i]!.paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) => true;
}
