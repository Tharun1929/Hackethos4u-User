import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
// Cloudinary removed – using Firebase Storage
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class InvoiceService {
  static final InvoiceService _instance = InvoiceService._internal();
  factory InvoiceService() => _instance;
  InvoiceService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ===== INVOICE GENERATION =====

  /// Generate invoice for payment
  Future<String?> generateInvoice({
    required String courseId,
    required String courseTitle,
    required double amount,
    required String paymentMethod,
    required String transactionId,
    double? discount = 0.0,
    String? couponCode,
    String? userEmail,
    String? userName,
    String? userAddress,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get user details if not provided
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};
      
      final finalUserEmail = userEmail ?? user.email ?? userData['email'] ?? 'N/A';
      final finalUserName = userName ?? user.displayName ?? userData['fullName'] ?? 'N/A';
      final finalUserAddress = userAddress ?? userData['address'] ?? 'N/A';

      // Generate unique invoice ID
      final invoiceId = _generateInvoiceId();

      // Generate invoice data
      final invoiceData = _createInvoiceData(
        invoiceId: invoiceId,
        courseId: courseId,
        courseTitle: courseTitle,
        amount: amount,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
        discount: discount,
        couponCode: couponCode,
        userEmail: finalUserEmail,
        userName: finalUserName,
        userAddress: finalUserAddress,
      );

      // Generate invoice PDF
      final pdfBytes = await _generateInvoicePDF(invoiceData);

      // Upload to Firebase Storage
      final invoiceUrl = await _uploadInvoiceToStorage(
        courseId: courseId,
        userId: user.uid,
        pdfBytes: pdfBytes,
      );

      // Save invoice record to Firestore
      await _saveInvoiceRecord(
        courseId: courseId,
        courseTitle: courseTitle,
        invoiceUrl: invoiceUrl,
        invoiceData: invoiceData,
      );

      return invoiceUrl;
    } catch (e) {
      // print('Error generating invoice: $e');
      return null;
    }
  }

  /// Generate unique invoice ID
  String _generateInvoiceId() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-$random';
  }

  /// Create invoice data
  Map<String, dynamic> _createInvoiceData({
    required String invoiceId,
    required String courseId,
    required String courseTitle,
    required double amount,
    required String paymentMethod,
    required String transactionId,
    double? discount,
    String? couponCode,
    required String userEmail,
    required String userName,
    required String userAddress,
  }) {
    final now = DateTime.now();
    final taxRate = 0.18; // 18% GST
    final subtotal = amount;
    final discountAmount = discount ?? 0.0;
    final taxableAmount = subtotal - discountAmount;
    final taxAmount = taxableAmount * taxRate;
    final grandTotal = taxableAmount + taxAmount;

    return {
      'invoice_id': invoiceId,
      'invoice_date': now,
      'due_date': now,
      'user_id': _auth.currentUser?.uid,
      'billing_details': {
        'name': userName,
        'email': userEmail,
        'address': userAddress,
      },
      'items': [
        {
          'name': courseTitle,
          'description': 'Online Course Access',
          'qty': 1,
          'unit_price': amount,
          'total': amount,
        }
      ],
      'subtotal': subtotal,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'discount': discountAmount,
      'grand_total': grandTotal,
      'payment_method': paymentMethod,
      'transaction_id': transactionId,
      'status': 'paid',
      'coupon_code': couponCode,
    };
  }

  /// Generate invoice PDF
  Future<Uint8List> _generateInvoicePDF(
      Map<String, dynamic> invoiceData) async {
    final pdf = pw.Document();

    // Add invoice page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(width: 1, color: PdfColors.grey),
            ),
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(30),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildInvoiceHeader(invoiceData),

                  pw.SizedBox(height: 30),

                  // Customer and Company Info
                  _buildCustomerCompanyInfo(invoiceData),

                  pw.SizedBox(height: 30),

                  // Invoice Details
                  _buildInvoiceDetails(invoiceData),

                  pw.SizedBox(height: 30),

                  // Course Details
                  _buildCourseDetails(invoiceData),

                  pw.SizedBox(height: 30),

                  // Payment Summary
                  _buildPaymentSummary(invoiceData),

                  pw.SizedBox(height: 30),

                  // Terms and Conditions
                  _buildTermsAndConditions(),

                  pw.SizedBox(height: 20),

                  // Footer
                  _buildInvoiceFooter(invoiceData),
                ],
              ),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Build invoice header
  pw.Widget _buildInvoiceHeader(Map<String, dynamic> invoiceData) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'HACKETHOS4U',
              style: pw.TextStyle(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Cybersecurity & Ethical Hacking Education',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.normal,
                color: PdfColors.blue,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Hyderabad, Telangana, India',
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
            ),
            pw.Text(
              'Phone: +91 98765 43210 | Email: info@hackethos4u.com',
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
            ),
            pw.Text(
              'GST: 36AABCH1234A1Z5',
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'INVOICE',
              style: pw.TextStyle(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Invoice #: ${invoiceData['invoice_id']}',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Date: ${_formatDate(invoiceData['invoice_date'])}',
              style: pw.TextStyle(fontSize: 12),
            ),
            pw.Text(
              'Status: ${invoiceData['status'].toString().toUpperCase()}',
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColors.green,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build customer and company info
  pw.Widget _buildCustomerCompanyInfo(Map<String, dynamic> invoiceData) {
    final billingDetails = invoiceData['billing_details'] as Map<String, dynamic>? ?? {};
    
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Bill To:',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                billingDetails['name'] ?? 'N/A',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                billingDetails['email'] ?? 'N/A',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.Text(
                billingDetails['address'] ?? 'N/A',
                style: pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Payment Method:',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                invoiceData['payment_method'] ?? 'N/A',
                style: pw.TextStyle(fontSize: 14),
              ),
              pw.Text(
                'Transaction ID: ${invoiceData['transaction_id'] ?? 'N/A'}',
                style: pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build invoice details
  pw.Widget _buildInvoiceDetails(Map<String, dynamic> invoiceData) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey300,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Invoice Details',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 15),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Invoice Number:', style: pw.TextStyle(fontSize: 14)),
              pw.Text(invoiceData['invoiceNumber'],
                  style: pw.TextStyle(fontSize: 14)),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Invoice Date:', style: pw.TextStyle(fontSize: 14)),
              pw.Text(_formatDate(invoiceData['invoiceDate']),
                  style: pw.TextStyle(fontSize: 14)),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Due Date:', style: pw.TextStyle(fontSize: 14)),
              pw.Text(_formatDate(invoiceData['dueDate']),
                  style: pw.TextStyle(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  /// Build course details
  pw.Widget _buildCourseDetails(Map<String, dynamic> invoiceData) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Course Details',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 15),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Course ID:', style: pw.TextStyle(fontSize: 14)),
              pw.Text(invoiceData['courseId'],
                  style: pw.TextStyle(fontSize: 14)),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Course Title:', style: pw.TextStyle(fontSize: 14)),
              pw.Text(invoiceData['courseTitle'],
                  style: pw.TextStyle(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  /// Build payment summary
  pw.Widget _buildPaymentSummary(Map<String, dynamic> invoiceData) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue100,
        border: pw.Border.all(color: PdfColors.blue300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Payment Summary',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 15),
          _buildPaymentRow(
              'Course Amount', '₹${invoiceData['amount'].toStringAsFixed(2)}'),
          if (invoiceData['discount'] > 0)
            _buildPaymentRow(
                'Discount', '-₹${invoiceData['discount'].toStringAsFixed(2)}',
                isDiscount: true),
          if (invoiceData['couponCode'] != null)
            _buildPaymentRow('Coupon Applied', invoiceData['couponCode']),
          _buildPaymentRow('GST (${(invoiceData['taxRate'] * 100).toInt()}%)',
              '₹${invoiceData['taxAmount'].toStringAsFixed(2)}'),
          pw.Divider(color: PdfColors.blue300),
          _buildPaymentRow('Total Amount',
              '₹${invoiceData['totalAmount'].toStringAsFixed(2)}',
              isTotal: true),
        ],
      ),
    );
  }

  /// Build payment row
  pw.Widget _buildPaymentRow(String label, String value,
      {bool isDiscount = false, bool isTotal = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isDiscount ? PdfColors.red : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  /// Build terms and conditions
  pw.Widget _buildTermsAndConditions() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Terms and Conditions',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            '• Payment is due upon receipt of this invoice',
            style: pw.TextStyle(fontSize: 12),
          ),
          pw.Text(
            '• Course access will be granted after payment confirmation',
            style: pw.TextStyle(fontSize: 12),
          ),
          pw.Text(
            '• Refunds are subject to our refund policy',
            style: pw.TextStyle(fontSize: 12),
          ),
          pw.Text(
            '• For any queries, contact support@edutiv.com',
            style: pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// Build invoice footer
  pw.Widget _buildInvoiceFooter(Map<String, dynamic> invoiceData) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey300,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        children: [
          pw.Column(
            children: [
              pw.Container(
                width: 100,
                height: 1,
                color: PdfColors.black,
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Student Signature',
                style: pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
          pw.Column(
            children: [
              pw.Container(
                width: 100,
                height: 1,
                color: PdfColors.black,
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Platform Director',
                style: pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Upload invoice to Firebase Storage
  Future<String> _uploadInvoiceToStorage({
    required String courseId,
    required String userId,
    required Uint8List pdfBytes,
  }) async {
    try {
      final fileName = 'invoice_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final ref = _storage.ref().child('invoices/$userId/$courseId/$fileName');
      final metadata = SettableMetadata(contentType: 'application/pdf');
      final task = await ref.putData(pdfBytes, metadata);
      final downloadUrl = await task.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      // print('Error uploading invoice: $e');
      rethrow;
    }
  }

  /// Save invoice record to Firestore
  Future<void> _saveInvoiceRecord({
    required String courseId,
    required String courseTitle,
    required String invoiceUrl,
    required Map<String, dynamic> invoiceData,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final invoiceRecord = {
        'userId': user.uid,
        'courseId': courseId,
        'courseTitle': courseTitle,
        'invoiceUrl': invoiceUrl,
        'invoiceNumber': invoiceData['invoiceNumber'],
        'amount': invoiceData['amount'],
        'totalAmount': invoiceData['totalAmount'],
        'paymentMethod': invoiceData['paymentMethod'],
        'transactionId': invoiceData['transactionId'],
        'status': invoiceData['status'],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('invoices')
          .doc('${user.uid}_$courseId')
          .set(invoiceRecord);

      // Update user's invoice count
      await _firestore.collection('users').doc(user.uid).update({
        'stats.invoicesGenerated': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // print('Error saving invoice record: $e');
      rethrow;
    }
  }

  // ===== INVOICE RETRIEVAL =====

  /// Get user's invoices
  Future<List<Map<String, dynamic>>> getUserInvoices() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final querySnapshot = await _firestore
          .collection('invoices')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          ...data,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      // print('Error getting user invoices: $e');
      return [];
    }
  }

  /// Get invoice by ID
  Future<Map<String, dynamic>?> getInvoiceById(String invoiceId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('invoices').doc(invoiceId).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          ...data,
          'id': doc.id,
        };
      }
      return null;
    } catch (e) {
      // print('Error getting invoice by ID: $e');
      return null;
    }
  }

  // ===== INVOICE DOWNLOAD =====

  /// Download invoice to local storage
  Future<String?> downloadInvoice(String invoiceUrl) async {
    try {
      final response = await http.get(Uri.parse(invoiceUrl));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'invoice_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = File('${directory.path}/$fileName');

        await file.writeAsBytes(bytes);
        return file.path;
      } else {
        throw Exception('Failed to download invoice: ${response.statusCode}');
      }
    } catch (e) {
      // print('Error downloading invoice: $e');
      return null;
    }
  }

  // ===== INVOICE STATISTICS =====

  /// Get invoice statistics
  Future<Map<String, dynamic>> getInvoiceStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final querySnapshot = await _firestore
          .collection('invoices')
          .where('userId', isEqualTo: user.uid)
          .get();

      final invoices = querySnapshot.docs;
      final totalInvoices = invoices.length;
      final totalAmount = invoices.fold<double>(0.0, (sum, doc) {
        final data = doc.data();
        return sum + (data['totalAmount'] ?? 0.0);
      });

      final thisYear = DateTime.now().year;
      final thisYearInvoices = invoices.where((doc) {
        final data = doc.data();
        final createdAt = data['createdAt'] as Timestamp?;
        if (createdAt == null) return false;
        return createdAt.toDate().year == thisYear;
      }).length;

      return {
        'totalInvoices': totalInvoices,
        'totalAmount': totalAmount,
        'thisYearInvoices': thisYearInvoices,
        'averageAmount': totalInvoices > 0 ? totalAmount / totalInvoices : 0.0,
      };
    } catch (e) {
      // print('Error getting invoice stats: $e');
      return {};
    }
  }
}
