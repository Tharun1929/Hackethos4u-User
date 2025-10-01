import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../model/ad_model.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all active ads (tolerant to schema variations)
  Future<List<AdModel>> getActiveAds() async {
    try {
      // Try preferred schema first
      Query query = _firestore.collection('ads');
      try {
        query = query.where('isActive', isEqualTo: true);
      } catch (_) {}
      QuerySnapshot snap;
      try {
        snap = await query.orderBy('createdAt', descending: true).get();
      } catch (_) {
        snap = await query.get();
      }

      final ads = snap.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            // Normalize alternate field names
            data['id'] = doc.id;
            data['title'] = data['title'] ?? data['name'] ?? '';
            data['thumbnail'] =
                data['thumbnail'] ?? data['image'] ?? data['banner'] ?? '';
            data['link'] = data['link'] ?? data['url'] ?? '';
            data['type'] = data['type'] ?? data['category'] ?? 'website';
            data['isActive'] = data['isActive'] ?? data['active'] ?? true;
            return AdModel.fromMap(data);
          })
          .where((a) => a.thumbnail.isNotEmpty && a.link.isNotEmpty)
          .toList();

      return ads;
    } catch (e) {
      return [];
    }
  }

  /// Get ads by type
  Future<List<AdModel>> getAdsByType(String type) async {
    try {
      final snapshot = await _firestore
          .collection('ads')
          .where('isActive', isEqualTo: true)
          .where('type', isEqualTo: type)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AdModel.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Record ad view
  Future<void> recordAdView(String adId) async {
    try {
      await _firestore.collection('ads').doc(adId).update({
        'viewCount': FieldValue.increment(1),
        'lastViewedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {}
  }

  /// Record ad click
  Future<void> recordAdClick(String adId) async {
    try {
      await _firestore.collection('ads').doc(adId).update({
        'clickCount': FieldValue.increment(1),
        'lastClickedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {}
  }

  /// Open ad link
  Future<void> openAdLink(AdModel ad) async {
    try {
      await recordAdClick(ad.id);
      final Uri url = Uri.parse(ad.link);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {}
  }

  /// Create a new ad (admin only)
  Future<String?> createAd({
    required String title,
    required String thumbnail,
    required String link,
    required String type,
    DateTime? expiresAt,
  }) async {
    try {
      final adData = {
        'title': title,
        'thumbnail': thumbnail,
        'link': link,
        'type': type,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': expiresAt,
        'clickCount': 0,
        'viewCount': 0,
      };

      final docRef = await _firestore.collection('ads').add(adData);
      return docRef.id;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateAd(String adId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('ads').doc(adId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAd(String adId) async {
    try {
      await _firestore.collection('ads').doc(adId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getAdAnalytics(String adId) async {
    try {
      final doc = await _firestore.collection('ads').doc(adId).get();
      if (doc.exists) {
        final data = doc.data()!;
        return {
          'clickCount': data['clickCount'] ?? 0,
          'viewCount': data['viewCount'] ?? 0,
          'clickRate': data['viewCount'] > 0
              ? (data['clickCount'] ?? 0) / (data['viewCount'] ?? 1)
              : 0.0,
          'lastViewedAt': data['lastViewedAt'],
          'lastClickedAt': data['lastClickedAt'],
        };
      }
      return {};
    } catch (e) {
      return {};
    }
  }
}
