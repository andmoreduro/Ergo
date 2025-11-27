import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"

Item {
    id: initialView

    // This component is the initial welcome screen.
    // It displays a welcome message and a list of recent projects for quick access.

    ColumnLayout {
        id: mainLayout
        anchors.centerIn: initialView
        width: initialView.width * 0.6
        spacing: 20

        Label {
            id: welcomeLabel
            text: qsTr("Welcome to Ergo")
            font.pointSize: 24
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        Label {
            id: subtitleLabel
            text: qsTr("Create or open a project to get started.")
            font.pointSize: 14
            Layout.alignment: Qt.AlignHCenter
            color: initialView.palette.text
            opacity: 0.7
        }

        RecentProjectsView {
            id: recentProjectsView
            onProjectOpened: {
                var mainWindow = initialView.Window.window;
                if (mainWindow && mainWindow.openProject) {
                    mainWindow.openProject(projectPath);
                }
            }
        }

        // Instructions when no recent projects exist
        Label {
            id: noProjectsLabel
            text: qsTr("No recent projects. Use File → New Ergo project to get started.")
            font.pointSize: 12
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 30
            color: initialView.palette.text
            opacity: 0.7
            visible: !recentProjectsView.visible
        }
    }
}