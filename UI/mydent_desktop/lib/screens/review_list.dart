import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layouts/master_screen.dart';
import '../models/review.dart';
import '../models/search_result.dart';
import '../providers/review_provider.dart';
import '../utils/utils_widgets.dart';

class ReviewList extends StatefulWidget {
  const ReviewList({super.key});

  @override
  State<ReviewList> createState() => _ReviewListState();
}

class _ReviewListState extends State<ReviewList> {
  late ReviewProvider _provider;
  SearchResult<Review>? result;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _provider = context.read<ReviewProvider>();
    initTable();
  }

  Future<void> initTable() async {
    try {
      var data = await _provider.get(filter: {"pageSize": 200});
      setState(() {
        result = data;
        isLoading = false;
      });
    } on Exception catch (e) {
      alertBox(context, 'Greška', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: "Recenzije",
      currentSection: AppSection.reviews,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildTable(),
      ),
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
              DataColumn(label: Text("Usluga")),
              DataColumn(label: Text("Ocjena")),
              DataColumn(label: Text("Komentar")),
              DataColumn(label: Text("Odobrena")),
              DataColumn(label: Text("Akcije")),
            ],
            rows: result?.items
                    ?.map(
                      (e) => DataRow(cells: [
                        DataCell(Text(e.patientName ?? '')),
                        DataCell(Text(e.doctorName ?? '')),
                        DataCell(Text(e.dentalServiceName ?? '')),
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < (e.rating ?? 0) ? Icons.star : Icons.star_border,
                              size: 16,
                              color: Colors.amber,
                            ),
                          ),
                        )),
                        DataCell(
                          SizedBox(
                            width: 260,
                            child: Tooltip(
                              message: e.comment ?? '',
                              child: Text(e.comment ?? '',
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ),
                          onTap: (e.comment ?? '').isEmpty
                              ? null
                              : () => _showFullText("Komentar", e.comment!),
                        ),
                        DataCell(Text(e.isApproved == true ? "Da" : "Ne")),
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (e.isApproved != true)
                              IconButton(
                                tooltip: "Odobri",
                                icon: const Icon(Icons.check, color: Colors.green),
                                onPressed: () => _setApproved(e, true),
                              )
                            else
                              IconButton(
                                tooltip: "Ukloni odobrenje",
                                icon: const Icon(Icons.close, color: Colors.orange),
                                onPressed: () => _setApproved(e, false),
                              ),
                            IconButton(
                              tooltip: "Obriši",
                              icon: const Icon(Icons.delete),
                              onPressed: () => _confirmDelete(e),
                            ),
                          ],
                        )),
                      ]),
                    )
                    .toList() ??
                List.empty(),
          ),
        ),
      ),
    );
  }

  void _showFullText(String title, String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(width: 400, child: Text(text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Zatvori"),
          ),
        ],
      ),
    );
  }

  Future _setApproved(Review e, bool approved) async {
    try {
      await _provider.update(e.id!, {"isApproved": approved});
      initTable();
    } on Exception catch (ex) {
      alertBox(context, "Greška", ex.toString());
    }
  }

  void _confirmDelete(Review e) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Brisanje"),
        content: const Text("Da li ste sigurni da želite obrisati ovu recenziju?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Odustani"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _provider.remove(e.id!);
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
