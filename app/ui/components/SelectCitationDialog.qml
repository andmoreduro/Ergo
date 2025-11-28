import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: root
    title: qsTr("Select Citation")
    modal: true
    width: 600
    height: 500

    property var allEntries: []
    property string selectedKey: ""

    signal citationSelected(string citationKey)
    signal createNewReference()

    onOpened: {
        allEntries = bibliographyManager.get_entries();
        listView.currentIndex = -1;
        selectedKey = "";
        searchField.text = "";
        searchField.forceActiveFocus();
    }

    footer: DialogButtonBox {
        Button {
            text: qsTr("Insert")
            enabled: listView.currentIndex !== -1
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            onClicked: {
                if (listView.currentIndex !== -1) {
                    root.citationSelected(selectedKey);
                    root.accept();
                }
            }
        }
        Button {
            text: qsTr("Create New...")
            onClicked: {
                root.createNewReference()
                root.close()
            }
        }
        Item { Layout.fillWidth: true } // Spacer
        Button {
            text: qsTr("Cancel")
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
        }
    }

    contentItem: ColumnLayout {
        spacing: 10

        TextField {
            id: searchField
            Layout.fillWidth: true
            placeholderText: qsTr("Search by author, title, or key...")
            font.italic: true
        }

        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            
            model: {
                var filter = searchField.text.toLowerCase();
                if (filter === "") {
                    return root.allEntries;
                }
                return root.allEntries.filter(function(entry) {
                    return (entry.ID || "").toLowerCase().includes(filter) ||
                           (entry.author || "").toLowerCase().includes(filter) ||
                           (entry.title || "").toLowerCase().includes(filter);
                });
            }

            onCurrentIndexChanged: {
                if (currentIndex !== -1) {
                    var currentItem = model[currentIndex];
                    if (currentItem) {
                        selectedKey = currentItem.ID;
                    }
                } else {
                    selectedKey = "";
                }
            }

            delegate: ItemDelegate {
                width: listView.width
                highlighted: ListView.isCurrentItem

                MouseArea {
                    anchors.fill: parent
                    propagateComposedEvents: true // Allow other MouseAreas to process the event
                    onClicked: (mouse) => {
                        // Manually set the index and let the event propagate
                        listView.currentIndex = index;
                        mouse.accepted = false; 
                    }
                    onDoubleClicked: {
                        if (listView.currentIndex !== -1) {
                            root.citationSelected(root.selectedKey);
                            root.accept();
                        }
                    }
                }

                contentItem: ColumnLayout {
                    spacing: 2
                    Label {
                        text: modelData.ID || "No Key"
                        font.bold: true
                        color: highlighted ? root.palette.highlightedText : root.palette.text
                    }
                    Label {
                        text: (modelData.author || "Unknown Author")
                        font.pointSize: 9
                        color: highlighted ? root.palette.highlightedText : root.palette.text
                        opacity: 0.8
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Label {
                        text: (modelData.title || "No Title")
                        font.pointSize: 9
                        font.italic: true
                        color: highlighted ? root.palette.highlightedText : root.palette.text
                        opacity: 0.7
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }

            ScrollIndicator.vertical: ScrollIndicator { }
            
            Label {
                anchors.centerIn: parent
                text: qsTr("No references found")
                visible: listView.count === 0
                opacity: 0.5
            }
        }
    }
}