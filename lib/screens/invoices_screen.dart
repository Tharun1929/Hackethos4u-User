import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../services/invoice_service.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _invoices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Load both payments and invoices
      final paymentsSnapshot = await _firestore
          .collection('payments')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      final invoicesSnapshot = await _firestore
          .collection('invoices')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      // Combine and deduplicate data
      final Map<String, Map<String, dynamic>> combinedData = {};

      // Add payments data
      for (var doc in paymentsSnapshot.docs) {
        final data = doc.data();
        combinedData[doc.id] = {
          ...data,
          'id': doc.id,
          'type': 'payment',
          // normalize types
          'amount': (data['amount'] is num)
              ? (data['amount'] as num).toDouble()
              : _parseAmount(data['amount']),
          'createdAt': data['createdAt'],
          'status': data['status'] ?? 'success',
        };
      }

      // Add invoices data (prefer invoice data if available)
      for (var doc in invoicesSnapshot.docs) {
        final data = doc.data();
        final paymentId = data['courseId'] != null
            ? '${user.uid}_${data['courseId']}'
            : doc.id;
        combinedData[paymentId] = {
          ...data,
          'id': doc.id,
          'type': 'invoice',
          'amount': (data['amount'] is num)
              ? (data['amount'] as num).toDouble()
              : _parseAmount(data['amount']),
          'createdAt': data['createdAt'],
          'status': data['status'] ?? 'success',
        };
      }

      setState(() {
        _invoices = combinedData.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      // print('Error loading invoices: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  double _parseAmount(dynamic value) {
    try {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      final s = value.toString().replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(s) ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  Future<void> _downloadInvoice(String invoiceId) async {
    try {
      final invoice = _invoices.firstWhere((inv) => inv['id'] == invoiceId);
      final invoiceUrl = invoice['invoiceUrl'];

      if (invoiceUrl != null && invoiceUrl.isNotEmpty) {
        // Open invoice PDF in browser
        final uri = Uri.parse(invoiceUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('Could not open invoice URL');
        }
      } else {
        // Generate new invoice if URL not available
        final invoiceService = InvoiceService();
        final newInvoiceUrl = await invoiceService.generateInvoice(
          courseId: invoice['courseId'] ?? '',
          courseTitle: invoice['courseTitle'] ?? 'Course',
          amount: _parseAmount(invoice['amount']),
          paymentMethod: invoice['paymentMethod'] ?? 'UPI',
          transactionId: invoice['transactionId'] ?? invoiceId,
          discount: _parseAmount(invoice['discount']),
          couponCode: invoice['couponCode'],
        );

        if (newInvoiceUrl != null) {
          // Persist URL to Firestore for future loads
          try {
            final user = _auth.currentUser;
            if (user != null) {
              await _firestore
                  .collection('invoices')
                  .doc(invoice['id'] ?? invoiceId)
                  .set({
                'id': invoice['id'] ?? invoiceId,
                'userId': user.uid,
                'courseId': invoice['courseId'] ?? '',
                'courseTitle': invoice['courseTitle'] ?? 'Course',
                'amount': _parseAmount(invoice['amount']),
                'paymentMethod': invoice['paymentMethod'] ?? 'UPI',
                'transactionId': invoice['transactionId'] ?? invoiceId,
                'invoiceUrl': newInvoiceUrl,
                'status': invoice['status'] ?? 'success',
                'createdAt':
                    invoice['createdAt'] ?? FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
            }
          } catch (_) {}
          final uri = Uri.parse(newInvoiceUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invoice opened successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening invoice: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(dynamic dt) {
    try {
      DateTime d;
      if (dt is Timestamp) {
        d = dt.toDate();
      } else if (dt is DateTime) {
        d = dt;
      } else {
        return '';
      }
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return '';
    }
  }

  Future<void> _shareInvoice(Map<String, dynamic> invoice) async {
    try {
      final courseTitle = invoice['courseTitle'] ?? 'Course';
      final amount = invoice['amount'] ?? 0.0;
      final invoiceNumber = invoice['invoiceNumber'] ?? invoice['id'];

      final shareText = '''
📄 HACKETHOS4U Invoice

Course: $courseTitle
Amount: ₹${amount.toStringAsFixed(2)}
Invoice #: $invoiceNumber

Thank you for choosing HACKETHOS4U for your cybersecurity education!

#HACKETHOS4U #Cybersecurity #Learning
      ''';

      await Share.share(shareText);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing invoice: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'success':
        return 'Paid';
      case 'failed':
        return 'Failed';
      case 'pending':
        return 'Pending';
      case 'refunded':
        return 'Refunded';
      default:
        return 'Unknown';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'success':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'refunded':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('My Invoices'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon:
              Icon(Icons.arrow_back, color: theme.appBarTheme.foregroundColor),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _invoices.isEmpty
              ? _buildEmptyState(theme)
              : _buildInvoicesList(theme),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 80,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No Invoices Yet',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your payment history will appear here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicesList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _invoices.length,
      itemBuilder: (context, index) {
        final invoice = _invoices[index];
        return _buildInvoiceCard(theme, invoice);
      },
    );
  }

  Widget _buildInvoiceCard(ThemeData theme, Map<String, dynamic> invoice) {
    final status = invoice['status'] ?? 'unknown';
    final amount = invoice['amount'] ?? 0.0;
    final courseTitle = invoice['courseTitle'] ?? 'Unknown Course';
    final createdAt = invoice['createdAt']?.toDate() ?? DateTime.now();
    final invoiceId = invoice['id'] ?? 'N/A';
    final discount = invoice['discount'] ?? 0.0;
    final originalAmount = amount + discount;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _downloadInvoice(invoiceId),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getStatusColor(status).withOpacity(0.1),
                    _getStatusColor(status).withOpacity(0.05),
                  ],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getStatusIcon(status),
                      color: _getStatusColor(status),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Invoice #$invoiceId',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(status),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          courseTitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.8),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusText(status),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.dividerColor.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Amount',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.7),
                              ),
                            ),
                            Text(
                              '₹${amount.toStringAsFixed(2)}',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        if (discount > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Original Price',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              Text(
                                '₹${originalAmount.toStringAsFixed(2)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Discount',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '-₹${discount.toStringAsFixed(2)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Date and payment method
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          theme,
                          Icons.calendar_today,
                          'Date',
                          _formatDate(createdAt),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoItem(
                          theme,
                          Icons.payment,
                          'Method',
                          'Razorpay',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          theme,
                          icon: Icons.download,
                          label: 'Download PDF',
                          onPressed: () => _downloadInvoice(invoiceId),
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          theme,
                          icon: Icons.share,
                          label: 'Share',
                          onPressed: () => _shareInvoice(invoice),
                          color: Colors.blue,
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

  Widget _buildInfoItem(
      ThemeData theme, IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    ThemeData theme, {
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'success':
        return Icons.check_circle;
      case 'failed':
        return Icons.cancel;
      case 'pending':
        return Icons.schedule;
      case 'refunded':
        return Icons.refresh;
      default:
        return Icons.help;
    }
  }

  void _viewInvoiceDetails(Map<String, dynamic> invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invoice Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Invoice ID', invoice['id'] ?? 'N/A'),
              _buildDetailRow('Course', invoice['courseTitle'] ?? 'N/A'),
              _buildDetailRow('Amount',
                  '₹${(invoice['amount'] ?? 0.0).toStringAsFixed(2)}'),
              _buildDetailRow(
                  'Status', _getStatusText(invoice['status'] ?? 'unknown')),
              _buildDetailRow(
                  'Payment Method', invoice['paymentMethod'] ?? 'N/A'),
              _buildDetailRow(
                  'Transaction ID', invoice['transactionId'] ?? 'N/A'),
              _buildDetailRow(
                  'Date', invoice['createdAt']?.toDate().toString() ?? 'N/A'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              _shareInvoice(invoice);
            },
            child: const Text('Share'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadInvoice(invoice['id']);
            },
            child: const Text('View PDF'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
