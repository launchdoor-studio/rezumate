import io
from xml.sax.saxutils import escape
from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch

def generate_ats_pdf(text_content: str) -> bytes:
    """
    Generates a clean, text-based PDF suitable for ATS parsing.
    """
    buffer = io.BytesIO()
    doc = SimpleDocTemplate(
        buffer,
        pagesize=letter,
        rightMargin=inch,
        leftMargin=inch,
        topMargin=inch,
        bottomMargin=inch
    )

    styles = getSampleStyleSheet()
    
    # Custom styles for clean, parseable resume
    normal_style = styles["Normal"]
    normal_style.fontSize = 11
    normal_style.leading = 14
    
    heading_style = ParagraphStyle(
        'Heading',
        parent=styles['Heading2'],
        fontSize=14,
        spaceAfter=6,
        spaceBefore=12
    )

    story = []
    
    # Very basic conversion of raw text to PDF paragraphs
    # In a full implementation, the 'text_content' would be structured JSON 
    # (e.g. { "name": "...", "experience": [...] }) to layout perfectly.
    
    lines = text_content.split('\n')
    for line in lines:
        line = line.strip()
        if not line:
            story.append(Spacer(1, 0.1 * inch))
            continue
            
        # Heuristic for section headers (short, all caps, or bold-like)
        if len(line) < 40 and (line.isupper() or line.endswith(':')):
            story.append(Paragraph(f"<b>{escape(line)}</b>", heading_style))
        else:
            story.append(Paragraph(escape(line), normal_style))
                
    doc.build(story)
    
    pdf_bytes = buffer.getvalue()
    buffer.close()
    return pdf_bytes
