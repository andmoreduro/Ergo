"""
Main entry point for the Ergo application.

This script initializes the Qt application, sets up the QML engine, handles
internationalization, and loads the main user interface defined in main.qml.
"""

import sys
from pathlib import Path

from PySide6.QtCore import QLocale, QTranslator
from PySide6.QtGui import QSurfaceFormat
from PySide6.QtQml import QQmlApplicationEngine, qmlRegisterType
from PySide6.QtQuickControls2 import QQuickStyle
from PySide6.QtWidgets import QApplication

from .backend.apa7_form_handler import Apa7FormHandler
from .backend.output_monitor import OutputMonitor
from .backend.process_manager import ProcessManager
from .backend.project_manager import ProjectManager
from .backend.settings_manager import SettingsManager
from .backend.svg_item import SvgItem


def main():
    """Initializes and runs the Qt application."""
    # Enable global antialiasing for QML (must be set before app creation)
    format = QSurfaceFormat()
    format.setSamples(4)
    QSurfaceFormat.setDefaultFormat(format)

    # --- Style Setup ---
    # Sets the Qt Quick Controls style based on the platform for better integration.
    # Enforce Fusion style with a light palette for a consistent, professional
    # look across all platforms (Windows, Linux, macOS).
    QQuickStyle.setStyle("Fusion")

    app = QApplication(sys.argv)

    # --- Backend Setup ---
    # Instantiates the managers that handle backend logic.
    process_manager = ProcessManager()
    settings_manager = SettingsManager()
    # ProjectManager receives the settings_manager to track recent projects.
    project_manager = ProjectManager(settings_manager=settings_manager)
    # Apa7FormHandler manages generation of main.typ files for APA7 projects.
    apa7_form_handler = Apa7FormHandler()
    # OutputMonitor watches the output directory for generated SVG files.
    output_monitor = OutputMonitor()

    # Ensures the background process is terminated when the application quits.
    app.aboutToQuit.connect(process_manager.stop_process)

    # --- Internationalization Setup ---
    # Dynamically loads a translation file (.qm) based on the system's locale
    # to support multiple languages for the UI.
    translator = QTranslator()
    translations_path = Path(__file__).resolve().parent / "i18n"
    # Uses the base language code (e.g., "es" from "es_MX") for broad language matching.
    locale = QLocale.system().name().split("_")[0]
    if translator.load(f"{locale}", str(translations_path)):
        app.installTranslator(translator)

    # --- QML Engine Setup ---
    # Loads the main QML file that defines the user interface.
    engine = QQmlApplicationEngine()

    # Register custom types
    qmlRegisterType(SvgItem, "Ergo", 1, 0, "SvgItem")

    # Exposes the manager instances to the QML context, allowing the UI to
    # call their methods.
    engine.rootContext().setContextProperty("processManager", process_manager)
    engine.rootContext().setContextProperty("projectManager", project_manager)
    engine.rootContext().setContextProperty("settingsManager", settings_manager)
    engine.rootContext().setContextProperty("apa7FormHandler", apa7_form_handler)
    engine.rootContext().setContextProperty("outputMonitor", output_monitor)

    # The main QML file that defines the user interface.
    qml_file = Path(__file__).resolve().parent / "ui" / "main.qml"
    engine.load(qml_file)

    # Critical check: if the QML engine fails to load, it likely indicates a
    # syntax error in the QML. The application cannot run in this state.
    if not engine.rootObjects():
        sys.exit(-1)

    # Hands control over to the Qt event loop until the application is closed.
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
