import io
from dataclasses import dataclass, field

import pdfplumber


@dataclass
class ExtractionResult:
    text: str
    status: str
    warnings: list[str] = field(default_factory=list)
    page_count: int = 0
    character_count: int = 0


def extract_pdf_text(pdf_bytes: bytes) -> ExtractionResult:
    text_parts: list[str] = []
    warnings: list[str] = []

    try:
        with pdfplumber.open(io.BytesIO(pdf_bytes)) as pdf:
            page_count = len(pdf.pages)

            for index, page in enumerate(pdf.pages, start=1):
                page_text = page.extract_text() or ""
                page_text = page_text.strip()

                if page_text:
                    text_parts.append(page_text)
                else:
                    warnings.append(f"Page {index} did not contain extractable text.")
    except Exception:
        return ExtractionResult(
            text="",
            status="failed",
            warnings=["Could not read this PDF. Try exporting it again or uploading a text-based PDF."],
        )

    text = normalize_resume_text("\n\n".join(text_parts))
    character_count = len(text)

    if not text:
        warnings.append("No extractable resume text was found.")
        status = "empty"
    elif character_count < 400:
        warnings.append("Very little text was extracted, so the analysis may be incomplete.")
        status = "low_quality"
    else:
        status = "ok"

    if text and text.count("\n") < 4:
        warnings.append("The extracted text has very few line breaks, which can reduce section detection accuracy.")

    return ExtractionResult(
        text=text,
        status=status,
        warnings=warnings,
        page_count=page_count,
        character_count=character_count,
    )


def normalize_resume_text(text: str) -> str:
    lines = [" ".join(line.split()) for line in text.replace("\r\n", "\n").replace("\r", "\n").split("\n")]
    normalized_lines: list[str] = []
    previous_blank = False

    for line in lines:
        is_blank = not line
        if is_blank and previous_blank:
            continue

        normalized_lines.append(line)
        previous_blank = is_blank

    return "\n".join(normalized_lines).strip()


def extract_text_from_pdf(pdf_bytes: bytes) -> str:
    return extract_pdf_text(pdf_bytes).text
