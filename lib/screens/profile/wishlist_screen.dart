import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _courses = [];

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final ids = userProvider.wishlistCourses;
      final List<Map<String, dynamic>> out = [];
      if (ids.isEmpty) {
        setState(() {
          _courses = out;
          _loading = false;
        });
        return;
      }

      // Firestore whereIn supports up to 10 ids per query
      for (int i = 0; i < ids.length; i += 10) {
        final batch = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);
        final snap = await FirebaseFirestore.instance
            .collection('courses')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        for (final d in snap.docs) {
          out.add({'id': d.id, ...d.data()});
        }
      }
      setState(() {
        _courses = out;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _courses.isEmpty
              ? _buildEmpty(theme)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _courses.length,
                  itemBuilder: (context, i) =>
                      _buildCourseCard(theme, _courses[i]),
                ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border,
              size: 80, color: theme.colorScheme.onSurface.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text('No items in wishlist', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Explore courses and tap the heart to add',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6))),
        ],
      ),
    );
  }

  Widget _buildCourseCard(ThemeData theme, Map<String, dynamic> c) {
    final title = (c['title'] ?? c['courseName'] ?? 'Course').toString();
    final thumb = c['thumbnailUrl'] ?? c['thumbnail'] ?? '';
    final author = c['instructorName'] ?? c['author'] ?? '';
    final price = (c['price'] is num) ? (c['price'] as num).toDouble() : 0.0;
    final originalPrice = (c['originalPrice'] is num)
        ? (c['originalPrice'] as num).toDouble()
        : null;
    final rating = (c['rating'] is num) ? (c['rating'] as num).toDouble() : 0.0;
    final studentCount = (c['enrollmentCount'] is num)
        ? (c['enrollmentCount'] as num).toInt()
        : 0;
    final duration = c['duration']?.toString() ?? '';
    final level = c['level']?.toString() ?? 'Beginner';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(context, '/coursePlan',
            arguments: {'courseData': c}),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Thumbnail
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 200,
                    child: thumb.toString().isNotEmpty
                        ? Image.network(
                            thumb,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: theme.dividerColor.withOpacity(0.2),
                              child: Icon(Icons.image,
                                  size: 50,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.3)),
                            ),
                          )
                        : Container(
                            color: theme.dividerColor.withOpacity(0.2),
                            child: Icon(Icons.image,
                                size: 50,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.3)),
                          ),
                  ),
                  // Wishlist button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.favorite,
                            color: Colors.red, size: 20),
                        onPressed: () async {
                          final userProvider =
                              Provider.of<UserProvider>(context, listen: false);
                          await userProvider.removeFromWishlist(c['id']);
                          setState(() {
                            _courses.removeWhere((e) => e['id'] == c['id']);
                          });
                        },
                      ),
                    ),
                  ),
                  // Level badge
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        level,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Course Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Author
                  Text(
                    author,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Rating and Students
                  Row(
                    children: [
                      // Rating
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // Student count
                      Row(
                        children: [
                          Icon(Icons.people,
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.6),
                              size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${_formatNumber(studentCount)} students',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Duration
                  if (duration.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.schedule,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            size: 16),
                        const SizedBox(width: 4),
                        Text(
                          duration,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Price
                  Row(
                    children: [
                      Text(
                        '₹${price.toStringAsFixed(0)}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (originalPrice != null && originalPrice > price) ...[
                        const SizedBox(width: 8),
                        Text(
                          '₹${originalPrice.toStringAsFixed(0)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${((originalPrice - price) / originalPrice * 100).round()}% OFF',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
