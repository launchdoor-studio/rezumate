from app.services.export_service import generate_ats_pdf


def test_export_escapes_resume_markup():
    pdf = generate_ats_pdf("EXPERIENCE\nBuilt <internal> APIs & tools.")

    assert pdf.startswith(b"%PDF")
