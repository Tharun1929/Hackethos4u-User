import 'package:cloud_firestore/cloud_firestore.dart';

class ExpertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getExperts({int limit = 10}) async {
    try {
      // First try to get from experts collection
      Query<Map<String, dynamic>> q = _firestore.collection('experts');
      QuerySnapshot<Map<String, dynamic>> snap;
      
      try {
        q = q.where('active', isEqualTo: true);
        snap = await q.limit(limit).get();
      } catch (_) {
        snap = await _firestore.collection('experts').limit(limit).get();
      }

      if (snap.docs.isNotEmpty) {
        return snap.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'] ?? data['title'] ?? 'Expert',
            'role': data['role'] ?? data['designation'] ?? data['title'] ?? 'Expert',
            'rating': (data['rating'] is num)
                ? (data['rating'] as num).toDouble()
                : 4.5,
            'students': (data['students'] ?? data['studentCount'] ?? 0) is num
                ? (data['students'] ?? data['studentCount'] ?? 0) as int
                : 1000,
            'image': (data['image'] ?? data['avatar'] ?? data['photo'] ?? '')
                .toString(),
            'bio': data['bio'] ?? data['description'] ?? 'Experienced expert in the field',
            'specialization': data['specialization'] ?? data['expertise'] ?? 'Technology',
            'experience': data['experience'] ?? '5+ years',
          };
        }).toList();
      }

      // Fallback: try to get from instructors collection
      try {
        final instructorsSnap = await _firestore
            .collection('instructors')
            .where('isActive', isEqualTo: true)
            .limit(limit)
            .get();

        if (instructorsSnap.docs.isNotEmpty) {
          return instructorsSnap.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'name': data['name'] ?? 'Expert',
              'role': data['title'] ?? data['specialization'] ?? 'Expert',
              'rating': (data['rating'] is num)
                  ? (data['rating'] as num).toDouble()
                  : 4.5,
              'students': (data['studentsCount'] ?? data['students'] ?? 0) is num
                  ? (data['studentsCount'] ?? data['students'] ?? 0) as int
                  : 1000,
              'image': (data['avatar'] ?? data['avatarUrl'] ?? '')
                  .toString(),
              'bio': data['bio'] ?? 'Experienced instructor',
              'specialization': data['specialization'] ?? 'Technology',
              'experience': data['experience'] ?? '5+ years',
            };
          }).toList();
        }
      } catch (_) {}

      // Final fallback: return sample data
      return _getSampleExperts(limit);
    } catch (e) {
      return _getSampleExperts(limit);
    }
  }

  List<Map<String, dynamic>> _getSampleExperts(int limit) {
    final sampleExperts = [
      {
        'id': '1',
        'name': 'Dr. Sarah Johnson',
        'role': 'Cybersecurity Expert',
        'rating': 4.8,
        'students': 2500,
        'image': '',
        'bio': '10+ years in cybersecurity, former NSA analyst',
        'specialization': 'Cybersecurity',
        'experience': '10+ years',
      },
      {
        'id': '2',
        'name': 'Michael Chen',
        'role': 'Ethical Hacker',
        'rating': 4.9,
        'students': 3200,
        'image': '',
        'bio': 'Certified Ethical Hacker, penetration testing expert',
        'specialization': 'Ethical Hacking',
        'experience': '8+ years',
      },
      {
        'id': '3',
        'name': 'Alex Rodriguez',
        'role': 'Network Security Specialist',
        'rating': 4.7,
        'students': 1800,
        'image': '',
        'bio': 'Network security consultant and trainer',
        'specialization': 'Network Security',
        'experience': '6+ years',
      },
      {
        'id': '4',
        'name': 'Dr. Emily Watson',
        'role': 'Digital Forensics Expert',
        'rating': 4.9,
        'students': 2100,
        'image': '',
        'bio': 'Digital forensics specialist and incident response expert',
        'specialization': 'Digital Forensics',
        'experience': '12+ years',
      },
    ];

    return sampleExperts.take(limit).toList();
  }
}
