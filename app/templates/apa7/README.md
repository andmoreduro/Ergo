# APA7 Template

This template provides a form and project structure for creating documents formatted according to the American Psychological Association (APA) 7th edition style guidelines.

## Features

### Dynamic Author Management
- Add multiple authors to your document
- Remove authors as needed
- Each author can be associated with multiple affiliations
- Include ORCID iDs for each author (optional)

### Dynamic Affiliation Management
- Add multiple affiliations (institutions, departments, organizations)
- Remove affiliations as needed
- Associate each affiliation with one or more authors

### Document Fields

**General Information:**
- **Title**: The main title of your document (should be in title case)
- **Running Head**: A short title for page headers (for professional papers)

**Author Information:**
- **Authors**: Add multiple authors with names and ORCID iDs
- **Affiliations**: Associate authors with their institutions/departments
- **Author Notes**: Acknowledgments, funding, conflicts of interest (for professional papers)

**Student Paper Fields:**
- **Course**: Course code and name
- **Instructor**: Instructor name
- **Due Date**: Submission date (leave empty to use today's date)

**Professional Paper Fields:**
- **Running Head**: Short title for headers
- **Author Notes**: Include acknowledgments, funding information, disclosures

**Abstract & Keywords:**
- **Abstract**: Brief summary of your work (150-250 words)
- **Keywords**: Comma-separated list of keywords

**Formatting Options:**
- **Font Family**: Libertinus Serif, Times New Roman, Arial, or Calibri
- **Font Size**: 10-14pt (default: 12pt)
- **Paper Size**: US Letter or A4
- **Region**: US, UK, or AU
- **Language**: English, Spanish, French, or German
- **Implicit Introduction Heading**: Whether to show/hide the introduction heading
- **Abstract as Description**: Use abstract as meta description tag

## Project Structure

When you create a new project using this template, the following structure is created:

```
project/
├── main.typ              # Main document file
├── assets/               # For images, figures, and other media
├── bibliography/         # For reference files
├── sections/             # For organizing document sections
└── output/               # For compiled PDF files
```

## Usage

1. **Select the APA7 template** when creating a new project
2. **Choose a location** for your project
3. **Fill in the form fields**:
   - Start by adding affiliations (institutions/departments)
   - Add authors and associate them with their affiliations
   - Fill in the document information
   - Optionally add an abstract and keywords

### Adding Affiliations

1. Click **"+ Add Affiliation"**
2. Enter the affiliation name (e.g., "Department of Psychology, University Name")
3. Add as many affiliations as needed
4. Remove affiliations using the **"−"** button

### Adding Authors

1. Click **"+ Add Author"**
2. Enter the author's name
3. Optionally enter the author's ORCID iD (format: 0000-0000-0000-0000)
4. Check the boxes to associate the author with their affiliations
5. An author can have multiple affiliations
6. Remove authors using the **"−"** button

### Paper Types

This template supports both **Student** and **Professional** papers:

- **Student Papers**: Fill in Course Information section (course, instructor, due date)
- **Professional Papers**: Fill in Running Head and Author Notes sections

You can fill in both sections if needed, and the generated document will include all provided information.

### Tips

- Add all affiliations before associating them with authors
- If you remove an affiliation, it will be automatically removed from all authors
- The form initializes with one author and one affiliation by default
- All fields can be edited at any time
- ORCID iDs are optional but recommended for professional papers
- Use title case for your document title (capitalize major words)
- Leave due date empty to automatically use today's date

## Future Features

This template is designed to support future enhancements including:
- Dynamic content generation based on form input
- Bibliography management
- Section management
- Content editing with formatting options