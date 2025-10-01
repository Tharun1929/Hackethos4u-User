import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../model/ad_model.dart';
import '../services/ad_service.dart';

class SlidingAdsWidget extends StatefulWidget {
  final double height;
  final Duration autoSlideDuration;
  final bool showDots;
  final bool autoSlide;

  const SlidingAdsWidget({
    super.key,
    this.height = 200,
    this.autoSlideDuration = const Duration(seconds: 5),
    this.showDots = true,
    this.autoSlide = true,
  });

  @override
  State<SlidingAdsWidget> createState() => _SlidingAdsWidgetState();
}

class _SlidingAdsWidgetState extends State<SlidingAdsWidget>
    with TickerProviderStateMixin {
  final AdService _adService = AdService();
  final PageController _pageController = PageController();

  List<AdModel> _ads = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _loadAds();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAds() async {
    try {
      final ads = await _adService.getActiveAds();
      setState(() {
        _ads = ads;
        _isLoading = false;
      });

      if (ads.isNotEmpty) {
        _animationController.forward();
        if (widget.autoSlide && ads.length > 1) {
          _startAutoSlide();
        }
      }
    } catch (e) {
      // print('Error loading ads: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startAutoSlide() {
    Future.delayed(widget.autoSlideDuration, () {
      if (mounted && _ads.length > 1) {
        _nextAd();
        _startAutoSlide();
      }
    });
  }

  void _nextAd() {
    if (_ads.isEmpty || !_pageController.hasClients) return;

    setState(() {
      _currentIndex = (_currentIndex + 1) % _ads.length;
    });

    _pageController.animateToPage(
      _currentIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousAd() {
    if (_ads.isEmpty || !_pageController.hasClients) return;

    setState(() {
      _currentIndex = (_currentIndex - 1 + _ads.length) % _ads.length;
    });

    _pageController.animateToPage(
      _currentIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToAd(int index) {
    if (_ads.isEmpty || !_pageController.hasClients) return;

    setState(() {
      _currentIndex = index;
    });

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_ads.isEmpty) {
      // Hide the ads widget when no ads are available instead of showing "No ads available"
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Ads carousel
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemCount: _ads.length,
                itemBuilder: (context, index) {
                  final ad = _ads[index];
                  return _buildAdItem(ad, theme);
                },
              ),

              // Navigation arrows
              if (_ads.length > 1) ...[
                Positioned(
                  left: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _previousAd,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _nextAd,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              // Dots indicator
              if (widget.showDots && _ads.length > 1)
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _ads.length,
                      (index) => GestureDetector(
                        onTap: () => _goToAd(index),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentIndex == index
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdItem(AdModel ad, ThemeData theme) {
    return GestureDetector(
      onTap: () => _adService.openAdLink(ad),
      child: Stack(
        children: [
          // Ad thumbnail
          CachedNetworkImage(
            imageUrl: ad.thumbnail,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: theme.colorScheme.surface,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: theme.colorScheme.surface,
              child: Icon(
                Icons.image,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
                size: 48,
              ),
            ),
          ),

          // Ad overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ad.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        _getAdTypeIcon(ad.type),
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getAdTypeText(ad.type),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'Tap to open',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAdTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'youtube':
        return Icons.play_circle_outline;
      case 'website':
        return Icons.language;
      case 'course':
        return Icons.school;
      case 'app':
        return Icons.phone_android;
      default:
        return Icons.link;
    }
  }

  String _getAdTypeText(String type) {
    switch (type.toLowerCase()) {
      case 'youtube':
        return 'YouTube Video';
      case 'website':
        return 'Website';
      case 'course':
        return 'Course';
      case 'app':
        return 'Mobile App';
      default:
        return 'Link';
    }
  }
}
