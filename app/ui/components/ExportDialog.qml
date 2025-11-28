import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: root
    title: qsTr("Export Project as PDF")
    modal: true
    width: 400

    // Properties to manage state and data
    property string destinationFolder: ""
    property string resultMessage: ""
    property bool exportSuccess: false
    property int currentState: 0 // 0: Ready, 1: Exporting, 2: Finished

    onOpened: {
        // Reset to initial state when dialog is shown
        currentState = 0
        destinationFolder = projectManager.get_documents_location()
        resultMessage = ""
        exportSuccess = false
    }

    // --- Content Area ---
    // Switches between the different states of the export process
    contentItem: StackLayout {
        currentIndex: root.currentState

        // --- State 0: Ready for user input ---
        ColumnLayout {
            spacing: 15
            
            Label {
                text: qsTr("Please select a destination folder for the PDF file.")
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                TextField {
                    id: folderField
                    Layout.fillWidth: true
                    readOnly: true
                    text: root.destinationFolder
                    placeholderText: qsTr("No folder selected")
                }
                Button {
                    text: qsTr("Browse...")
                    onClicked: {
                        var folder = projectManager.select_folder()
                        if (folder !== "") {
                            root.destinationFolder = folder
                        }
                    }
                }
            }
        }

        // --- State 1: Exporting (Busy) ---
        ColumnLayout {
            spacing: 20
            Layout.alignment: Qt.AlignHCenter
            
            BusyIndicator {
                running: root.currentState === 1
                Layout.alignment: Qt.AlignHCenter
            }
            Label {
                text: qsTr("Exporting PDF, please wait...")
                Layout.alignment: Qt.AlignHCenter
            }
        }

        // --- State 2: Finished (Success or Failure) ---
        ColumnLayout {
            spacing: 15

            Label {
                text: root.exportSuccess ? qsTr("Export Successful") : qsTr("Export Failed")
                font.bold: true
                font.pointSize: 14
                color: root.exportSuccess ? "green" : "red"
            }
            
            Label {
                text: root.resultMessage
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
    }

    // --- Footer Buttons ---
    // The footer changes based on the current state
    footer: DialogButtonBox {
        id: buttonBox

        // Buttons for the "Ready" state (State 0)
        Button {
            visible: root.currentState === 0
            text: qsTr("Export")
            enabled: root.destinationFolder !== ""
            // By omitting `DialogButtonBox.buttonRole`, we prevent the dialog from auto-closing
            // on click, allowing the result to be displayed.
            onClicked: {
                root.currentState = 1 // Switch to exporting view
                var folderUrl = Qt.resolvedUrl(root.destinationFolder)
                processManager.export_pdf(folderUrl.toString())
            }
        }
        Button {
            visible: root.currentState === 0
            text: qsTr("Cancel")
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            onClicked: root.close()
        }
        
        // Button for the "Finished" state (State 2)
        Button {
            visible: root.currentState === 2
            text: qsTr("Close")
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            onClicked: root.close()
        }
    }

    // --- Signal Handling ---
    // Listens for the completion signal from the backend
    Connections {
        target: processManager
        // This function MUST be named on<SignalName>
        function onPdfExportFinished(success, message) {
            console.log("ExportDialog: Received pdfExportFinished signal. Success: " + success);
            // This handler is called when the export process completes
            if (root.visible) {
                console.log("ExportDialog: Dialog is visible, updating state.");
                root.exportSuccess = success
                root.resultMessage = message
                root.currentState = 2 // Switch to the "Finished" view
                console.log("ExportDialog: State changed to " + root.currentState);
            } else {
                console.log("ExportDialog: Dialog is not visible, ignoring signal.");
            }
        }
    }
}