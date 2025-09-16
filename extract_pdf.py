import fitz  # PyMuPDF

# Open the PDF file
pdf_path = "Project 5 - Hotel Reservation and Guest Services Management System.pdf"
doc = fitz.open(pdf_path)

# Extract all text
text = ""
for page in doc:
    text += page.get_text()

# Write to file and print
with open("pdf_content.txt", "w", encoding="utf-8") as f:
    f.write(text)

print(text)
doc.close()