import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/appointment.dart';
import '../models/dental_service.dart';
import '../models/enums.dart';
import '../models/news.dart';
import '../models/recommendation.dart';
import '../models/search_result.dart';
import '../models/service_category.dart';
import '../providers/appointment_provider.dart';
import '../providers/dental_service_provider.dart';
import '../providers/news_provider.dart';
import '../providers/recommendation_provider.dart';
import '../providers/service_category_provider.dart';
import '../theme/app_theme.dart';
import '../utils/utils_widgets.dart';
import '../widgets/news_detail_dialog.dart';
import 'appointment_details_screen.dart';
import 'dental_service_details_screen.dart';
import 'service_browse_screen.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  /// Switches the shared bottom-tab shell (`ContainerScreen`) to the
  /// "Termini" tab — home has no navigator/tab-index of its own.
  final VoidCallback onGoToAppointments;

  /// Opens the same "pick a service to book" sheet as the shell's FAB
  /// (kept in `ContainerScreen` so there's one implementation, not two).
  final VoidCallback onBookAppointment;

  /// Bumped by `ContainerScreen` every time the Home tab is switched to.
  /// `IndexedStack` keeps this screen's State alive across tab switches, so
  /// without this, `_load()` only ever ran once in `initState` — a service
  /// activated (or any other data changed) elsewhere never showed up here
  /// until the app was restarted or the patient pulled to refresh.
  final int refreshTick;

  const HomeScreen({
    super.key,
    required this.onGoToAppointments,
    required this.onBookAppointment,
    this.refreshTick = 0,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DentalServiceProvider _serviceProvider;
  late ServiceCategoryProvider _categoryProvider;
  late RecommendationProvider _recommendationProvider;
  late NewsProvider _newsProvider;
  late AppointmentProvider _appointmentProvider;

  SearchResult<DentalService>? services;
  SearchResult<ServiceCategory>? categories;
  List<Recommendation> recommendations = [];
  Appointment? _nextAppointment;
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
    _appointmentProvider = context.read<AppointmentProvider>();

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

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshTick != oldWidget.refreshTick) _load();
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

      Appointment? next;
      try {
        // AppointmentService forces non-Admin callers to their own appointments regardless
        // of filter, so this is already scoped to the current patient.
        final appts = await _appointmentProvider.get(filter: {"pageSize": 200});
        final now = DateTime.now();
        final upcoming = (appts.items ?? [])
            .where((a) =>
                a.scheduledAt != null &&
                a.scheduledAt!.isAfter(now) &&
                a.status != AppointmentStatus.cancelled.index)
            .toList()
          ..sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));
        next = upcoming.isNotEmpty ? upcoming.first : null;
      } catch (_) {
        // Same reasoning as recommendations — the hero card is a bonus, not a blocker.
      }

      _newsPage = 1;
      final n = await _newsProvider
          .get(filter: {"isPublished": true, "page": _newsPage});

      if (!mounted) return;
      setState(() {
        services = s;
        categories = c;
        recommendations = recs;
        _nextAppointment = next;
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
                const SizedBox(height: 16),
                // Figma leads with the next-appointment card, quick actions come
                // after it — the reverse of how these were first ordered here.
                if (_nextAppointment != null) ...[
                  _buildNextAppointmentCard(_nextAppointment!),
                  const SizedBox(height: 16),
                ],
                _buildQuickActions(),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Usluge", style: Theme.of(context).textTheme.titleMedium),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ServiceBrowseScreen()),
                      ),
                      child: const Text("Prikaži sve"),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ...?services?.items?.take(4).map(_buildServiceTile),
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

  static const _weekdays = [
    'Ponedjeljak', 'Utorak', 'Srijeda', 'Četvrtak', 'Petak', 'Subota', 'Nedjelja',
  ];
  static const _months = [
    'januara', 'februara', 'marta', 'aprila', 'maja', 'juna',
    'jula', 'avgusta', 'septembra', 'oktobra', 'novembra', 'decembra',
  ];

  /// "Dobro jutro/dan/veče" — Figma's greeting varies by time of day, unlike
  /// the flat "Zdravo" this previously always showed.
  String _timeOfDayGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Dobro jutro';
    if (hour < 18) return 'Dobar dan';
    return 'Dobro veče';
  }

  Widget _buildHero() {
    final firstName = AuthProvider.accessTokenDecoded?['FirstName'] as String?;
    final now = DateTime.now();
    final dateLine =
        '${_weekdays[now.weekday - 1]}, ${now.day}. ${_months[now.month - 1]} ${now.year}.';

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
            dateLine,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            firstName != null && firstName.isNotEmpty
                ? "${_timeOfDayGreeting()}, $firstName 👋"
                : "Dobrodošli 👋",
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

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _quickActionButton(
            icon: Icons.add_circle_outline,
            label: 'Zakaži termin',
            onTap: widget.onBookAppointment,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _quickActionButton(
            icon: Icons.event_note_outlined,
            label: 'Moji termini',
            onTap: widget.onGoToAppointments,
          ),
        ),
      ],
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  /// "Next appointment" hero — the piece the Figma reference leads the home
  /// screen with; this app previously had no equivalent at all (a patient
  /// had to open the Termini tab to see what's coming up).
  Widget _buildNextAppointmentCard(Appointment a) {
    final dt = a.scheduledAt!.toLocal();
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final tomorrow = now.add(const Duration(days: 1));
    final isTomorrow =
        dt.year == tomorrow.year && dt.month == tomorrow.month && dt.day == tomorrow.day;
    final dateLabel = isToday
        ? 'Danas'
        : isTomorrow
            ? 'Sutra'
            : '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}.';
    final timeLabel =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AppointmentDetailsScreen(appointmentId: a.id!),
        ),
      ).then((_) => _load()),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.event_available_outlined, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Sljedeći termin',
                              style: TextStyle(fontSize: 12, color: Colors.white60)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(dateLabel,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(a.dentalServiceName ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('${a.doctorName ?? ''} · $timeLabel',
                          style: const TextStyle(fontSize: 12, color: Colors.white60)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white38),
              ],
            ),
            Divider(height: 24, color: AppColors.primary.withValues(alpha: 0.15)),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${ClinicInfo.name} · ${ClinicInfo.address}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
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
