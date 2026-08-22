import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../layouts/master_screen.dart';
import '../models/appointment.dart';
import '../models/enums.dart';
import '../models/payment.dart';
import '../models/search_result.dart';
import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/payment_provider.dart';
import '../theme/app_theme.dart';
import '../utils/api_client_exception.dart';
import '../utils/utils_widgets.dart';
import '../widgets/stat_card.dart';

/// Admin landing screen — ported from the approved Figma design's "Izvještaji"
/// (Reports) view. Unlike the Figma mock (which drives its charts off static
/// demo arrays), every number here is aggregated client-side from the real
/// Appointments/Payments endpoints, the same pattern the existing list screens
/// already use for their header StatCards — there is no dedicated reporting/
/// aggregate endpoint on the backend yet.
///
/// One deliberate deviation from the Figma source: its "Termini po doktorima"
/// bar chart plots appointment *count* and revenue on the same axis (e.g. 42 vs
/// 3.200), which makes the count bars unreadable next to the revenue bars.
/// Charting two differently-scaled measures on one axis is a real bug, not a
/// stylistic choice, so this version shows appointment count only.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

enum _Period { month, year, all }

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  List<Appointment> _appointments = [];
  List<Payment> _payments = [];
  _Period _period = _Period.year;

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Maj', 'Jun',
    'Jul', 'Avg', 'Sep', 'Okt', 'Nov', 'Dec',
  ];

  static const _pieColors = [
    Color(0xFF7C3AED),
    Color(0xFFA78BFA),
    Color(0xFF06B6D4),
    Color(0xFF10B981),
    Color(0xFFDDD6FE),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final appointmentProvider = context.read<AppointmentProvider>();
      final paymentProvider = context.read<PaymentProvider>();
      // pageSize is large on purpose — see class doc: this aggregates
      // client-side over (almost) the full dataset.
      final results = await Future.wait<dynamic>([
        appointmentProvider.get(filter: {"pageSize": 2000}),
        paymentProvider.get(filter: {"pageSize": 2000}),
      ]);
      if (!mounted) return;
      setState(() {
        _appointments =
            (results[0] as SearchResult<Appointment>).items ?? [];
        _payments = (results[1] as SearchResult<Payment>).items ?? [];
        _isLoading = false;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      alertBox(context, 'Greška', e.toString());
    }
  }

  // ─── Period helpers ─────────────────────────────────────────────────────

  (DateTime, DateTime)? get _currentRange {
    final now = DateTime.now();
    switch (_period) {
      case _Period.month:
        return (DateTime(now.year, now.month, 1), DateTime(now.year, now.month + 1, 1));
      case _Period.year:
        return (DateTime(now.year, 1, 1), DateTime(now.year + 1, 1, 1));
      case _Period.all:
        return null;
    }
  }

  (DateTime, DateTime)? get _previousRange {
    final now = DateTime.now();
    switch (_period) {
      case _Period.month:
        return (DateTime(now.year, now.month - 1, 1), DateTime(now.year, now.month, 1));
      case _Period.year:
        return (DateTime(now.year - 1, 1, 1), DateTime(now.year, 1, 1));
      case _Period.all:
        return null;
    }
  }

  /// GET /Reports/* requires concrete Start/EndDate — falls back to the
  /// earliest known appointment when the "Sve" (all-time) period is active,
  /// since that toggle has no fixed start date of its own.
  (DateTime, DateTime) get _reportRange {
    final range = _currentRange;
    if (range != null) return range;
    final dates = _appointments.map((a) => a.scheduledAt).whereType<DateTime>();
    final start = dates.isEmpty
        ? DateTime.now().subtract(const Duration(days: 365))
        : dates.reduce((a, b) => a.isBefore(b) ? a : b);
    return (start, DateTime.now());
  }

  // Which report is currently downloading, if any — null means neither
  // button is busy. A single shared bool here previously made clicking one
  // report button show a spinner on *both* buttons.
  String? _exportingReport;

  Future<void> _exportPdf(String reportPath, String fileNamePrefix) async {
    setState(() => _exportingReport = reportPath);
    try {
      final (start, end) = _reportRange;
      final baseUrl = const String.fromEnvironment(
        "API_BASE_URL",
        defaultValue: "http://localhost:5126/",
      );
      final uri = Uri.parse(
          "$baseUrl$reportPath?StartDate=${start.toIso8601String()}&EndDate=${end.toIso8601String()}");
      final response = await http.get(uri, headers: {
        "Authorization": "Bearer ${AuthProvider.accesstoken ?? ''}",
      });

      if (response.statusCode >= 300) {
        final parsed = ApiErrorParser.messageFromBody(response.body);
        throw ApiClientException(parsed ?? 'Izvještaj nije moguće generisati.');
      }

      final fileName =
          '$fileNamePrefix-${start.toIso8601String().substring(0, 10)}_${end.toIso8601String().substring(0, 10)}.pdf';
      final savedPath = await FilePicker.saveFile(
        dialogTitle: 'Sačuvaj izvještaj',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        bytes: response.bodyBytes,
      );

      if (!mounted) return;
      setState(() => _exportingReport = null);
      if (savedPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Izvještaj uspješno preuzet: $fileName')),
              ],
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _exportingReport = null);
      alertBox(context, 'Greška', e.toString());
    }
  }

  String get _deltaSuffix => switch (_period) {
        _Period.month => 'vs prošli mj.',
        _Period.year => 'vs prošlu god.',
        _Period.all => '',
      };

  bool _inRange(DateTime? dt, (DateTime, DateTime)? range) {
    if (dt == null) return false;
    if (range == null) return true;
    final (start, end) = range;
    return !dt.isBefore(start) && dt.isBefore(end);
  }

  List<Appointment> _apptsIn((DateTime, DateTime)? range) =>
      _appointments.where((a) => _inRange(a.scheduledAt, range)).toList();

  double _paidTotalIn((DateTime, DateTime)? range) => _payments
      .where((p) => p.status == PaymentStatus.paid.index && _inRange(p.paidAt, range))
      .fold(0.0, (sum, p) => sum + (p.amount ?? 0));

  /// Null return means "don't show a trend" (previous-period baseline of 0
  /// makes a percentage meaningless, and the "Sve" period has no baseline).
  double? _percentDelta(num current, num previous) {
    if (_period == _Period.all) return null;
    if (previous == 0) return current == 0 ? 0 : null;
    return (current - previous) / previous * 100;
  }

  String _formatMoney(double value) => '${_thousands(value.round())} KM';

  String _thousands(int n) {
    final digits = n.abs().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return (n < 0 ? '-' : '') + buffer.toString();
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: 'Početna',
      currentSection: AppSection.dashboard,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildStatCards(),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _buildRevenueCard()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildServicePieCard()),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildDoctorBarCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Wrap(
          spacing: 8,
          children: _Period.values.map((p) {
            final active = _period == p;
            return ChoiceChip(
              label: Text(switch (p) {
                _Period.month => 'Ovaj mjesec',
                _Period.year => 'Ova godina',
                _Period.all => 'Sve',
              }),
              selected: active,
              onSelected: (_) => setState(() => _period = p),
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFEDE9F5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              labelStyle: TextStyle(
                color: active ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            );
          }).toList(),
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: _exportingReport != null
              ? null
              : () => _exportPdf('Reports/revenue', 'izvjestaj-prihod'),
          icon: _exportingReport == 'Reports/revenue'
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.download_outlined, size: 18),
          label: const Text('Izvještaj o prihodu'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: _exportingReport != null
              ? null
              : () => _exportPdf('Reports/service-popularity', 'izvjestaj-popularnost'),
          icon: _exportingReport == 'Reports/service-popularity'
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.download_outlined, size: 18),
          label: const Text('Izvještaj o popularnosti'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCards() {
    final current = _currentRange;
    final previous = _previousRange;

    final currentAppts = _apptsIn(current);
    final previousAppts = _apptsIn(previous);

    final revenue = _paidTotalIn(current);
    final revenuePrev = _paidTotalIn(previous);

    final cancelled = currentAppts
        .where((a) => a.status == AppointmentStatus.cancelled.index)
        .length;
    final cancelledPrev = previousAppts
        .where((a) => a.status == AppointmentStatus.cancelled.index)
        .length;

    final patients =
        currentAppts.map((a) => a.patientId).whereType<int>().toSet().length;
    final patientsPrev =
        previousAppts.map((a) => a.patientId).whereType<int>().toSet().length;

    return Row(
      children: [
        StatCard(
          icon: Icons.savings_outlined,
          label: 'Ukupan prihod',
          value: _formatMoney(revenue),
          color: AppColors.primary,
          deltaPercent: _percentDelta(revenue, revenuePrev),
          deltaSuffix: _deltaSuffix,
        ),
        const SizedBox(width: 16),
        StatCard(
          icon: Icons.event_outlined,
          label: 'Ukupno termina',
          value: currentAppts.length.toString(),
          color: AppColors.success,
          deltaPercent: _percentDelta(currentAppts.length, previousAppts.length),
          deltaSuffix: _deltaSuffix,
        ),
        const SizedBox(width: 16),
        StatCard(
          icon: Icons.people_outline,
          label: 'Pacijenata',
          value: patients.toString(),
          color: const Color(0xFF06B6D4),
          deltaPercent: _percentDelta(patients, patientsPrev),
          deltaSuffix: _deltaSuffix,
        ),
        const SizedBox(width: 16),
        StatCard(
          icon: Icons.event_busy_outlined,
          label: 'Otkazanih',
          value: cancelled.toString(),
          color: AppColors.warning,
          deltaPercent: _percentDelta(cancelled, cancelledPrev),
          deltaSuffix: _deltaSuffix,
        ),
      ],
    );
  }

  /// Rolling last-6-months trend — intentionally independent of the period
  /// toggle above (matching the Figma reference, whose chart also doesn't
  /// react to its own period control).
  Widget _buildRevenueCard() {
    final now = DateTime.now();
    final months = List.generate(6, (i) => DateTime(now.year, now.month - 5 + i, 1));
    final totals = months.map((m) {
      final range = (m, DateTime(m.year, m.month + 1, 1));
      return _paidTotalIn(range);
    }).toList();
    final labels = months.map((m) => _monthNames[m.month - 1]).toList();
    final hasData = totals.any((v) => v > 0);

    return _ChartCard(
      title: 'Prihodi po mjesecima',
      trailing: Text('${now.year}.',
          style: const TextStyle(fontSize: 12, color: Colors.black45)),
      child: SizedBox(
        height: 220,
        child: hasData
            ? CustomPaint(
                size: Size.infinite,
                painter: _AreaChartPainter(
                  values: totals,
                  labels: labels,
                  lineColor: AppColors.primary,
                ),
              )
            : const Center(
                child: Text('Nema podataka o plaćanjima za prikaz.',
                    style: TextStyle(color: Colors.black45, fontSize: 12)),
              ),
      ),
    );
  }

  /// All-time booking popularity by service (not limited to the period toggle
  /// or to non-cancelled appointments — this measures how often a service
  /// gets booked at all).
  Widget _buildServicePieCard() {
    final counts = <String, int>{};
    for (final a in _appointments) {
      final name = a.dentalServiceName;
      if (name == null || name.isEmpty) continue;
      counts[name] = (counts[name] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    const topN = 4;
    final top = sorted.take(topN).toList();
    final otherCount = sorted.skip(topN).fold(0, (sum, e) => sum + e.value);

    final slices = [
      for (final e in top) _PieSlice(e.key, e.value),
      if (otherCount > 0) _PieSlice('Ostalo', otherCount),
    ];
    final total = slices.fold(0, (sum, s) => sum + s.count);

    return _ChartCard(
      title: 'Usluge po popularnosti',
      child: total == 0
          ? const SizedBox(
              height: 180,
              child: Center(
                child: Text('Nema podataka o terminima za prikaz.',
                    style: TextStyle(color: Colors.black45, fontSize: 12)),
              ),
            )
          : Column(
              children: [
                SizedBox(
                  height: 150,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _DonutChartPainter(
                      values: [for (final s in slices) s.count.toDouble()],
                      colors: _pieColors,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                for (int i = 0; i < slices.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _pieColors[i % _pieColors.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            slices[i].label,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF4B4560)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text('${(slices[i].count / total * 100).round()}%',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildDoctorBarCard() {
    final now = DateTime.now();
    final range = (DateTime(now.year, now.month, 1), DateTime(now.year, now.month + 1, 1));
    final counts = <String, int>{};
    for (final a in _appointments) {
      if (!_inRange(a.scheduledAt, range)) continue;
      final name = a.doctorName;
      if (name == null || name.isEmpty) continue;
      counts[name] = (counts[name] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(6).toList();
    final maxVal = top.isEmpty ? 0 : top.map((e) => e.value).reduce(math.max);

    return _ChartCard(
      title: 'Termini po doktorima (ovaj mjesec)',
      child: top.isEmpty
          ? const SizedBox(
              height: 160,
              child: Center(
                child: Text('Nema termina u ovom mjesecu.',
                    style: TextStyle(color: Colors.black45, fontSize: 12)),
              ),
            )
          : SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final e in top)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('${e.value}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Container(
                              height: maxVal == 0 ? 0 : 120 * e.value / maxVal,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              e.key,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF4B4560)),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _PieSlice {
  const _PieSlice(this.label, this.count);
  final String label;
  final int count;
}

/// Plain white rounded card used for every chart on the dashboard — no new
/// dependency was pulled in for this (see the two CustomPainters below); the
/// existing pubspec already covers everything this screen needs.
class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE9F5)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Gridded area/line chart (revenue trend). Straight segments rather than a
/// curve — simpler to get right without a charting dependency and reads just
/// as clearly at 6 data points.
class _AreaChartPainter extends CustomPainter {
  _AreaChartPainter({required this.values, required this.labels, required this.lineColor});

  final List<double> values;
  final List<String> labels;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    const leftAxisWidth = 44.0;
    const bottomAxisHeight = 20.0;
    final chartWidth = size.width - leftAxisWidth;
    final chartHeight = size.height - bottomAxisHeight;
    if (chartWidth <= 0 || chartHeight <= 0 || values.isEmpty) return;

    final maxVal = values.reduce(math.max);
    final safeMax = maxVal <= 0 ? 1.0 : maxVal;

    final gridPaint = Paint()
      ..color = const Color(0xFFF0EAFF)
      ..strokeWidth = 1;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i <= 3; i++) {
      final y = chartHeight * i / 3;
      canvas.drawLine(Offset(leftAxisWidth, y), Offset(size.width, y), gridPaint);
      final labelValue = (safeMax * (3 - i) / 3).round();
      textPainter.text = TextSpan(
        text: '$labelValue',
        style: const TextStyle(fontSize: 10, color: Color(0xFF7C6FA8)),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(leftAxisWidth - textPainter.width - 6, y - textPainter.height / 2),
      );
    }

    final dx = values.length > 1 ? chartWidth / (values.length - 1) : 0.0;
    final points = <Offset>[
      for (int i = 0; i < values.length; i++)
        Offset(leftAxisWidth + dx * i, chartHeight - (values[i] / safeMax) * chartHeight),
    ];

    final areaPath = Path()..moveTo(points.first.dx, chartHeight);
    for (final p in points) {
      areaPath.lineTo(p.dx, p.dy);
    }
    areaPath.lineTo(points.last.dx, chartHeight);
    areaPath.close();
    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lineColor.withValues(alpha: 0.22), lineColor.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(leftAxisWidth, 0, chartWidth, chartHeight));
    canvas.drawPath(areaPath, areaPaint);

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    for (final p in points) {
      canvas.drawCircle(p, 3, Paint()..color = Colors.white);
      canvas.drawCircle(
        p,
        3,
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    for (int i = 0; i < labels.length; i++) {
      textPainter.text = TextSpan(
        text: labels[i],
        style: const TextStyle(fontSize: 10, color: Color(0xFF7C6FA8)),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(points[i].dx - textPainter.width / 2, chartHeight + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _AreaChartPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.labels != labels ||
      oldDelegate.lineColor != lineColor;
}

/// Donut chart, rendered as a ring of arcs — avoids pulling in a charting
/// package for a single screen.
class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter({required this.values, required this.colors});

  final List<double> values;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold(0.0, (sum, v) => sum + v);
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;
    const strokeWidth = 22.0;
    const gapRadians = 0.035;

    var startAngle = -math.pi / 2;
    for (int i = 0; i < values.length; i++) {
      final fullSweep = (values[i] / total) * (2 * math.pi);
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      final drawnSweep = fullSweep - gapRadians;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        drawnSweep < 0 ? fullSweep : drawnSweep,
        false,
        paint,
      );
      startAngle += fullSweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.colors != colors;
}
