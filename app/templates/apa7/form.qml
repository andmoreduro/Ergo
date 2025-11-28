import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: apaForm

    // This component provides the form interface for APA 7th edition template projects.
    // It contains all the fields specific to APA 7th edition-formatted documents with
    // dynamic author and affiliation management, matching the versatile-apa package.
    // Fields are organized in the order they appear in the document.

    // Data models for authors and affiliations
    property var authors: []
    property var affiliations: []
    property var sections: []
    property string projectLocation: ""
    
    // Property to track if there are valid affiliations (updates without recreating delegates)
    property bool hasValidAffiliations: false
    
    // Timestamp that changes to force checkbox text re-evaluation without recreating delegates
    property int affiliationNamesVersion: 0

    // Formatting properties
    property string fontFamily: {
        var fonts = Qt.fontFamilies();
        var candidates = ["Libertinus Serif", "Times New Roman", "Liberation Serif", "Georgia", "Cambria"];
        for (var i = 0; i < candidates.length; i++) {
            if (fonts.indexOf(candidates[i]) !== -1) return candidates[i];
        }
        return "Times New Roman"; // Fallback
    }
    property int fontSize: 12
    property string paperSize: "us-letter"
    property string region: "us"
    property string language: "en"
    property bool implicitIntroductionHeading: false
    property bool abstractAsDescription: true

    onImplicitIntroductionHeadingChanged: {
        var newSections = apaForm.sections.slice();
        var hasIntro = newSections.length > 0 && newSections[0].id === "implicit_intro";
        
        if (implicitIntroductionHeading) {
            if (!hasIntro) {
                newSections.unshift({
                    id: "implicit_intro",
                    title: titleField.text,
                    content: "",
                    isImplicit: true
                });
                apaForm.sections = newSections;
                apaForm.scheduleUpdate();
            }
        } else {
            if (hasIntro) {
                newSections.shift();
                apaForm.sections = newSections;
                apaForm.scheduleUpdate();
            }
        }
    }
    
    // Helper function to update hasValidAffiliations property
    function updateValidAffiliationsState() {
        var hasValid = false;
        for (var i = 0; i < apaForm.affiliations.length; i++) {
            if (apaForm.affiliations[i].name && apaForm.affiliations[i].name.trim() !== "") {
                hasValid = true;
                break;
            }
        }
        apaForm.hasValidAffiliations = hasValid;
    }

    // Queue-based update system for immediate sequential processing
    property var updateQueue: []
    property bool isProcessing: false
    property bool isLoading: false

    // Function to add update request to queue
    function scheduleUpdate() {
        if (isLoading) return;

        // Adds a timestamp to track the update request
        updateQueue.push(Date.now());
        
        // If not already processing, start processing the queue
        if (!isProcessing) {
            processQueue();
        }
    }

    // Function to process the queue
    function processQueue() {
        if (updateQueue.length === 0) {
            isProcessing = false;
            return;
        }

        isProcessing = true;
        
        // Clears the queue and processes once (handles all accumulated changes)
        updateQueue = [];
        
        // Generates the file
        apaForm.generateMainTyp();
        
        // Uses a short timer to avoid blocking the UI thread
        Qt.callLater(processQueue);
    }

    // Function to load saved data from JSON
    function loadSavedData() {
        isLoading = true;
        
        var dataLoaded = false;
        if (typeof apa7FormHandler !== 'undefined') {
            var data = apa7FormHandler.load_form_data();
            
            if (data && Object.keys(data).length > 0) {
                dataLoaded = true;
                // Helper to safely get string
                var getStr = function(val) { return val ? val : ""; };
                
                titleField.text = getStr(data.title);
                runningHeadField.text = getStr(data.running_head);
                authorNotesTextArea.text = getStr(data.author_notes);
                courseField.text = getStr(data.course);
                instructorField.text = getStr(data.instructor);
                dueDateField.text = getStr(data.due_date);
                abstractTextArea.text = getStr(data.abstract);
                keywordsField.text = getStr(data.keywords);
                
                // Load formatting settings
                if (data.font_family) apaForm.fontFamily = data.font_family;
                if (data.font_size) apaForm.fontSize = data.font_size;
                if (data.paper_size) apaForm.paperSize = data.paper_size;
                if (data.region) apaForm.region = data.region;
                if (data.language) apaForm.language = data.language;
                if (data.implicit_intro !== undefined) apaForm.implicitIntroductionHeading = data.implicit_intro;
                if (data.abstract_as_desc !== undefined) apaForm.abstractAsDescription = data.abstract_as_desc;

                if (data.sections) {
                    apaForm.sections = data.sections;
                }

                if (data.affiliations) {
                    apaForm.affiliations = data.affiliations;
                    var maxId = 0;
                    for (var i = 0; i < data.affiliations.length; i++) {
                        if (data.affiliations[i].id >= maxId) maxId = data.affiliations[i].id;
                    }
                    apaForm.nextAffiliationId = maxId + 1;
                }
                
                if (data.authors) {
                    apaForm.authors = data.authors;
                    var maxAuthId = 0;
                    for (var j = 0; j < data.authors.length; j++) {
                        if (data.authors[j].id >= maxAuthId) maxAuthId = data.authors[j].id;
                    }
                    apaForm.nextAuthorId = maxAuthId + 1;
                }
                
                apaForm.updateValidAffiliationsState();
            }
        }
        
        isLoading = false;
        
        // ONLY schedule an update if we actually loaded data.
        // This prevents overwriting a new project's default JSON
        // with an empty state before the user has made any changes.
        if (dataLoaded) {
            apaForm.scheduleUpdate();
        }
    }

    // Function to collect all form data and generate main.typ
    function generateMainTyp() {
        if (typeof apa7FormHandler === 'undefined') {
            return;
        }

        apa7FormHandler.generate_main_typ(
            titleField.text,
            apaForm.authors,
            apaForm.affiliations,
            apaForm.sections,
            runningHeadField.text,
            authorNotesTextArea.text,
            courseField.text,
            instructorField.text,
            dueDateField.text,
            abstractTextArea.text,
            keywordsField.text,
            apaForm.fontFamily,
            apaForm.fontSize,
            apaForm.paperSize,
            apaForm.region,
            apaForm.language,
            apaForm.implicitIntroductionHeading,
            apaForm.abstractAsDescription
        );
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TabBar {
            id: formTabBar
            Layout.fillWidth: true
            TabButton { text: qsTr("Cover Page") }
            TabButton { text: qsTr("Content") }
        }

        StackLayout {
            currentIndex: formTabBar.currentIndex
            Layout.fillWidth: true
            Layout.fillHeight: true

            // --- TAB 1: COVER PAGE ---
            ScrollView {
                clip: true
                contentWidth: availableWidth
                leftPadding: 10
                rightPadding: 10

                ColumnLayout {
                    width: parent.width
                    spacing: 15

            // --- TITLE PAGE SECTION ---
            Label {
                id: titlePageHeaderLabel
                text: qsTr("Title Page")
                font.bold: true
                font.pointSize: 16
            }

            // Document Title
            Label { text: qsTr("Title") }
            TextField {
                id: titleField
                Layout.fillWidth: true
                placeholderText: qsTr("The title of your document (use title case)")
                onTextChanged: {
                    if (apaForm.implicitIntroductionHeading && apaForm.sections.length > 0 && apaForm.sections[0].id === "implicit_intro") {
                        var newSections = apaForm.sections.slice();
                        newSections[0].title = text;
                        apaForm.sections = newSections;
                    }
                    apaForm.scheduleUpdate();
                }
            }

            // Running Head (Professional papers)
            Label { text: qsTr("Running Head (Professional papers)") }
            TextField {
                id: runningHeadField
                Layout.fillWidth: true
                placeholderText: qsTr("Short title for page headers")
                onTextChanged: apaForm.scheduleUpdate()
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: apaForm.palette.text
                opacity: 0.2
                Layout.topMargin: 10
                Layout.bottomMargin: 10
            }

            // --- AUTHORS SECTION ---
            Label {
                text: qsTr("Authors")
                font.bold: true
                font.pointSize: 14
            }
            Label {
                text: qsTr("Add authors and associate them with their affiliations. Optionally include ORCID iDs.")
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                color: apaForm.palette.text
                opacity: 0.7
            }

            Repeater {
                id: authorsRepeater
                model: apaForm.authors
                delegate: ColumnLayout {
                    id: outerAuthorDelegate
                    Layout.fillWidth: true
                    spacing: 5

                    property var rootForm: apaForm
                    property var authorData: modelData
                    property int authorIndex: index

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 5
                        TextField {
                            id: authorNameField
                            Layout.fillWidth: true
                            placeholderText: qsTr("Author name (e.g., John Doe)")
                            text: modelData.name
                            onTextChanged: {
                                if (authorNameField.text !== modelData.name) {
                                    rootForm.authors[index].name = authorNameField.text;
                                    rootForm.scheduleUpdate();
                                }
                            }
                            onEditingFinished: {
                                rootForm.authorsChanged();
                            }
                        }
                        Button {
                            text: "−"
                            flat: true
                            Layout.preferredWidth: 40
                            onClicked: rootForm.removeAuthor(index)
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 20
                        spacing: 5
                        Label { text: qsTr("ORCID iD:"); font.pointSize: 10 }
                        TextField {
                            id: orcidField
                            Layout.fillWidth: true
                            placeholderText: qsTr("0000-0000-0000-0000 (optional)")
                            text: modelData.orcid
                            onTextChanged: {
                                if (orcidField.text !== modelData.orcid) {
                                    rootForm.authors[index].orcid = orcidField.text;
                                    rootForm.scheduleUpdate();
                                }
                            }
                            onEditingFinished: {
                                rootForm.authorsChanged();
                            }
                        }
                    }

                    Label {
                        text: qsTr("  Associated Affiliations:")
                        font.pointSize: 10
                        color: apaForm.palette.text
                        opacity: 0.7
                    }

                    Flow {
                        Layout.fillWidth: true
                        Layout.leftMargin: 20
                        spacing: 10
                        visible: rootForm.hasValidAffiliations
                        Repeater {
                            id: affiliationCheckboxesRepeater
                            model: rootForm.affiliations
                            delegate: CheckBox {
                                id: affiliationCheckbox
                                text: {
                                    var _ = rootForm.affiliationNamesVersion;
                                    var currentName = rootForm.affiliations[index] ? rootForm.affiliations[index].name : "";
                                    return currentName || qsTr("Affiliation ") + (index + 1);
                                }
                                checked: outerAuthorDelegate.authorData ? outerAuthorDelegate.authorData.affiliationIds.indexOf(modelData.id) !== -1 : false
                                onToggled: {
                                    if (checked) {
                                        rootForm.addAffiliationToAuthor(outerAuthorDelegate.authorIndex, modelData.id);
                                    } else {
                                        rootForm.removeAffiliationFromAuthor(outerAuthorDelegate.authorIndex, modelData.id);
                                    }
                                }
                            }
                        }
                    }

                    Label {
                        Layout.leftMargin: 20
                        text: qsTr("No affiliations available. Add affiliations below to associate them with this author.")
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                        color: rootForm.palette.text
                        opacity: 0.7
                        font.italic: true
                        visible: !rootForm.hasValidAffiliations
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: apaForm.palette.text
                        opacity: 0.1
                        Layout.topMargin: 5
                        Layout.bottomMargin: 5
                    }
                }
            }

            Button {
                text: qsTr("+ Add Author")
                flat: true
                Layout.alignment: Qt.AlignLeft
                onClicked: apaForm.addAuthor()
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: apaForm.palette.text
                opacity: 0.2
                Layout.topMargin: 10
                Layout.bottomMargin: 10
            }

            // --- AFFILIATIONS SECTION ---
            Label {
                text: qsTr("Affiliations")
                font.bold: true
                font.pointSize: 14
            }
            Label {
                text: qsTr("Add the institutions, departments, or organizations associated with this work.")
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                color: apaForm.palette.text
                opacity: 0.7
            }
            
            Repeater {
                id: affiliationsRepeater
                model: apaForm.affiliations
                delegate: RowLayout {
                    id: affiliationDelegate
                    Layout.fillWidth: true
                    spacing: 5
                    
                    property var rootForm: apaForm

                    TextField {
                        id: affiliationField
                        Layout.fillWidth: true
                        placeholderText: qsTr("Affiliation name (e.g., Department of Psychology, University Name)")
                        text: modelData.name
                        onTextEdited: {
                            if (affiliationField.text !== modelData.name) {
                                rootForm.affiliations[index].name = affiliationField.text;
                                rootForm.updateValidAffiliationsState();
                                rootForm.affiliationNamesVersion++;
                                rootForm.scheduleUpdate();
                            }
                        }
                        onEditingFinished: {
                            rootForm.scheduleUpdate();
                            rootForm.affiliationsChanged();
                        }
                    }

                    Button {
                        text: "−"
                        flat: true
                        Layout.preferredWidth: 40
                        onClicked: rootForm.removeAffiliation(index)
                    }
                }
            }

            Button {
                text: qsTr("+ Add Affiliation")
                flat: true
                Layout.alignment: Qt.AlignLeft
                onClicked: apaForm.addAffiliation()
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: apaForm.palette.text
                opacity: 0.2
                Layout.topMargin: 10
                Layout.bottomMargin: 10
            }

            // --- AUTHOR NOTES SECTION (Professional papers) ---
            Label {
                text: qsTr("Author Notes (Professional papers, optional)")
                font.bold: true
                font.pointSize: 14
            }
            Label {
                text: qsTr("Include any acknowledgments, funding information, or conflicts of interest.")
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                color: apaForm.palette.text
                opacity: 0.7
            }
            TextArea {
                id: authorNotesTextArea
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                wrapMode: Text.WordWrap
                placeholderText: qsTr("Enter author notes, acknowledgments, or disclosures")
                onTextChanged: apaForm.scheduleUpdate()
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: apaForm.palette.text
                opacity: 0.2
                Layout.topMargin: 10
                Layout.bottomMargin: 10
            }

            // --- COURSE INFORMATION SECTION (Student papers) ---
            Label {
                text: qsTr("Course Information (Student papers)")
                font.bold: true
                font.pointSize: 14
            }
            Label { text: qsTr("Course") }
            TextField {
                id: courseField
                Layout.fillWidth: true
                placeholderText: qsTr("Course number and name")
                onTextChanged: apaForm.scheduleUpdate()
            }
            Label { text: qsTr("Instructor") }
            TextField {
                id: instructorField
                Layout.fillWidth: true
                placeholderText: qsTr("Instructor name")
                onTextChanged: apaForm.scheduleUpdate()
            }
            Label { text: qsTr("Due Date") }
            TextField {
                id: dueDateField
                Layout.fillWidth: true
                placeholderText: qsTr("Due date (e.g., October 24, 2023)")
                onTextChanged: apaForm.scheduleUpdate()
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: apaForm.palette.text
                opacity: 0.2
                Layout.topMargin: 10
                Layout.bottomMargin: 10
            }
                }
            }

            // --- TAB 2: CONTENT ---
            ScrollView {
                clip: true
                contentWidth: availableWidth
                leftPadding: 10
                rightPadding: 10

                ColumnLayout {
                    width: parent.width
                    spacing: 15

            // --- ABSTRACT SECTION ---
            Label {
                text: qsTr("Abstract")
                font.bold: true
                font.pointSize: 16
            }
            Label {
                text: qsTr("A brief summary of your work (150-250 words).")
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                color: apaForm.palette.text
                opacity: 0.7
            }
            TextArea {
                id: abstractTextArea
                Layout.fillWidth: true
                Layout.preferredHeight: 150
                wrapMode: Text.WordWrap
                placeholderText: qsTr("Write your abstract here")
                onTextChanged: apaForm.scheduleUpdate()
            }
            Label { text: qsTr("Keywords") }
            TextField {
                id: keywordsField
                Layout.fillWidth: true
                placeholderText: qsTr("keyword1, keyword2, keyword3")
                onTextChanged: apaForm.scheduleUpdate()
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: apaForm.palette.text
                opacity: 0.2
                Layout.topMargin: 10
                Layout.bottomMargin: 10
            }

            // --- SECTIONS ---
            Label {
                text: qsTr("Sections")
                font.bold: true
                font.pointSize: 16
            }

            Repeater {
                id: sectionsRepeater
                model: apaForm.sections
                delegate: ColumnLayout {
                    property int sectionIndex: index
                    Layout.fillWidth: true
                    spacing: 5
                    Layout.leftMargin: ((modelData.level || 1) - 1) * 30

                    RowLayout {
                        Layout.fillWidth: true

                        Label {
                            text: {
                                var lvl = modelData.level || 1;
                                var subscripts = ["₀", "₁", "₂", "₃", "₄", "₅"];
                                return "#" + (subscripts[lvl] || lvl);
                            }
                            font.bold: true
                            opacity: 0.6
                        }

                        TextField {
                            id: sectionTitleField
                            Layout.fillWidth: true
                            placeholderText: qsTr("Section Title")
                            text: modelData.title
                            enabled: !modelData.isImplicit
                            onTextEdited: {
                                if (text !== modelData.title) {
                                    apaForm.sections[index].title = text;
                                    apaForm.sectionTitleChanged();
                                    apaForm.scheduleUpdate();
                                }
                            }
                        }
                        Button {
                            text: "⋮"
                            flat: true
                            visible: !modelData.isImplicit
                            onClicked: sectionMenu.open()
                            
                            Menu {
                                id: sectionMenu
                                y: parent.height
                                
                                MenuItem {
                                    text: qsTr("Add Subsection")
                                    enabled: (modelData.level || 1) < 5
                                    onTriggered: apaForm.addSubsection(index)
                                }
                                MenuItem {
                                    text: qsTr("Delete Section")
                                    onTriggered: apaForm.removeSection(index)
                                }
                            }
                        }
                    }

                    // Content Blocks
                    Repeater {
                        id: blocksRepeater
                        model: modelData.blocks || (modelData.content ? [{type: "text", content: modelData.content}] : [])
                        delegate: ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 5
                            
                            // Header for block
                            RowLayout {
                                Layout.fillWidth: true
                                Item { Layout.fillWidth: true }
                                Button {
                                    text: "×"
                                    flat: true
                                    display: AbstractButton.TextOnly
                                    font.pixelSize: 14
                                    onClicked: apaForm.removeBlock(sectionIndex, index)
                                }
                            }

                            // Text Block
                            TextArea {
                                visible: modelData.type === "text"
                                Layout.fillWidth: true
                                Layout.preferredHeight: Math.max(100, implicitHeight)
                                wrapMode: Text.WordWrap
                                placeholderText: qsTr("Paragraph text...")
                                text: modelData.content || ""
                                onTextChanged: {
                                    var section = apaForm.sections[sectionIndex];
                                    if (section.blocks) {
                                        section.blocks[index].content = text;
                                    } else {
                                        section.content = text;
                                    }
                                    apaForm.scheduleUpdate();
                                }
                            }

                            // Image Block
                            ColumnLayout {
                                visible: modelData.type === "image"
                                Layout.fillWidth: true
                                spacing: 5
                                
                                Image {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 200
                                    fillMode: Image.PreserveAspectFit
                                    source: modelData.path ? "file:///" + apaForm.projectLocation + "/" + modelData.path : ""
                                    mipmap: true

                                    Rectangle {
                                        anchors.fill: parent
                                        color: "transparent"
                                        border.color: apaForm.palette.mid
                                        visible: parent.status !== Image.Ready
                                        Label {
                                            anchors.centerIn: parent
                                            text: qsTr("Image preview unavailable")
                                            visible: parent.parent.status === Image.Error
                                        }
                                    }

                                    ToolTip.visible: imgHover.containsMouse
                                    ToolTip.text: modelData.path || ""

                                    MouseArea {
                                        id: imgHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                    }
                                }
                                
                                TextField {
                                    Layout.fillWidth: true
                                    placeholderText: qsTr("Caption")
                                    text: modelData.caption || ""
                                    onTextEdited: {
                                        apaForm.sections[sectionIndex].blocks[index].caption = text;
                                        apaForm.scheduleUpdate();
                                    }
                                }
                                
                                TextArea {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 60
                                    placeholderText: qsTr("Note (optional)")
                                    text: modelData.note || ""
                                    onTextChanged: {
                                        apaForm.sections[sectionIndex].blocks[index].note = text;
                                        apaForm.scheduleUpdate();
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        Button {
                            text: qsTr("+ Add Text")
                            flat: true
                            onClicked: apaForm.addTextBlock(sectionIndex)
                        }
                        Button {
                            text: qsTr("+ Add Image")
                            flat: true
                            onClicked: apaForm.addImageBlock(sectionIndex)
                        }
                    }
                            
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: apaForm.palette.text
                        opacity: 0.1
                        Layout.topMargin: 5
                        Layout.bottomMargin: 5
                    }
                }
            }

            Button {
                text: qsTr("+ Add Section")
                flat: true
                onClicked: apaForm.addSection()
            }

            // Spacer at the bottom
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 20
            }
                }
            }
        }
    }

    // --- Helper Functions ---
    property int nextAffiliationId: 1
    property int nextAuthorId: 1

    signal sectionTitleChanged()

    function addSection() {
        var newSections = apaForm.sections.slice();
        newSections.push({
            id: "sec_" + Date.now(),
            title: "",
            content: "",
            blocks: [{type: "text", content: ""}],
            isImplicit: false,
            level: 1
        });
        apaForm.sections = newSections;
        apaForm.scheduleUpdate();
    }

    function addSubsection(parentIndex) {
        var parentLevel = apaForm.sections[parentIndex].level || 1;
        if (parentLevel >= 5) return;

        var newSections = apaForm.sections.slice();
        var insertIndex = parentIndex + 1;
        
        // Find insertion point (end of children)
        while (insertIndex < newSections.length) {
            var nextLevel = newSections[insertIndex].level || 1;
            if (nextLevel <= parentLevel) break;
            insertIndex++;
        }

        newSections.splice(insertIndex, 0, {
            id: "sec_" + Date.now(),
            title: "",
            content: "",
            blocks: [{type: "text", content: ""}],
            isImplicit: false,
            level: parentLevel + 1
        });
        apaForm.sections = newSections;
        apaForm.scheduleUpdate();
    }

    function removeSection(index) {
        var level = apaForm.sections[index].level || 1;
        var newSections = apaForm.sections.slice();
        
        // Remove section and all its subsections
        var count = 1;
        while (index + count < newSections.length) {
            var nextLevel = newSections[index + count].level || 1;
            if (nextLevel <= level) break;
            count++;
        }

        newSections.splice(index, count);
        apaForm.sections = newSections;
        apaForm.scheduleUpdate();
    }

    function addTextBlock(sectionIndex) {
        var newSections = apaForm.sections.slice();
        var blocks = newSections[sectionIndex].blocks;
        if (!blocks) {
             blocks = [];
             if (newSections[sectionIndex].content) {
                 blocks.push({type: "text", content: newSections[sectionIndex].content});
             }
        }
        blocks.push({type: "text", content: ""});
        newSections[sectionIndex].blocks = blocks;
        apaForm.sections = newSections;
        apaForm.scheduleUpdate();
    }

    function addImageBlock(sectionIndex) {
        var path = projectManager.select_image();
        if (path === "") return;

        var relativePath = projectManager.import_image(path, apaForm.projectLocation);
        if (relativePath === "") return;

        var newSections = apaForm.sections.slice();
        var blocks = newSections[sectionIndex].blocks;
        if (!blocks) {
             blocks = [];
             if (newSections[sectionIndex].content) {
                 blocks.push({type: "text", content: newSections[sectionIndex].content});
             }
        }
        blocks.push({
            type: "image", 
            path: relativePath,
            caption: "",
            note: "",
            label: projectManager.generate_unique_id()
        });
        newSections[sectionIndex].blocks = blocks;
        apaForm.sections = newSections;
        apaForm.scheduleUpdate();
    }

    function removeBlock(sectionIndex, blockIndex) {
        var newSections = apaForm.sections.slice();
        var blocks = newSections[sectionIndex].blocks;
        if (!blocks) {
             blocks = [];
             if (newSections[sectionIndex].content) {
                 blocks.push({type: "text", content: newSections[sectionIndex].content});
             }
        }
        if (blocks.length > blockIndex) {
            blocks.splice(blockIndex, 1);
            newSections[sectionIndex].blocks = blocks;
            apaForm.sections = newSections;
            apaForm.scheduleUpdate();
        }
    }

    function addAffiliation() {
        var newAffiliations = apaForm.affiliations.slice();
        newAffiliations.push({
            id: apaForm.nextAffiliationId++,
            name: ""
        });
        apaForm.affiliations = newAffiliations;
        apaForm.affiliationsChanged();
        apaForm.updateValidAffiliationsState();
        apaForm.scheduleUpdate();
    }

    function removeAffiliation(index) {
        var affiliationId = apaForm.affiliations[index].id;
        var newAuthors = apaForm.authors.slice();
        for (var i = 0; i < newAuthors.length; i++) {
            var affiliationIndex = newAuthors[i].affiliationIds.indexOf(affiliationId);
            if (affiliationIndex !== -1) {
                newAuthors[i].affiliationIds.splice(affiliationIndex, 1);
            }
        }
        apaForm.authors = newAuthors;
        
        var newAffiliations = apaForm.affiliations.slice();
        newAffiliations.splice(index, 1);
        apaForm.affiliations = newAffiliations;

        apaForm.affiliationsChanged();
        apaForm.authorsChanged();
        apaForm.updateValidAffiliationsState();
        apaForm.scheduleUpdate();
    }

    function addAuthor() {
        var newAuthors = apaForm.authors.slice();
        newAuthors.push({
            id: apaForm.nextAuthorId++,
            name: "",
            orcid: "",
            affiliationIds: []
        });
        apaForm.authors = newAuthors;
        apaForm.authorsChanged();
        apaForm.scheduleUpdate();
    }

    function removeAuthor(index) {
        var newAuthors = apaForm.authors.slice();
        newAuthors.splice(index, 1);
        apaForm.authors = newAuthors;
        apaForm.authorsChanged();
        apaForm.scheduleUpdate();
    }

    function addAffiliationToAuthor(authorIndex, affiliationId) {
        console.log("addAffiliationToAuthor - Index:", authorIndex, "AffiliationID:", affiliationId, "Authors count:", apaForm.authors.length);
        if (authorIndex === undefined || authorIndex === null || authorIndex < 0 || authorIndex >= apaForm.authors.length) {
            console.error("Invalid author index in addAffiliationToAuthor:", authorIndex);
            return;
        }

        if (apaForm.authors[authorIndex].affiliationIds.indexOf(affiliationId) === -1) {
            // Need to operate on a copy for the change to be detected
            var newAuthors = apaForm.authors.slice();
            newAuthors[authorIndex].affiliationIds.push(affiliationId);
            apaForm.authors = newAuthors;
            apaForm.authorsChanged();
            apaForm.scheduleUpdate();
        }
    }

    function removeAffiliationFromAuthor(authorIndex, affiliationId) {
        console.log("removeAffiliationFromAuthor - Index:", authorIndex, "AffiliationID:", affiliationId, "Authors count:", apaForm.authors.length);
        if (authorIndex === undefined || authorIndex === null || authorIndex < 0 || authorIndex >= apaForm.authors.length) {
            console.error("Invalid author index in removeAffiliationFromAuthor:", authorIndex);
            return;
        }

        var affiliationIndex = apaForm.authors[authorIndex].affiliationIds.indexOf(affiliationId);
        if (affiliationIndex !== -1) {
            // Need to operate on a copy for the change to be detected
            var newAuthors = apaForm.authors.slice();
            newAuthors[authorIndex].affiliationIds.splice(affiliationIndex, 1);
            apaForm.authors = newAuthors;
            apaForm.authorsChanged();
            apaForm.scheduleUpdate();
        }
    }

    Component.onCompleted: {
        // Data is now loaded explicitly by the main view (main.qml) to prevent race conditions.
    }
}