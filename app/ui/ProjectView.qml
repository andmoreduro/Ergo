import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"

Item {
    id: projectView

    // This component encapsulates the main project editing interface with a
    // three-column layout: document structure, form inputs, and output preview.
    // All columns are user-resizable via SplitView handles.
    // The form in the middle column is dynamically loaded based on the template.

    property string templateName: ""
    property string projectLocation: ""
    property alias formItem: formLoader.item

    onProjectLocationChanged: {
        if (projectLocation !== "") {
            bibliographyManager.set_project_path(projectLocation)
        }
    }

    SplitView {
        id: mainSplitView
        anchors.fill: projectView
        orientation: Qt.Horizontal

        // --- First Column: Project Sidebar ---
        // Displays the hierarchical structure of the document and bibliography.
        ProjectSidebar {
            id: sidebar
            SplitView.fillWidth: false
            SplitView.preferredWidth: mainSplitView.width * 0.20
            SplitView.minimumWidth: 150
            formItem: projectView.formItem
        }

        // --- Second Column: Form Input Panel ---
        // Contains the template-specific form fields loaded dynamically.
        Item {
            id: inputPanel
            SplitView.fillWidth: true
            SplitView.minimumWidth: 300

            Loader {
                id: formLoader
                anchors.fill: inputPanel

                source: {
                    if (projectView.templateName === "") {
                        return "";
                    }
                    // Constructs the path to the template's form.qml file.
                    // The path is relative to the application's templates directory.
                    return "../templates/" + projectView.templateName + "/form.qml";
                }

                onStatusChanged: {
                    if (formLoader.status === Loader.Error) {
                        console.error("Failed to load form for template:", projectView.templateName);
                    } else if (formLoader.status === Loader.Ready) {
                        console.log("Successfully loaded form for template:", projectView.templateName);
                    }
                }

                Binding {
                    target: formLoader.item
                    property: "projectLocation"
                    value: projectView.projectLocation
                }
            }

            // Fallback message if no template is selected or form fails to load.
            Label {
                id: noFormLabel
                anchors.centerIn: inputPanel
                text: qsTr("No template selected or form unavailable")
                visible: formLoader.status !== Loader.Ready
                color: projectView.palette.text
                opacity: 0.7
            }
        }

        // --- Third Column: Output Preview Panel ---
        // Displays the rendered document output as images.
        OutputPanel {
            id: outputPanel
            SplitView.fillWidth: false
            SplitView.preferredWidth: mainSplitView.width * 0.45
            SplitView.minimumWidth: 150

            imageSources: outputMonitor ? outputMonitor.get_output_files() : []

            Connections {
                id: outputMonitorConnections
                target: outputMonitor
                enabled: outputMonitor !== null
                function onFilesChanged(files) {
                    outputPanel.imageSources = files;
                }
                function onActivePageChanged(index) {
                    outputPanel.scrollToPage(index);
                }
            }

            Component.onCompleted: {
                // Loads initial file list when panel is created
                if (outputMonitor) {
                    outputPanel.imageSources = outputMonitor.get_output_files();
                }
            }
        }
    }
}
