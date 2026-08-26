import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layouts/master_screen.dart';
import '../models/news.dart';
import '../models/search_result.dart';
import '../providers/news_provider.dart';
import '../utils/utils_widgets.dart';
import '../widgets/asset_thumbnail.dart';
import 'news_details_screen.dart';

class NewsList extends StatefulWidget {
  const NewsList({super.key});

  @override
  State<NewsList> createState() => _NewsListState();
}

class _NewsListState extends State<NewsList> {
  late NewsProvider _provider;
  SearchResult<News>? result;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _provider = context.read<NewsProvider>();
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
      title: "Novosti",
      currentSection: AppSection.news,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () async {
                  var refresh = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const NewsDetailsScreen(news: null),
                    ),
                  );
                  if (refresh == "reload") initTable();
                },
                child: const Text("Nova vijest"),
              ),
            ),
            const SizedBox(height: 8),
            isLoading
                ? const Expanded(
                    child: Center(child: CircularProgressIndicator()))
                : _buildTable(),
          ],
        ),
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
              DataColumn(label: Text("")),
              DataColumn(label: Text("Naslov")),
              DataColumn(label: Text("Autor")),
              DataColumn(label: Text("Objavljeno")),
              DataColumn(label: Text("Datum objave")),
              DataColumn(label: Text("Obriši")),
            ],
            rows: result?.items
                    ?.map(
                      (e) => DataRow(
                        onSelectChanged: (v) async {
                          var refresh = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => NewsDetailsScreen(news: e),
                            ),
                          );
                          if (refresh == "reload") initTable();
                        },
                        cells: [
                          DataCell(AssetThumbnail(assetId: e.imageAssetId)),
                          DataCell(Text(e.title ?? '')),
                          DataCell(Text(e.createdByUserName ?? '')),
                          DataCell(Text(e.isPublished == true ? "Da" : "Ne")),
                          DataCell(Text(e.publishedAt?.toLocal().toString().substring(0, 16) ?? '')),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _confirmDelete(e),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList() ??
                List.empty(),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(News e) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Brisanje"),
        content: Text("Da li ste sigurni da želite obrisati vijest '${e.title}'?"),
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
