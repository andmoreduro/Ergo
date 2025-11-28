import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property var formItem: null
    property int refreshTrigger: 0
    property var bibliographyList: []

    Connections {
        target: bibliographyManager
        function onEntriesChanged(entries) {
            root.bibliographyList = entries
        }
    }

    Component.onCompleted: {
        if (typeof bibliographyManager !== "undefined") {
            root.bibliographyList = bibliographyManager.get_entries()
        }
    }

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
            Layout.preferredHeight: 40

            TabButton {
                text: qsTr("Structure")
                height: parent.height
                anchors.verticalCenter: parent.verticalCenter
            }
            TabButton {
                text: qsTr("References")
                height: parent.height
                anchors.verticalCenter: parent.verticalCenter
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

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    ListView {
                        id: bibList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: root.bibliographyList
                        spacing: 2

                        delegate: ItemDelegate {
                            width: bibList.width
                            height: contentCol.implicitHeight + 20

                            background: Rectangle {
                                color: parent.hovered ? root.palette.midlight : "transparent"
                                opacity: 0.3
                            }

                            contentItem: ColumnLayout {
                                id: contentCol
                                spacing: 2
                                Label {
                                    text: modelData.ID || "No Key"
                                    font.bold: true
                                    color: root.palette.text
                                }
                                Label {
                                    text: (modelData.author || "Unknown Author") + ". " + (modelData.title || "No Title")
                                    font.pointSize: 9
                                    color: root.palette.text
                                    opacity: 0.8
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                Label {
                                    text: modelData.ENTRYTYPE + " (" + (modelData.year || modelData.date || "????") + ")"
                                    font.pointSize: 8
                                    color: root.palette.text
                                    opacity: 0.6
                                }
                            }

                            Button {
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 5
                                text: "×"
                                flat: true
                                visible: parent.hovered
                                onClicked: bibliographyManager.remove_entry(modelData.ID)
                            }
                        }

                        Label {
                            anchors.centerIn: parent
                            text: qsTr("No references added")
                            visible: bibList.count === 0
                            opacity: 0.5
                        }

                        footer: Item {
                            width: bibList.width
                            height: 40
                            Button {
                                anchors.fill: parent
                                text: qsTr("+ Add Reference")
                                flat: true
                                onClicked: addRefDialog.open()
                            }
                        }
                    }

                    AddReferenceDialog {
                        id: addRefDialog
                        parent: Overlay.overlay
                        anchors.centerIn: parent
                    }
                }
            }
        }
    }
}
