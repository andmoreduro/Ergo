import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Displays a scrollable, vertical list of images.
ScrollView {
    id: root

    // Prevent images from rendering outside the component's boundaries.
    clip: true

    // Provides a consistent margin around the content.
    leftPadding: 50
    rightPadding: 50
    topPadding: 50

    // --- Public API ---
    // These properties are set by the parent to control the displayed content.

    // Absolute path to the project directory, used as a base for image paths.
    property string projectPath: ""

    // List of image file paths, relative to `projectPath`.
    property var relativeImageSources: []

    // --- Internal Logic ---
    // Transforms the relative image paths into a list of full, loadable file URLs
    // to be used as the model for the Repeater.
    readonly property var fullImagePaths: {
        // Guard against an unset project path.
        if (!projectPath || projectPath === "") return [];

        return relativeImageSources.map(function(fileName) {
            // Prepend the "file:///" prefix required for local file access.
            return "file:///" + projectPath + "/" + fileName;
        });
    }

    ColumnLayout {
        // Bind the width to the parent's available width to respect its padding.
        width: root.availableWidth
        spacing: 10 // Vertical spacing between each image.

        // Dynamically generate an Image component for each path in the model.
        Repeater {
            model: root.fullImagePaths

            // The delegate is the template for each dynamically created image.
            delegate: Item {
                Layout.fillWidth: true

                // DEV-NOTE: Height is calculated from the image's aspect ratio
                // and available width. This avoids a circular binding dependency
                // that would occur if binding to `paintedHeight`.
                Layout.preferredHeight: imageContent.sourceSize.width > 0 ? (width / imageContent.sourceSize.width * imageContent.sourceSize.height) : 0

                Image {
                    id: imageContent
                    anchors.fill: parent
                    source: modelData // Provided by the Repeater.

                    fillMode: Image.PreserveAspectFit
                    asynchronous: true // Prevent UI freeze while loading large images.
                }
            }
        }
    }
}