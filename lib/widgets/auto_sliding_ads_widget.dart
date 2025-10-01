import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../model/ad_model.dart';

class AutoSlidingAdsWidget extends StatefulWidget {
  final double height;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;
  final VoidCallback? onAdTap;

  const AutoSlidingAdsWidget({
    super.key,
    this.height = 160, // Reduced default height to prevent overflow
    this.margin,
    this.borderRadius,
    this.onAdTap,
  });

  @override
  State<AutoSlidingAdsWidget> createState() => _AutoSlidingAdsWidgetState();
}

class _AutoSlidingAdsWidgetState extends State<AutoSlidingAdsWidget>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _ads = [];
  int _currentAdIndex = 0;
  bool _isAutoSliding = true;
  final PageController _pageController = PageController();
  Timer? _autoSlideTimer;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadMockAds();
    _startAutoSlide();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    ));

    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _pageController.dispose();
    _autoSlideTimer?.cancel();
    super.dispose();
  }

  void _loadMockAds() {
    // Load real ads from Firebase
    _loadAdsFromFirebase();
  }

  Future<void> _loadAdsFromFirebase() async {
    try {
      // Import Firebase Firestore
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore
          .collection('ads')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _ads = snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'title': data['title'] ?? 'Ad',
              'description': data['description'] ?? '',
              'thumbnail': data['imageUrl'] ??
                  data['thumbnail'] ??
                  'assets/hackethos4u_logo.png',
              'link': data['link'] ?? data['actionUrl'] ?? '#',
              'type': data['type'] ?? 'banner',
              'isActive': data['isActive'] ?? true,
            };
          }).toList();
        });
      } else {
        // Fallback to mock ads if no real ads found
        _ads = [
          {
            'id': '1',
            'title': 'Learn Flutter',
            'description': 'Master mobile app development',
            'imageUrl': 'assets/hackethos4u_logo.png',
            'actionUrl': 'https://flutter.dev',
          },
          {
            'id': '2',
            'title': 'Firebase Course',
            'description': 'Build scalable apps with Firebase',
            'imageUrl': 'assets/hackethos4u_logo.png',
            'actionUrl': 'https://firebase.google.com',
          },
        ];
      }
    } catch (e) {
      print('Error loading ads from Firebase: $e');
      // Fallback to mock ads on error
      _ads = [
        {
          'id': '1',
          'title': 'Learn Flutter',
          'description': 'Master mobile app development',
          'imageUrl': 'assets/hackethos4u_logo.png',
          'actionUrl': 'https://flutter.dev',
        },
        {
          'id': '2',
          'title': 'Firebase Course',
          'description': 'Build scalable apps with Firebase',
          'imageUrl': 'assets/hackethos4u_logo.png',
          'actionUrl': 'https://firebase.google.com',
        },
      ];
    }
  }

  void _startAutoSlide() {
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_isAutoSliding && _ads.isNotEmpty) {
        _currentAdIndex = (_currentAdIndex + 1) % _ads.length;
        _pageController.animateToPage(
          _currentAdIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _stopAutoSlide() {
    _autoSlideTimer?.cancel();
    _isAutoSliding = false;
  }

  void _toggleAutoSlide() {
    if (_isAutoSliding) {
      _stopAutoSlide();
    } else {
      _isAutoSliding = true;
      _startAutoSlide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeAds = _ads;

    if (activeAds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: widget.height,
      margin: widget.margin ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentAdIndex = index;
              });
            },
            itemCount: activeAds.length,
            itemBuilder: (context, index) {
              final ad = activeAds[index];
              return _buildAdCard(AdModel.fromMap(ad));
            },
          ),
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: _buildNavigationDots(activeAds.length),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: _buildPlayButton(),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: _buildAutoSlideIndicator(),
          ),
        ],
      ),
    );
  }

  Widget _buildAdCard(AdModel ad) {
    return GestureDetector(
      onTap: () => _handleAdTap(ad),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
          child: Stack(
            children: [
              // Ad Image/Thumbnail
              Container(
                width: double.infinity,
                height: widget.height,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: _getAdImage(ad),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Gradient overlay for better text readability
              Container(
                width: double.infinity,
                height: widget.height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),

              // Ad content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          ad.type.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Promoted tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Promoted',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Ad title
                      Text(
                        ad.title ?? 'Ad Title',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 12),

                      // Action button
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.play_arrow,
                                    color: Colors.black, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'Watch Now',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ImageProvider _getAdImage(AdModel ad) {
    // Try to get thumbnail from ad data
    if (ad.thumbnail.isNotEmpty) {
      return NetworkImage(ad.thumbnail);
    }

    // Try to extract thumbnail from YouTube URL
    if (ad.link.isNotEmpty && ad.link.contains('youtube.com')) {
      final videoId = _extractYouTubeVideoId(ad.link);
      if (videoId != null) {
        return NetworkImage(
            'https://img.youtube.com/vi/$videoId/maxresdefault.jpg');
      }
    }

    // Fallback to bundled banner as default
    return const AssetImage('assets/hackethos4u_logo.png');
  }

  String? _extractYouTubeVideoId(String url) {
    final regExp = RegExp(
      r'(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([^&\n?#]+)',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  void _handleAdTap(AdModel ad) {
    if (ad.link.isNotEmpty) {
      // Check if it's a YouTube URL
      if (ad.link.contains('youtube.com') || ad.link.contains('youtu.be')) {
        _openYouTubeVideo(ad.link);
      } else {
        // Handle other URLs
        _openRedirectUrl(ad.link);
      }
    }

    // Call custom onAdTap callback if provided
    if (widget.onAdTap != null) {
      widget.onAdTap!();
    }
  }

  void _openYouTubeVideo(String url) {
    try {
      final uri = Uri.parse(url);
      launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening video: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openVideoPlayer(AdModel ad) {
    // Navigate to video player screen
    Navigator.pushNamed(
      context,
      '/videoPlayer',
      arguments: {
        'videoUrl': ad.link,
        'title': ad.title,
        'isPreview': true,
        'adData': ad,
      },
    );
  }

  void _openRedirectUrl(String url) {
    try {
      final uri = Uri.parse(url);
      launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening link: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPlaceholderBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[400]!,
            Colors.purple[600]!,
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.play_circle_fill,
          color: Colors.white,
          size: 48,
        ),
      ),
    );
  }

  Widget _buildNavigationDots(int totalDots) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalDots, (index) {
        final isActive = index == _currentAdIndex;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 8,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  Widget _buildPlayButton() {
    return GestureDetector(
      onTap: () {
        if (_isAutoSliding) {
          _stopAutoSlide();
        } else {
          _startAutoSlide();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          _isAutoSliding ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildAutoSlideIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            Icons.auto_awesome,
            color: Colors.white,
            size: 12,
          ),
          SizedBox(width: 4),
          Text(
            'Auto',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
