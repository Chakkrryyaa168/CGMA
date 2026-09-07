import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../models/invoice_model.dart';
import '../../models/repair_job_model.dart';

class InvoicePdfPreviewScreen extends StatefulWidget {
  final InvoiceModel invoice;
  final RepairJobModel? repairJob;

  const InvoicePdfPreviewScreen({
    super.key,
    required this.invoice,
    this.repairJob,
  });

  @override
  State<InvoicePdfPreviewScreen> createState() => _InvoicePdfPreviewScreenState();
}

class _InvoicePdfPreviewScreenState extends State<InvoicePdfPreviewScreen> {
  final ApiClient _apiClient = ApiClient();

  Future<Uint8List> _fetchOrGeneratePdf(PdfPageFormat format) async {
    try {
      // 1. Try fetching live ReportLab PDF stream from backend API
      final response = await _apiClient.dio.get(
        '${ApiConstants.invoices}${widget.invoice.id}/pdf/',
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200 && response.data != null) {
        return Uint8List.fromList(response.data);
      }
    } catch (_) {
      // Fallback: Generate PDF locally on client if offline/network error
    }

    return _generateClientPdf(format);
  }

  Future<Uint8List> _generateClientPdf(PdfPageFormat format) async {
    final pdf = pw.Document();

    final inv = widget.invoice;
    final rJob = widget.repairJob;
    final vehicle = rJob?.vehicle;
    final customer = vehicle?.customer;
    final user = customer?.user;

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Banner
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'CAR GARAGE MANAGEMENT SYSTEM',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.Text(
                        '123 Service Auto Way • Phone: +1-800-GARAGE',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'INVOICE #${inv.id}',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text('Date: ${inv.createdAt ?? 'Today'}', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.Divider(thickness: 1.5, color: PdfColors.blue900),
              pw.SizedBox(height: 12),

              // Customer & Vehicle Grid
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('CUSTOMER DETAILS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                          pw.SizedBox(height: 4),
                          pw.Text('Name: ${user?.fullName ?? "Valued Customer"}'),
                          pw.Text('Phone: ${user?.phone ?? "N/A"}'),
                          pw.Text('Address: ${customer?.address ?? "N/A"}'),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('VEHICLE & REPAIR', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                          pw.SizedBox(height: 4),
                          pw.Text('Vehicle: ${vehicle?.displayName ?? "N/A"}'),
                          pw.Text('Mileage: ${rJob?.checkInMileage ?? 0} km'),
                          pw.Text('Mechanic: ${rJob?.mechanic?.displayName ?? "Assigned Staff"}'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 16),

              // Itemized Table
              pw.Text('BREAKDOWN OF SERVICES & PARTS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
                cellHeight: 24,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerRight,
                  2: pw.Alignment.centerRight,
                },
                headers: ['Description', 'Category', 'Cost'],
                data: [
                  ['Service Fee', 'Service Charge', '\$${inv.serviceFee.toStringAsFixed(2)}'],
                  ['Mechanic Labor Charge', 'Labor', '\$${inv.laborCost.toStringAsFixed(2)}'],
                  ['Spare Parts Total', 'Parts', '\$${inv.partsCost.toStringAsFixed(2)}'],
                ],
              ),

              pw.SizedBox(height: 16),

              // Totals Table
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 220,
                    child: pw.Column(
                      children: [
                        _buildPdfCostRow('Subtotal', inv.subtotal),
                        _buildPdfCostRow('Tax (7%)', inv.tax),
                        _buildPdfCostRow('Discount', -inv.discount),
                        pw.Divider(),
                        _buildPdfCostRow('TOTAL DUE', inv.totalAmount, isTotal: true),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // Footer
              pw.Center(
                child: pw.Text(
                  'Thank you for choosing Car Garage Management System!',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey700),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildPdfCostRow(String label, double val, {bool isTotal = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: isTotal ? 12 : 10,
            ),
          ),
          pw.Text(
            '\$${val.toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: isTotal ? 12 : 10,
              color: isTotal ? PdfColors.blue900 : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice #${widget.invoice.id} - PDF Preview'),
      ),
      body: PdfPreview(
        build: (format) => _fetchOrGeneratePdf(format),
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        pdfFileName: 'Invoice_${widget.invoice.id}.pdf',
      ),
    );
  }
}
