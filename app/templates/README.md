# Ergo Templates

This directory contains template definitions for creating new Ergo projects. Each template is a self-contained directory that defines both the project structure and the user interface form.

## Template Structure

Each template directory must contain:

1. **`form.qml`** - The QML form component that will be displayed in the middle column of the ProjectView
2. **`structure/`** - A directory containing the actual project structure to be copied to the user's location
3. **`README.md`** (optional) - Description of the template

### Example Template Layout

```
templates/
├── apa7/
│   ├── form.qml              # The form UI for APA 7th edition template
│   ├── structure/            # Project structure to copy
│   │   ├── main.typ
│   │   ├── assets/
│   │   ├── bibliography/
│   │   ├── sections/
│   │   └── output/
│   └── README.md             # Optional: template description
└── basic/
    ├── form.qml
    ├── structure/
    │   ├── main.typ
    │   └── output/
    └── README.md
```

## Creating a New Template

To create a new template:

1. **Create a directory** in `templates/` with your template name (e.g., `mytemplate`)

2. **Create `form.qml`** - This defines the form interface that users will see:
   ```qml
   import QtQuick
   import QtQuick.Controls
   import QtQuick.Layouts
   
   ScrollView {
       id: myForm
       
       ColumnLayout {
           width: myForm.width
           
           Label {
               text: "My Field"
           }
           TextField {
               Layout.fillWidth: true
               placeholderText: "Enter value"
           }
       }
   }
   ```

3. **Create `structure/` directory** containing your project structure:
   - Add all directories and files that should be in the project
   - File content will typically be generated dynamically from user input
   - Include placeholder files as needed

4. **Test** by selecting your template in the application

## How It Works

When a user creates a new project:

1. User selects a template from the "New Project" dialog
2. The `structure/` directory is copied recursively to the user's chosen location
3. The `form.qml` component is dynamically loaded in the ProjectView's middle column
4. User fills in the form, which will generate/update the content of project files

## Form Component Guidelines

Your `form.qml` should:

- Be a `ScrollView` or similar container as the root element
- Use qualified access for all properties (add `id` to elements and reference them explicitly)
- Follow the existing commenting style
- Use `qsTr()` for all user-facing strings (for internationalization)
- Properly size itself to fit the available width

### Example Form Template

```qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    id: rootForm
    
    ColumnLayout {
        id: formLayout
        width: rootForm.width
        spacing: 10
        
        Label {
            id: sectionLabel
            text: qsTr("Section Title")
            font.bold: true
        }
        
        TextField {
            id: inputField
            Layout.fillWidth: true
            placeholderText: qsTr("Enter text here")
        }
    }
}
```

## Available Templates

- **apa7/**: American Psychological Association (APA) 7th edition format template with sections, bibliography, and assets directories

## Tips

- Keep the project structure in `structure/` minimal but complete
- The form should collect all necessary information to generate the project files
- Use clear, descriptive labels and placeholders in your forms
- Test your template by creating a new project with it
- Include a README.md in your template directory to document its purpose