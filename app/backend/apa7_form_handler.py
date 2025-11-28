"""
Handles form data processing and main.typ file generation for APA7 template.

This module provides functionality to generate and update the main.typ file
in real-time as users fill in the APA7 form. It takes form data and converts
it to the appropriate Typst syntax for the versatile-apa package.
"""

import json
import uuid
from pathlib import Path
from typing import Optional

from PySide6.QtCore import QObject, Signal, Slot


class Apa7FormHandler(QObject):
    """
    Manages the generation and updating of main.typ file for APA7 projects.

    This class takes form input data and generates the corresponding Typst code
    using the versatile-apa package format. It writes the main.typ file in
    real-time as the user updates form fields.
    """

    # Signal emitted when the file is successfully generated/updated.
    fileGenerated = Signal(str)  # Emits the file path

    # Signal emitted when file generation fails.
    fileGenerationFailed = Signal(str)  # Emits the error message

    def __init__(self, parent=None):
        """Initializes the Apa7FormHandler."""
        super().__init__(parent)
        self.project_path: Optional[Path] = None

    @Slot(str)
    def set_project_path(self, project_path: str):
        """
        Sets the project path where main.typ will be generated.

        Args:
            project_path: The absolute path to the project directory.
        """
        self.project_path = Path(project_path)

    @Slot(result=dict)
    def load_form_data(self):
        """
        Loads form data from the project's form_data.json file.

        Returns:
            A dictionary containing the saved form data, or an empty dict if
            the file doesn't exist or loading fails.
        """
        if not self.project_path:
            return {}

        json_path = self.project_path / "form_data.json"
        if not json_path.exists():
            return {}

        try:
            with open(json_path, "r", encoding="utf-8") as f:
                return json.load(f)
        except (OSError, json.JSONDecodeError) as e:
            print(f"Error loading form data: {e}")
            return {}

    @Slot(str, list, list, list, str, str, str, str, str, str, str, str, int, str, str, str, bool, bool)
    def generate_main_typ(
        self,
        title: str,
        authors: list,
        affiliations: list,
        sections: list,
        running_head: str,
        author_notes: str,
        course: str,
        instructor: str,
        due_date: str,
        abstract: str,
        keywords: str,
        font_family: str,
        font_size: int,
        paper_size: str,
        region: str,
        language: str,
        implicit_intro: bool,
        abstract_as_desc: bool,
    ):
        """
        Generates the main.typ file based on form input.

        Args:
            title: Document title
            authors: List of author dictionaries with name, orcid, affiliationIds
            affiliations: List of affiliation dictionaries with id, name
            running_head: Short title for page headers
            author_notes: Author notes, acknowledgments, disclosures
            course: Course code and name
            instructor: Instructor name
            due_date: Due date string
            abstract: Abstract text
            keywords: Comma-separated keywords
            font_family: Font family name
            font_size: Font size in points
            paper_size: Paper size (us-letter, a4)
            region: Region code (us, uk, au)
            language: Language code (en, es, fr, de)
            implicit_intro: Whether to use implicit introduction heading
            abstract_as_desc: Whether to use abstract as description meta tag
        """
        if not self.project_path:
            error_msg = "Project path not set. Cannot generate main.typ."
            print(f"Error: {error_msg}")
            self.fileGenerationFailed.emit(error_msg)
            return

        try:
            # Create sections directory
            sections_dir = self.project_path / "sections"
            sections_dir.mkdir(exist_ok=True)

            # Write section files (Level 1 sections get their own file, subsections are appended)
            current_l1_id = None
            current_l1_content = []

            for section in sections:
                sec_id = section.get("id")
                sec_title = section.get("title", "")
                
                # Determine content from blocks (text/image) or fallback to simple content
                blocks = section.get("blocks", [])
                if blocks:
                    parts = []
                    for block in blocks:
                        b_type = block.get("type", "text")
                        if b_type == "text":
                            parts.append(block.get("content", ""))
                        elif b_type == "image":
                            path = block.get("path", "").replace("\\", "/")
                            caption = block.get("caption", "")
                            note = block.get("note", "")
                            
                            label = block.get("label", "")
                            if not label:
                                label = f"img:{uuid.uuid4()}"
                                block["label"] = label

                            fig_code = "#figure(\n"
                            fig_code += f'  image("../{path}"),\n'
                            if caption:
                                fig_code += f"  caption: [{self._escape_typst(caption)}],\n"
                            fig_code += ")"
                            if label:
                                fig_code += f" <{label}>"
                            
                            if note:
                                fig_code += "\n#pad(top: 0.5em)[\n"
                                fig_code += f'  #text(style: "italic")[Note.] {self._escape_typst(note)}\n'
                                fig_code += "]"
                            
                            parts.append(fig_code)
                    sec_content = "\n\n".join(parts)
                else:
                    sec_content = section.get("content", "")

                level = int(section.get("level", 1))

                heading_markup = f"{'=' * level} {self._escape_typst(sec_title)}"
                full_content = f"{heading_markup}\n\n{sec_content}"

                if level == 1:
                    # Write previous accumulated L1 section if exists
                    if current_l1_id:
                        file_content = '#import "@preview/versatile-apa:7.1.5": *\n\n' + "\n\n".join(current_l1_content)
                        (sections_dir / f"{current_l1_id}.typ").write_text(file_content, encoding="utf-8")
                    
                    current_l1_id = sec_id
                    current_l1_content = [full_content]
                else:
                    # Append subsection to current L1 section
                    if current_l1_id:
                        current_l1_content.append(full_content)

            # Write the final section
            if current_l1_id:
                file_content = '#import "@preview/versatile-apa:7.1.5": *\n\n' + "\n\n".join(current_l1_content)
                (sections_dir / f"{current_l1_id}.typ").write_text(file_content, encoding="utf-8")

            content = self._build_main_typ_content(
                title,
                authors,
                affiliations,
                sections,
                running_head,
                author_notes,
                course,
                instructor,
                due_date,
                abstract,
                keywords,
                font_family,
                font_size,
                paper_size,
                region,
                language,
                implicit_intro,
                abstract_as_desc,
            )

            main_typ_path = self.project_path / "main.typ"
            main_typ_path.write_text(content, encoding="utf-8")

            # Save form data to JSON for persistence
            form_data = {
                "title": title,
                "authors": authors,
                "affiliations": affiliations,
                "sections": sections,
                "running_head": running_head,
                "author_notes": author_notes,
                "course": course,
                "instructor": instructor,
                "due_date": due_date,
                "abstract": abstract,
                "keywords": keywords,
                "font_family": font_family,
                "font_size": font_size,
                "paper_size": paper_size,
                "region": region,
                "language": language,
                "implicit_intro": implicit_intro,
                "abstract_as_desc": abstract_as_desc,
            }

            json_path = self.project_path / "form_data.json"
            try:
                with open(json_path, "w", encoding="utf-8") as f:
                    json.dump(form_data, f, indent=2, ensure_ascii=False)
            except OSError as e:
                print(f"Warning: Failed to save form data: {e}")

            self.fileGenerated.emit(str(main_typ_path))

        except OSError as e:
            error_msg = f"Failed to write main.typ: {e}"
            print(f"Error: {error_msg}")
            self.fileGenerationFailed.emit(error_msg)

    def _build_main_typ_content(
        self,
        title: str,
        authors: list,
        affiliations: list,
        sections: list,
        running_head: str,
        author_notes: str,
        course: str,
        instructor: str,
        due_date: str,
        abstract: str,
        keywords: str,
        font_family: str,
        font_size: int,
        paper_size: str,
        region: str,
        language: str,
        implicit_intro: bool,
        abstract_as_desc: bool,
    ) -> str:
        """
        Builds the complete main.typ file content.

        Args:
            Same as generate_main_typ

        Returns:
            The complete main.typ file content as a string.
        """
        lines = []

        # Import statement
        lines.append('#import "@preview/versatile-apa:7.1.5": *')
        lines.append("")



        # Document title
        lines.append("// Document titles should be formatted in title case")
        lines.append(f"#let doc-title = [{self._escape_typst(title)}]")
        lines.append("")

        # versatile-apa setup
        lines.append("#show: versatile-apa.with(")
        lines.append("  title: doc-title,")
        lines.append("")

        # Authors and affiliations
        if authors and affiliations:
            lines.extend(self._build_authors_section(authors, affiliations))

        # Student-specific fields
        if course or instructor or due_date:
            lines.append("  // Student-specific fields")
            if course:
                lines.append(f"  course: [{self._escape_typst(course)}],")
            if instructor:
                lines.append(f"  instructor: [{self._escape_typst(instructor)}],")
            if due_date:
                lines.append(f"  due-date: [{self._escape_typst(due_date)}],")
            else:
                lines.append("  due-date: datetime.today().display(),")
            lines.append("")

        # Professional-specific fields
        if running_head or author_notes:
            lines.append("  // Professional-specific fields")
            if running_head:
                lines.append(f"  running-head: [{self._escape_typst(running_head)}],")
            if author_notes:
                lines.extend(self._build_author_notes_section(author_notes, authors))
            lines.append("")

        # Abstract and keywords
        if abstract or keywords:
            if abstract:
                lines.append(f"  abstract: [{self._escape_typst(abstract)}],")
            if keywords:
                keywords_list = self._build_keywords_list(keywords)
                lines.append(f"  keywords: {keywords_list},")
            lines.append("")

        # Common fields (formatting options)
        lines.append("  // Common fields")
        lines.append(f'  font-family: "{font_family}",')
        lines.append(f"  font-size: {font_size}pt,")
        lines.append(f'  region: "{region}",')
        lines.append(f'  language: "{language}",')
        lines.append(f'  paper-size: "{paper_size}",')
        lines.append("  implicit-introduction-heading: false,")
        lines.append(f"  abstract-as-description: {str(abstract_as_desc).lower()},")
        lines.append(")")
        lines.append("")

        # Outlines section
        lines.append("// Document outlines")
        lines.append("#outline()")
        lines.append("#pagebreak()")
        lines.append('#outline(target: figure.where(kind: table), title: [Tables])')
        lines.append("#pagebreak()")
        lines.append('#outline(target: figure.where(kind: image), title: [Figures])')
        lines.append("#pagebreak()")
        lines.append('#outline(target: figure.where(kind: math.equation), title: [Equations])')
        lines.append("#pagebreak()")
        lines.append('#outline(target: figure.where(kind: raw), title: [Listings])')
        lines.append("#pagebreak()")
        lines.append("")

        # Document content
        lines.append("// Main document content")
        
        # Include sections
        for section in sections:
            sec_id = section.get("id")
            level = int(section.get("level", 1))
            if sec_id and level == 1:
                lines.append(f'#include "sections/{sec_id}.typ"')
        lines.append("")

        # Bibliography
        lines.append("#pagebreak()")
        lines.append("#bibliography(")
        lines.append('  "bibliography/ref.bib",')
        lines.append('  style: "csl/apa.csl",')
        lines.append("  full: true,")
        lines.append("  title: auto,")
        lines.append(")")

        return "\n".join(lines)

    def _build_authors_section(self, authors: list, affiliations: list) -> list:
        """
        Builds the authors and affiliations section.

        Args:
            authors: List of author dictionaries
            affiliations: List of affiliation dictionaries

        Returns:
            List of lines for the authors section
        """
        lines = []
        lines.append("  // Authors and affiliations")
        lines.append("  authors: (")

        for author in authors:
            name = author.get("name", "")
            affiliation_ids = author.get("affiliationIds", [])

            # Skips authors without a name or without any affiliations
            # (APA template requires at least one affiliation per author)
            if name and affiliation_ids:
                lines.append("    (")
                lines.append(f"      name: [{self._escape_typst(name)}],")

                # Maps affiliation IDs to AF-N format
                af_ids = []
                for aff_id in affiliation_ids:
                    # Finds the index of this affiliation in the list
                    for idx, aff in enumerate(affiliations):
                        if aff.get("id") == aff_id:
                            af_ids.append(f'"AF-{idx + 1}"')
                            break
                if af_ids:
                    lines.append(f"      affiliations: ({', '.join(af_ids)}),")

                lines.append("    ),")

        lines.append("  ),")

        lines.append("  affiliations: (")
        for idx, affiliation in enumerate(affiliations):
            name = affiliation.get("name", "")
            if name:
                lines.append("    (")
                lines.append(f'      id: "AF-{idx + 1}",')
                lines.append(f"      name: [{self._escape_typst(name)}],")
                lines.append("    ),")
        lines.append("  ),")
        lines.append("")

        return lines

    def _build_author_notes_section(self, author_notes: str, authors: list) -> list:
        """
        Builds the author notes section with ORCID iDs.

        Args:
            author_notes: The author notes text
            authors: List of author dictionaries (may contain ORCID iDs)

        Returns:
            List of lines for the author notes section
        """
        lines = []
        lines.append("  author-notes: [")

        # Adds ORCID iDs for authors who have them
        for author in authors:
            name = author.get("name", "")
            orcid = author.get("orcid", "")
            if name and orcid:
                lines.append(f"    #include-orcid([{self._escape_typst(name)}], \"{orcid}\")")
                lines.append("")

        # Adds the author notes text
        if author_notes:
            lines.append(f"    {self._escape_typst(author_notes)}")

        lines.append("  ],")

        return lines

    def _build_keywords_list(self, keywords: str) -> str:
        """
        Converts comma-separated keywords string to Typst array format.

        Args:
            keywords: Comma-separated keywords string

        Returns:
            Typst array format string (e.g., ("keyword1", "keyword2"))
        """
        if not keywords:
            return "()"

        # Splits by comma and strips whitespace
        keyword_list = [kw.strip() for kw in keywords.split(",") if kw.strip()]

        if not keyword_list:
            return "()"

        # Formats as Typst array
        formatted_keywords = ", ".join(f'"{self._escape_typst(kw)}"' for kw in keyword_list)
        return f"({formatted_keywords})"

    def _escape_typst(self, text: str) -> str:
        """
        Escapes special characters for Typst markup.

        Args:
            text: The text to escape

        Returns:
            The escaped text safe for use in Typst
        """
        if not text:
            return ""

        # Escapes characters that have special meaning in Typst
        # Note: This is a basic implementation. May need to be expanded.
        text = text.replace("\\", "\\\\")  # Backslash must be first
        text = text.replace("[", "\\[")
        text = text.replace("]", "\\]")
        text = text.replace("#", "\\#")
        text = text.replace("$", "\\$")

        return text