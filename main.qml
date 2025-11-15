import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import "components"

Window {
    title: qsTr("Ergo")
    width: 800
    height: 600
    visible: true
    color: "white"

    // --- Backend Data Properties ---
    // DEV-NOTE: These properties are hardcoded for demonstration and should be
    // connected to a Python backend.

    // The absolute path to the project directory, used by child components to
    // resolve relative asset paths.
    property string currentProjectPath: "/home/andmoreduro/QtProjects/Ergo"

    // A list of image paths, relative to `currentProjectPath`, to be displayed.
    property var currentImageFiles: [
        "assets/placeholder.svg",
        "assets/placeholder.svg"
    ]

    // Divides the window into a resizable input form and output preview.
    SplitView {
        anchors.fill: parent
        orientation: Qt.Horizontal

        // Left Panel: Contains all user-editable fields for document metadata and content.
        ScrollView {
            id: inputPanel
            SplitView.fillWidth: true
            SplitView.preferredWidth: parent.width / 2

            // The width is bound to the parent to ensure the layout reflows
            // correctly when the splitter is moved.
            ColumnLayout {
                width: inputPanel.width

                // --- Title Page Section ---
                Label {
                    text: qsTr("Title Page")
                }

                Label {
                    text: qsTr("Title")
                }
                TextField {
                    Layout.fillWidth: true
                    placeholderText: qsTr("&lt;TITLE&gt;")
                }

                Label {
                    text: qsTr("Author")
                }
                TextField {
                    Layout.fillWidth: true
                    placeholderText: qsTr("&lt;AUTHOR&gt;")
                }

                Label {
                    text: qsTr("Affiliation")
                }
                TextField {
                    Layout.fillWidth: true
                    placeholderText: qsTr("&lt;AFFILIATION&gt;")
                }

                Label {
                    text: qsTr("Course")
                }
                TextField {
                    Layout.fillWidth: true
                    placeholderText: qsTr("&lt;COURSE&gt;")
                }

                Label {
                    text: qsTr("Professor")
                }
                TextField {
                    Layout.fillWidth: true
                    placeholderText: qsTr("&lt;PROFESSOR&gt;")
                }

                Label {
                    text: qsTr("Due Date")
                }
                TextField {
                    Layout.fillWidth: true
                    placeholderText: qsTr("&lt;DUE_DATE&gt;")
                }

                Label {
                    text: qsTr("Content")
                }

                // A preferred height is set to prevent the content area from
                // initially dominating the layout.
                ScrollView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 200
                    ScrollBar.horizontal.policy: ScrollBar.AsNeeded
                    ScrollBar.vertical.policy: ScrollBar.AlwaysOff

                    TextArea {
                        topInset: 0
                        placeholderText: qsTr("&lt;CONTENT&gt;")
                        wrapMode: Text.WordWrap
                        background: Rectangle {
                            color: "#141618"
                        }
                    }
                }
            }
        }

        // Right Panel: Displays the rendered output. This is a custom
        // component defined in 'components/OutputPanel.qml'.
        OutputPanel {
            id: outputPanel
            SplitView.fillWidth: true
            SplitView.preferredWidth: parent.width / 2

            // Pass the main window's data down to the output panel.
            projectPath: currentProjectPath
            relativeImageSources: currentImageFiles
        }
    }
}
