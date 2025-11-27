"""
Monitors the output directory for generated SVG files from Typst.

This module provides functionality to watch the output folder for new or updated
SVG files and emit signals when changes are detected. It maintains a sorted list
of page SVGs that can be displayed in the preview panel.
"""

from pathlib import Path
from typing import Optional

from PySide6.QtCore import QFileSystemWatcher, QObject, QTimer, Signal, Slot


class OutputMonitor(QObject):
    """
    Monitors the output directory for SVG file changes.

    This class watches the output folder where Typst generates SVG files
    (p1.svg, p2.svg, etc.) and maintains a sorted list of available pages.
    It emits signals when the file list changes so the UI can update.
    """

    # Signal emitted when the list of output files changes.
    # Emits a list of absolute file paths in sorted order.
    filesChanged = Signal(list)

    # Signal emitted when a specific page changes (for auto-scrolling).
    # Emits the index of the page (0-based).
    activePageChanged = Signal(int)

    def __init__(self, parent=None):
        """Initializes the OutputMonitor."""
        super().__init__(parent)
        self.project_path: Optional[Path] = None
        self.output_path: Optional[Path] = None
        self.watcher = QFileSystemWatcher()
        self.file_timestamps = {}  # Maps file path to (mtime, cache_buster_timestamp)

        # Connects the file system watcher to our handler
        self.watcher.directoryChanged.connect(self._on_directory_changed)
        self.watcher.fileChanged.connect(self._on_file_changed)

        # Polling timer as fallback when QFileSystemWatcher doesn't detect changes
        self.poll_timer = QTimer()
        self.poll_timer.setInterval(500)  # Poll less frequently since we watch files directly
        self.poll_timer.timeout.connect(self._check_for_changes)

    @Slot(str)
    def set_project_path(self, project_path: str):
        """
        Sets the project path and starts monitoring its output directory.

        Args:
            project_path: The absolute path to the project directory.
        """
        # Stops watching previous paths
        if self.watcher.directories():
            self.watcher.removePaths(self.watcher.directories())
        if self.watcher.files():
            self.watcher.removePaths(self.watcher.files())
        
        # Stop any existing polling timers before starting a new one
        self.poll_timer.stop()

        self.project_path = Path(project_path)
        self.output_path = self.project_path / "output"

        # Ensures the output directory exists
        if not self.output_path.exists():
            print(f"Output directory does not exist, creating: {self.output_path}")
            self.output_path.mkdir(parents=True, exist_ok=True)

        # Starts watching the output directory
        self.watcher.addPath(str(self.output_path))

        # Performs initial scan to populate the file list and watch existing files
        self._scan_and_emit()

        # Starts the polling timer as fallback
        self.poll_timer.start()

    @Slot()
    def stop_monitoring(self):
        """Stops monitoring the output directory."""
        self.poll_timer.stop()

        watched_dirs = self.watcher.directories()
        watched_files = self.watcher.files()

        if watched_dirs:
            self.watcher.removePaths(watched_dirs)
        if watched_files:
            self.watcher.removePaths(watched_files)

    @Slot(result=list)
    def get_output_files(self):
        """
        Gets the current list of output SVG files.

        Returns:
            A sorted list of absolute file paths (as strings) for all SVG files
            in the output directory, ordered by page number (p1, p2, p3, ...).
        """
        if not self.output_path or not self.output_path.exists():
            return []

        files = self._get_sorted_svg_files()
        # Converts Path objects to file:// URLs for QML Image with per-file cache busting
        urls, _ = self._build_urls_with_cache_busting(files)
        return urls

    def _on_directory_changed(self, path: str):
        """
        Handles directory change events.

        Args:
            path: The path of the directory that changed.
        """
        self._scan_and_emit()

    def _on_file_changed(self, path: str):
        """
        Handles file change events.

        Args:
            path: The path of the file that changed.
        """
        self._scan_and_emit()

    def _check_for_changes(self):
        """
        Polls for file changes (fallback for when QFileSystemWatcher doesn't work).

        Checks modification times of all files and triggers scan if any changed.
        """
        if not self.output_path or not self.output_path.exists():
            return

        files = self._get_sorted_svg_files()

        # Checks if any file modification times changed
        for file_path in files:
            file_key = str(file_path)
            try:
                current_mtime = file_path.stat().st_mtime

                if file_key in self.file_timestamps:
                    stored_mtime, _ = self.file_timestamps[file_key]
                    if current_mtime != stored_mtime:
                        # File changed - trigger scan
                        self._scan_and_emit()
                        return
            except OSError:
                pass




    def _scan_and_emit(self):
        """Scans the output directory and emits the updated file list."""
        files = self._get_sorted_svg_files()

        if files:
            # Ensure all output files are being watched directly
            current_watched = set(self.watcher.files())
            for file_path in files:
                path_str = str(file_path)
                if path_str not in current_watched:
                    self.watcher.addPath(path_str)

            # Builds URLs with per-file cache busting (only changed files get new timestamps)
            file_urls, changed_index = self._build_urls_with_cache_busting(files)
            self.filesChanged.emit(file_urls)

            if changed_index != -1:
                self.activePageChanged.emit(changed_index)
        else:
            self.filesChanged.emit([])

    def _get_sorted_svg_files(self) -> list[Path]:
        """
        Gets a sorted list of SVG files from the output directory.

        Returns:
            A list of Path objects for SVG files, sorted by page number.
        """
        if not self.output_path or not self.output_path.exists():
            return []

        # Finds all SVG files matching the pattern p*.svg
        svg_files = list(self.output_path.glob("p*.svg"))

        # Sorts by extracting the page number from the filename
        def get_page_number(path: Path) -> int:
            """Extracts the page number from a filename like 'p1.svg'."""
            try:
                # Removes 'p' prefix and '.svg' suffix, then converts to int
                name = path.stem  # Gets filename without extension (e.g., "p1")
                if name.startswith('p'):
                    return int(name[1:])  # Removes 'p' and converts to int
                return 0
            except (ValueError, IndexError):
                return 0

        svg_files.sort(key=get_page_number)
        return svg_files

    def _build_urls_with_cache_busting(self, files: list[Path]) -> tuple[list[str], int]:
        """
        Builds file:// URLs with per-file cache busting timestamps.

        Only files that have been modified get new timestamps, so only those
        images will reload in QML. Unchanged files keep their old timestamps
        and won't reload.

        Args:
            files: List of Path objects for SVG files

        Returns:
            Tuple containing:
            - List of file:// URLs with cache-busting query parameters
            - Index of the first file that changed (or -1 if none changed)
        """
        import time

        urls = []
        current_time = int(time.time() * 1000)  # Millisecond timestamp
        first_changed_index = -1

        for idx, file_path in enumerate(files):
            file_key = str(file_path)

            try:
                # Gets the current modification time of the file
                current_mtime = file_path.stat().st_mtime

                if file_key in self.file_timestamps:
                    stored_mtime, cache_buster = self.file_timestamps[file_key]

                    # Only updates cache buster if file was actually modified
                    if current_mtime != stored_mtime:
                        print(f"OutputMonitor: File modified - {file_path.name}")
                        cache_buster = current_time
                        self.file_timestamps[file_key] = (current_mtime, cache_buster)
                        if first_changed_index == -1:
                            first_changed_index = idx
                else:
                    # New file - initialize with current time
                    cache_buster = current_time
                    self.file_timestamps[file_key] = (current_mtime, cache_buster)
                    if first_changed_index == -1:
                        first_changed_index = idx

                # Builds URL with the file's specific cache buster
                url = f"file://{file_key}?t={cache_buster}"
                urls.append(url)

            except OSError:
                # Fallback: use current time as cache buster
                urls.append(f"file://{file_key}?t={current_time}")

        return urls, first_changed_index