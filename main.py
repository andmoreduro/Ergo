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
    # Initialize the core Qt application instance.
    app = QGuiApplication(sys.argv)

    # --- Internationalization Setup ---
    # Detects the system's locale and loads the corresponding translation file
    # from the 'i18n' directory to display the UI in the user's language.
    translator = QTranslator()
    translations_path = Path(__file__).resolve().parent / "i18n"
    # Use the base language code (e.g., "es" from "es_MX") for broad language matching.
    locale = QLocale.system().name().split('_')[0]
    if translator.load(f"{locale}", str(translations_path)):
        app.installTranslator(translator)

    # --- QML Engine Setup ---
    # The engine interprets QML code to create the hierarchy of UI objects.
    engine = QQmlApplicationEngine()
    qml_file = Path(__file__).resolve().parent / "main.qml"
    engine.load(qml_file)

    # If the QML engine fails to load any root objects, it signifies a critical
    # error (e.g., a syntax error in the QML file). The application cannot
    # proceed and exits immediately.
    if not engine.rootObjects():
        return -1

    # Start the Qt event loop. The application will block here until the user
    # closes the main window. The window's exit code is then returned.
    return app.exec()


if __name__ == "__main__":
    sys.exit(main())