import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/app_theme.dart';
import '../../model/course/course_data.dart';
import '../../providers/cart_provider.dart';
import '../payment/enhanced_payment_screen.dart';
import '../../services/enhanced_review_user_service.dart';
import '../../services/enhanced_certificate_service.dart';
import '../../model/wishlist/wishlist_viewmodel.dart';
import '../../model/course/course_model.dart';

class DetailCourseScreen extends StatefulWidget {
  final String courseId;

  const DetailCourseScreen({super.key, required this.courseId});

  @override
  State<DetailCourseScreen> createState() => _DetailCourseScreenState();
}

class _DetailCourseScreenState extends State<DetailCourseScreen>
    with AutomaticKeepAliveClientMixin {
  Map<String, dynamic>? course;
  bool _isLoading = true;
  bool _isEnrolled = false;
  bool _showBuyNow = true;
  bool _loadingCurriculum = true;
  List<Map<String, dynamic>> _modules = [];
  int _activeTab = 0;

  // New state variables for enhanced features
  Map<String, dynamic>? _instructor;
  bool _loadingInstructor = false;
  Map<String, dynamic>? _certificate;
  bool _loadingCertificate = false;
  List<Map<String, dynamic>> _reviews = [];
  bool _loadingReviews = false;
  List<Map<String, dynamic>> _faqs = [];
  bool _loadingFaqs = false;
  String _faqSearchQuery = '';
  double _averageRating = 0.0;
  int _totalReviews = 0;
  Map<int, int> _ratingDistribution = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadCourseData();
    _checkEnrollmentStatus();
    // Defer instructor load until course is fetched to avoid null/shape issues
    _loadInstructorData();
    _loadCertificateData();
    _loadReviewsData();
    _loadFaqsData();
  }

  Future<void> _loadCourseData() async {
    try {
      final courseData = await CourseData.getCourseById(widget.courseId);
      if (mounted) {
        setState(() {
          course = courseData;
          _isLoading = false;
        });
        _loadCurriculum();
        _loadInstructorData();
        _loadCertificateData();
        _loadReviewsData();
        _loadFaqsData();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading course: $e')),
        );
      }
    }
  }

  Future<void> _checkEnrollmentStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final enrollmentDoc = await FirebaseFirestore.instance
            .collection('enrollments')
            .where('userId', isEqualTo: user.uid)
            .where('courseId', isEqualTo: widget.courseId)
            .get();

        if (mounted) {
          setState(() {
            _isEnrolled = enrollmentDoc.docs.isNotEmpty;
            _showBuyNow = !_isEnrolled;
          });
        }
      } catch (e) {
        // ignore
      }
    }
  }

  Future<void> _loadCurriculum() async {
    try {
      // Support two shapes for embedded curriculum:
      // 1) modules: [ { title, description, duration, lessons: [...] } ]
      // 2) modules: [ { title, description, duration, submodules: [...] } ]
      final rawEmbedded = course?['modules'];
      if (rawEmbedded is List && rawEmbedded.isNotEmpty) {
        final normalized = <Map<String, dynamic>>[];
        for (final m in rawEmbedded) {
          if (m is Map) {
            final map = Map<String, dynamic>.from(m);
            final List lessonsSource = (map['lessons'] is List)
                ? (map['lessons'] as List)
                : (map['submodules'] is List)
                    ? (map['submodules'] as List)
                    : const [];
            final lessons = lessonsSource
                .whereType<Map>()
                .map((s) => Map<String, dynamic>.from(s))
                .toList()
              ..sort((a, b) => ((a['order'] ?? 0) as num)
                  .toInt()
                  .compareTo(((b['order'] ?? 0) as num).toInt()));
            normalized.add({
              'id': (map['id'] ?? '').toString(),
              'title': map['title'] ?? 'Module',
              'description': map['description'] ?? map['desc'],
              // Prefer explicit duration; otherwise try estimatedDuration; as a
              // fallback, extract from title like "(6 hours)" if present.
              'duration': map['duration'] ??
                  map['estimatedDuration'] ??
                  _extractDurationFromTitle(map['title']?.toString() ?? ''),
              'lessons': lessons,
            });
          }
        }
        if (normalized.isNotEmpty) {
          setState(() {
            _modules = normalized
              ..sort((a, b) => ((a['order'] ?? 0) as num)
                  .toInt()
                  .compareTo(((b['order'] ?? 0) as num).toInt()));
            _loadingCurriculum = false;
          });
          return;
        }
      }

      final modulesSnap = await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('modules')
          .orderBy('order', descending: false)
          .get();

      final fetched = <Map<String, dynamic>>[];
      for (final m in modulesSnap.docs) {
        final data = m.data();
        final subsSnap = await m.reference
            .collection('lessons')
            .orderBy('order', descending: false)
            .get();
        fetched.add({
          'id': m.id,
          'title': data['title'] ?? 'Module',
          'description': data['desc'] ?? data['description'],
          'duration': data['duration'],
          'lessons': subsSnap.docs
              .map((s) => {
                    'id': s.id,
                    ...s.data(),
                  })
              .toList(),
        });
      }

      if (mounted) {
        setState(() {
          _modules = fetched;
          _loadingCurriculum = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _modules = [];
          _loadingCurriculum = false;
        });
      }
    }
  }

  Future<void> _buyNow() async {
    if (course == null) return;

    try {
      // Navigate to enhanced payment screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EnhancedPaymentScreen(
            courseData: {
              'id': widget.courseId,
              'title': course!['title'] ?? 'Course',
              'price': _asDouble(course!['price']),
              'thumbnail': course!['thumbnail'] ?? course!['courseImage'] ?? '',
              'description': course!['description'] ?? '',
              'instructor': (course!['instructor'] is Map)
                  ? (course!['instructor']['name'] ?? '')
                  : (course!['instructor'] ?? ''),
              'duration': course!['duration'] ?? '',
            },
          ),
        ),
      );

      if (result == true && mounted) {
        // Payment successful, refresh enrollment status
        _checkEnrollmentStatus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful! Course unlocked.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _enrollInCourse() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('enrollments').add({
          'userId': user.uid,
          'courseId': widget.courseId,
          'enrolledAt': FieldValue.serverTimestamp(),
          'status': 'active',
        });

        if (mounted) {
          setState(() {
            _isEnrolled = true;
            _showBuyNow = false;
          });
        }
      } catch (e) {
        // ignore
      }
    }
  }

  void _addToCart() {
    if (course == null) return;

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    
    // Convert CourseModel to Map<String, dynamic> for cart
    final dynamic instructorRaw = course!['instructor'];
    final String instructorName = instructorRaw is Map<String, dynamic>
        ? (instructorRaw['name']?.toString() ?? 'Instructor')
        : (instructorRaw?.toString() ?? 'Instructor');

    final num? priceNum = course!['price'] is num
        ? course!['price'] as num
        : (course!['price'] is String
            ? num.tryParse((course!['price'] as String)
                .replaceAll(RegExp(r'[^0-9\.]'), ''))
            : null);
    final double price = (priceNum ?? 0).toDouble();

    final num? originalPriceNum = course!['originalPrice'] is num
        ? course!['originalPrice'] as num
        : (course!['originalPrice'] is String
            ? num.tryParse((course!['originalPrice'] as String)
                .replaceAll(RegExp(r'[^0-9\.]'), ''))
            : null);

    final courseMap = {
      'id': course!['id']?.toString() ?? widget.courseId,
      'title': course!['title']?.toString() ?? 'Course Title',
      'instructor': instructorName,
      'thumbnail': (course!['thumbnail']?.toString() ?? course!['courseImage']?.toString() ?? ''),
      'price': price,
      'originalPrice': (originalPriceNum?.toDouble() ?? (price > 0 ? price * 1.2 : null)),
      'duration': course!['duration']?.toString() ?? 'N/A',
      'lessonsCount': course!['lessonsCount'] ?? course!['totalVideo'] ?? course!['total_video'] ?? 0,
      'rating': (course!['rating'] is num) ? (course!['rating'] as num).toDouble() : 0.0,
      'studentsCount': course!['studentsCount'] ?? course!['students'] ?? 0,
      'hasFreeDemo': true,
    };
    
    cartProvider.addToCart(courseMap);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course added to cart!')),
      );
    }
  }

  void _addToWishlist() {
    if (course == null) return;

    try {
      // Convert course data to CourseModel for wishlist
      final courseModel = CourseModel(
        id: course!['id'],
        courseName: course!['course_name'] ?? course!['title'],
        courseImage: course!['course_image'] ?? course!['thumbnail'],
        instructor: course!['instructor'],
        price: course!['price']?.toDouble(),
        duration: course!['duration'],
        totalVideo: course!['total_video'] ?? course!['lessonsCount'],
        rating: course!['rating']?.toDouble() ?? course!['total_rating']?.toDouble(),
        studentsCount: course!['students_count'] ?? course!['studentsCount'],
      );

      // Add to wishlist using WishlistViewModel
      final wishlistViewModel = WishlistViewModel();
      wishlistViewModel.addToWishlist(courseModel);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to wishlist'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding to wishlist: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // New data loading methods
  Future<void> _loadInstructorData() async {
    setState(() => _loadingInstructor = true);
    try {
      // First try to get instructor from course data
      final dynamic rawInstructor = course?['instructor'];
      if (rawInstructor is Map) {
        final Map<String, dynamic> instructorData =
            rawInstructor.map((key, value) => MapEntry(key.toString(), value));
        if (mounted) {
          setState(() {
            _instructor = instructorData;
            _loadingInstructor = false;
          });
        }
        return;
      }

      // If instructorId exists, fetch from instructors collection
      if ((course?['instructorId'] ?? '').toString().isNotEmpty) {
        final instructorDoc = await FirebaseFirestore.instance
            .collection('instructors')
            .doc(course?['instructorId'].toString())
            .get();

        if (mounted && instructorDoc.exists) {
          setState(() {
            _instructor = instructorDoc.data();
            _loadingInstructor = false;
          });
        } else {
          setState(() => _loadingInstructor = false);
        }
      } else {
        // Fallback: create a basic instructor object from course data
        if (mounted) {
          setState(() {
            _instructor = {
              'name': (course?['instructor'] ?? course?['instructorName'] ?? 'Course Instructor').toString(),
              'title': 'Expert Instructor',
              'bio': 'Experienced instructor with expertise in this field',
              'rating': 4.5,
              'avatar': null,
            };
            _loadingInstructor = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _instructor = {
            'name': (course?['instructor'] ?? course?['instructorName'] ?? 'Course Instructor').toString(),
            'title': 'Expert Instructor',
            'bio': 'Experienced instructor with expertise in this field',
            'rating': 4.5,
            'avatar': null,
          };
          _loadingInstructor = false;
        });
      }
    }
  }

  Future<void> _loadCertificateData() async {
    if (course == null || course?['certificate'] != true) return;

    setState(() => _loadingCertificate = true);
    try {
      final certificateDoc = await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('certificate')
          .doc('preview')
          .get();

      if (mounted && certificateDoc.exists) {
        setState(() {
          _certificate = certificateDoc.data();
          _loadingCertificate = false;
        });
      } else {
        setState(() => _loadingCertificate = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingCertificate = false);
      }
    }
  }

  Future<void> _loadReviewsData() async {
    setState(() => _loadingReviews = true);
    try {
      final reviews = <Map<String, dynamic>>[];
      double totalRating = 0.0;
      int reviewCount = 0;
      final ratingCounts = <int, int>{};

      // First try to get reviews from course data
      if (course?['reviews'] != null && course?['reviews'] is List) {
        final courseReviews = course?['reviews'] as List<dynamic>;
        for (final review in courseReviews) {
          if (review is Map<String, dynamic>) {
            reviews.add(review);
            final rating = (review['rating'] as num?)?.toInt() ?? 0;
            if (rating > 0 && rating <= 5) {
              totalRating += rating;
              reviewCount++;
              ratingCounts[rating] = (ratingCounts[rating] ?? 0) + 1;
            }
          }
        }
      }

      // If no reviews in course data, try to get from subcollection
      if (reviews.isEmpty) {
        final reviewsSnap = await FirebaseFirestore.instance
            .collection('courses')
            .doc(widget.courseId)
            .collection('reviews')
            .orderBy('createdAt', descending: true)
            .limit(10)
            .get();

        if (reviewsSnap.docs.isNotEmpty) {
          for (final doc in reviewsSnap.docs) {
            final data = doc.data();
            reviews.add(data);

            final rating = (data['rating'] as num?)?.toInt() ?? 0;
            if (rating > 0 && rating <= 5) {
              totalRating += rating;
              reviewCount++;
              ratingCounts[rating] = (ratingCounts[rating] ?? 0) + 1;
            }
          }
        } else {
          // Fallback: try to get reviews from main reviews collection
          final mainReviewsSnap = await FirebaseFirestore.instance
              .collection('reviews')
              .where('courseId', isEqualTo: widget.courseId)
              .orderBy('createdAt', descending: true)
              .limit(10)
              .get();

          for (final doc in mainReviewsSnap.docs) {
            final data = doc.data();
            reviews.add(data);

            final rating = (data['rating'] as num?)?.toInt() ?? 0;
            if (rating > 0 && rating <= 5) {
              totalRating += rating;
              reviewCount++;
              ratingCounts[rating] = (ratingCounts[rating] ?? 0) + 1;
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _reviews = reviews;
          _averageRating = reviewCount > 0 ? totalRating / reviewCount : 0.0;
          _totalReviews = reviewCount;
          _ratingDistribution = ratingCounts;
          _loadingReviews = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _reviews = [];
          _averageRating = 0.0;
          _totalReviews = 0;
          _ratingDistribution = {};
          _loadingReviews = false;
        });
      }
    }
  }

  Future<void> _loadFaqsData() async {
    setState(() => _loadingFaqs = true);
    try {
      final faqsSnap = await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('faqs')
          .where('isPublished', isEqualTo: true)
          .orderBy('order', descending: false)
          .get();

      final faqs = faqsSnap.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();

      if (mounted) {
        setState(() {
          _faqs = faqs;
          _loadingFaqs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingFaqs = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Course Details'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading course details...'),
            ],
          ),
        ),
      );
    }

    if (course == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Course Details'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Course not found',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'The course you\'re looking for doesn\'t exist or has been removed.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Course Details'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              _addToWishlist();
            },
            icon: const Icon(Icons.favorite_border),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Course shared'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Course Hero Section
          SliverToBoxAdapter(
            child: _buildCourseHero(),
          ),

          // Course Content Tabs
          SliverToBoxAdapter(child: _buildCourseTabs()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 980;
                  final content = _buildTabContent();
                  if (!isWide) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [content, const SizedBox(height: 120)],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: content),
                      const SizedBox(width: 20),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: _buildPricingSidebar(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      actions: [
        IconButton(
          tooltip: 'Share',
          icon: const Icon(Icons.share_outlined),
          onPressed: () {
            final title = course?['title'] ?? '';
            final url = course?['shareUrl'] ?? '';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Share $title ${url.isNotEmpty ? url : ''}')),
            );
          },
        ),
        IconButton(
          tooltip: 'Save',
          icon: const Icon(Icons.bookmark_border),
          onPressed: () {
            _addToWishlist();
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (course?['thumbnail'] != null || course?['courseImage'] != null)
              Image.network(
                course?['thumbnail'] ?? course?['courseImage'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppTheme.primaryColor,
                    child:
                        const Icon(Icons.image, size: 64, color: Colors.white),
                  );
                },
              )
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                ),
                child: const Icon(Icons.school, size: 64, color: Colors.white),
              ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black45, Colors.transparent],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final theme = Theme.of(context);
    final dynamic instrRaw = course?['instructor'];
    final String instructorName = instrRaw is Map
        ? (instrRaw['name']?.toString() ?? '')
        : (instrRaw?.toString() ?? '');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            course?['title'] ?? 'Course Title',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            course?['subtitle'] ?? '',
            style: theme.textTheme.titleMedium
                ?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text('${course?['rating'] ?? 0.0}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              Text('(${course?['reviewsCount'] ?? 0} reviews)',
                  style: theme.textTheme.bodySmall),
              const SizedBox(height: 12),
              const Icon(Icons.groups, size: 18, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                  '${course?['students'] ?? course?['studentsCount'] ?? 0} enrolled',
                  style: theme.textTheme.bodySmall),
              const Spacer(),
              if (instructorName.isNotEmpty)
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundImage: _instructor?['avatar'] != null &&
                              _instructor!['avatar'].toString().isNotEmpty
                          ? NetworkImage(_instructor!['avatar'])
                          : null,
                      child: _instructor?['avatar'] == null ||
                              _instructor!['avatar'].toString().isEmpty
                          ? const Icon(Icons.person, size: 16)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('By $instructorName',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        if (_instructor?['title'] != null && _instructor!['title'].toString().isNotEmpty)
                          Text(_instructor!['title'],
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[600])),
                      ],
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if ((course?['category'] ?? '').toString().isNotEmpty)
                _chip(theme, course?['category']),
              if ((course?['level'] ?? '').toString().isNotEmpty)
                _chip(theme, course?['level']),
              if (course?['certificate'] == true)
                _chip(theme, 'Certificate on completion'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightsGrid() {
    final theme = Theme.of(context);
    final cert = course?['certificate'] == true ? 'Yes' : 'No';
    final certPct = course?['certificatePercent']?.toString();
    final items = [
      {
        'icon': Icons.access_time,
        'label': 'Duration',
        'value': course?['duration'] ?? 'N/A'
      },
      {
        'icon': Icons.school,
        'label': 'Level',
        'value': course?['level'] ?? 'N/A'
      },
      {
        'icon': Icons.language,
        'label': 'Language',
        'value': course?['language'] ?? 'N/A'
      },
      {
        'icon': Icons.verified,
        'label': 'Certificate',
        'value': certPct != null ? 'Yes ($certPct%)' : cert
      },
      {
        'icon': Icons.all_inclusive,
        'label': 'Access',
        'value': course?['lifetimeAccess'] == true
            ? 'Lifetime'
            : (course?['access'] ?? 'Limited')
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final isWide = c.maxWidth > 520;
          final crossAxis = isWide ? 5 : 2;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxis,
              mainAxisExtent: 56,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final it = items[index];
              return Row(
                children: [
                  Icon(it['icon'] as IconData,
                      size: 20, color: AppTheme.primarySolid),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(it['label'] as String,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: AppTheme.textSecondary)),
                        const SizedBox(height: 2),
                        Text(it['value']?.toString() ?? '-',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _chip(ThemeData theme, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildLearnings() {
    final theme = Theme.of(context);
    final items = (course?['whatYouLearn'] ?? []) as List;
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What you\'ll learn',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...items.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle,
                        size: 18, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(e.toString(),
                            style: theme.textTheme.bodyMedium)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildAboutCourse() {
    final theme = Theme.of(context);
    final about =
        (course?['longDesc'] ?? course?['description'] ?? '').toString();
    if (about.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About this course',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(about,
              style: theme.textTheme.bodyMedium, textAlign: TextAlign.start),
        ],
      ),
    );
  }

  Widget _buildRequirements() {
    final theme = Theme.of(context);
    final items = (course?['requirements'] ?? []) as List;
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Requirements',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...items.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        size: 18, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(e.toString(),
                            style: theme.textTheme.bodyMedium)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCurriculumSection() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.menu_book,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Course Curriculum',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loadingCurriculum)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Loading curriculum...',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else if (_modules.isEmpty)
            _buildEmptyCurriculumState(theme)
          else ...[
            _buildCurriculumHeaderSummary(theme),
            const SizedBox(height: 16),
            _buildCurriculumModules(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyCurriculumState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.schedule,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'Curriculum Coming Soon',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We are preparing comprehensive course content for you.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurriculumModules(ThemeData theme) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _modules.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final module = _modules[index];
        final lessons = List<Map<String, dynamic>>.from(
            (module['lessons'] as List?) ?? const []);
        final moduleDuration = _formatDuration(module['duration'] ?? '');
        final isExpanded = module['isExpanded'] ?? false;
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              initiallyExpanded: isExpanded,
              onExpansionChanged: (expanded) {
                setState(() {
                  module['isExpanded'] = expanded;
                });
              },
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.folder_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              title: Text(
                module['title'] ?? 'Module ${index + 1}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    module['description'] ?? 'Module content and lessons',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${lessons.length} lessons',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        moduleDuration,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  moduleDuration,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              children: lessons.map((sub) {
                final subDuration = _formatDuration(sub['duration'] ?? '');
                final isCompleted = sub['isCompleted'] ?? false;
                final isFree = sub['isFree'] == true;
                final locked = !_isEnrolled && !isFree;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCompleted 
                        ? Colors.green[50] 
                        : locked 
                            ? Colors.grey[100] 
                            : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCompleted 
                          ? Colors.green[200]! 
                          : locked 
                              ? Colors.grey[300]! 
                              : Colors.grey[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCompleted 
                              ? Colors.green[100] 
                              : locked
                                  ? Colors.grey[300]
                                  : theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          sub['type'] == 'video'
                              ? Icons.play_circle_outline
                              : sub['type'] == 'quiz'
                                  ? Icons.quiz_outlined
                                  : Icons.description_outlined,
                          color: isCompleted 
                              ? Colors.green[700] 
                              : locked
                                  ? Colors.grey[500]
                                  : theme.colorScheme.primary,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sub['title'] ?? sub['name'] ?? 'Lesson',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: isCompleted 
                                    ? Colors.green[800] 
                                    : locked 
                                        ? Colors.grey[500] 
                                        : null,
                              ),
                            ),
                            if (sub['description'] != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                sub['description'],
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (subDuration.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            subDuration,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                          ),
                        ),
                      if (isCompleted) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.check_circle,
                          color: Colors.green[600],
                          size: 16,
                        ),
                      ] else if (locked) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.lock_outline,
                          color: Colors.grey[500],
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurriculumHeaderSummary(ThemeData theme) {
    int totalLessons = 0;
    int totalMinutes = 0;
    for (final m in _modules) {
      final lessons = (m['lessons'] as List? ?? []);
      totalLessons += lessons.length;
      final dur = _parseMinutes(m['duration']);
      totalMinutes += dur;
      for (final lesson in lessons) {
        totalMinutes += _parseMinutes(lesson['duration']);
      }
    }
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final durationText = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.menu_book,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Course Overview',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalLessons lessons • $durationText total duration',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(dynamic duration) {
    if (duration == null) return '';
    final durationStr = duration.toString();
    if (durationStr.isEmpty) return '';
    
    // Try to parse as minutes first
    final minutes = _parseMinutes(duration);
    if (minutes > 0) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (hours > 0) {
        return '${hours}h ${remainingMinutes}m';
      } else {
        return '${remainingMinutes}m';
      }
    }
    
    // If parsing failed, return original string
    return durationStr;
  }

  int _parseMinutes(dynamic duration) {
    if (duration == null) return 0;
    final str = duration.toString();
    // Try patterns like "1h 20m", "85m", "01:20:00"
    final hMatch = RegExp(r"(\d+)h").firstMatch(str);
    final mMatch = RegExp(r"(\d+)m").firstMatch(str);
    final timeMatch = RegExp(r"^(\d+):(\d+):(\d+)").firstMatch(str);
    if (timeMatch != null) {
      final h = int.tryParse(timeMatch.group(1)!) ?? 0;
      final m = int.tryParse(timeMatch.group(2)!) ?? 0;
      // seconds ignored in summary
      return h * 60 + m;
    }
    int minutes = 0;
    if (hMatch != null) minutes += (int.tryParse(hMatch.group(1)!) ?? 0) * 60;
    if (mMatch != null) minutes += int.tryParse(mMatch.group(1)!) ?? 0;
    if (minutes == 0) {
      final asInt = int.tryParse(str);
      if (asInt != null) return asInt;
    }
    return minutes;
  }
  
  // Try to pull minutes from titles like "(6 hours)"
  String _extractDurationFromTitle(String title) {
    final match = RegExp(r"\((\d+)\s*hour").firstMatch(title);
    if (match != null) {
      final h = int.tryParse(match.group(1)!) ?? 0;
      if (h > 0) return (h * 60).toString();
    }
    return '';
  }

  // Duplicate helper removed (merged with the version above)

  Widget _buildDemoVideoOrThumbnail() {
    final previewUrl = course?['videoPreview'] ?? course?['demoVideo'];
    if (previewUrl == null || previewUrl.toString().isEmpty) {
      return const SizedBox.shrink();
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => _VideoPreviewScreen(url: previewUrl)));
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black12,
              ),
              child: const Center(
                child: Icon(Icons.play_circle_fill,
                    size: 64, color: Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateSection() {
    if (course?['certificate'] != true) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final imageUrl =
        (_certificate?['imageUrl'] ?? course?['certificateUrl'])?.toString();
    final hasUrl = imageUrl != null && imageUrl.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Certificate',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 140,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.borderLight),
                      color: Colors.grey.shade50,
                    ),
                    child: hasUrl
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, _, __) => const Center(
                                child: Icon(Icons.image_not_supported_outlined,
                                    size: 40, color: Colors.grey)),
                          )
                        : Image.asset(
                            'assets/CERTIFICATE.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, _, __) => const Center(
                                child: Icon(Icons.image,
                                    size: 40, color: Colors.grey)),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Earn a shareable certificate upon completion',
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(
                        'Showcase your achievement on LinkedIn and your resume. Certificates include your name, course title, and completion date.',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppTheme.textSecondary)),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  void _openCertificateModal(String urlOrAsset) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: urlOrAsset.startsWith('http')
                      ? Image.network(urlOrAsset, fit: BoxFit.contain)
                      : Image.asset(urlOrAsset, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyReviewsState() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ]),
      child: Column(
        children: [
          // Star rating display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...List.generate(5, (index) {
                return Icon(
                  Icons.star_border,
                  color: Colors.grey[400],
                  size: 32,
                );
              }),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'No Reviews Yet',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to review this course!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Rating breakdown
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Text(
                  'Rate this course',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        // Handle rating tap
                        _showRatingDialog();
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(
                          Icons.star_border,
                          color: theme.colorScheme.primary,
                          size: 28,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap to rate',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Write review button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _showWriteReviewDialog();
              },
              icon: const Icon(Icons.edit),
              label: const Text('Write a Review'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSampleReviews() {
    final theme = Theme.of(context);
    final sampleReviews = [
      {
        'userName': 'Alex Thompson',
        'rating': 5,
        'comment': 'Outstanding course! The instructor explains complex ethical hacking concepts in a way that\'s easy to understand. The hands-on labs are fantastic and really help solidify the learning.',
        'createdAt': DateTime.now().subtract(const Duration(days: 2)),
        'verified': true,
      },
      {
        'userName': 'Sarah Chen',
        'rating': 5,
        'comment': 'This course exceeded my expectations. The practical exercises are top-notch and the instructor\'s teaching style is engaging. Highly recommend for anyone serious about cybersecurity.',
        'createdAt': DateTime.now().subtract(const Duration(days: 5)),
        'verified': true,
      },
      {
        'userName': 'Michael Rodriguez',
        'rating': 4,
        'comment': 'Great content and well-structured curriculum. The real-world examples make it easy to understand. Only minor issue is some videos could be a bit longer.',
        'createdAt': DateTime.now().subtract(const Duration(days: 7)),
        'verified': false,
      },
      {
        'userName': 'Emily Watson',
        'rating': 5,
        'comment': 'Perfect for beginners! The step-by-step approach and detailed explanations helped me understand ethical hacking concepts I never thought I could grasp. The community support is also excellent.',
        'createdAt': DateTime.now().subtract(const Duration(days: 10)),
        'verified': true,
      },
      {
        'userName': 'David Kim',
        'rating': 4,
        'comment': 'Solid course with practical knowledge. The instructor is knowledgeable and the course material is up-to-date. Would love to see more advanced topics covered.',
        'createdAt': DateTime.now().subtract(const Duration(days: 12)),
        'verified': false,
      },
    ];

    // Calculate average rating
    final avgRating = sampleReviews.isEmpty
        ? 0.0
        : sampleReviews.fold<double>(0.0, (sum, review) {
            final r = (review['rating'] as num?)?.toDouble() ?? 0.0;
            return sum + r;
          }) /
            sampleReviews.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with rating summary
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Student Reviews',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < avgRating.floor() ? Icons.star : 
                            (index < avgRating ? Icons.star_half : Icons.star_border),
                            color: Colors.amber,
                            size: 24,
                          );
                        }),
                        const SizedBox(width: 12),
                        Text('${avgRating.toStringAsFixed(1)}',
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        Text('(${sampleReviews.length} reviews)',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                      ],
                    ),
                  ],
                ),
              ),
              // Rating distribution
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text('${avgRating.toStringAsFixed(1)}',
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                    Text('out of 5',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.primary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Reviews list
          ...sampleReviews.map((review) => _buildEnhancedReviewItem(review)),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    final theme = Theme.of(context);
    if (_loadingReviews) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderLight)),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_reviews.isEmpty) {
      // Show empty state with star rating system
      return _buildEmptyReviewsState();
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderLight)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ratings & Reviews',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_averageRating.toStringAsFixed(1),
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                      children: List.generate(
                          5,
                          (i) => Icon(
                              i < _averageRating.round()
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 18))),
                  const SizedBox(height: 4),
                  Text('$_totalReviews reviews',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppTheme.textSecondary)),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(child: _buildRatingDistributionBars()),
            ],
          ),
          const SizedBox(height: 16),
          // Write review CTA
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: _openWriteReview,
              icon: const Icon(Icons.rate_review_rounded, size: 18),
              label: const Text('Write a review'),
            ),
          ),
          const SizedBox(height: 8),
          ..._reviews.take(5).map((r) => _buildReviewItem(r)),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/courseReviews',
                    arguments: {'courseId': widget.courseId});
              },
              child: const Text('See all reviews'),
            ),
          ),
        ],
      ),
    );
  }

  void _openWriteReview() async {
    final theme = Theme.of(context);
    final TextEditingController controller = TextEditingController();
    double rating = 5;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rate this course', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              StatefulBuilder(builder: (context, setSt) {
                return Row(
                  children: List.generate(5, (i) {
                    return IconButton(
                      icon: Icon(
                        i < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      ),
                      onPressed: () => setSt(() => rating = (i + 1).toDouble()),
                    );
                  }),
                );
              }),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Share your experience...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    try {
                      final ok = await EnhancedReviewUserService().submitReview(
                        courseId: widget.courseId,
                        courseTitle: (course?['title'] ?? '').toString(),
                        rating: rating,
                        reviewText: controller.text.trim(),
                      );
                      if (ok) {
                        _loadReviewsData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Review submitted for approval')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to submit review')),
                        );
                      }
                    } catch (_) {}
                  },
                  child: const Text('Submit'),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildRatingDistributionBars() {
    final total = _totalReviews == 0 ? 1 : _totalReviews;
    return Column(
      children: List.generate(5, (idx) {
        final star = 5 - idx;
        final count = _ratingDistribution[star] ?? 0;
        final pct = count / total;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              SizedBox(
                  width: 24, child: Text('$star★', textAlign: TextAlign.right)),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade200,
                      color: AppTheme.primarySolid),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(width: 32, child: Text('$count')),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> r) {
    final name = (r['userName'] ?? r['name'] ?? 'User').toString();
    final avatar = r['userAvatar'];
    final rating = (r['rating'] as num?)?.toInt() ?? 0;
    final comment = (r['comment'] ?? '').toString();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
              radius: 18,
              backgroundImage: (avatar ?? '').toString().isNotEmpty
                  ? NetworkImage(avatar)
                  : null,
              child:
                  (avatar == null) ? const Icon(Icons.person, size: 18) : null),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(name,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Row(
                      children: List.generate(
                          5,
                          (i) => Icon(
                              i < rating ? Icons.star : Icons.star_border,
                              size: 14,
                              color: Colors.amber)))
                ]),
                if (comment.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(comment)
                ],
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEnhancedReviewItem(Map<String, dynamic> review) {
    final theme = Theme.of(context);
    final name = (review['userName'] ?? review['name'] ?? 'User').toString();
    final rating = (review['rating'] as num?)?.toInt() ?? 0;
    final comment = (review['comment'] ?? '').toString();
    final createdAt = review['createdAt'] as DateTime? ?? DateTime.now();
    final verified = review['verified'] as bool? ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info and rating
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (verified) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified, color: Colors.white, size: 12),
                                const SizedBox(width: 2),
                                Text(
                                  'Verified',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 16,
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Comment
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              comment,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),
          ],
          // Helpful buttons
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.thumb_up_outlined, size: 16),
                label: Text('Helpful'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface.withOpacity(0.6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
              const SizedBox(width: 16),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.reply_outlined, size: 16),
                label: Text('Reply'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface.withOpacity(0.6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    }
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate this Course'),
        content: const Text('Please rate this course from 1 to 5 stars.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showWriteReviewDialog();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showWriteReviewDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Write a Review'),
        content: const Text('This feature will be available soon! You can rate and review courses after completing them.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqSection() {
    final theme = Theme.of(context);
    if (_loadingFaqs) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderLight)),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_faqs.isEmpty) return const SizedBox.shrink();

    final filtered = _faqSearchQuery.isEmpty
        ? _faqs
        : _faqs
            .where((f) => (f['question'] ?? '')
                .toString()
                .toLowerCase()
                .contains(_faqSearchQuery.toLowerCase()))
            .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderLight)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FAQs',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search), hintText: 'Search FAQs'),
            onChanged: (v) => setState(() => _faqSearchQuery = v),
          ),
          const SizedBox(height: 12),
          ...filtered.map((f) => Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: AppTheme.borderLight)),
                child: ExpansionTile(
                  title: Text(f['question'] ?? ''),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text((f['answer'] ?? '').toString())),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildInstructorInfo() {
    final theme = Theme.of(context);
    
    // Get instructor data from multiple sources
    final dynamic rawInstructor = _instructor ?? course?['instructor'];
    final Map<String, dynamic> instructor = rawInstructor is Map
        ? Map<String, dynamic>.from(rawInstructor)
        : {
            'name': rawInstructor?.toString() ?? 'Course Instructor',
            'title': 'Expert Instructor',
            'bio': 'Experienced instructor with expertise in this field',
            'rating': 4.5,
            'avatar': null,
          };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Instructor',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_loadingInstructor)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator()))
          else
            InkWell(
              onTap: () => _openInstructorModal(),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: (instructor['avatar'] ?? '')
                                .toString()
                                .isNotEmpty
                            ? NetworkImage(instructor['avatar'].toString())
                        : null,
                    child: ((instructor['avatar'] ?? '')
                                .toString()
                                .isEmpty)
                        ? const Icon(Icons.person, size: 30)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text((instructor['name'] ?? 'Instructor Name').toString(),
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text((instructor['title'] ?? 'Course Instructor').toString(),
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.textSecondary)),
                        if (double.tryParse((instructor['rating'] ?? 0).toString()) != null &&
                            (double.tryParse((instructor['rating'] ?? 0).toString()) ?? 0) > 0)
                          ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  size: 16, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text('${instructor['rating']}',
                                  style: theme.textTheme.bodyMedium),
                            ],
                          ),
                        ]
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _openInstructorModal() {
    final instructor = _instructor ?? {};
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                controller: controller,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundImage:
                            (instructor['avatar'] ?? '').toString().isNotEmpty
                                ? NetworkImage(instructor['avatar'])
                                : null,
                        child: (instructor['avatar'] == null ||
                                instructor['avatar'].toString().isEmpty)
                            ? const Icon(Icons.person, size: 34)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(instructor['name'] ?? 'Instructor',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(instructor['title'] ?? '',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if ((instructor['bio'] ?? '').toString().isNotEmpty) ...[
                    Text('About',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(instructor['bio'],
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 16),
                  ],
                  if (instructor['social'] is Map) ...[
                    Text('Social',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ...(instructor['social'] as Map)
                        .entries
                        .map<Widget>((e) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(children: [
                                const Icon(Icons.link, size: 16),
                                const SizedBox(width: 8),
                                Expanded(child: Text('${e.key}: ${e.value}'))
                              ]),
                            )),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomBar() {
    final originalPrice = _asDouble(course?['originalPrice']);
    final currentPrice = _asDouble(course?['price']);
    final hasDiscount = originalPrice > currentPrice && currentPrice > 0;
    final monthly = _asDouble(course?['monthlyPrice']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(color: AppTheme.borderLight),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (currentPrice > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('₹${currentPrice.toStringAsFixed(0)}',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.success)),
                  if (hasDiscount) ...[
                    const SizedBox(width: 8),
                    Text('₹${originalPrice.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: AppTheme.textSecondary)),
                  ]
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (monthly > 0) ...[
              Text('or ₹${monthly.toStringAsFixed(0)}/month',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                if (_isEnrolled) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/learningCourse',
                            arguments: widget.courseId);
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Continue Learning'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.badgeBeginner,
                          foregroundColor: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _getCertificate,
                    icon: const Icon(Icons.workspace_premium_rounded),
                    label: const Text('Get Certificate'),
                  ),
                ] else if (_showBuyNow) ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _buyNow,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primarySolid,
                          foregroundColor: Colors.white),
                      child: const Text('Buy Now'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _addToCart,
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('Add to Cart'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primarySolid,
                        side: BorderSide(color: AppTheme.primarySolid)),
                  ),
                ] else ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleEnrollClick,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primarySolid,
                          foregroundColor: Colors.white),
                      child: const Text('Enroll Now'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleEnrollClick() {
    _buyNow();
  }

  Future<void> _getCertificate() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to continue')),
        );
        return;
      }
      final completionPct = await _fetchCompletionPercent();
      final url = await EnhancedCertificateService().generateCertificate(
        courseId: widget.courseId,
        courseTitle: (course?['title'] ?? '').toString(),
        userName: user.displayName ?? 'Student',
        completionPercentage: completionPct,
      );
      if (!mounted) return;
      if (url != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Certificate generated')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complete more to unlock certificate')),
        );
      }
    } catch (_) {}
  }

  Future<double> _fetchCompletionPercent() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 0;
      final snap = await FirebaseFirestore.instance
          .collection('enrollments')
          .where('userId', isEqualTo: user.uid)
          .where('courseId', isEqualTo: widget.courseId)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return 0;
      final data = snap.docs.first.data();
      return (data['progressPercent'] as num?)?.toDouble() ??
          (data['progress'] as num?)?.toDouble() ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  double _asDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^0-9\.]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  Widget _buildPricingSidebar() {
    final originalPrice = _asDouble(course?['originalPrice']);
    final currentPrice = _asDouble(course?['price']);
    final hasDiscount = originalPrice > currentPrice && currentPrice > 0;
    final monthly = _asDouble(course?['monthlyPrice']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDemoVideoOrThumbnail(),
          const SizedBox(height: 12),
          if (currentPrice > 0) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₹${currentPrice.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold, color: AppTheme.success)),
                if (hasDiscount) ...[
                  const SizedBox(width: 8),
                  Text('₹${originalPrice.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: AppTheme.textSecondary)),
                ]
              ],
            ),
            const SizedBox(height: 6),
          ],
          if (monthly > 0)
            Text('or ₹${monthly.toStringAsFixed(0)}/month',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _buyNow,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primarySolid,
                  foregroundColor: Colors.white),
              child: const Text('Buy Now'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addToCart,
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Add to Cart'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primarySolid,
                  side: BorderSide(color: AppTheme.primarySolid)),
            ),
          ),
        ],
      ),
    );
  }

  // UI helpers: belong to the state to access `course`, `_showBuyNow`, etc.
  Widget _buildCourseHero() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: Stack(
        children: [
          if (course?['thumbnail'] != null)
            Positioned.fill(
              child: Opacity(
                opacity: 0.3,
                child: Image.network(
                  course!['thumbnail'],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container();
                  },
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Text(
                      course?['category'] ?? 'Course',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    course?['title'] ?? 'Course Title',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (course?['subtitle'] != null)
                    Text(
                      course!['subtitle'],
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildHeroStatItem(
                        Icons.star,
                        '${course?['rating'] ?? 4.5}',
                        'Rating',
                      ),
                      const SizedBox(width: 20),
                      _buildHeroStatItem(
                        Icons.people,
                        '${course?['studentsCount'] ?? 0}',
                        'Students',
                      ),
                      const SizedBox(width: 20),
                      _buildHeroStatItem(
                        Icons.access_time,
                        course?['duration'] ?? '10h',
                        'Duration',
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

  Widget _buildHeroStatItem(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 16,
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCourseTabs() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (course?['originalPrice'] != null &&
                          course!['originalPrice'] != course!['price'])
                        Text(
                          '₹${course!['originalPrice']}',
                          style: const TextStyle(
                            fontSize: 16,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          ),
                        ),
                      Text(
                        '₹${course?['price'] ?? 0}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                if (_showBuyNow)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[600]!, Colors.blue[700]!],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _buyNow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Enroll Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green[600]!, Colors.green[700]!],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _enrollInCourse,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Start Learning',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                _buildTabButton('Overview', 0),
                _buildTabButton('Curriculum', 1),
                _buildTabButton('Instructor', 2),
                _buildTabButton('Reviews', 3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    return Expanded(
      child: InkWell(
        onTap: () {
          if (_activeTab != index) setState(() => _activeTab = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: _activeTab == index
                    ? Colors.blue[600]!
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _activeTab == index ? Colors.blue[600] : Colors.grey[600],
              fontWeight:
                  _activeTab == index ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_activeTab) {
      case 1:
        return _buildCurriculumSection();
      case 2:
        return _buildInstructorInfo();
      case 3:
        return _buildReviewsSection();
      case 0:
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 20),
            _buildHighlightsGrid(),
            const SizedBox(height: 20),
            _buildDemoVideoOrThumbnail(),
            const SizedBox(height: 24),
            _buildLearnings(),
            const SizedBox(height: 24),
            _buildAboutCourse(),
            const SizedBox(height: 24),
            _buildRequirements(),
            const SizedBox(height: 24),
            _buildCertificateSection(),
            const SizedBox(height: 24),
            _buildFaqSection(),
          ],
        );
    }
  }
}

class _VideoPreviewScreen extends StatelessWidget {
  final String url;
  const _VideoPreviewScreen({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Course Preview')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_circle_fill, size: 80),
            const SizedBox(height: 12),
            Text('Preview URL:',
                style: Theme.of(context).textTheme.titleMedium),
            Text(url, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
