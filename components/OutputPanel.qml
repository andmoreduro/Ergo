import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    id: root
    clip: true

    // Set padding on the ScrollView directly. This is the idiomatic way
    // to create space around the scrollable content.
    leftPadding: 50
    rightPadding: 50
    topPadding: 50

    // Holds the absolute path to the root of the active project directory.
    // This path is used as the base for resolving relative image sources.
    // Example: "/home/user/Documents/MyProject"
    property string projectPath: ""

    // Holds a list of relative filenames for the images to be displayed.
    // Paths are resolved relative to the `projectPath`.
    // Example: ["assets/image1.svg", "assets/figure2.svg"]
    property var relativeImageSources: []

    // A read-only property that constructs a list of full, well-formed file URLs
    // by combining `projectPath` and `relativeImageSources`. This list serves as the
    // model for the Repeater.
    readonly property var fullImagePaths: {
        // Prevent errors if projectPath is not yet set.
        if (!projectPath || projectPath === "") return [];
        return relativeImageSources.map(function(fileName) {
            // Prepend the standard 'file:///' prefix for local file access.
            return "file:///" + projectPath + "/" + fileName;
        });
    }

    ColumnLayout {
        // The layout's width should track the available width of the ScrollView,
        // which automatically accounts for the padding we added above.
        width: root.availableWidth
        spacing: 10

        // Dynamically generates Image components based on the `fullImagePaths` model.
        Repeater {
            model: root.fullImagePaths

            delegate: Item {
                // The delegate is a lightweight container for the image.
                Layout.fillWidth: true
                // Calculate the required height to maintain the image's aspect ratio
                // based on the available width. This breaks the circular dependency
                // that occurs when using 'paintedHeight'.
                Layout.preferredHeight: imageContent.sourceSize.width > 0 ? (width / imageContent.sourceSize.width * imageContent.sourceSize.height) : 0

                Image {
                    id: imageContent
                    anchors.fill: parent
                    source: modelData
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }
            }
        }
    }
}