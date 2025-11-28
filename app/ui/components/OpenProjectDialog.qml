import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Dialog {
    id: root
    title: qsTr("Open Project")
    modal: true
    width: 500
    
    signal projectSelected(string path)

    contentItem: ColumnLayout {
        spacing: 10

        // Recent Projects Component
        // Automatically manages its own visibility based on list count.
        // It includes a header ("Recent Projects") and a Clear button.
        RecentProjectsView {
            id: recentView
            Layout.fillWidth: true
            
            onProjectOpened: (projectPath) => {
                root.projectSelected(projectPath)
                root.close()
            }
        }

        // Fallback view when no recent projects exist
        Item {
            visible: !recentView.visible
            Layout.fillWidth: true
            Layout.preferredHeight: 150
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 10
                
                Label {
                    text: qsTr("No recent projects")
                    font.bold: true
                    font.pointSize: 12
                    Layout.alignment: Qt.AlignHCenter
                    color: root.palette.text
                    opacity: 0.5
                }
                
                Label {
                    text: qsTr("Projects you open will appear here.")
                    Layout.alignment: Qt.AlignHCenter
                    color: root.palette.text
                    opacity: 0.4
                }
            }
        }
        
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: root.palette.mid
            opacity: 0.3
            Layout.topMargin: 5
            Layout.bottomMargin: 5
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 5
            
            Label {
                text: qsTr("Open from disk:")
                opacity: 0.7
            }
            
            Item { Layout.fillWidth: true }
            
            Button {
                text: qsTr("Browse Folder...")
                highlighted: true
                onClicked: {
                    var folder = projectManager.select_folder()
                    if (folder !== "") {
                        root.projectSelected(folder)
                        root.close()
                    }
                }
            }
        }
    }

    footer: DialogButtonBox {
        Button {
            text: qsTr("Cancel")
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
        }
        onRejected: root.close()
    }
}