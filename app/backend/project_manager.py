"""
Manages project creation by copying template directory structures.

This module provides functionality for creating new projects from templates.
Templates are simply directories containing the complete project structure,
which are copied recursively to the user's chosen location.
"""

import shutil
import uuid
from pathlib import Path

from PySide6.QtCore import QObject, QStandardPaths, QUrl, Signal, Slot
from PySide6.QtWidgets import QFileDialog


class ProjectManager(QObject):
    """
    Handles the creation of new projects by copying template directories.

    This class finds template directories in the templates folder and copies
    their entire structure to the user's chosen location. It integrates with
    the SettingsManager to track recently created projects.
    """

    # Signal emitted when a project is successfully created.
    projectCreated = Signal(str)  # Emits the project path

    # Signal emitted when project creation fails.
    projectCreationFailed = Signal(str)  # Emits the error message

    def __init__(self, settings_manager=None, parent=None):
        """
        Initializes the ProjectManager.

        Args:
            settings_manager: Optional SettingsManager instance for tracking recent projects.
            parent: Optional parent QObject.
        """
        super().__init__(parent)
        self.settings_manager = settings_manager

        # Locates the templates directory relative to this module.
        self.templates_dir = Path(__file__).resolve().parent.parent / "templates"

    @Slot(str, result=bool)
    def check_project_exists(self, project_path: str):
        """
        Checks if a project directory exists.

        Args:
            project_path: The path to the project directory.

        Returns:
            True if the directory exists, False otherwise.
        """
        if not project_path:
            return False

        path = Path(project_path)
        # Handle file:// URLs just in case
        if project_path.startswith("file://"):
            try:
                path = Path(QUrl(project_path).toLocalFile())
            except Exception:
                pass

        return path.exists() and path.is_dir()

    @Slot(result=str)
    def select_folder(self):
        """
        Opens a native folder selection dialog.

        Returns:
            The selected folder path as a string, or an empty string if cancelled.
        """
        folder = QFileDialog.getExistingDirectory(
            None,
            "Select New Project Folder",
            str(Path.home()),
        )
        return folder

    @Slot(result=str)
    def select_image(self):
        """
        Opens a native file selection dialog for images.

        Returns:
            The selected image path as a string, or an empty string if cancelled.
        """
        file_path, _ = QFileDialog.getOpenFileName(
            None,
            "Select Image",
            str(Path.home()),
            "Images (*.png *.jpg *.jpeg *.svg *.pdf)",
        )
        return file_path

    @Slot(str, str, result=str)
    def import_image(self, source_path: str, project_location: str):
        """
        Imports an image into the project's assets/images directory.

        Args:
            source_path: The path to the source image.
            project_location: The project root location.

        Returns:
            The relative path to the imported image for use in Typst (e.g. "assets/images/foo.png").
        """
        try:
            # Handle source path
            if source_path.startswith("file:"):
                src = Path(QUrl(source_path).toLocalFile())
            else:
                src = Path(source_path)

            # Handle project path
            if project_location.startswith("file:"):
                proj = Path(QUrl(project_location).toLocalFile())
            else:
                proj = Path(project_location)

            if not src.exists():
                print(f"Error: Image source not found: {src}")
                return ""

            # Target directory
            images_dir = proj / "assets" / "images"
            images_dir.mkdir(parents=True, exist_ok=True)

            # Destination file
            dest = images_dir / src.name
            
            # Copy file
            shutil.copy2(src, dest)
            print(f"Imported image to: {dest}")

            # Return relative path with forward slashes for Typst
            return f"assets/images/{src.name}"

        except Exception as e:
            print(f"Error importing image: {e}")
            return ""

    @Slot(result=str)
    def get_documents_location(self):
        """
        Gets the platform-specific user Documents folder path.

        Returns:
            The path to the Documents folder as a string.
        """
        return QStandardPaths.writableLocation(QStandardPaths.StandardLocation.DocumentsLocation)

    @Slot(result=str)
    def get_documents_location(self):
        """
        Gets the platform-specific user Documents folder path.

        Returns:
            The path to the Documents folder as a string.
        """
        return QStandardPaths.writableLocation(QStandardPaths.StandardLocation.DocumentsLocation)

    @Slot(result=str)
    def generate_unique_id(self):
        """Generates a unique ID for an image label."""
        return f"img:{uuid.uuid4()}"

    @Slot(result=str)
    def generate_citation_key(self):
        """Generates a unique citation key for a bibliography entry."""
        return f"ref:{uuid.uuid4().hex[:8]}"

    @Slot(str, str)
    def create_project(self, project_location: str, template_name: str):
        """
        Creates a project by copying a template directory to the specified location.

        Recursively copies all files and subdirectories from the template
        directory to the user's chosen project location.

        Args:
            project_location: The URL of the root project folder, passed from QML.
            template_name: The name of the template directory to copy (e.g., "apa").
        """
        try:
            # Converts the QML URL to a local file path.
            if project_location.startswith("file:"):
                project_path = Path(QUrl(project_location).toLocalFile())
            else:
                project_path = Path(project_location)
        except Exception as e:
            error_msg = f"Invalid project location '{project_location}'. Details: {e}"
            print(f"Error: {error_msg}")
            self.projectCreationFailed.emit(error_msg)
            return

        if not project_path.is_dir():
            error_msg = f"Project location is not a valid directory: {project_path}"
            print(f"Error: {error_msg}")
            self.projectCreationFailed.emit(error_msg)
            return

        # Locates the template directory and its structure subdirectory.
        template_path = self.templates_dir / template_name
        structure_path = template_path / "structure"

        if not template_path.exists():
            error_msg = f"Template '{template_name}' not found at: {template_path}"
            print(f"Error: {error_msg}")
            self.projectCreationFailed.emit(error_msg)
            return

        if not template_path.is_dir():
            error_msg = f"Template '{template_name}' is not a directory: {template_path}"
            print(f"Error: {error_msg}")
            self.projectCreationFailed.emit(error_msg)
            return

        if not structure_path.exists() or not structure_path.is_dir():
            error_msg = f"Template '{template_name}' is missing 'structure/' directory"
            print(f"Error: {error_msg}")
            self.projectCreationFailed.emit(error_msg)
            return

        print(f"Creating '{template_name}' project at: {project_path}")
        print(f"Copying from template structure: {structure_path}")

        try:
            # Use a single shutil.copytree call to merge the template structure
            # into the project location. This correctly handles subdirectories
            # and files, preserving the hierarchy.
            shutil.copytree(structure_path, project_path, dirs_exist_ok=True)
            print("Project structure created successfully.")

            # Adds the newly created project to the recent projects list.
            if self.settings_manager:
                self.settings_manager.add_recent_project(str(project_path))

            # Emits success signal with the project path.
            self.projectCreated.emit(str(project_path))

        except OSError as e:
            error_msg = f"Error creating project structure: {e}"
            print(f"Error: {error_msg}")
            self.projectCreationFailed.emit(error_msg)

    @Slot(result=list)
    def get_available_templates(self):
        """
        Retrieves a list of all available template names.

        Scans the templates directory for subdirectories, which are treated
        as available templates.

        Returns:
            A list of template names (strings) that can be used for project creation.
        """
        if not self.templates_dir.exists():
            print(f"Warning: Templates directory not found: {self.templates_dir}")
            return []

        templates = []
        for item in self.templates_dir.iterdir():
            # Only includes directories as templates (ignores files like README.md).
            if item.is_dir():
                templates.append(item.name)

        return sorted(templates)

    @Slot(str, result=str)
    def get_template_description(self, template_name: str):
        """
        Retrieves a description for a specific template.

        Looks for a README.md or description.txt file in the template directory
        to provide information about the template.

        Args:
            template_name: The name of the template.

        Returns:
            A description string for the template, or a default message if
            no description file is found.
        """
        template_path = self.templates_dir / template_name

        if not template_path.exists() or not template_path.is_dir():
            return "Template not found"

        # Checks for common description files.
        for desc_file_name in ["README.md", "description.txt", "DESCRIPTION.md"]:
            desc_file = template_path / desc_file_name
            if desc_file.exists() and desc_file.is_file():
                try:
                    # Reads the first few lines as the description.
                    description = desc_file.read_text(encoding="utf-8")
                    # Returns the first 500 characters as a preview.
                    return description[:500].strip()
                except OSError:
                    pass

        return f"Template: {template_name}"