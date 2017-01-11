

proc createMenu { win } {
    $win configure -menu .todoMainMenu
    
    set todoMainMenu [menu .todoMainMenu -tearoff 0]

    fileMenu $todoMainMenu
    settingsMenu $todoMainMenu
    aboutMenu $todoMainMenu
    
}



proc fileMenu { todoMainMenu } {
    
    $todoMainMenu add cascade -label "File" -menu $todoMainMenu.file
    
    set todoFileMenu [menu $todoMainMenu.file -tearoff 0]

    $todoFileMenu add command -label "Add Todo" -underline 0 -command [list AddNewEntry ]
    $todoFileMenu add command -label "Remove Todo" -underline 0 -command [list RemoveSelectedTodo]
    
    $todoFileMenu add separator
    #$todoFileMenu add command -label "Load From File" -underline 0 -command [list LoadFromFile]
    #$todoFileMenu add command -label "Export As" -underline 0 -command [list ExportAs]
}


proc settingsMenu { todoMainMenu } {
    
    $todoMainMenu add cascade -label "Settings" -menu $todoMainMenu.settings
    
    set todoSettingsMenu [menu $todoMainMenu.settings -tearoff 0]

    
    
    
    $todoSettingsMenu add command -label "Font Style" -underline 0 -command [list setFont]
    $todoSettingsMenu add command -label "Background Color" -underline 0 -command [list setBgColor]
    $todoSettingsMenu add command -label "Font Color" -underline 1 -command [list setFontColor]
}


proc aboutMenu { todoMainMenu } {
    
    $todoMainMenu add command -label "About" -command {
	tk_messageBox -title "About" -message "This Todo Application is built with Tcl/Tk \n
Author: 73mp74710n(zombieleet)\nVersion: 0.0.1\nGithubRepo:https://github.com/zombieleet/TodoApp\nTcl Website: http://tcl.tk\nTk Website: http://tcl-tk.tk" -icon info -type ok
    }
    
}
