import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layouts/master_screen.dart';
import '../models/enums.dart';
import '../models/payment.dart';
import '../models/search_result.dart';
import '../providers/payment_provider.dart';
import '../theme/app_theme.dart';
import '../utils/utils_widgets.dart';
import '../widgets/stat_card.dart';

class PaymentList extends StatefulWidget {
  const PaymentList({super.key});

  @override
  State<PaymentList> createState() => _PaymentListState();
}

class _PaymentListState extends State<PaymentList> {
  late PaymentProvider _provider;
  SearchResult<Payment>? result;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _provider = context.read<PaymentProvider>();
    initTable();
  }

  Future<void> initTable() async {
    try {
      var data = await _provider.get(filter: {"pageSize": 200});
      if (!mounted) return;
      setState(() {
        result = data;
        isLoading = false;
      });
    } on Exception catch (e) {
      if (mounted) alertBox(context, 'Greška', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: "Plaćanja",
      currentSection: AppSection.payments,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildStats(),
                  const SizedBox(height: 16),
                  _buildTable(),
                ],
              ),
      ),
    );
  }

  Widget _buildStats() {
    final payments = result?.items ?? [];
    final paid = payments
        .where((p) => PaymentStatusX.fromInt(p.status) == PaymentStatus.paid);
    final refunded = payments.where(
        (p) => PaymentStatusX.fromInt(p.status) == PaymentStatus.refunded);
    final totalPaid = paid.fold<double>(0, (sum, p) => sum + (p.amount ?? 0));

    return Row(
      children: [
        StatCard(
          icon: Icons.payments_outlined,
          label: "Naplaćeno",
          value: "${totalPaid.toStringAsFixed(2)} KM",
        ),
        const SizedBox(width: 16),
        StatCard(
          icon: Icons.check_circle_outline,
          label: "Plaćeni",
          value: paid.length.toString(),
          color: Theme.of(context).colorScheme.tertiary,
        ),
        const SizedBox(width: 16),
        StatCard(
          icon: Icons.undo_outlined,
          label: "Refundirani",
          value: refunded.length.toString(),
          color: Theme.of(context).colorScheme.error,
        ),
      ],
    );
  }

  Widget _buildTable() {
    return Expanded(
      child: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          child: DataTable(
            showCheckboxColumn: false,
            columns: const [
              DataColumn(label: Text("Pacijent")),
              DataColumn(label: Text("Doktor")),
              DataColumn(label: Text("Iznos")),
              DataColumn(label: Text("Status")),
              DataColumn(label: Text("Plaćeno")),
              DataColumn(label: Text("Refundirano")),
              DataColumn(label: Text("Akcije")),
            ],
            rows: result?.items
                    ?.map(
                      (e) => DataRow(cells: [
                        DataCell(Text(e.patientName ?? '')),
                        DataCell(Text(e.doctorName ?? '')),
                        DataCell(Text(e.amount != null ? "${e.amount} KM" : '')),
                        DataCell(StatusBadge.payment(PaymentStatusX.fromInt(e.status))),
                        DataCell(Text(e.paidAt?.toLocal().toString().substring(0, 16) ?? '—')),
                        DataCell(Text(e.refundedAmount != null
                            ? "${e.refundedAmount} KM"
                            : '—')),
                        DataCell(
                          PaymentStatusX.fromInt(e.status) == PaymentStatus.paid
                              ? TextButton(
                                  onPressed: () => _confirmRefund(e),
                                  child: const Text("Refundiraj"),
                                )
                              : const SizedBox(),
                        ),
                      ]),
                    )
                    .toList() ??
                List.empty(),
          ),
        ),
      ),
    );
  }

  void _confirmRefund(Payment e) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Refundacija"),
        content: Text(
            "Refundirati plaćanje od ${e.amount} KM za pacijenta '${e.patientName}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Odustani"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _provider.refund(e.id!);
                if (!mounted) return;
                Navigator.pop(context);
                initTable();
              } on Exception catch (ex) {
                alertBoxMoveBack(context, "Greška", ex.toString());
              }
            },
            child: const Text("Da"),
          ),
        ],
      ),
    );
  }
}
