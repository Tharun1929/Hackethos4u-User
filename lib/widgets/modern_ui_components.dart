import 'package:flutter/material.dart';
import '../theme/modern_theme.dart';

// Modern Glassmorphism Card
class ModernGlassCard extends StatelessWidget {
  final Widget child;
  final double blurRadius;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const ModernGlassCard({
    super.key,
    required this.child,
    this.blurRadius = 20,
    this.borderRadius = 16,
    this.backgroundColor,
    this.borderColor,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(20),
        decoration: ModernTheme.glassmorphismDecoration(
          blurRadius: blurRadius,
          borderRadius: borderRadius,
          backgroundColor: backgroundColor,
          borderColor: borderColor,
        ),
        child: child,
      ),
    );
  }
}

// Modern Animated Button
class ModernAnimatedButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool isLoading;
  final bool isGradient;

  const ModernAnimatedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.borderRadius = 12,
    this.padding,
    this.isLoading = false,
    this.isGradient = true,
  });

  @override
  State<ModernAnimatedButton> createState() => _ModernAnimatedButtonState();
}

class _ModernAnimatedButtonState extends State<ModernAnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: widget.padding ??
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                gradient:
                    widget.isGradient ? ModernTheme.primaryGradient : null,
                color: widget.isGradient
                    ? null
                    : (widget.backgroundColor ??
                        ModernTheme.primaryGradientStart),
                borderRadius: BorderRadius.circular(widget.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: (widget.backgroundColor ??
                            ModernTheme.primaryGradientStart)
                        .withOpacity(0.3),
                    blurRadius: _isPressed ? 8 : 16,
                    offset: Offset(0, _isPressed ? 4 : 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      color: widget.textColor ?? Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.text,
                    style: TextStyle(
                      color: widget.textColor ?? Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Modern Search Bar
class ModernSearchBar extends StatefulWidget {
  final String? hintText;
  final Function(String)? onSearch;
  final Function()? onClear;
  final TextEditingController? controller;
  final bool showFilters;

  const ModernSearchBar({
    super.key,
    this.hintText,
    this.onSearch,
    this.onClear,
    this.controller,
    this.showFilters = true,
  });

  @override
  State<ModernSearchBar> createState() => _ModernSearchBarState();
}

class _ModernSearchBarState extends State<ModernSearchBar> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _hasText = _controller.text.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ModernGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: ModernTheme.textSecondary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: widget.onSearch,
              decoration: InputDecoration(
                hintText: widget.hintText ?? 'Search courses...',
                hintStyle: TextStyle(
                  color: ModernTheme.textSecondary,
                  fontSize: 16,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: ModernTheme.modernTextStyle(
                fontSize: 16,
                color: ModernTheme.textPrimary,
              ),
            ),
          ),
          if (_hasText)
            IconButton(
              onPressed: () {
                _controller.clear();
                widget.onClear?.call();
              },
              icon: Icon(
                Icons.clear_rounded,
                color: ModernTheme.textSecondary,
                size: 20,
              ),
            ),
          if (widget.showFilters)
            IconButton(
              onPressed: () {
                // Show filter options
                _showFilterOptions(context);
              },
              icon: Icon(
                Icons.tune_rounded,
                color: ModernTheme.textSecondary,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const ModernFilterSheet(),
    );
  }
}

// Modern Filter Sheet
class ModernFilterSheet extends StatefulWidget {
  const ModernFilterSheet({super.key});

  @override
  State<ModernFilterSheet> createState() => _ModernFilterSheetState();
}

class _ModernFilterSheetState extends State<ModernFilterSheet> {
  String _selectedCategory = 'All';
  String _selectedLevel = 'All';
  double _minPrice = 0;
  double _maxPrice = 1000;
  double _minRating = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: ModernTheme.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter Courses',
                  style: ModernTheme.modernTextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Category Filter
                _buildFilterSection(
                  'Category',
                  [
                    'All',
                    'Programming',
                    'Design',
                    'Business',
                    'Marketing',
                    'Music'
                  ],
                  _selectedCategory,
                  (value) => setState(() => _selectedCategory = value),
                ),

                const SizedBox(height: 20),

                // Level Filter
                _buildFilterSection(
                  'Level',
                  ['All', 'Beginner', 'Intermediate', 'Advanced'],
                  _selectedLevel,
                  (value) => setState(() => _selectedLevel = value),
                ),

                const SizedBox(height: 20),

                // Price Range
                Text(
                  'Price Range',
                  style: ModernTheme.modernTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                RangeSlider(
                  values: RangeValues(_minPrice, _maxPrice),
                  min: 0,
                  max: 1000,
                  divisions: 20,
                  activeColor: ModernTheme.primaryGradientStart,
                  onChanged: (values) {
                    setState(() {
                      _minPrice = values.start;
                      _maxPrice = values.end;
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('\$${_minPrice.toInt()}'),
                    Text('\$${_maxPrice.toInt()}'),
                  ],
                ),

                const SizedBox(height: 20),

                // Rating Filter
                Text(
                  'Minimum Rating',
                  style: ModernTheme.modernTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Slider(
                  value: _minRating,
                  min: 0,
                  max: 5,
                  divisions: 10,
                  activeColor: ModernTheme.primaryGradientStart,
                  onChanged: (value) => setState(() => _minRating = value),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Any'),
                    Text('${_minRating.toStringAsFixed(1)} ★'),
                  ],
                ),

                const SizedBox(height: 32),

                // Apply Button
                SizedBox(
                  width: double.infinity,
                  child: ModernAnimatedButton(
                    text: 'Apply Filters',
                    onPressed: () {
                      Navigator.pop(context);
                      // Apply filters logic here
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(
    String title,
    List<String> options,
    String selectedValue,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: ModernTheme.modernTextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = option == selectedValue;
            return GestureDetector(
              onTap: () => onChanged(option),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? ModernTheme.primaryGradientStart
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? ModernTheme.primaryGradientStart
                        : ModernTheme.textSecondary.withOpacity(0.3),
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  option,
                  style: ModernTheme.modernTextStyle(
                    fontSize: 14,
                    color:
                        isSelected ? Colors.white : ModernTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// Modern Course Card
class ModernCourseCard extends StatefulWidget {
  final Map<String, dynamic> course;
  final VoidCallback? onTap;
  final bool showProgress;

  const ModernCourseCard({
    super.key,
    required this.course,
    this.onTap,
    this.showProgress = false,
  });

  @override
  State<ModernCourseCard> createState() => _ModernCourseCardState();
}

class _ModernCourseCardState extends State<ModernCourseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _animationController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _animationController.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                decoration: ModernTheme.animatedContainerDecoration(
                  isHovered: _isHovered,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course Image
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          widget.course['thumbnailUrl'] ??
                              'assets/hackethos4u_logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: ModernTheme.primaryGradient,
                              ),
                              child: const Icon(
                                Icons.school_rounded,
                                color: Colors.white,
                                size: 48,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: ModernTheme.primaryGradientStart
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.course['category'] ?? 'Course',
                              style: ModernTheme.modernTextStyle(
                                fontSize: 12,
                                color: ModernTheme.primaryGradientStart,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Course Title
                          Text(
                            widget.course['title'] ?? 'Course Title',
                            style: ModernTheme.modernTextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 8),

                          // Instructor
                          Text(
                            'by ${widget.course['instructor'] ?? 'Instructor'}',
                            style: ModernTheme.modernTextStyle(
                              fontSize: 14,
                              color: ModernTheme.textSecondary,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Course Info
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 16,
                                color: ModernTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.course['duration'] ?? '8 weeks',
                                style: ModernTheme.modernTextStyle(
                                  fontSize: 12,
                                  color: ModernTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.star_rounded,
                                size: 16,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.course['rating']?.toStringAsFixed(1) ?? '4.5'}',
                                style: ModernTheme.modernTextStyle(
                                  fontSize: 12,
                                  color: ModernTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Progress Bar (if showProgress is true)
                          if (widget.showProgress) ...[
                            LinearProgressIndicator(
                              value: (widget.course['progress'] ?? 0) / 100,
                              backgroundColor:
                                  ModernTheme.textSecondary.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                ModernTheme.primaryGradientStart,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${widget.course['progress']?.toStringAsFixed(0) ?? '0'}% Complete',
                              style: ModernTheme.modernTextStyle(
                                fontSize: 12,
                                color: ModernTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Price
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                widget.course['price'] == 0
                                    ? 'Free'
                                    : '\$${widget.course['price']}',
                                style: ModernTheme.modernTextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: widget.course['price'] == 0
                                      ? ModernTheme.success
                                      : ModernTheme.primaryGradientStart,
                                ),
                              ),
                              if (widget.course['price'] != 0 &&
                                  widget.course['originalPrice'] != null)
                                Text(
                                  '\$${widget.course['originalPrice']}',
                                  style: ModernTheme.modernTextStyle(
                                    fontSize: 14,
                                    color: ModernTheme.textSecondary,
                                    fontWeight: FontWeight.w400,
                                  ).copyWith(
                                      decoration: TextDecoration.lineThrough),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Modern Loading Shimmer
class ModernLoadingShimmer extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ModernLoadingShimmer({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = 8,
  });

  @override
  State<ModernLoadingShimmer> createState() => _ModernLoadingShimmerState();
}

class _ModernLoadingShimmerState extends State<ModernLoadingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation =
        Tween<double>(begin: -1.0, end: 2.0).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: [
                ModernTheme.textSecondary.withOpacity(0.1),
                ModernTheme.textSecondary.withOpacity(0.3),
                ModernTheme.textSecondary.withOpacity(0.1),
              ],
            ),
          ),
        );
      },
    );
  }
}
