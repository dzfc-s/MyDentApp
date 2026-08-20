import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/dental_service.dart';
import '../models/news.dart';
import '../models/recommendation.dart';
import '../models/search_result.dart';
import '../models/service_category.dart';
import '../providers/dental_service_provider.dart';
import '../providers/news_provider.dart';
import '../providers/recommendation_provider.dart';
import '../providers/service_category_provider.dart';
import '../theme/app_theme.dart';
import '../utils/utils_widgets.dart';
import '../widgets/news_detail_dialog.dart';
import 'dental_service_details_screen.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DentalServiceProvider _serviceProvider;
  late ServiceCategoryProvider _categoryProvider;
  late RecommendationProvider _recommendationProvider;
  late NewsProvider _newsProvider;

  SearchResult<DentalService>? services;
  SearchResult<ServiceCategory>? categories;
  List<Recommendation> recommendations = [];
  int? _selectedCategoryId;
  bool isLoading = true;

  final List<News> _newsItems = [];
  int _newsPage = 1;
  bool _newsHasMore = true;
  bool _isLoadingMoreNews = false;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _serviceProvider = context.read<DentalServiceProvider>();
    _categoryProvider = context.read<ServiceCategoryProvider>();
    _recommendationProvider = context.read<RecommendationProvider>();
    _newsProvider = context.read<NewsProvider>();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoadingMoreNews &&
          _newsHasMore) {
        _loadMoreNews();
      }
    });

    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final s = await _serviceProvider.get(filter: {
        "name": _searchController.text,
        if (_selectedCategoryId != null)
          "serviceCategoryId": _selectedCategoryId,
        "isActive": true,
      });
      final c = await _categoryProvider.get(filter: {"isActive": true});
      List<Recommendation> recs = [];
      try {
        recs = await _recommendationProvider.getRecommendations();
      } catch (_) {
        // Recommendations are a nice-to-have — never block browsing on their failure.
      }

      _newsPage = 1;
      final n = await _newsProvider
          .get(filter: {"isPublished": true, "page": _newsPage});

      if (!mounted) return;
      setState(() {
        services = s;
        categories = c;
        recommendations = recs;
        _newsItems
          ..clear()
          ..addAll(n.items ?? []);
        _newsHasMore = (n.items?.isNotEmpty ?? false);
        isLoading = false;
      });
    } on Exception catch (e) {
      if (mounted) alertBox(context, 'Greška', e.toString());
    }
  }

  Future<void> _loadMoreNews() async {
    setState(() => _isLoadingMoreNews = true);
    try {
      _newsPage++;
      final n = await _newsProvider
          .get(filter: {"isPublished": true, "page": _newsPage});

      if (!mounted) return;
      setState(() {
        if (n.items == null || n.items!.isEmpty) {
          _newsHasMore = false;
        } else {
          _newsItems.addAll(n.items!);
        }
        _isLoadingMoreNews = false;
      });
    } on Exception catch (_) {
      if (mounted) setState(() => _isLoadingMoreNews = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                _buildHero(),
                const SizedBox(height: 20),
                if (recommendations.isNotEmpty) ...[
                  Text("Preporučeno za vas",
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _buildRecommendations(),
                  const SizedBox(height: 16),
                ],
                _buildCategoryChips(),
                const SizedBox(height: 16),
                Text("Usluge", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...?services?.items?.map(_buildServiceTile),
                const SizedBox(height: 24),
                Text("Novosti klinike",
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ..._newsItems.map(_buildNewsTile),
                if (_isLoadingMoreNews)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (!_newsHasMore && _newsItems.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                        child: Text("Nema više vijesti",
                            style: TextStyle(color: Colors.grey))),
                  ),
              ],
            ),
    );
  }

  Widget _buildHero() {
    final firstName = AuthProvider.accessTokenDecoded?['FirstName'] as String?;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF5B21B6)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            firstName != null && firstName.isNotEmpty
                ? "Zdravo, $firstName"
                : "Dobrodošli",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Pronađite uslugu ili zakažite termin",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Pretraži usluge',
              hintStyle: const TextStyle(color: Colors.white60),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (_) => _load(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    final cats = categories?.items ?? [];
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text("Sve"),
              selected: _selectedCategoryId == null,
              onSelected: (_) {
                setState(() => _selectedCategoryId = null);
                _load();
              },
            ),
          ),
          ...cats.map((c) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(c.name ?? ''),
                  selected: _selectedCategoryId == c.id,
                  onSelected: (_) {
                    setState(() => _selectedCategoryId = c.id);
                    _load();
                  },
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: recommendations.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final r = recommendations[index];
          return InkWell(
            onTap: () => _openService(r.dentalServiceId!),
            child: Container(
              width: 220,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.dentalServiceName ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(r.reasonDetail ?? '',
                      style: const TextStyle(fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const Spacer(),
                  Text("${r.price} KM",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildServiceTile(DentalService s) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(s.name ?? ''),
        subtitle: Text("${s.serviceCategoryName ?? ''} · ${s.durationMinutes} min"),
        trailing: Text("${s.price} KM",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => DentalServiceDetailsScreen(service: s)),
        ),
      ),
    );
  }

  Widget _buildNewsTile(News n) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(n.title ?? ''),
        subtitle: Text(
          n.content ?? '',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () => showDialog(
          context: context,
          builder: (_) => NewsDetailDialog(news: n),
        ),
      ),
    );
  }

  Future<void> _openService(int id) async {
    try {
      final service = await _serviceProvider.getById(id);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => DentalServiceDetailsScreen(service: service)),
      );
    } on Exception catch (e) {
      alertBox(context, 'Greška', e.toString());
    }
  }
}
