import 'dart:ui' show PathMetric;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:piggytrunk/theme/app_theme.dart';
import '../request_form_screen.dart';
import '../request_history_screen.dart';

class RaiserRequestTab extends StatefulWidget {
  final List<Map<String, dynamic>> activeAssignments;
  final Map<String, dynamic> raiserData;
  final List<Map<String, dynamic>> requestsList;
  final Future<void> Function() onRefresh;

  const RaiserRequestTab({
    super.key,
    required this.activeAssignments,
    required this.raiserData,
    required this.requestsList,
    required this.onRefresh,
  });

  @override
  State<RaiserRequestTab> createState() => _RaiserRequestTabState();
}

class _RaiserRequestTabState extends State<RaiserRequestTab> {
  String _requestView = 'home';
  String? _previousRequestView;
  static const Color _brandColor = Color(0xFF18314F);

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_requestView == 'form') {
      return RequestFormScreen(
        activeAssignments: widget.activeAssignments,
        raiserData: widget.raiserData,
        onBack: () {
          setState(() {
            _requestView = 'home';
          });
        },
        onSuccess: () {
          setState(() {
            _requestView = 'home';
          });
          widget.onRefresh();
        },
        onViewHistory: () {
          setState(() {
            _previousRequestView = 'form';
            _requestView = 'history';
          });
        },
      );
    } else if (_requestView == 'history') {
      return RequestHistoryScreen(
        raiserData: widget.raiserData,
        onBack: () {
          setState(() {
            _requestView = _previousRequestView ?? 'home';
            _previousRequestView = null;
          });
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Requests',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _brandColor,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.search, color: _brandColor),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.history_rounded, color: _brandColor),
                    onPressed: () {
                      setState(() {
                        _previousRequestView = 'home';
                        _requestView = 'history';
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          GestureDetector(
            onTap: () {
              setState(() {
                _requestView = 'form';
              });
            },
            child: CustomPaint(
              painter: DashedRectPainter(
                color: _brandColor.withValues(alpha: 0.3),
                gap: 5.0,
              ),
              child: Container(
                width: double.infinity,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _brandColor.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 28,
                          color: _brandColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Request Stocks',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _brandColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),

          Text(
            'Requests Activity',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _brandColor,
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: widget.requestsList.isEmpty
                ? Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: PiggyTrunkTheme.ptBorder),
                      ),
                      child: Center(
                        child: Text(
                          'Walang kamakailang aktibidad.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: PiggyTrunkTheme.ptMuted,
                          ),
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: widget.requestsList.length,
                    itemBuilder: (context, index) {
                      final req = widget.requestsList[index];
                      final dateStr = _formatDate(req['request_date']);
                      final status = req['status'] as String;
                      final quantity = req['quantity'] ?? 1;
                      final category = req['category'] ?? 'Feeds';
                      final feedType = req['feed_type'];
                      final rawBatchName = (req['assignments']?['batches']?['batch_name'] ?? 'Batch').toString();
                      String batchName = rawBatchName;
                      if (rawBatchName.contains('(')) {
                        final parts = rawBatchName.split('(');
                        if (parts.last.endsWith(')')) {
                          batchName = parts.sublist(0, parts.length - 1).join('(').trim();
                        }
                      }

                      Color statusColor = const Color(0xffa0aec0);
                      if (status.toLowerCase() == 'approved') {
                        statusColor = PiggyTrunkTheme.ptSuccess;
                      } else if (status.toLowerCase() == 'pending') {
                        statusColor = PiggyTrunkTheme.ptInProgress;
                      } else if (status.toLowerCase() == 'rejected') {
                        statusColor = _brandColor;
                      }

                      String iconPath = 'assets/feeds_icon.png';
                      if (category == 'Vitamins') {
                        iconPath = 'assets/vitamins_icon.png';
                      } else if (category == 'Medicine') {
                        iconPath = 'assets/medicine_icon.png';
                      }

                      String titleText = '$quantity Sacks of $category';
                      if (category == 'Feeds' && feedType != null) {
                        titleText = '$quantity Sacks of $feedType';
                      } else if (category != 'Feeds') {
                        titleText = '$quantity Items of $category';
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: PiggyTrunkTheme.ptBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _brandColor.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(11.0),
                                child: Image.asset(
                                  iconPath,
                                  color: _brandColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    titleText,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: _brandColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$batchName • $dateStr',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: PiggyTrunkTheme.ptMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedRectPainter({
    this.color = const Color(0xFF18314F),
    this.strokeWidth = 1.5,
    this.gap = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path();
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(20),
    ));

    final Path dashPath = Path();
    double distance = 0.0;
    for (PathMetric measurePath in path.computeMetrics()) {
      while (distance < measurePath.length) {
        dashPath.addPath(
          measurePath.extractPath(distance, distance + gap),
          Offset.zero,
        );
        distance += gap * 2;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(DashedRectPainter oldDelegate) => false;
}
