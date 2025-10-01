import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VerifyCertificateScreen extends StatefulWidget {
  const VerifyCertificateScreen({super.key});

  @override
  State<VerifyCertificateScreen> createState() => _VerifyCertificateScreenState();
}

class _VerifyCertificateScreenState extends State<VerifyCertificateScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _result;
  bool _isLoading = false;

  Future<void> _verify() async {
    final certNo = _controller.text.trim();
    if (certNo.isEmpty) return;
    setState(() { _isLoading = true; _result = null; });
    try {
      final qs = await _firestore
          .collection('certificates')
          .where('certificate_number', isEqualTo: certNo)
          .limit(1)
          .get();
      if (qs.docs.isEmpty) {
        setState(() { _result = {'status': 'not_found'}; _isLoading = false; });
        return;
      }
      final data = qs.docs.first.data();
      setState(() { _result = data; _isLoading = false; });
    } catch (e) {
      setState(() { _result = {'status': 'error', 'message': e.toString()}; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Certificate'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Certificate Number',
                hintText: 'H4U-COURSE-YYYYMMDD-HHMMSS-1234',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _verify(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verify,
                child: _isLoading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Verify'),
              ),
            ),
            const SizedBox(height: 16),
            if (_result != null) _buildResult(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(ThemeData theme) {
    if (_result!['status'] == 'not_found') {
      return const ListTile(
        leading: Icon(Icons.error_outline, color: Colors.red),
        title: Text('Certificate not found'),
      );
    }
    if (_result!['status'] == 'error') {
      return ListTile(
        leading: const Icon(Icons.error, color: Colors.red),
        title: Text('Error: ${''}'),
        subtitle: Text(_result!['message'] ?? ''),
      );
    }

    final status = (_result!['status'] ?? 'valid').toString();
    final isRevoked = status.toLowerCase() == 'revoked';

    final userName = _result!['userName'] ?? '-';
    final course = _result!['courseTitle'] ?? _result!['course_id'] ?? '-';
    final issueDate = _result!['issue_date'];

    String issued = '-';
    if (issueDate is Timestamp) {
      final d = issueDate.toDate();
      issued = '${d.day}/${d.month}/${d.year}';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isRevoked ? Icons.cancel : Icons.verified, color: isRevoked ? Colors.red : Colors.green),
                const SizedBox(width: 8),
                Text(isRevoked ? 'Revoked' : 'Valid', style: TextStyle(fontWeight: FontWeight.w600, color: isRevoked ? Colors.red : Colors.green)),
              ],
            ),
            const SizedBox(height: 12),
            _kv('Certificate Number', _result!['certificate_number'] ?? '-'),
            _kv('User Name', userName),
            _kv('Course', course),
            _kv('Issue Date', issued),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 160, child: Text('$k:', style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}
