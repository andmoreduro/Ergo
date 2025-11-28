import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Ergo 1.0

ColumnLayout {
    id: root
    spacing: 0

    ExportDialog {
        id: exportDialog
        parent: Overlay.overlay
        anchors.centerIn: parent
    }

    property var imageSources: []
    property int zoomLevel: 100 // Percentage

    Timer {
        id: scrollRetryTimer
        interval: 100
        repeat: false
        property int targetIndex: -1
        onTriggered: root.scrollToPage(targetIndex)
    }

    // Scroll to a specific page index
    function scrollToPage(index) {
        if (index < 0) return;
        
        // Wait if model isn't populated yet
        if (imageRepeater.count === 0 || index >= imageRepeater.count) {
            scrollRetryTimer.targetIndex = index;
            scrollRetryTimer.restart();
            return;
        }
        
        var item = imageRepeater.itemAt(index);
        // Ensure item exists and has been laid out
        if (item && item.height > 0) {
            // Calculate the item's y-position relative to the content container
            var pos = item.mapToItem(workspace, 0, 0);

            // Verify layout has occurred: items beyond the first one should not be at the very top
            // Since paperColumn is centered with 100px extra height, top is at 50px.
            // So any item > 0 should be well below 50px.
            if (index > 0 && pos.y < 100) {
                scrollRetryTimer.targetIndex = index;
                scrollRetryTimer.restart();
                return;
            }

            if (pos) {
                // Calculate the scroll position
                // ScrollBar.position corresponds to contentY / contentHeight
                var targetPosition = Math.max(0, pos.y - 20) / workspace.height;

                if (previewScrollView.ScrollBar.vertical) {
                    previewScrollView.ScrollBar.vertical.position = targetPosition;
                } else if (previewScrollView.contentItem && previewScrollView.contentItem.contentY !== undefined) {
                    // Fallback: Access the internal Flickable directly
                    previewScrollView.contentItem.contentY = Math.max(0, pos.y - 20);
                }
            }
        } else {
            // Item not ready, retry
            scrollRetryTimer.targetIndex = index;
            scrollRetryTimer.restart();
        }
    }

    // --- Toolbar ---
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 40
        color: root.palette.window
        border.color: root.palette.mid
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 15
            anchors.rightMargin: 15
            spacing: 10

            Label {
                text: qsTr("Document Preview")
                font.bold: true
                color: root.palette.text
            }

            Item { Layout.fillWidth: true } // Spacer

            Button {
                text: qsTr("⇩ PDF")
                flat: true
                onClicked: exportDialog.open()
                ToolTip.visible: hovered
                ToolTip.text: qsTr("Export project as PDF")
            }

            // Zoom Controls
            Button {
                text: "−"
                flat: true
                Layout.preferredWidth: 30
                onClicked: {
                    root.zoomLevel = Math.max(25, root.zoomLevel - 10);
                }
            }

            Slider {
                id: zoomSlider
                from: 25
                to: 400
                value: root.zoomLevel
                stepSize: 5
                Layout.preferredWidth: 150
                onMoved: {
                    root.zoomLevel = value;
                }
            }

            Button {
                text: "+"
                flat: true
                Layout.preferredWidth: 30
                onClicked: {
                    root.zoomLevel = Math.min(400, root.zoomLevel + 10);
                }
            }

            Label {
                text: root.zoomLevel + "%"
                Layout.preferredWidth: 40
                horizontalAlignment: Text.AlignRight
                color: root.palette.text
            }
        }
    }

    // --- Preview Area ---
    ScrollView {
        id: previewScrollView
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AsNeeded
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        contentWidth: workspace.width
        contentHeight: workspace.height

        // Background for the workspace
        background: Rectangle {
            color: "#e6e6e6" // Light grey background
        }

        // Content Container
        // This item ensures the content can be larger than the view (scrolling)
        // or centered if smaller than the view.
        Item {
            id: workspace
            width: paperColumn.width + 100
            height: paperColumn.height + 100

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                onWheel: (wheel) => {
                    if (wheel.modifiers & Qt.ControlModifier) {
                        var delta = wheel.angleDelta.y;
                        if (delta > 0) {
                            root.zoomLevel = Math.min(400, root.zoomLevel + 10);
                        } else if (delta < 0) {
                            root.zoomLevel = Math.max(25, root.zoomLevel - 10);
                        }
                        wheel.accepted = true;
                    } else {
                        wheel.accepted = false;
                    }
                }
            }

            Column {
                id: paperColumn
                anchors.centerIn: parent
                spacing: 20

                // 816px is roughly 100% width for US Letter at standard DPI (8.5 inch * 96 dpi = 816)
                // We use this as a baseline for 100% zoom.
                width: 816 * (root.zoomLevel / 100)

                Repeater {
                    id: imageRepeater
                    model: root.imageSources

                    delegate: Item {
                        id: pageDelegate
                        width: paperColumn.width

                        // Calculate height based on aspect ratio of the loaded image
                        // Default to roughly US Letter aspect ratio (1.29) if loading
                        height: (imageContent && imageContent.implicitWidth > 0 && imageContent.implicitHeight > 0)
                                              ? (pageDelegate.width / imageContent.implicitWidth * imageContent.implicitHeight)
                                              : pageDelegate.width * 1.2941

                        required property string modelData

                        // Paper Sheet Appearance
                        Rectangle {
                            anchors.fill: parent
                            color: "white"

                            // Shadow effect using border and slight offset logic if we were using a real DropShadow
                            // For simplicity, just a crisp border here.
                            border.color: "#cccccc"
                            border.width: 1

                            SvgItem {
                                id: imageContent
                                anchors.fill: parent
                                anchors.margins: 1
                                source: pageDelegate.modelData
                            }
                        }
                    }
                }

                // Extra space at bottom
                Item { height: 20; width: 1 }
            }
        }
    }
}
