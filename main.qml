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

    // Properties that would typically be managed by a Python backend.
    // These are hardcoded for demonstration purposes.

    // Defines the absolute path to the currently active project directory.
    // This path is used by child components to resolve relative asset paths.
    // Example: "/home/user/projects/Ergo"
    property string currentProjectPath: "/home/andmoreduro/QtProjects/Ergo"

    // Defines the list of relative image filenames to be displayed.
    property var currentImageFiles: [
        "assets/placeholder.svg",
        "assets/placeholder.svg"
    ]

    SplitView {
        anchors.fill: parent
        orientation: Qt.Horizontal

        ScrollView {
            id: inputPanel
            SplitView.fillWidth: true
            SplitView.preferredWidth: parent.width / 2

            ColumnLayout {
                width: inputPanel.width

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

        OutputPanel {
            id: outputPanel
            SplitView.fillWidth: true
            SplitView.preferredWidth: parent.width / 2

            // Bind the component's properties to the main window's state.
            projectPath: currentProjectPath
            relativeImageSources: currentImageFiles
        }
    }
}
