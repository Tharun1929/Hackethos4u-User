import 'package:flutter/material.dart';
import '../utils/theme.dart';

class CourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final VoidCallback? onTap;

  const CourseCard({
    super.key,
    required this.course,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final originalPrice = (course['originalPrice'] ?? 0.0).toDouble();
    final currentPrice = (course['price'] ?? 0.0).toDouble();
    final discount = originalPrice > 0
        ? ((originalPrice - currentPrice) / originalPrice * 100).toInt()
        : 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Thumbnail with improved aspect ratio
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Stack(
                  children: [
                    Image.asset(
                      course['thumbnail'],
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: AppGradients.primaryGradient,
                          ),
                          child: const Icon(
                            Icons.school,
                            color: Colors.white,
                            size: 40,
                          ),
                        );
                      },
                    ),
                    // Badges with improved positioning
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Row(
                        children: [
                          if (course['isNew'] == true)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppThemes.badgeBeginner,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
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
                          if (course['isNew'] == true && discount > 0)
                            const SizedBox(width: 6),
                          if (discount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppThemes.badgeAdvanced,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                '$discount% OFF',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (course['isPopular'] == true)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppThemes.badgeIntermediate,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'HOT',
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
            ),

            // Course Info with improved spacing
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course Title with bold styling
                    Text(
                      course['title'],
                      style: theme.textTheme.titleLarge?.copyWith(height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Instructor with small text styling
                    Text(
                      course['instructor'],
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontSize: 13, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // Rating and Students with improved layout
                    Row(
                      children: [
                        Icon(Icons.star_rounded,
                            color: Colors.amber[600], size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${course['rating']}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.people_rounded,
                            color: theme.textTheme.bodySmall?.color, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${(course['students'] / 1000).toStringAsFixed(1)}k',
                          style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Price with improved styling
                    Row(
                      children: [
                        Text(
                          '\$${((course['price'] ?? 0.0) / 100).toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '\$${((course['originalPrice'] ?? 0.0) / 100).toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14,
                            decoration: TextDecoration.lineThrough,
                            color: theme.textTheme.bodySmall?.color,
                            fontWeight: FontWeight.w500,
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
    );
  }
}
