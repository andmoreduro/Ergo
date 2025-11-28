"""
Defines the ProcessManager for handling the Typst watch process.

This module manages the background Typst compiler process that watches
the main.typ file and automatically regenerates the PDF output when changes
are detected.
"""
import sys
import platform
import shutil
from pathlib import Path

from PySide6.QtCore import QObject, QProcess, QUrl, Signal, Slot


class ProcessManager(QObject):
    """
    Manages the Typst watch background process.

    This class handles the logic for finding the correct platform-specific
    Typst executable, starting it in watch mode, stopping it, and capturing
    its output. The watch mode continuously monitors main.typ and regenerates
    the PDF to output/p{n}.pdf on any changes.
    """

    # Signal emitted when the process outputs to stdout
    processOutput = Signal(str)

    # Signal emitted when the process outputs to stderr
    processError = Signal(str)

    # Signal emitted when the process starts successfully
    processStarted = Signal()

    # Signal emitted when the process stops
    processStopped = Signal()

    # Signal for PDF export completion
    pdfExportFinished = Signal(bool, str)  # success: bool, message: str

    def __init__(self, parent=None):
        """Initializes the ProcessManager and its internal QProcess instance."""
        super().__init__(parent)
        self.process = QProcess()
        self.project_path = None

        # Connects process signals to handlers
        self.process.readyReadStandardOutput.connect(self._handle_stdout)
        self.process.readyReadStandardError.connect(self._handle_stderr)
        self.process.started.connect(self._handle_started)
        self.process.finished.connect(self._handle_finished)
        self.process.errorOccurred.connect(self._handle_error)

    def _get_typst_executable_path(self):
        """
        Determines the absolute path to the platform-specific Typst executable.

        Constructs the path based on the current operating system and architecture,
        looking inside the application's 'bin' directory. Returns None if the
        executable cannot be found.
        """
        os_name = sys.platform

        # Normalizes the architecture string to handle variations like 'AMD64'.
        arch = platform.machine()
        if arch.upper() in ['AMD64', 'X86_64']:
            arch = 'x86_64'

        if os_name.startswith('linux'):
            platform_dir = f"linux-{arch}"
            executable_name = "typst_0.14.0"
        elif os_name == 'win32':
            platform_dir = f"windows-{arch}"
            executable_name = "typst_0.14.0.exe"
        else:
            # Handles unsupported operating systems.
            print(f"Error: Unsupported operating system '{os_name}'.")
            return None

        # The path is built relative to this script's location. Assumes this
        # file is in 'app/backend/', so it navigates up to the 'app/' root.
        base_path = Path(__file__).resolve().parent.parent
        executable_path = base_path / "bin" / platform_dir / executable_name

        if not executable_path.is_file():
            print(f"Error: Typst executable not found at '{executable_path}'.")
            return None

        return str(executable_path)

    @Slot(str)
    def set_project_path(self, project_path: str):
        """
        Sets the project path where the Typst process will run.

        Args:
            project_path: The absolute path to the project directory containing main.typ
        """
        self.project_path = project_path
        print(f"ProcessManager: Project path set to '{project_path}'")

    @Slot()
    def start_typst_watch(self):
        """
        Starts the Typst watch process for the current project.

        The process watches main.typ and automatically regenerates the PDF
        to output/p{n}.pdf whenever changes are detected.
        """
        # Prevents attempting to start a process that is already active.
        if self.process.state() != QProcess.ProcessState.NotRunning:
            print("Warning: Typst watch process is already running.")
            return

        if not self.project_path:
            print("Error: Cannot start Typst watch - project path not set.")
            return

        executable_path = self._get_typst_executable_path()
        if not executable_path:
            return

        # Sets the working directory to the project path
        self.process.setWorkingDirectory(self.project_path)

        # Arguments for typst watch: typst watch main.typ output/p{p}.svg
        # {p} is replaced by Typst with the page number
        arguments = ["watch", "main.typ", "output/p{p}.svg"]

        print(f"Starting Typst watch process...")
        print(f"  Executable: {executable_path}")
        print(f"  Working directory: {self.project_path}")
        print(f"  Arguments: {arguments}")

        self.process.start(executable_path, arguments)

    @Slot()
    def stop_process(self):
        """Stops the Typst watch process if it is running."""
        # Checks if the process is active before attempting to terminate it.
        if self.process.state() != QProcess.ProcessState.NotRunning:
            print("Stopping Typst watch process...")
            self.process.terminate()
            
            # A timeout is given to allow for a graceful shutdown. If the
            # process does not terminate in time, it is forcefully killed.
            if not self.process.waitForFinished(2000):  # 2-second timeout
                print("Warning: Process did not terminate gracefully, killing...")
                self.process.kill()
                self.process.waitForFinished(1000)  # Wait for kill to complete
        else:
            print("No Typst watch process is running.")

    @Slot(result=bool)
    def is_running(self):
        """
        Checks if the Typst watch process is currently running.

        Returns:
            True if the process is running, False otherwise.
        """
        return self.process.state() != QProcess.ProcessState.NotRunning

    @Slot(str)
    def export_pdf(self, destination_folder_url: str):
        """
        Asynchronously compiles the project to PDF and moves it to a destination.

        Args:
            destination_folder_url: The file URL of the folder to save the PDF in.
        """
        if not self.project_path:
            self.pdfExportFinished.emit(False, "Project path not set.")
            return

        executable_path = self._get_typst_executable_path()
        if not executable_path:
            self.pdfExportFinished.emit(False, "Typst executable not found.")
            return

        try:
            dest_folder = Path(QUrl(destination_folder_url).toLocalFile())
            if not dest_folder.is_dir():
                self.pdfExportFinished.emit(False, "Destination is not a valid folder.")
                return
        except Exception as e:
            self.pdfExportFinished.emit(False, f"Invalid destination path: {e}")
            return

        # Define source and final destination paths
        output_dir = Path(self.project_path) / "output"
        output_dir.mkdir(exist_ok=True)
        source_pdf = output_dir / "main.pdf"
        final_dest_pdf = dest_folder / f"{Path(self.project_path).name}.pdf"

        # Use a new QProcess instance for export to not interfere with the watch process
        export_process = QProcess()
        export_process.setWorkingDirectory(self.project_path)
        
        # Arguments: typst compile main.typ output/main.pdf
        arguments = ["compile", "main.typ", str(source_pdf)]

        # This handler will be called when the export process finishes
        def on_finished(exit_code, exit_status):
            if exit_status == QProcess.ExitStatus.NormalExit and exit_code == 0:
                # Check if PDF exists
                if source_pdf.exists():
                    try:
                        # Move the file
                        shutil.move(str(source_pdf), str(final_dest_pdf))
                        self.pdfExportFinished.emit(True, f"Successfully exported to:\n{final_dest_pdf}")
                    except Exception as e:
                        self.pdfExportFinished.emit(False, f"Failed to move PDF: {e}")
                else:
                    self.pdfExportFinished.emit(False, "Typst reported success, but PDF file was not found.")
            else:
                error_output = export_process.readAllStandardError().data().decode('utf-8', errors='replace')
                self.pdfExportFinished.emit(False, f"PDF export failed.\n\nError:\n{error_output}")
            
            export_process.deleteLater() # Clean up the process object

        export_process.finished.connect(on_finished)
        export_process.start(executable_path, arguments)

    def _handle_stdout(self):
        """Handles standard output from the Typst process."""
        data = self.process.readAllStandardOutput()
        output = bytes(data).decode('utf-8', errors='replace')
        
        if output.strip():
            print(f"Typst output: {output.strip()}")
            self.processOutput.emit(output)

    def _handle_stderr(self):
        """Handles standard error output from the Typst process."""
        data = self.process.readAllStandardError()
        error = bytes(data).decode('utf-8', errors='replace')
        
        if error.strip():
            # Filters out routine watch status messages
            error_text = error.strip()
            if not error_text.startswith("watching ") and not error_text.startswith("writing to "):
                print(f"Typst: {error_text}")
            self.processError.emit(error)

    def _handle_started(self):
        """Handles the process started event."""
        print("Typst watch process started successfully.")
        self.processStarted.emit()

    def _handle_finished(self, exit_code, exit_status):
        """
        Handles the process finished event.

        Args:
            exit_code: The exit code of the process
            exit_status: The exit status (normal or crashed)
        """
        print(f"Typst watch process finished. Exit code: {exit_code}, Status: {exit_status}")
        self.processStopped.emit()

    def _handle_error(self, error):
        """
        Handles process errors.

        Args:
            error: The QProcess.ProcessError enum value
        """
        error_messages = {
            QProcess.ProcessError.FailedToStart: "Failed to start (executable not found or insufficient permissions)",
            QProcess.ProcessError.Crashed: "Process crashed",
            QProcess.ProcessError.Timedout: "Process timed out",
            QProcess.ProcessError.WriteError: "Write error",
            QProcess.ProcessError.ReadError: "Read error",
            QProcess.ProcessError.UnknownError: "Unknown error",
        }
        
        error_msg = error_messages.get(error, "Unknown error")
        print(f"Typst process error: {error_msg}")
        self.processError.emit(f"Process error: {error_msg}")