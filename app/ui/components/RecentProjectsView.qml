import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    Layout.fillWidth: true
    Layout.topMargin: 30
    spacing: 10
    visible: recentProjectsList.count > 0

    signal projectOpened(string projectPath)

    Label {
        id: recentProjectsTitle
        text: qsTr("Recent Projects")
        font.pointSize: 16
        font.bold: true
    }

    // Scrollable list of recent projects
    ScrollView {
        id: recentProjectsScrollView
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(recentProjectsList.count * 50, 300)
        clip: true

        ListView {
            id: recentProjectsList
            model: settingsManager ? settingsManager.get_recent_projects() : []
            spacing: 5

            Component.onCompleted: {
                // Refreshes the list when the component is created
                if (settingsManager) {
                    console.log("Loading recent projects...");
                    var projects = settingsManager.get_recent_projects();
                    console.log("Recent projects count:", projects.length);
                    recentProjectsList.model = projects;
                }
            }

            delegate: ItemDelegate {
                id: projectDelegate
                width: recentProjectsList.width
                height: 50

                required property string modelData
                required property int index

                background: Rectangle {
                    id: delegateBackground
                    color: projectDelegate.hovered ? root.palette.highlight : "transparent"
                    opacity: projectDelegate.hovered ? 0.1 : 1.0
                    radius: 4
                }

                contentItem: ColumnLayout {
                    id: delegateContent
                    spacing: 2

                    Label {
                        id: projectNameLabel
                        text: {
                            // Extracts the project name from the full path
                            var path = projectDelegate.modelData;
                            var parts = path.split('/');
                            if (parts.length === 0) {
                                parts = path.split('\\');
                            }
                            return parts[parts.length - 1] || path;
                        }
                        font.pointSize: 11
                        font.bold: true
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        color: root.palette.text
                    }

                    Label {
                        id: projectPathLabel
                        text: projectDelegate.modelData
                        font.pointSize: 9
                        color: root.palette.text
                        opacity: 0.7
                        elide: Text.ElideMiddle
                        Layout.fillWidth: true
                    }
                }

                onClicked: {
                    root.projectOpened(projectDelegate.modelData);
                }
            }
        }
    }

    // Clear recent projects button
    Button {
        id: clearRecentButton
        text: qsTr("Clear Recent Projects")
        Layout.alignment: Qt.AlignRight
        flat: true
        onClicked: {
            if (settingsManager) {
                settingsManager.clear_recent_projects();
                // Refreshes the list by reassigning the model
                recentProjectsList.model = settingsManager.get_recent_projects();
            }
        }
    }

    // Listens for changes to recent projects and refreshes the list
    Connections {
        id: settingsConnections
        target: settingsManager
        enabled: settingsManager !== null
        function onRecentProjectsChanged() {
            if (settingsManager) {
                recentProjectsList.model = settingsManager.get_recent_projects();
            }
        }
    }
}