import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/certificate_service.dart';
import '../../utils/app_theme.dart';

class CertificateDisplayScreen extends StatefulWidget {
  const CertificateDisplayScreen({super.key});

  @override
  State<CertificateDisplayScreen> createState() =>
      _CertificateDisplayScreenState();
}

class _CertificateDisplayScreenState extends State<CertificateDisplayScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _certificates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCertificates();
  }

  Future<void> _loadCertificates() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final certificates = await _getUserCertificates(user.uid);
        setState(() {
          _certificates = certificates;
          _isLoading = false;
        });
      }
    } catch (e) {
      // print('Error loading certificates: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Certificates'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _certificates.isEmpty
              ? _buildEmptyState()
              : _buildCertificatesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            'No Certificates Yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'Complete courses to earn certificates!',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.explore),
            label: const Text('Explore Courses'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificatesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _certificates.length,
      itemBuilder: (context, index) {
        final certificate = _certificates[index];
        return _buildCertificateCard(certificate);
      },
    );
  }

  Widget _buildCertificateCard(Map<String, dynamic> certificate) {
    final courseName = certificate['courseName'] ?? 'Unknown Course';
    final certificateId = certificate['certificateId'] ?? 'N/A';
    final dynamic rawIssue = certificate['issueDate'];
    final DateTime issueDate = rawIssue is Timestamp
        ? rawIssue.toDate()
        : (rawIssue is DateTime ? rawIssue : DateTime.now());
    final imageUrl = certificate['certificateImageUrl'];
    final pdfUrl = certificate['certificatePdfUrl'];
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.cardColor,
            theme.cardColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showCertificateDetails(certificate),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Certificate preview with overlay
            if (imageUrl != null) ...[
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.0),
                      Colors.black.withOpacity(0.3),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 200,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: theme.dividerColor.withOpacity(0.2),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.verified,
                                    color: theme.colorScheme.primary,
                                    size: 50,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Certificate Preview',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Overlay with certificate info
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.8),
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.verified,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    courseName,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Certificate ID: $certificateId',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 20,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // No image - show placeholder
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.verified,
                          color: theme.colorScheme.primary,
                          size: 50,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        courseName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Certificate ID: $certificateId',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Content section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Issue date
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Issued Date',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          Text(
                            _formatDate(issueDate),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.share,
                          label: 'Share',
                          onPressed: () => _shareCertificate(certificate),
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (pdfUrl != null && (pdfUrl as String).isNotEmpty) ...[
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.picture_as_pdf,
                            label: 'View PDF',
                            onPressed: () => _openPdf(pdfUrl),
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.download,
                          label: 'Download',
                          onPressed: () => _downloadCertificate(certificate),
                          color: Colors.green,
                        ),
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
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCertificateDetails(Map<String, dynamic> certificate) {
    showDialog(
      context: context,
      builder: (context) => CertificateDetailsDialog(certificate: certificate),
    );
  }

  void _shareCertificate(Map<String, dynamic> certificate) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildShareOptions(certificate),
    );
  }

  Widget _buildShareOptions(Map<String, dynamic> certificate) {
    final courseName = certificate['courseName'] ?? 'Course';
    final certificateId = certificate['certificateId'] ?? 'N/A';
    final imageUrl = certificate['certificateImageUrl'];

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Share Certificate',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildShareOption(
                icon: Icons.share,
                label: 'General',
                onTap: () {
                  Navigator.pop(context);
                  Share.share(
                    'I just completed "$courseName" and earned a certificate from HACKETHOS4U!\n\nCertificate ID: $certificateId\n\n#HACKETHOS4U #Learning #Certification',
                  );
                },
              ),
              _buildShareOption(
                icon: Icons.work,
                label: 'LinkedIn',
                onTap: () {
                  Navigator.pop(context);
                  _shareToLinkedIn(certificate);
                },
              ),
              _buildShareOption(
                icon: Icons.image,
                label: 'Image',
                onTap: () {
                  Navigator.pop(context);
                  if (imageUrl != null) {
                    Share.shareXFiles([XFile(imageUrl)],
                        text: 'Check out my certificate!');
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  void _shareToLinkedIn(Map<String, dynamic> certificate) {
    final courseName = certificate['courseName'] ?? 'Course';
    final certificateId = certificate['certificateId'] ?? 'N/A';

    final linkedInText =
        'I just completed "$courseName" and earned a certificate from HACKETHOS4U! '
        'Certificate ID: $certificateId #HACKETHOS4U #Learning #Certification #Cybersecurity';

    final encodedText = Uri.encodeComponent(linkedInText);
    final linkedInUrl =
        'https://www.linkedin.com/sharing/share-offsite/?url=${Uri.encodeComponent('https://hackethos4u.com')}&summary=$encodedText';

    _launchUrl(Uri.parse(linkedInUrl));
  }

  void _downloadCertificate(Map<String, dynamic> certificate) {
    final imageUrl = certificate['certificateImageUrl'];
    if (imageUrl != null) {
      _launchUrl(Uri.parse(imageUrl));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Certificate image not available'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _openPdf(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      _launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid PDF URL'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _launchUrl(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open certificate'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<List<Map<String, dynamic>>> _getUserCertificates(String userId) async {
    try {
      // Import the certificate service
      final certificateService = CertificateService();
      final certificates = await certificateService.getUserCertificates();

      // Transform the data to match the expected format
      return certificates
          .map((cert) => {
                'certificateId': cert['certificateId'] ?? 'N/A',
                'courseName': cert['courseTitle'] ?? 'Unknown Course',
                'issueDate': cert['issuedAt'] ?? cert['completionDate'],
                'certificateImageUrl': cert['certificateUrl'],
                'certificatePdfUrl': cert['certificateUrl'],
                'userName': cert['userName'] ?? 'Student',
                'finalScore': cert['finalScore'] ?? 0.0,
                'isValid': cert['isValid'] ?? true,
              })
          .toList();
    } catch (e) {
      print('Error getting certificates: $e');
      return [];
    }
  }
}

class CertificateDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> certificate;

  const CertificateDetailsDialog({
    super.key,
    required this.certificate,
  });

  @override
  Widget build(BuildContext context) {
    final courseName = certificate['courseName'] ?? 'Unknown Course';
    final certificateId = certificate['certificateId'] ?? 'N/A';
    final userName = certificate['userName'] ?? 'Student';
    final issueDate = certificate['issueDate']?.toDate() ?? DateTime.now();
    final imageUrl = certificate['certificateImageUrl'];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Certificate Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'ID: $certificateId',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Certificate image
                    if (imageUrl != null) ...[
                      Container(
                        height: 300,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.fill,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[100],
                                child: const Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey,
                                    size: 40,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Details
                    _buildDetailRow('Course', courseName),
                    _buildDetailRow('Student', userName),
                    _buildDetailRow('Issued Date', _formatDate(issueDate)),
                    _buildDetailRow('Issued By', 'HACKETHOS4U'),
                    _buildDetailRow('Director', 'MANITEJA THAGARAM'),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _shareCertificate(context),
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _shareToLinkedIn(context),
                      icon: const Icon(Icons.work),
                      label: const Text('LinkedIn'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: BorderSide(color: AppTheme.primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _downloadCertificate(context),
                      icon: const Icon(Icons.download),
                      label: const Text('Download'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _shareCertificate(BuildContext context) {
    final courseName = certificate['courseName'] ?? 'Course';
    final certificateId = certificate['certificateId'] ?? 'N/A';

    Share.share(
      'I just completed "$courseName" and earned a certificate from HACKETHOS4U!\n\nCertificate ID: $certificateId\n\n#HACKETHOS4U #Learning #Certification',
    );
  }

  void _shareToLinkedIn(BuildContext context) {
    final courseName = certificate['courseName'] ?? 'Course';
    final certificateId = certificate['certificateId'] ?? 'N/A';

    final linkedInText =
        'I just completed "$courseName" and earned a certificate from HACKETHOS4U! '
        'Certificate ID: $certificateId #HACKETHOS4U #Learning #Certification #Cybersecurity';

    final encodedText = Uri.encodeComponent(linkedInText);
    final linkedInUrl =
        'https://www.linkedin.com/sharing/share-offsite/?url=${Uri.encodeComponent('https://hackethos4u.com')}&summary=$encodedText';

    _launchUrl(context, Uri.parse(linkedInUrl));
  }

  Future<void> _launchUrl(BuildContext context, Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open LinkedIn'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _downloadCertificate(BuildContext context) {
    final imageUrl = certificate['certificateImageUrl'];
    if (imageUrl != null) {
      // Launch URL to download
      _launchUrl(context, Uri.parse(imageUrl));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Certificate image not available'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<List<Map<String, dynamic>>> _getUserCertificates(String userId) async {
    try {
      // Import the certificate service
      final certificateService = CertificateService();
      final certificates = await certificateService.getUserCertificates();

      // Transform the data to match the expected format
      return certificates
          .map((cert) => {
                'certificateId': cert['certificateId'] ?? 'N/A',
                'courseName': cert['courseTitle'] ?? 'Unknown Course',
                'issueDate': cert['issuedAt'] ?? cert['completionDate'],
                'certificateImageUrl': cert['certificateUrl'],
                'certificatePdfUrl': cert['certificateUrl'],
                'userName': cert['userName'] ?? 'Student',
                'finalScore': cert['finalScore'] ?? 0.0,
                'isValid': cert['isValid'] ?? true,
              })
          .toList();
    } catch (e) {
      print('Error getting certificates: $e');
      return [];
    }
  }
}
