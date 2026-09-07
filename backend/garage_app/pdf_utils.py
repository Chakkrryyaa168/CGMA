import io
from decimal import Decimal
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, HRFlowable
)

def generate_invoice_pdf(invoice):
    """
    Generates a printable PDF binary buffer for a given Invoice model instance.
    """
    buffer = io.BytesIO()
    doc = SimpleDocTemplate(
        buffer,
        pagesize=letter,
        rightMargin=36,
        leftMargin=36,
        topMargin=36,
        bottomMargin=36
    )

    story = []
    styles = getSampleStyleSheet()

    # Custom styles
    title_style = ParagraphStyle(
        'InvoiceTitle',
        parent=styles['Heading1'],
        fontName='Helvetica-Bold',
        fontSize=22,
        leading=26,
        textColor=colors.HexColor('#1E3A8A')
    )

    subtitle_style = ParagraphStyle(
        'InvoiceSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=10,
        leading=14,
        textColor=colors.HexColor('#6B7280')
    )

    header_style = ParagraphStyle(
        'SectionHeader',
        parent=styles['Heading2'],
        fontName='Helvetica-Bold',
        fontSize=12,
        leading=16,
        textColor=colors.HexColor('#1E3A8A')
    )

    bold_text = ParagraphStyle(
        'BoldText',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=10,
        leading=14
    )

    normal_text = ParagraphStyle(
        'NormalText',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=9,
        leading=13
    )

    # 1. Header Banner
    repair_job = invoice.repair_job
    vehicle = repair_job.vehicle
    customer = vehicle.customer
    user = customer.user

    header_data = [
        [
            Paragraph("CAR GARAGE MANAGEMENT SYSTEM<br/><font size=9 color='#6B7280'>123 Service Auto Way, Tech City • Phone: +1-800-GARAGE</font>", title_style),
            Paragraph(f"<b>INVOICE #{invoice.id}</b><br/>Date: {invoice.created_at.strftime('%Y-%m-%d')}<br/>Status: <b>{'PAID' if hasattr(invoice, 'payments') and invoice.payments.filter(status='COMPLETED').exists() else 'UNPAID'}</b>", ParagraphStyle('HeaderRight', parent=normal_text, alignment=2))
        ]
    ]

    header_table = Table(header_data, colWidths=[340, 200])
    header_table.setStyle(TableStyle([
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
    ]))
    story.append(header_table)
    story.append(Spacer(1, 15))
    story.append(HRFlowable(width="100%", thickness=1.5, color=colors.HexColor('#1E3A8A'), spaceAfter=15))

    # 2. Customer & Vehicle Info Grid
    info_data = [
        [
            Paragraph("<b>CUSTOMER INFORMATION</b>", header_style),
            Paragraph("<b>VEHICLE & REPAIR DETAILS</b>", header_style)
        ],
        [
            Paragraph(
                f"<b>Name:</b> {user.full_name}<br/>"
                f"<b>Email:</b> {user.email}<br/>"
                f"<b>Phone:</b> {user.phone if user.phone else 'N/A'}<br/>"
                f"<b>Address:</b> {customer.address if customer.address else 'N/A'}",
                normal_text
            ),
            Paragraph(
                f"<b>Vehicle:</b> {vehicle.brand} {vehicle.model} ({vehicle.year})<br/>"
                f"<b>Plate Number:</b> {vehicle.plate_number}<br/>"
                f"<b>Mileage at Check-in:</b> {repair_job.check_in_mileage} km<br/>"
                f"<b>Assigned Mechanic:</b> {repair_job.mechanic.user.full_name if repair_job.mechanic else 'N/A'}",
                normal_text
            )
        ]
    ]

    info_table = Table(info_data, colWidths=[270, 270])
    info_table.setStyle(TableStyle([
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('BACKGROUND', (0, 0), (0, 0), colors.HexColor('#F3F4F6')),
        ('BACKGROUND', (1, 0), (1, 0), colors.HexColor('#F3F4F6')),
        ('PADDING', (0, 0), (-1, -1), 8),
    ]))
    story.append(info_table)
    story.append(Spacer(1, 20))

    # 3. Itemized Services & Parts Table
    story.append(Paragraph("ITEMIZED REPAIR & SERVICES BREAKDOWN", header_style))
    story.append(Spacer(1, 8))

    item_table_data = [
        [
            Paragraph("<b>Item / Description</b>", bold_text),
            Paragraph("<b>Category / Part #</b>", bold_text),
            Paragraph("<b>Qty</b>", bold_text),
            Paragraph("<b>Unit Price</b>", bold_text),
            Paragraph("<b>Amount</b>", bold_text),
        ]
    ]

    # Service item
    if repair_job.booking and repair_job.booking.service:
        service = repair_job.booking.service
        item_table_data.append([
            Paragraph(f"Service: {service.name}", normal_text),
            Paragraph("Service Charge", normal_text),
            Paragraph("1", normal_text),
            Paragraph(f"${invoice.service_fee:.2f}", normal_text),
            Paragraph(f"${invoice.service_fee:.2f}", normal_text),
        ])

    # Labor item
    item_table_data.append([
        Paragraph("Mechanic Labor & Inspection", normal_text),
        Paragraph("Labor Charge", normal_text),
        Paragraph("1", normal_text),
        Paragraph(f"${invoice.labor_cost:.2f}", normal_text),
        Paragraph(f"${invoice.labor_cost:.2f}", normal_text),
    ])

    # Spare Parts Used
    for usage in repair_job.part_usages.all():
        part = usage.part
        item_table_data.append([
            Paragraph(f"Spare Part: {part.part_name}", normal_text),
            Paragraph(part.part_number, normal_text),
            Paragraph(str(usage.quantity_used), normal_text),
            Paragraph(f"${usage.unit_price:.2f}", normal_text),
            Paragraph(f"${usage.parts_cost:.2f}", normal_text),
        ])

    items_table = Table(item_table_data, colWidths=[200, 110, 50, 90, 90])
    items_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#E5E7EB')),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#D1D5DB')),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('ALIGN', (2, 0), (-1, -1), 'CENTER'),
        ('ALIGN', (3, 0), (-1, -1), 'RIGHT'),
        ('PADDING', (0, 0), (-1, -1), 6),
    ]))
    story.append(items_table)
    story.append(Spacer(1, 20))

    # 4. Financial Totals & Payment Summary Table
    totals_data = [
        [Paragraph("Subtotal:", bold_text), Paragraph(f"${invoice.subtotal:.2f}", normal_text)],
        [Paragraph("Tax (7%):", bold_text), Paragraph(f"${invoice.tax:.2f}", normal_text)],
        [Paragraph("Discount:", bold_text), Paragraph(f"-${invoice.discount:.2f}", normal_text)],
        [Paragraph("<b>TOTAL DUE:</b>", ParagraphStyle('TotalLabel', parent=bold_text, fontSize=12)),
         Paragraph(f"<b>${invoice.total_amount:.2f}</b>", ParagraphStyle('TotalVal', parent=bold_text, fontSize=12, textColor=colors.HexColor('#1E3A8A')))],
    ]

    totals_table = Table(totals_data, colWidths=[120, 100], hAlign='RIGHT')
    totals_table.setStyle(TableStyle([
        ('ALIGN', (0, 0), (-1, -1), 'RIGHT'),
        ('BACKGROUND', (0, 3), (1, 3), colors.HexColor('#FEF3C7')),
        ('PADDING', (0, 0), (-1, -1), 6),
        ('GRID', (0, 3), (1, 3), 1, colors.HexColor('#F59E0B')),
    ]))
    story.append(totals_table)
    story.append(Spacer(1, 30))

    # 5. Footer & Terms
    footer_text = Paragraph(
        "<b>Thank you for choosing Car Garage Management System!</b><br/>"
        "<font size=8 color='#6B7280'>All repairs come with a 30-day warranty. For any inquiries regarding this invoice, please contact support@garage.com.</font>",
        ParagraphStyle('Footer', parent=normal_text, alignment=1)
    )
    story.append(footer_text)

    # Build PDF
    doc.build(story)
    pdf_value = buffer.getvalue()
    buffer.close()
    return pdf_value
