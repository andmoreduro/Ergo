"""
Manages bibliography entries using BibLaTeX format.

This module provides functionality to load, add, remove, and save bibliography
entries to a .bib (or .tex) file using the bibtexparser library.
"""

import uuid
from pathlib import Path
from typing import Optional

import bibtexparser
from bibtexparser.bparser import BibTexParser
from bibtexparser.bwriter import BibTexWriter
from bibtexparser.bibdatabase import BibDatabase
from PySide6.QtCore import QObject, QUrl, Signal, Slot


class BibliographyManager(QObject):
    """
    Manages the project's bibliography file.
    
    This class handles reading and writing BibLaTeX entries to 'bibliography/bib.tex'.
    """

    # Signal emitted when the list of entries changes.
    # Emits a list of dictionaries, where each dict represents an entry.
    entriesChanged = Signal(list)
    
    # Signal emitted when an error occurs.
    errorOccurred = Signal(str)

    def __init__(self, parent=None):
        """Initializes the BibliographyManager."""
        super().__init__(parent)
        self.project_path: Optional[Path] = None
        self.bib_file_path: Optional[Path] = None
        self.db = BibDatabase()

    @Slot(str)
    def set_project_path(self, project_path: str):
        """
        Sets the project path and loads the bibliography.
        
        Args:
            project_path: The absolute path or file URL to the project directory.
        """
        if not project_path:
            return

        # Handle file:// URLs
        if project_path.startswith("file:"):
            self.project_path = Path(QUrl(project_path).toLocalFile())
        else:
            self.project_path = Path(project_path)

        # Ensure bibliography directory exists
        bib_dir = self.project_path / "bibliography"
        bib_dir.mkdir(exist_ok=True)
        
        # The bibliography file will be named ref.bib
        self.bib_file_path = bib_dir / "ref.bib"

        if not self.bib_file_path.exists():
            # Create empty file
            try:
                self.bib_file_path.write_text("", encoding="utf-8")
            except OSError as e:
                self.errorOccurred.emit(f"Failed to create bibliography file: {e}")
                return
        
        self.load_bibliography()

    @Slot()
    def load_bibliography(self):
        """Loads entries from the bibliography file."""
        if not self.bib_file_path or not self.bib_file_path.exists():
            return

        try:
            with open(self.bib_file_path, 'r', encoding='utf-8') as bibtex_file:
                parser = BibTexParser()
                # Enable common strings and ignore nonstandard types to support BibLaTeX
                parser.ignore_nonstandard_types = False 
                parser.homogenise_fields = False  # Keep original fields
                
                self.db = bibtexparser.load(bibtex_file, parser=parser)
                self._emit_entries()
        except Exception as e:
            self.errorOccurred.emit(f"Failed to load bibliography: {str(e)}")

    @Slot(str, str, dict)
    def add_entry(self, entry_type: str, citation_key: str, fields: dict):
        """
        Adds or updates a bibliography entry.
        
        Args:
            entry_type: The type of entry (article, book, etc.)
            citation_key: The unique citation key (ID)
            fields: Dictionary of fields (author, title, year, etc.)
        """
        if not self.bib_file_path:
            self.errorOccurred.emit("Project not loaded")
            return

        if not citation_key:
            citation_key = f"ref:{uuid.uuid4().hex[:8]}"

        # Create entry dict required by bibtexparser
        entry = {
            'ENTRYTYPE': entry_type,
            'ID': citation_key,
        }
        
        # Update with user fields, ensuring values are strings
        for k, v in fields.items():
            entry[k] = str(v)

        # Remove existing entry with same ID if any (update behavior)
        self.db.entries = [e for e in self.db.entries if e.get('ID') != citation_key]
        
        # Add new entry
        self.db.entries.append(entry)
        
        if self.save_bibliography():
            self._emit_entries()

    @Slot(str)
    def remove_entry(self, citation_key: str):
        """
        Removes an entry by citation key.
        
        Args:
            citation_key: The ID of the entry to remove.
        """
        if not self.bib_file_path:
            return

        original_count = len(self.db.entries)
        self.db.entries = [e for e in self.db.entries if e.get('ID') != citation_key]
        
        if len(self.db.entries) != original_count:
            if self.save_bibliography():
                self._emit_entries()

    @Slot(str)
    def remove_entry(self, citation_key: str):
        """
        Removes an entry by citation key.
        
        Args:
            citation_key: The ID of the entry to remove.
        """
        if not self.bib_file_path:
            return

        original_count = len(self.db.entries)
        self.db.entries = [e for e in self.db.entries if e.get('ID') != citation_key]
        
        if len(self.db.entries) != original_count:
            if self.save_bibliography():
                self._emit_entries()

    def save_bibliography(self) -> bool:
        """
        Saves the current database to the file.
        
        Returns:
            True if successful, False otherwise.
        """
        if not self.bib_file_path:
            return False

        try:
            writer = BibTexWriter()
            writer.indent = '  '     # Indent entries for readability
            writer.order_entries_by = ('ID',) # Sort by ID
            
            with open(self.bib_file_path, 'w', encoding='utf-8') as bibtex_file:
                bibtex_file.write(writer.write(self.db))
            return True
        except Exception as e:
            self.errorOccurred.emit(f"Failed to save bibliography: {str(e)}")
            return False

    def _emit_entries(self):
        """Emits the entriesChanged signal with the current list of entries."""
        # QML converts Python list of dicts to JS array of objects automatically
        self.entriesChanged.emit(self.db.entries)

    @Slot(result=list)
    def get_entries(self):
        """
        Returns the current list of entries.
        
        Returns:
            List of entry dictionaries.
        """
        return self.db.entries