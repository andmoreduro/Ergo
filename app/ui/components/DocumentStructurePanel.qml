import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    id: root
    
    property var formItem: null

    ColumnLayout {
        id: structureLayout
        width: root.width
        spacing: 10

        Label {
            id: structureTitle
            text: qsTr("Document Structure")
            font.bold: true
            font.pointSize: 12
            leftPadding: 5
        }

        ListView {
            id: structureList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            
            model: formItem ? formItem.sections : []
            
            delegate: ItemDelegate {
                width: structureList.width
                text: (modelData.title || qsTr("Untitled Section")) + (modelData.isImplicit ? qsTr(" (Intro)") : "")
                font.bold: modelData.isImplicit || false
                
                background: Rectangle {
                    color: parent.hovered ? root.palette.midlight : "transparent"
                    opacity: 0.3
                }
            }

            Label {
                anchors.centerIn: parent
                text: qsTr("No sections added")
                visible: structureList.count === 0
                opacity: 0.5
            }
        }
    }
}