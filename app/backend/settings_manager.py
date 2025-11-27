"""
Manages application settings and recent projects using Qt's QSettings.

This module provides a centralized way to store and retrieve user preferences,
recent project paths, and other persistent application state. QSettings
automatically handles platform-specific storage locations.
"""

from PySide6.QtCore import QObject, QSettings, Signal, Slot


class SettingsManager(QObject):
    """
    Handles persistent storage of application settings and recent projects.

    Uses QSettings to store data in platform-appropriate locations:
    - Linux: ~/.config/Ergo/Ergo.conf
    - Windows: Registry (HKEY_CURRENT_USER\\Software\\Ergo\\Ergo)
    - macOS: ~/Library/Preferences/com.Ergo.plist

    Emits signals when settings change so the UI can react accordingly.
    """

    # Signal emitted when the recent projects list changes.
    recentProjectsChanged = Signal()

    def __init__(self, parent=None):
        """Initializes the SettingsManager with organization and application name."""
        super().__init__(parent)

        # Sets the organization and application name for QSettings.
        # This determines where settings are stored on each platform.
        self.settings = QSettings("Ergo", "Ergo")

    # --- Recent Projects Management ---

    @Slot(str)
    def add_recent_project(self, project_path: str):
        """
        Adds a project path to the recent projects list.

        If the project already exists in the list, it is moved to the top.
        The list is limited to a maximum of 10 recent projects.

        Args:
            project_path: The absolute path to the project directory.
        """
        recent_projects = self.get_recent_projects()

        # Removes the project if it already exists to avoid duplicates.
        if project_path in recent_projects:
            recent_projects.remove(project_path)

        # Inserts the project at the beginning (most recent).
        recent_projects.insert(0, project_path)

        # Limits the list to the 10 most recent projects.
        recent_projects = recent_projects[:10]

        self.settings.setValue("recentProjects", recent_projects)
        self.recentProjectsChanged.emit()

    @Slot(result=list)
    def get_recent_projects(self):
        """
        Retrieves the list of recent project paths.

        Returns:
            A list of project paths, ordered from most to least recent.
            Returns an empty list if no recent projects exist.
        """
        # QSettings returns None if the key doesn't exist, so we provide a default.
        recent_projects = self.settings.value("recentProjects", [])

        # Ensures we always return a list (QSettings might return a string for single items).
        if not recent_projects:
            return []

        if isinstance(recent_projects, str):
            # QSettings returns a string when there's only one item
            return [recent_projects]

        if not isinstance(recent_projects, list):
            return []

        return recent_projects

    @Slot(str)
    def remove_recent_project(self, project_path: str):
        """
        Removes a project path from the recent projects list.

        Useful when a project has been deleted or is no longer accessible.

        Args:
            project_path: The path to remove from the recent projects list.
        """
        recent_projects = self.get_recent_projects()

        if project_path in recent_projects:
            recent_projects.remove(project_path)
            self.settings.setValue("recentProjects", recent_projects)
            self.recentProjectsChanged.emit()

    @Slot()
    def clear_recent_projects(self):
        """Clears all recent projects from the list."""
        self.settings.setValue("recentProjects", [])
        self.recentProjectsChanged.emit()

    # --- Application Settings ---

    @Slot(str, result=str)
    def get_setting(self, key: str, default_value: str = ""):
        """
        Retrieves a setting value by key.

        Args:
            key: The setting key to retrieve.
            default_value: The value to return if the key doesn't exist.

        Returns:
            The setting value as a string, or the default value if not found.
        """
        return self.settings.value(key, default_value)

    @Slot(str, str)
    def set_setting(self, key: str, value: str):
        """
        Stores a setting value.

        Args:
            key: The setting key.
            value: The value to store.
        """
        self.settings.setValue(key, value)

    @Slot(str, result=bool)
    def get_bool_setting(self, key: str, default_value: bool = False):
        """
        Retrieves a boolean setting value by key.

        Args:
            key: The setting key to retrieve.
            default_value: The value to return if the key doesn't exist.

        Returns:
            The setting value as a boolean.
        """
        value = self.settings.value(key, default_value)
        # QSettings sometimes returns strings "true"/"false", so we normalize.
        if isinstance(value, str):
            return value.lower() in ("true", "1", "yes")
        return bool(value)

    @Slot(str, bool)
    def set_bool_setting(self, key: str, value: bool):
        """
        Stores a boolean setting value.

        Args:
            key: The setting key.
            value: The boolean value to store.
        """
        self.settings.setValue(key, value)

    @Slot(str, result=int)
    def get_int_setting(self, key: str, default_value: int = 0):
        """
        Retrieves an integer setting value by key.

        Args:
            key: The setting key to retrieve.
            default_value: The value to return if the key doesn't exist.

        Returns:
            The setting value as an integer.
        """
        value = self.settings.value(key, default_value)
        try:
            # Explicitly cast to int, handling various return types from QSettings
            return value if value is not None else int(default_value)
        except (ValueError, TypeError):
            return int(default_value)

    @Slot(str, int)
    def set_int_setting(self, key: str, value: int):
        """
        Stores an integer setting value.

        Args:
            key: The setting key.
            value: The integer value to store.
        """
        self.settings.setValue(key, value)
