import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Dialog {
    id: root
    title: qsTr("New Project")
    modal: true
    width: 500
    
    // Input properties
    property string projectName: ""
    property string projectLocation: ""
    property string selectedTemplate: ""
    
    // Computed property for UI display
    property string fullPath: ""
    
    // Validation: forbidden characters in directory names
    // < > : " / \ | ? * are generally unsafe across file systems
    readonly property var invalidChars: /[<>:"/\\|?*]/

    signal projectCreated(string path, string template)

    onOpened: {
        // Reset defaults
        nameField.text = ""
        // If location is not set, we leave it empty to force user selection
        // or it persists from previous opens if the parent didn't reset it.
        
        // Load available templates
        var templates = projectManager.get_available_templates()
        templateModel.clear()
        for (var i = 0; i < templates.length; i++) {
            templateModel.append({text: templates[i]})
        }
        if (templateModel.count > 0) {
            templateCombo.currentIndex = 0
            root.selectedTemplate = templateCombo.currentText
        }
        
        // Force update path
        updateFullPath()
    }

    // Custom Footer to handle validation state on the Create button
    footer: DialogButtonBox {
        Button {
            text: qsTr("Create")
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            enabled: nameField.text.length > 0 && 
                     !nameField.text.match(root.invalidChars) && 
                     root.projectLocation.length > 0
        }
        Button {
            text: qsTr("Cancel")
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
        }
        
        onAccepted: {
            root.accept()
        }
        onRejected: {
            root.reject()
        }
    }

    contentItem: ColumnLayout {
        spacing: 15
        
        // --- Project Name ---
        ColumnLayout {
            spacing: 5
            Label { 
                text: qsTr("Project Name") 
                font.bold: true
            }
            TextField {
                id: nameField
                Layout.fillWidth: true
                text: ""
                placeholderText: qsTr("Enter project name")
                selectByMouse: true
                
                onTextChanged: {
                    root.projectName = text
                    root.updateFullPath()
                }

                // Custom background to show validation error state
                background: Rectangle {
                    implicitWidth: 200
                    implicitHeight: 40
                    color: root.palette.base
                    border.color: nameField.activeFocus ? root.palette.highlight : 
                                  (nameField.text.match(root.invalidChars) ? "red" : root.palette.mid)
                    border.width: nameField.activeFocus ? 2 : 1
                    radius: 2
                }
            }
            Label {
                text: qsTr("Name contains invalid characters")
                color: "red"
                font.pointSize: 9
                visible: nameField.text.match(root.invalidChars)
            }
        }

        // --- Location ---
        ColumnLayout {
            spacing: 5
            Label { 
                text: qsTr("Location") 
                font.bold: true
            }
            RowLayout {
                TextField {
                    id: locationField
                    Layout.fillWidth: true
                    readOnly: true
                    placeholderText: qsTr("Select parent folder...")
                    text: root.projectLocation
                    
                    // Allow manual edit? No, safer to browse for directory validity.
                    // But we could allow it if we validate existence.
                }
                Button {
                    text: qsTr("Browse...")
                    onClicked: {
                        var folder = projectManager.select_folder()
                        if (folder !== "") {
                            root.projectLocation = folder
                            locationField.text = folder
                            root.updateFullPath()
                        }
                    }
                }
            }
        }

        // --- Template ---
        ColumnLayout {
            spacing: 5
            Label { 
                text: qsTr("Template") 
                font.bold: true
            }
            ComboBox {
                id: templateCombo
                Layout.fillWidth: true
                textRole: "text"
                model: ListModel { id: templateModel }
                onCurrentTextChanged: {
                    root.selectedTemplate = currentText
                }
            }
            
            // Template Description
            Label {
                text: projectManager ? projectManager.get_template_description(root.selectedTemplate) : ""
                font.italic: true
                color: root.palette.text
                opacity: 0.7
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }

        // --- Path Preview ---
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: root.palette.mid
            opacity: 0.5
            Layout.topMargin: 10
            Layout.bottomMargin: 5
        }
        
        ColumnLayout {
            spacing: 2
            Label {
                text: qsTr("The project will be created at:")
                opacity: 0.7
                font.pointSize: 10
            }
            Label {
                text: root.fullPath || qsTr("(Please set name and location)")
                font.bold: true
                font.pointSize: 11
                wrapMode: Text.WrapAnywhere
                Layout.fillWidth: true
                color: (root.fullPath.length > 0) ? root.palette.text : root.palette.mid
            }
        }
    }

    function updateFullPath() {
        if (projectLocation && projectName) {
            // Determine separator based on OS
            var sep = Qt.platform.os === "windows" ? "\\" : "/"
            
            var loc = projectLocation
            // Ensure trailing separator on location
            if (!loc.endsWith(sep) && !loc.endsWith("/") && !loc.endsWith("\\")) {
                loc += sep
            }
            
            // Normalize slashes for display consistency
            var path = loc + projectName
            if (Qt.platform.os === "windows") {
                path = path.replace(/\//g, "\\")
            }
            
            fullPath = path
        } else {
            fullPath = ""
        }
    }
}