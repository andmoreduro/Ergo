"""
Custom QML item for direct SVG rendering.

This module provides the SvgItem class, a QQuickPaintedItem subclass
that uses QSvgRenderer to render SVG content directly. This offers better
scaling quality than QML's Image component for vector graphics by avoiding
rasterization at fixed resolutions.
"""

from PySide6.QtCore import Property, QUrl, Signal
from PySide6.QtGui import QPainter
from PySide6.QtQuick import QQuickPaintedItem
from PySide6.QtSvg import QSvgRenderer


class SvgItem(QQuickPaintedItem):
    """
    A QML item that renders SVG files using QSvgRenderer.
    
    This component redraws the vector content whenever the item is resized,
    ensuring crisp edges at any zoom level. It replaces the standard Image
    element for SVG previewing purposes.
    
    Attributes:
        source (str): The URL or path to the SVG file.
    """

    # Signal emitted when the source property changes
    sourceChanged = Signal()

    def __init__(self, parent=None):
        """Initializes the SvgItem."""
        super().__init__(parent)
        self._source = ""
        self._renderer = QSvgRenderer()

        # Enable antialiasing for smoother vector lines
        self.setAntialiasing(True)
        
        # Render to an internal Image buffer (software rasterization).
        # This is generally performant for document viewing where the content
        # is static but the view transforms (zoom/pan) change.
        self.setRenderTarget(QQuickPaintedItem.RenderTarget.Image)
        self.setMipmap(True)

    def paint(self, painter: QPainter):
        """
        Paints the SVG content onto the item.
        
        Args:
            painter: The QPainter used for drawing.
        """
        if self._renderer.isValid():
            # Render the SVG into the full bounding rectangle of the item.
            # QSvgRenderer handles the scaling automatically based on the
            # target rectangle size.
            self._renderer.render(painter, self.boundingRect())

    @Property(str, notify=sourceChanged)
    def source(self):
        """Gets the source URL of the SVG."""
        return self._source

    @source.setter
    def source(self, value):
        """
        Sets the source URL of the SVG.
        
        Args:
            value: The new source URL.
        """
        if self._source == value:
            return

        self._source = value
        self.sourceChanged.emit()
        self._load_svg()

    def _load_svg(self):
        """Loads the SVG file from the source URL."""
        url_str = self._source
        path = url_str

        # Handle URL parsing to extract local file path
        if "file://" in url_str:
            qurl = QUrl(url_str)
            if qurl.isValid():
                path = qurl.toLocalFile()
        
        # Manually strip query parameters (like cache busters ?t=...)
        # if they weren't handled by QUrl (or if passed as raw string)
        if "?" in path:
            path = path.split("?")[0]

        if not path:
            return

        # Load the SVG data into the renderer
        if self._renderer.load(path):
            # Update the implicit size of the item to match the SVG's natural size
            default_size = self._renderer.defaultSize()
            self.setImplicitWidth(default_size.width())
            self.setImplicitHeight(default_size.height())
            
            # Force a repaint since the content has changed
            self.update()
        else:
            print(f"SvgItem: Failed to load SVG from {path}")