import 'package:flutter/material.dart';
import 'home_recommendation_service.dart';
import 'home_header.dart';
import 'home_featured_section.dart';
import 'home_trending_section.dart';
import 'home_explore_section.dart';
import '../detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeRecommendationService _recommendationService =
      HomeRecommendationService();
  final ScrollController _scrollController = ScrollController();

  HomeData? _homeData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHomeData() async {
    try {
      final data = await _recommendationService.loadHomeData();
      if (mounted) {
        setState(() {
          _homeData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading home data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _recommendationService.refreshHomeData();
      if (mounted) {
        setState(() {
          _homeData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error refreshing data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading || _homeData == null
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF5C6BC0),
                ),
              )
            : RefreshIndicator(
                onRefresh: _refreshData,
                color: const Color(0xFF5C6BC0),
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // HEADER
                    HomeHeader(userName: _homeData!.userName),

                    const SliverToBoxAdapter(child: SizedBox(height: 10)),

                    // SECTION: COCOK UNTUKMU
                    SliverToBoxAdapter(
                      child: HomeFeaturedSection(
                        books: _homeData!.recommendedBooks,
                        onBookTap: (book) => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailScreen(book: book),
                          ),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 30)),

                    // SECTION: SEDANG TREN
                    SliverToBoxAdapter(
                      child: HomeTrendingSection(
                        books: _homeData!.trendingBooks,
                        genre: _homeData!.trendingGenre,
                        onBookTap: (book) => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailScreen(book: book),
                          ),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 20)),

                    // SECTION: JELAJAHI (GENRE ACAK)
                    SliverToBoxAdapter(
                      child: HomeExploreSection(
                        books: _homeData!.exploreBooks,
                        genre: _homeData!.exploreGenre,
                        onBookTap: (book) => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailScreen(book: book),
                          ),
                        ),
                      ),
                    ),

                    // SPACER BOTTOM
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 30),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
