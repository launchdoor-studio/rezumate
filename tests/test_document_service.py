import pytest
from app.services.document_service import extract_pdf_text, extract_docx_text, evaluate_extracted_text

def test_evaluate_extracted_text_empty():
    text = ""
    warnings = []
    
    result = evaluate_extracted_text(text, warnings, page_count=1)
    
    assert result.status == "empty"
    assert "No extractable resume text was found." in result.warnings

def test_evaluate_extracted_text_low_quality():
    text = "John Doe\nSoftware Engineer"
    warnings = []
    
    result = evaluate_extracted_text(text, warnings, page_count=1)
    
    assert result.status == "low_quality"
    assert "Very little text was extracted" in result.warnings[0]

def test_invalid_pdf_bytes():
    result = extract_pdf_text(b"not a pdf file")
    assert result.status == "failed"
    assert "Could not read this PDF" in result.warnings[0]

def test_invalid_docx_bytes():
    result = extract_docx_text(b"not a docx file")
    assert result.status == "failed"
    assert "Could not read this DOCX file" in result.warnings[0]
