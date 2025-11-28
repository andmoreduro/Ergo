import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: projectSettingsDialog

    // This dialog provides access to project-wide formatting settings
    // for the APA template, matching the versatile-apa package options.

    title: qsTr("Project Settings")
    modal: true
    standardButtons: Dialog.Ok | Dialog.Cancel

    // Settings properties that can be bound to form data
    property string fontFamily: "Libertinus Serif"
    property int fontSize: 12
    property string paperSize: "us-letter"
    property string region: "us"
    property string language: "en"
    property bool implicitIntroductionHeading: false
    property bool abstractAsDescription: true

    onVisibleChanged: {
        if (visible) {
            var fontIdx = fontFamilyComboBox.indexOfValue(fontFamily);
            if (fontIdx !== -1) {
                fontFamilyComboBox.currentIndex = fontIdx;
            } else {
                fontFamilyComboBox.editText = fontFamily;
            }

            var paperIdx = paperSizeComboBox.indexOfValue(paperSize);
            if (paperIdx !== -1) paperSizeComboBox.currentIndex = paperIdx;

            var regionIdx = regionComboBox.indexOfValue(region);
            if (regionIdx !== -1) regionComboBox.currentIndex = regionIdx;

            var langIdx = languageComboBox.indexOfValue(language);
            if (langIdx !== -1) languageComboBox.currentIndex = langIdx;
        }
    }

    width: 500
    height: 500

    contentItem: ScrollView {
        id: settingsScrollView
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            id: settingsLayout
            width: settingsScrollView.availableWidth
            spacing: 15

            Label {
                id: headerLabel
                text: qsTr("Document Formatting Options")
                font.bold: true
                font.pointSize: 14
            }

            Label {
                id: descriptionLabel
                text: qsTr("These settings apply to the entire document and affect how it is formatted when generated.")
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                color: projectSettingsDialog.palette.mid
            }

            Rectangle {
                id: separator1
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: projectSettingsDialog.palette.mid
                Layout.topMargin: 5
                Layout.bottomMargin: 5
            }

            // Font Settings
            Label {
                id: fontSectionLabel
                text: qsTr("Font Settings")
                font.bold: true
                font.pointSize: 12
            }

            Label {
                id: fontFamilyLabel
                text: qsTr("Font Family")
            }
            ComboBox {
                id: fontFamilyComboBox
                Layout.fillWidth: true
                model: Qt.fontFamilies()
                editable: true
                Component.onCompleted: {
                    var idx = fontFamilyComboBox.indexOfValue(projectSettingsDialog.fontFamily);
                    if (idx !== -1) {
                        fontFamilyComboBox.currentIndex = idx;
                    } else {
                        fontFamilyComboBox.editText = projectSettingsDialog.fontFamily;
                    }
                }
                onCurrentTextChanged: {
                    projectSettingsDialog.fontFamily = fontFamilyComboBox.currentText;
                }
            }

            Label {
                id: fontSizeLabel
                text: qsTr("Font Size (pt)")
            }
            SpinBox {
                id: fontSizeSpinBox
                Layout.fillWidth: true
                from: 10
                to: 14
                value: projectSettingsDialog.fontSize
                editable: true
                onValueChanged: {
                    projectSettingsDialog.fontSize = fontSizeSpinBox.value;
                }
            }

            Rectangle {
                id: separator2
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: projectSettingsDialog.palette.mid
                Layout.topMargin: 10
                Layout.bottomMargin: 5
            }

            // Page Settings
            Label {
                id: pageSectionLabel
                text: qsTr("Page Settings")
                font.bold: true
                font.pointSize: 12
            }

            Label {
                id: paperSizeLabel
                text: qsTr("Paper Size")
            }
            ComboBox {
                id: paperSizeComboBox
                Layout.fillWidth: true
                model: ["us-letter", "a4"]
                Component.onCompleted: {
                    paperSizeComboBox.currentIndex = paperSizeComboBox.indexOfValue(projectSettingsDialog.paperSize);
                }
                onCurrentTextChanged: {
                    projectSettingsDialog.paperSize = paperSizeComboBox.currentText;
                }
            }

            Rectangle {
                id: separator3
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: projectSettingsDialog.palette.mid
                Layout.topMargin: 10
                Layout.bottomMargin: 5
            }

            // Localization Settings
            Label {
                id: localizationSectionLabel
                text: qsTr("Localization")
                font.bold: true
                font.pointSize: 12
            }

            Label {
                id: regionLabel
                text: qsTr("Region")
            }
            ComboBox {
                id: regionComboBox
                Layout.fillWidth: true
                textRole: "text"
                valueRole: "value"
                model: [
                    { value: "us", text: qsTr("United States") },
                    { value: "co", text: qsTr("Colombia") }
                ]
                Component.onCompleted: {
                    regionComboBox.currentIndex = regionComboBox.indexOfValue(projectSettingsDialog.region);
                }
                onActivated: {
                    projectSettingsDialog.region = currentValue;
                }
            }

            Label {
                id: languageLabel
                text: qsTr("Language")
            }
            ComboBox {
                id: languageComboBox
                Layout.fillWidth: true
                textRole: "text"
                valueRole: "value"
                model: [
                    { value: "en", text: qsTr("English") },
                    { value: "es", text: qsTr("Spanish") }
                ]
                Component.onCompleted: {
                    languageComboBox.currentIndex = languageComboBox.indexOfValue(projectSettingsDialog.language);
                }
                onActivated: {
                    projectSettingsDialog.language = currentValue;
                }
            }

            Rectangle {
                id: separator4
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: projectSettingsDialog.palette.mid
                Layout.topMargin: 10
                Layout.bottomMargin: 5
            }

            // Advanced Settings
            Label {
                id: advancedSectionLabel
                text: qsTr("Advanced Options")
                font.bold: true
                font.pointSize: 12
            }

            CheckBox {
                id: implicitIntroCheckBox
                text: qsTr("Implicit introduction heading")
                checked: projectSettingsDialog.implicitIntroductionHeading
                onCheckedChanged: {
                    projectSettingsDialog.implicitIntroductionHeading = implicitIntroCheckBox.checked;
                }
                ToolTip.visible: implicitIntroCheckBox.hovered
                ToolTip.text: qsTr("Automatically add an introduction heading without explicitly writing it")
            }

            CheckBox {
                id: abstractAsDescCheckBox
                text: qsTr("Abstract as description meta tag")
                checked: projectSettingsDialog.abstractAsDescription
                onCheckedChanged: {
                    projectSettingsDialog.abstractAsDescription = abstractAsDescCheckBox.checked;
                }
                ToolTip.visible: abstractAsDescCheckBox.hovered
                ToolTip.text: qsTr("Use the abstract text as the document's meta description")
            }

            // Spacer at the bottom
            Item {
                id: bottomSpacer
                Layout.fillWidth: true
                Layout.preferredHeight: 20
            }
        }
    }
}