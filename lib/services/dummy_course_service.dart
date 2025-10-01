import 'dart:math';

class DummyCourseService {
  static final Random _random = Random();

  // Dummy video URLs (using sample videos that work)
  static const List<String> _dummyVideoUrls = [
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
  ];

  static const List<String> _courseTitles = [
    'Complete Ethical Hacking Course',
    'Advanced Cybersecurity Fundamentals',
    'Network Security Mastery',
    'Penetration Testing Bootcamp',
    'Digital Forensics & Incident Response',
    'Web Application Security',
    'Mobile Security Testing',
    'Cloud Security Essentials',
    'Malware Analysis & Reverse Engineering',
    'Security Operations Center (SOC)',
  ];

  static const List<String> _moduleTitles = [
    'Introduction to Cybersecurity',
    'Network Fundamentals',
    'Operating System Security',
    'Web Application Security',
    'Mobile Security',
    'Cloud Security',
    'Incident Response',
    'Digital Forensics',
    'Penetration Testing',
    'Security Operations',
  ];

  static const List<String> _lessonTitles = [
    'Understanding Cyber Threats',
    'Network Protocols & Security',
    'Windows Security Basics',
    'Linux Security Fundamentals',
    'Web Application Vulnerabilities',
    'SQL Injection Attacks',
    'Cross-Site Scripting (XSS)',
    'Authentication & Authorization',
    'Encryption & Cryptography',
    'Security Monitoring & Logging',
    'Incident Response Planning',
    'Digital Evidence Collection',
    'Network Penetration Testing',
    'Web Application Testing',
    'Social Engineering Attacks',
    'Vulnerability Assessment',
    'Security Policy Development',
    'Risk Management',
    'Compliance & Regulations',
    'Security Awareness Training',
  ];

  // Generate dummy course data
  static Map<String, dynamic> generateDummyCourse({
    String? courseId,
    bool includeDemo = true,
    bool isPaid = true,
    double price = 2999.0,
  }) {
    final id = courseId ?? 'course_${DateTime.now().millisecondsSinceEpoch}';
    final title = _courseTitles[_random.nextInt(_courseTitles.length)];
    final modules = _generateModules(5); // 5 modules
    final totalLessons = modules.fold<int>(
        0, (sum, module) => sum + (module['lessons'] as List).length);

    return {
      'id': id,
      'title': title,
      'shortDesc':
          'Master cybersecurity with this comprehensive course covering all essential topics.',
      'longDesc':
          'This comprehensive cybersecurity course covers everything from basic concepts to advanced techniques. You\'ll learn about network security, web application security, penetration testing, digital forensics, and much more. Perfect for beginners and professionals looking to enhance their security skills.',
      'category': 'Cybersecurity',
      'instructor': 'MANITEJA THAGARAM',
      'instructorTitle': 'Cybersecurity Expert & CEO',
      'instructorAvatar': '',
      'instructorBio':
          '10+ years experience in cybersecurity, ethical hacking, and digital forensics.',
      'published': true,
      'price': price.toString(),
      'originalPrice': (price * 1.5).toString(),
      'monthlyPrice': (price / 3).toString(),
      'demoAvailable': includeDemo,
      'demoVideo': includeDemo ? _dummyVideoUrls[0] : null,
      'videoPreview': includeDemo ? _dummyVideoUrls[0] : null,
      'access': isPaid ? 'Paid' : 'Free',
      'duration': '${totalLessons * 10} minutes', // 10 minutes per lesson
      'certificatePercent': '70',
      'certificate': true,
      'lifetimeAccess': true,
      'isPopular': true,
      'isFeatured': _random.nextBool(),
      'isNew': _random.nextBool(),
      'level': 'Intermediate',
      'language': 'English',
      'thumbnail': '',
      'modules': modules,
      'whatYouLearn': [
        'Master ethical hacking techniques',
        'Understand network security fundamentals',
        'Learn penetration testing methodologies',
        'Develop incident response skills',
        'Gain digital forensics knowledge',
        'Implement security best practices',
      ],
      'requirements': [
        'Basic computer knowledge',
        'Understanding of networking concepts',
        'Windows/Linux operating system',
        'Internet connection',
      ],
      'tags': [
        'cybersecurity',
        'ethical-hacking',
        'penetration-testing',
        'network-security'
      ],
      'rating': 4.5 + (_random.nextDouble() * 0.5),
      'totalRating': 4.5 + (_random.nextDouble() * 0.5),
      'reviewsCount': 150 + _random.nextInt(200),
      'studentsCount': 1000 + _random.nextInt(5000),
      'lessonsCount': totalLessons,
      'createdAt':
          DateTime.now().subtract(Duration(days: _random.nextInt(365))),
      'updatedAt': DateTime.now(),
      'archived': false,
      'courseMcqs': _generateMCQs(10),
    };
  }

  // Generate modules with lessons
  static List<Map<String, dynamic>> _generateModules(int moduleCount) {
    final modules = <Map<String, dynamic>>[];

    for (int i = 0; i < moduleCount; i++) {
      final moduleTitle = _moduleTitles[i % _moduleTitles.length];
      final lessonCount = 3 + _random.nextInt(3); // 3-5 lessons per module
      final lessons = _generateLessons(lessonCount, i);

      modules.add({
        'id': 'module_${i + 1}',
        'title': moduleTitle,
        'description':
            'Learn ${moduleTitle.toLowerCase()} with practical examples and hands-on exercises.',
        'order': i + 1,
        'lessons': lessons,
        'duration': '${lessonCount * 10} minutes',
        'isUnlocked': i == 0, // First module unlocked by default
      });
    }

    return modules;
  }

  // Generate lessons for a module
  static List<Map<String, dynamic>> _generateLessons(
      int lessonCount, int moduleIndex) {
    final lessons = <Map<String, dynamic>>[];

    for (int i = 0; i < lessonCount; i++) {
      final lessonTitle =
          _lessonTitles[(_random.nextInt(_lessonTitles.length))];
      final videoIndex =
          (moduleIndex * lessonCount + i) % _dummyVideoUrls.length;

      lessons.add({
        'id': 'lesson_${moduleIndex + 1}_${i + 1}',
        'title': lessonTitle,
        'description':
            'In this lesson, you will learn about $lessonTitle with detailed explanations and practical examples.',
        'order': i + 1,
        'videoUrl': _dummyVideoUrls[videoIndex],
        'duration': '10:00', // 10 minutes
        'durationSeconds': 600,
        'isUnlocked':
            moduleIndex == 0 && i == 0, // First lesson of first module unlocked
        'isCompleted': false,
        'hasPreview': i == 0, // First lesson of each module has preview
        'type': 'video',
        'thumbnail': '',
        'resources': _generateResources(),
        'quiz': _generateQuiz(),
      });
    }

    return lessons;
  }

  // Generate lesson resources
  static List<Map<String, dynamic>> _generateResources() {
    return [
      {
        'id': 'resource_1',
        'title': 'Lesson Notes PDF',
        'type': 'pdf',
        'url': '',
        'size': '2.5 MB',
      },
      {
        'id': 'resource_2',
        'title': 'Practice Exercise',
        'type': 'exercise',
        'url': '',
        'size': '1.2 MB',
      },
    ];
  }

  // Generate quiz for lesson
  static Map<String, dynamic> _generateQuiz() {
    return {
      'id': 'quiz_1',
      'title': 'Lesson Quiz',
      'questions': [
        {
          'id': 'q1',
          'question': 'What is the primary goal of cybersecurity?',
          'options': [
            'To hack systems',
            'To protect information and systems',
            'To create viruses',
            'To break passwords',
          ],
          'correctAnswer': 1,
          'explanation':
              'Cybersecurity aims to protect information and systems from cyber threats.',
        },
        {
          'id': 'q2',
          'question': 'Which of the following is a common cyber attack?',
          'options': [
            'Phishing',
            'Cooking',
            'Swimming',
            'Reading',
          ],
          'correctAnswer': 0,
          'explanation':
              'Phishing is a common social engineering attack used to steal sensitive information.',
        },
      ],
      'passingScore': 70,
      'timeLimit': 300, // 5 minutes
    };
  }

  // Generate MCQs for course
  static List<Map<String, dynamic>> _generateMCQs(int count) {
    final mcqs = <Map<String, dynamic>>[];

    for (int i = 0; i < count; i++) {
      mcqs.add({
        'id': 'mcq_${i + 1}',
        'question': 'Sample question ${i + 1}?',
        'options': [
          'Option A',
          'Option B',
          'Option C',
          'Option D',
        ],
        'correctAnswer': _random.nextInt(4),
        'explanation': 'Explanation for question ${i + 1}',
        'difficulty': ['Easy', 'Medium', 'Hard'][_random.nextInt(3)],
        'category': 'General',
      });
    }

    return mcqs;
  }

  // Generate multiple dummy courses
  static List<Map<String, dynamic>> generateDummyCourses({int count = 10}) {
    final courses = <Map<String, dynamic>>[];

    for (int i = 0; i < count; i++) {
      courses.add(generateDummyCourse(
        courseId: 'dummy_course_${i + 1}',
        includeDemo: true,
        isPaid: i % 3 != 0, // Some free courses
        price: 999.0 + (i * 500.0),
      ));
    }

    return courses;
  }

  // Get dummy course by ID
  static Map<String, dynamic>? getDummyCourse(String courseId) {
    // For testing, return a specific course
    return generateDummyCourse(courseId: courseId);
  }

  // Get all dummy courses
  static List<Map<String, dynamic>> getAllDummyCourses() {
    return generateDummyCourses(count: 15);
  }
}
