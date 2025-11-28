import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import "components"

ApplicationWindow {
    id: root
    title: qsTr("Ergo")
    width: 800
    height: 600
    visible: true
    color: root.palette.window

    property string projectLocation: ""
    property string selectedTemplate: ""
    property bool projectActive: false

    menuBar: MenuBar {
        id: mainMenuBar

        Menu {
            id: fileMenu
            title: qsTr("File")

            Action {
                id: newProjectAction
                text: qsTr("New Ergo project")
                onTriggered: {
                    var folder = projectManager.select_folder();
                    if (folder !== "") {
                        root.projectLocation = folder;
                        root.selectedTemplate = "apa7";
                        projectManager.create_project(root.projectLocation, root.selectedTemplate);
                        apa7FormHandler.set_project_path(root.projectLocation);
                        processManager.set_project_path(root.projectLocation);
                        processManager.start_typst_watch();
                        outputMonitor.set_project_path(root.projectLocation);
                        viewLoader.source = "ProjectView.qml";
                        root.projectActive = true;
                    }
                }
            }

            Action {
                id: openProjectAction
                text: qsTr("Open Ergo project")
                onTriggered: {
                    var folder = projectManager.select_folder();
                    if (folder !== "") {
                        openProject(folder);
                    }
                }
            }
        }

        Menu {
            id: projectMenu
            title: qsTr("Project")
            enabled: root.projectActive

            Action {
                id: projectOptionsAction
                text: qsTr("Options")
                onTriggered: {
                    var form = viewLoader.item ? viewLoader.item.formItem : null;
                    if (form) {
                        projectSettingsDialog.fontFamily = form.fontFamily;
                        projectSettingsDialog.fontSize = form.fontSize;
                        projectSettingsDialog.paperSize = form.paperSize;
                        projectSettingsDialog.region = form.region;
                        projectSettingsDialog.language = form.language;
                        projectSettingsDialog.implicitIntroductionHeading = form.implicitIntroductionHeading;
                        projectSettingsDialog.abstractAsDescription = form.abstractAsDescription;
                        projectSettingsDialog.open();
                    }
                }
            }
        }
    }

    Loader {
        id: viewLoader
        anchors.fill: parent
        source: "InitialView.qml"

        onLoaded: {
            // Passes properties to the newly loaded view
            if (viewLoader.item) {
                if (viewLoader.item.hasOwnProperty("templateName")) {
                    viewLoader.item.templateName = root.selectedTemplate;
                }
                if (viewLoader.item.hasOwnProperty("projectLocation")) {
                    viewLoader.item.projectLocation = root.projectLocation;
                }
            }

            // If we just loaded the project view, explicitly tell the form to load its data.
            // This is more reliable than Component.onCompleted for new projects.
            if (source.toString().endsWith("ProjectView.qml")) {
                var form = viewLoader.item ? viewLoader.item.formItem : null;
                if (form && form.loadSavedData) {
                    // Use a short timer to ensure the form item is fully constructed
                    // before we try to call its functions. This resolves race conditions.
                    Qt.callLater(form.loadSavedData);
                }
            }
        }
    }

    // Function to open a project from recent projects list
    function openProject(projectPath) {
        if (!projectManager.check_project_exists(projectPath)) {
            projectNotFoundDialog.text = qsTr("The project directory could not be found:\n") + projectPath + qsTr("\n\nIt may have been moved or deleted.");
            projectNotFoundDialog.open();
            return;
        }

        root.projectLocation = projectPath;
        root.selectedTemplate = "apa7"; // TODO: Detect template type from project
        apa7FormHandler.set_project_path(projectPath);
        processManager.set_project_path(projectPath);
        processManager.start_typst_watch();
        outputMonitor.set_project_path(projectPath);
        viewLoader.source = "ProjectView.qml";
        root.projectActive = true;
    }



    ProjectSettingsDialog {
        id: projectSettingsDialog
        parent: Overlay.overlay
        anchors.centerIn: parent
        onAccepted: {
            var form = viewLoader.item ? viewLoader.item.formItem : null;
            if (form) {
                form.fontFamily = projectSettingsDialog.fontFamily;
                form.fontSize = projectSettingsDialog.fontSize;
                form.paperSize = projectSettingsDialog.paperSize;
                form.region = projectSettingsDialog.region;
                form.language = projectSettingsDialog.language;
                form.implicitIntroductionHeading = projectSettingsDialog.implicitIntroductionHeading;
                form.abstractAsDescription = projectSettingsDialog.abstractAsDescription;

                if (form.scheduleUpdate) form.scheduleUpdate();
            }
        }
    }

    MessageDialog {
        id: projectNotFoundDialog
        title: qsTr("Project Not Found")
        buttons: MessageDialog.Ok
    }
}
