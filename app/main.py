# This Python file uses the following encoding: utf-8
"""
Main entry point for the Ergo application.

This script initializes the Qt application, sets up the QML engine, handles
internationalization, and loads the main user interface defined in main.qml.
"""
import sys
from pathlib import Path

from PySide6.QtCore import QTranslator, QLocale
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine


def main():
    """Initializes and runs the Qt application."""
    app = QGuiApplication(sys.argv)

    # --- Internationalization Setup ---
    # Dynamically loads a translation file (.qm) based on the system's locale
    # to support multiple languages for the UI.
    translator = QTranslator()
    translations_path = Path(__file__).resolve().parent / "i18n"
    # Use the base language code (e.g., "es" from "es_MX") for broad language matching.
    locale = QLocale.system().name().split('_')[0]
    if translator.load(f"{locale}", str(translations_path)):
        app.installTranslator(translator)

    # --- QML Engine Setup ---
    # Loads the main QML file that defines the user interface.
    engine = QQmlApplicationEngine()
    qml_file = Path(__file__).resolve().parent / "main.qml"
    engine.load(qml_file)

    # Critical check: if the QML engine fails to load, it likely indicates a
    # syntax error in the QML. The application cannot run in this state.
    if not engine.rootObjects():
        sys.exit(-1)

    # Hand control over to the Qt event loop until the application is closed.
    sys.exit(app.exec())
