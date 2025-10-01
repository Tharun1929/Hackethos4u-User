import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../model/ad_model.dart';
import '../services/ad_service.dart';

class SimpleAdWidget extends StatefulWidget {
  final AdModel ad;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const SimpleAdWidget({
    super.key,
    required this.ad,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  State<SimpleAdWidget> createState() => _SimpleAdWidgetState();
}

class _SimpleAdWidgetState extends State<SimpleAdWidget> {
  final AdService _adService = AdService();

  @override
  void initState() {
    super.initState();
    // Record view when widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _adService.recordAdView(widget.ad.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        _adService.openAdLink(widget.ad);
        widget.onTap?.call();
      },
      child: Container(
        width: widget.width,
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
              // Ad thumbnail
              CachedNetworkImage(
                imageUrl: widget.ad.thumbnail,
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
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.ad.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            _getAdTypeIcon(widget.ad.type),
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getAdTypeText(widget.ad.type),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Tap to open',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
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
        ),
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
