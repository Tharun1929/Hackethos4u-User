import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../screens/course/detail_course_screen.dart';

class EnhancedCourseCard extends StatefulWidget {
  final Map<String, dynamic> course;
  final bool isHorizontal;
  final bool showProgress;
  final double? progress;
  final VoidCallback? onTap;

  const EnhancedCourseCard({
    super.key,
    required this.course,
    this.isHorizontal = false,
    this.showProgress = false,
    this.progress,
    this.onTap,
  });

  @override
  State<EnhancedCourseCard> createState() => _EnhancedCourseCardState();
}

class _EnhancedCourseCardState extends State<EnhancedCourseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: GestureDetector(
              onTap: widget.onTap ?? () => _navigateToCourseDetail(),
              onTapDown: (_) => _animationController.forward(),
              onTapUp: (_) => _animationController.reverse(),
              onTapCancel: () => _animationController.reverse(),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: widget.isHorizontal
                    ? _buildHorizontalCard()
                    : _buildVerticalCard(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVerticalCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Course Image with Overlays
        _buildCourseImage(),

        // Course Content
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Title
              Text(
                widget.course['title'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Instructor
              Text(
                widget.course['instructor'],
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),

              // Course Stats
              _buildCourseStats(),
              const SizedBox(height: 12),

              // Price and Action
              _buildPriceAndAction(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalCard() {
    return Row(
      children: [
        // Course Image
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
          child: SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              children: [
                Image.asset(
                  widget.course['thumbnail'],
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
                _buildImageOverlays(),
              ],
            ),
          ),
        ),

        // Course Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.course['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.course['instructor'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                _buildCourseStats(),
                const SizedBox(height: 12),
                _buildPriceAndAction(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseImage() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(16),
      ),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.asset(
              widget.course['thumbnail'],
              fit: BoxFit.cover,
            ),
          ),
          _buildImageOverlays(),
        ],
      ),
    );
  }

  Widget _buildImageOverlays() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.3),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Rating Badge
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.course['rating'].toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // New Badge
            if (widget.course['isNew'] == true)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

            // Popular Badge
            if (widget.course['isPopular'] == true &&
                widget.course['isNew'] != true)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'POPULAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseStats() {
    return Row(
      children: [
        // Duration
        Row(
          children: [
            Icon(
              Icons.access_time_rounded,
              size: 14,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              widget.course['duration'],
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),

        // Students
        Row(
          children: [
            Icon(
              Icons.people_rounded,
              size: 14,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              _formatStudentCount(widget.course['students']),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),

        // Level
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getLevelColor(widget.course['level']).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getLevelColor(widget.course['level']).withOpacity(0.3),
            ),
          ),
          child: Text(
            widget.course['level'],
            style: TextStyle(
              fontSize: 10,
              color: _getLevelColor(widget.course['level']),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceAndAction() {
    final price = widget.course['price'];
    final originalPrice = widget.course['originalPrice'];
    final hasDiscount = originalPrice != null && originalPrice > price;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '₹${price.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            if (hasDiscount)
              Text(
                '₹${originalPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF999999),
                  decoration: TextDecoration.lineThrough,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0056D2),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0056D2).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Text(
            'Enroll',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _formatStudentCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  void _navigateToCourseDetail() {
    Get.to(() => DetailCourseScreen(courseId: widget.course['id']));
  }
}
