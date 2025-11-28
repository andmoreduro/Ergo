import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    
    property var formItem: null
    property int refreshTrigger: 0

    Connections {
        target: formItem
        ignoreUnknownSignals: true
        function onSectionTitleChanged() {
            root.refreshTrigger += 1
        }
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        spacing: 0

        TabBar {
            id: sidebarTabs
            Layout.fillWidth: true
            
            TabButton {
                text: qsTr("Structure")
            }
            TabButton {
                text: qsTr("References")
            }
        }

        StackLayout {
            currentIndex: sidebarTabs.currentIndex
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            // --- Tab 1: Structure ---
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: structureList
                    anchors.fill: parent
                    clip: true
                    
                    model: {
                        root.refreshTrigger
                        return formItem ? formItem.sections : []
                    }
                    
                    delegate: ItemDelegate {
                        width: structureList.width
                        text: (modelData.title || qsTr("Untitled Section")) + (modelData.isImplicit ? qsTr(" (Intro)") : "")
                        font.bold: modelData.isImplicit || false
                        leftPadding: 10 + ((modelData.level || 1) - 1) * 15
                        
                        background: Rectangle {
                            color: parent.hovered ? root.palette.midlight : "transparent"
                            opacity: 0.3

                            Repeater {
                                model: (modelData.level || 1) - 1
                                delegate: Rectangle {
                                    width: 1
                                    height: parent.height
                                    color: root.palette.text
                                    opacity: 0.5
                                    x: 10 + index * 15
                                }
                            }
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

            // --- Tab 2: References ---
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                Label {
                    anchors.centerIn: parent
                    text: qsTr("Bibliography Manager\n(Empty)")
                    horizontalAlignment: Text.AlignHCenter
                    opacity: 0.5
                }
            }
        }
    }
}