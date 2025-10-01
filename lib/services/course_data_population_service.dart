import 'package:cloud_firestore/cloud_firestore.dart';

class CourseDataPopulationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Populate sample course data for testing
  static Future<void> populateSampleCourseData() async {
    try {
      // Sample course data
      final sampleCourse = {
        'title': 'Ethical Hacking',
        'subtitle': 'Complete Ethical Hacking Course',
        'description': 'Hands-on cybersecurity, reconnaissance, exploitation and reporting with real labs',
        'instructor': {
          'name': 'MANI',
          'title': 'Senior Cybersecurity Expert',
          'bio': 'Experienced cybersecurity professional with 10+ years in ethical hacking and penetration testing.',
          'rating': 4.8,
          'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
          'studentsCount': 5000,
          'coursesCount': 15,
        },
        'instructorId': 'instructor_001',
        'category': 'Cybersecurity',
        'subcategory': 'Ethical Hacking',
        'level': 'Beginner',
        'language': 'English',
        'price': 1500.0,
        'originalPrice': 1999.0,
        'monthlyPrice': 500.0,
        'currency': 'INR',
        'rating': 4.5,
        'reviewsCount': 128,
        'studentsCount': 1250,
        'duration': '30 hours',
        'durationMinutes': 1800,
        'thumbnail': 'https://images.unsplash.com/photo-1550751827-4bd374c3f58b?w=500',
        'courseImage': 'https://images.unsplash.com/photo-1550751827-4bd374c3f58b?w=800',
        'videoPreview': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
        'certificate': true,
        'lifetimeAccess': true,
        'whatYouLearn': [
          'Learn ethical hacking from scratch',
          'Understand penetration testing methodologies',
          'Master network security concepts',
          'Learn to identify vulnerabilities',
          'Practice with real-world scenarios',
          'Get hands-on experience with tools'
        ],
        'requirements': [
          'Basic computer knowledge',
          'Windows or Mac computer',
          'Internet connection',
          'No prior hacking experience needed'
        ],
        'modules': [
          {
            'id': 'module_1',
            'title': 'Ethical Hacking Foundations',
            'description': 'Introduction to ethical hacking, legal frameworks, and cybersecurity fundamentals',
            'duration': '6 hours',
            'durationMinutes': 360,
            'order': 1,
            'lessons': [
              {
                'id': 'lesson_1_1',
                'title': 'Introduction to Ethical Hacking',
                'description': 'Understanding the basics of ethical hacking and its importance',
                'type': 'video',
                'duration': '45 minutes',
                'durationMinutes': 45,
                'isFree': true,
                'order': 1,
                'videoUrl': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4'
              },
              {
                'id': 'lesson_1_2',
                'title': 'Legal and Ethical Considerations',
                'description': 'Understanding the legal framework and ethical guidelines',
                'type': 'video',
                'duration': '30 minutes',
                'durationMinutes': 30,
                'isFree': false,
                'order': 2,
                'videoUrl': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4'
              },
              {
                'id': 'lesson_1_3',
                'title': 'Hacking Methodologies',
                'description': 'Different approaches and methodologies in ethical hacking',
                'type': 'video',
                'duration': '60 minutes',
                'durationMinutes': 60,
                'isFree': false,
                'order': 3,
                'videoUrl': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4'
              },
              {
                'id': 'lesson_1_4',
                'title': 'Quiz: Foundations',
                'description': 'Test your understanding of ethical hacking foundations',
                'type': 'quiz',
                'duration': '15 minutes',
                'durationMinutes': 15,
                'isFree': false,
                'order': 4,
                'questions': 10
              }
            ]
          },
          {
            'id': 'module_2',
            'title': 'Network Security and Reconnaissance',
            'description': 'Network protocols, scanning techniques, and reconnaissance methodologies',
            'duration': '8 hours',
            'durationMinutes': 480,
            'order': 2,
            'lessons': [
              {
                'id': 'lesson_2_1',
                'title': 'Network Fundamentals',
                'description': 'Understanding network protocols and architecture',
                'type': 'video',
                'duration': '90 minutes',
                'durationMinutes': 90,
                'isFree': false,
                'order': 1,
                'videoUrl': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4'
              },
              {
                'id': 'lesson_2_2',
                'title': 'Port Scanning Techniques',
                'description': 'Learning various port scanning methods and tools',
                'type': 'video',
                'duration': '75 minutes',
                'durationMinutes': 75,
                'isFree': false,
                'order': 2,
                'videoUrl': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4'
              },
              {
                'id': 'lesson_2_3',
                'title': 'Vulnerability Assessment',
                'description': 'Identifying and assessing network vulnerabilities',
                'type': 'video',
                'duration': '120 minutes',
                'durationMinutes': 120,
                'isFree': false,
                'order': 3,
                'videoUrl': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4'
              },
              {
                'id': 'lesson_2_4',
                'title': 'Lab: Network Scanning',
                'description': 'Hands-on practice with network scanning tools',
                'type': 'lab',
                'duration': '60 minutes',
                'durationMinutes': 60,
                'isFree': false,
                'order': 4,
                'labUrl': 'https://lab.example.com/network-scanning'
              }
            ]
          },
          {
            'id': 'module_3',
            'title': 'Web Application Security',
            'description': 'Web vulnerabilities, OWASP Top 10, and secure coding practices',
            'duration': '10 hours',
            'durationMinutes': 600,
            'order': 3,
            'lessons': [
              {
                'id': 'lesson_3_1',
                'title': 'Web Application Architecture',
                'description': 'Understanding how web applications work',
                'type': 'video',
                'duration': '60 minutes',
                'durationMinutes': 60,
                'isFree': false,
                'order': 1,
                'videoUrl': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4'
              },
              {
                'id': 'lesson_3_2',
                'title': 'OWASP Top 10 Vulnerabilities',
                'description': 'Understanding the most common web vulnerabilities',
                'type': 'video',
                'duration': '120 minutes',
                'durationMinutes': 120,
                'isFree': false,
                'order': 2,
                'videoUrl': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4'
              },
              {
                'id': 'lesson_3_3',
                'title': 'SQL Injection Attacks',
                'description': 'Understanding and exploiting SQL injection vulnerabilities',
                'type': 'video',
                'duration': '90 minutes',
                'durationMinutes': 90,
                'isFree': false,
                'order': 3,
                'videoUrl': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4'
              },
              {
                'id': 'lesson_3_4',
                'title': 'XSS and CSRF Attacks',
                'description': 'Cross-site scripting and cross-site request forgery',
                'type': 'video',
                'duration': '90 minutes',
                'durationMinutes': 90,
                'isFree': false,
                'order': 4,
                'videoUrl': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4'
              }
            ]
          }
        ],
        'instructor': {
          'name': 'MANI',
          'title': 'Senior Cybersecurity Expert',
          'bio': 'Experienced cybersecurity professional with 10+ years in ethical hacking and penetration testing. Certified Ethical Hacker (CEH) and Certified Information Security Manager (CISM).',
          'rating': 4.8,
          'studentsCount': 5000,
          'coursesCount': 15,
          'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
          'specializations': ['Ethical Hacking', 'Penetration Testing', 'Network Security'],
          'experience': '10+ years',
          'certifications': ['CEH', 'CISM', 'CISSP']
        },
        'reviews': [
          {
            'id': 'review_1',
            'userId': 'user_001',
            'userName': 'John Doe',
            'rating': 5,
            'comment': 'Excellent course! Very comprehensive and well-structured.',
            'createdAt': DateTime.now().subtract(const Duration(days: 2)),
            'helpful': 12
          },
          {
            'id': 'review_2',
            'userId': 'user_002',
            'userName': 'Jane Smith',
            'rating': 4,
            'comment': 'Great content, learned a lot about ethical hacking.',
            'createdAt': DateTime.now().subtract(const Duration(days: 2)),
            'helpful': 8
          },
          {
            'id': 'review_3',
            'userId': 'user_003',
            'userName': 'Mike Johnson',
            'rating': 5,
            'comment': 'The instructor is very knowledgeable and explains concepts clearly.',
            'createdAt': DateTime.now().subtract(const Duration(days: 2)),
            'helpful': 15
          }
        ],
        'faqs': [
          {
            'id': 'faq_1',
            'question': 'Do I need any prior experience in hacking?',
            'answer': 'No prior experience is required. This course starts from the basics and gradually builds up your knowledge.',
            'category': 'General'
          },
          {
            'id': 'faq_2',
            'question': 'What tools will I learn to use?',
            'answer': 'You will learn to use various tools including Nmap, Wireshark, Metasploit, Burp Suite, and many others.',
            'category': 'Tools'
          },
          {
            'id': 'faq_3',
            'question': 'Is this course suitable for beginners?',
            'answer': 'Yes, this course is designed for beginners and covers all the fundamentals before moving to advanced topics.',
            'category': 'Level'
          }
        ],
        'published': true,
        'featured': true,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      };

      // Add course to Firestore
      await _firestore.collection('courses').doc('ethical_hacking_course').set(sampleCourse);

      // Add instructor data
      await _firestore.collection('instructors').doc('instructor_001').set(sampleCourse['instructor'] as Map<String, dynamic>);

      // Add reviews to course subcollection
      for (final review in sampleCourse['reviews'] as List<dynamic>) {
        await _firestore
            .collection('courses')
            .doc('ethical_hacking_course')
            .collection('reviews')
            .add(review);
      }

      // Add FAQs to course subcollection
      for (final faq in sampleCourse['faqs'] as List<dynamic>) {
        await _firestore
            .collection('courses')
            .doc('ethical_hacking_course')
            .collection('faqs')
            .add(faq);
      }

      print('Sample course data populated successfully!');
    } catch (e) {
      print('Error populating sample course data: $e');
    }
  }

  /// Check if sample data exists
  static Future<bool> hasSampleData() async {
    try {
      final doc = await _firestore.collection('courses').doc('ethical_hacking_course').get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Populate sample data if it doesn't exist
  static Future<void> ensureSampleData() async {
    final hasData = await hasSampleData();
    if (!hasData) {
      await populateSampleCourseData();
    }
  }
}
