import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Dialog {
    id: root
    title: qsTr("Add Reference")
    modal: true
    width: 450
    
    signal referenceAdded()

    onOpened: {
        // Reset fields
        typeCombo.currentIndex = 0
        keyField.text = ""
        titleField.text = ""
        authorField.text = ""
        yearField.text = ""
        publisherField.text = ""
        journalField.text = ""
        doiField.text = ""
        urlField.text = ""
    }

    footer: DialogButtonBox {
        Button {
            text: qsTr("Add")
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            enabled: keyField.text.length > 0 && titleField.text.length > 0
        }
        Button {
            text: qsTr("Cancel")
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
        }
        onAccepted: {
            var fields = {}
            if (titleField.text) fields["title"] = titleField.text
            if (authorField.text) fields["author"] = authorField.text
            if (yearField.text) fields["date"] = yearField.text // BibLaTeX uses 'date' or 'year'
            if (publisherField.visible && publisherField.text) fields["publisher"] = publisherField.text
            if (journalField.visible && journalField.text) fields["journaltitle"] = journalField.text // BibLaTeX prefers journaltitle
            if (doiField.text) fields["doi"] = doiField.text
            if (urlField.text) fields["url"] = urlField.text
            
            bibliographyManager.add_entry(typeCombo.currentValue, keyField.text, fields)
            root.referenceAdded()
            root.close()
        }
        onRejected: root.close()
    }

    contentItem: ColumnLayout {
        spacing: 10
        
        // Type
        RowLayout {
            Label { text: qsTr("Type"); Layout.preferredWidth: 100 }
            ComboBox {
                id: typeCombo
                Layout.fillWidth: true
                textRole: "text"
                valueRole: "value"
                model: [
                    { text: "Article", value: "article" },
                    { text: "Book", value: "book" },
                    { text: "In Collection", value: "incollection" },
                    { text: "Web Page", value: "online" },
                    { text: "Report", value: "report" },
                    { text: "Thesis", value: "thesis" },
                    { text: "Misc", value: "misc" }
                ]
            }
        }

        // Key
        RowLayout {
            Label { text: qsTr("Citation Key"); Layout.preferredWidth: 100 }
            TextField {
                id: keyField
                Layout.fillWidth: true
                placeholderText: qsTr("e.g. Smith2023")
                selectByMouse: true
            }
        }
        
        Rectangle { 
            Layout.fillWidth: true; height: 1; color: root.palette.mid; opacity: 0.5 
            Layout.topMargin: 5; Layout.bottomMargin: 5
        }

        // Title
        RowLayout {
            Label { text: qsTr("Title"); Layout.preferredWidth: 100 }
            TextField {
                id: titleField
                Layout.fillWidth: true
                placeholderText: qsTr("Title of the work")
                selectByMouse: true
            }
        }

        // Author
        RowLayout {
            Label { text: qsTr("Author(s)"); Layout.preferredWidth: 100 }
            TextField {
                id: authorField
                Layout.fillWidth: true
                placeholderText: qsTr("Smith, John and Doe, Jane")
                selectByMouse: true
            }
        }

        // Year
        RowLayout {
            Label { text: qsTr("Year"); Layout.preferredWidth: 100 }
            TextField {
                id: yearField
                Layout.fillWidth: true
                placeholderText: qsTr("2023")
                validator: IntValidator { bottom: 0; top: 9999 }
                selectByMouse: true
            }
        }

        // Publisher (Books, etc)
        RowLayout {
            visible: ["book", "incollection", "report", "thesis", "misc"].includes(typeCombo.currentValue)
            Label { text: qsTr("Publisher"); Layout.preferredWidth: 100 }
            TextField {
                id: publisherField
                Layout.fillWidth: true
                placeholderText: qsTr("Publisher name")
                selectByMouse: true
            }
        }
        
        // Journal (Articles)
        RowLayout {
            visible: typeCombo.currentValue === "article"
            Label { text: qsTr("Journal"); Layout.preferredWidth: 100 }
            TextField {
                id: journalField
                Layout.fillWidth: true
                placeholderText: qsTr("Journal Name")
                selectByMouse: true
            }
        }

        // DOI
        RowLayout {
            Label { text: qsTr("DOI"); Layout.preferredWidth: 100 }
            TextField {
                id: doiField
                Layout.fillWidth: true
                placeholderText: qsTr("10.xxxx/xxxxx")
                selectByMouse: true
            }
        }

        // URL
        RowLayout {
            Label { text: qsTr("URL"); Layout.preferredWidth: 100 }
            TextField {
                id: urlField
                Layout.fillWidth: true
                placeholderText: qsTr("https://...")
                selectByMouse: true
            }
        }
    }
}