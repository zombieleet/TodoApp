#!/usr/bin/env wish


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
    $todoFileMenu add command -label "Load From File" -underline 0 -command [list LoadFromFile]

    $todoFileMenu add command -label "Export As" -underline 0 -command [list ExportAs]
}


proc settingsMenu { todoMainMenu } {
    $todoMainMenu add cascade -label "Settings" -menu $todoMainMenu.settings
    
    set todoSettingsMenu [menu $todoMainMenu.settings -tearoff 0]

    $todoSettingsMenu add command -label "Font Style" -underline 0 -command [list setFont]
    $todoSettingsMenu add command -label "Background Color" -underline 0 -command [list setBgColor]
    $todoSettingsMenu add command -label "Font Color" -underline 1 -command [list setFontColor]
}

proc aboutMenu { todoMainMenu } {
    $todoMainMenu add cascade -label "About" -menu $todoMainMenu.about
}

proc RemoveSelectedTodo { } {
    global j dbCommand

    set dbCmd $dbCommand

    destroy .tableWindow
    
    set topLevel [toplevel .todoListsToRemove]

    grab $topLevel
    focus $topLevel

    set frBtn [frame $topLevel.frButtons]
    
    set selectAll [button $frBtn.select-all -text "Select All" -command [list selectAllTodos]]
    set unselectAll [button $frBtn.unselect-all -text "Unselect All" -command [list unselectAllTodos]]
    set delete [button $frBtn.delete -text "Delete " -command [list DeleteTodos] -state disabled]


    set frLbTodo [frame $topLevel.frLbTodo]
    set titleLabel [label $frLbTodo.titleLabel -text "Title"]
    set idLabel [label $frLbTodo.idlb -text "ID"]
    
    pack $idLabel $titleLabel -side left -anchor nw -padx 38

    pack configure $titleLabel -padx 12

    
    pack $frLbTodo  -fill x
    set j 0
    $dbCmd foreach row {SELECT * FROM TodoDb} {

	StyleRemove $row
    }
    pack $selectAll $unselectAll $delete -side left -anchor nw

    pack $frBtn -fill x
}

proc StyleRemove { createdTodo } {
    global j
    set topLevel .todoListsToRemove
    set todoid [dict get $createdTodo id]
    set todotitle [dict get $createdTodo Title]

    set frLabels [frame $topLevel.frLabels$j]
    set todoID [label $frLabels.idLabel -text "$todoid" ]
    set todoTITLE [label $frLabels.idTitle -text "$todotitle"]
    
    if {0} {
	set tododay [dict get $createdTodo Day]
	set todomonth [dict get $createdTodo Month]
	set todoyear [dict get $createdTodo Year]
	
	set tododate ${tododay}/${todomonth}/${todoyear}
    
	set todotime [dict get $createdTodo Hour]:[dict get $createdTodo Minute][dict get $createdTodo AmPm]
	
	set todocontent [string range [dict get $createdTodo Content] 0 10]
    }


    set chkBtn [checkbutton $frLabels.chkBtn_$todoid -variable $todoid -onvalue "false" -offvalue "true"]
    pack $chkBtn $todoID $todoTITLE -side left -fill x -anchor nw


    
    pack configure $todoID -padx 15
    pack configure $todoTITLE -padx 20
    pack $frLabels  -fill x

    
    bind $chkBtn <Button-1> [list saveMe %W $todoid $todoid]
    bind $todoID <ButtonPress-1> {[list $chkBtn select]}
    bind $todoTITLE <ButtonPress-1> {[list $chkBtn select]}
    incr j
    
}
proc saveMe { path tdid realId} {
    global Stack
    upvar 1 $tdid trueOrFalse
    set Stack($realId) [list $path $trueOrFalse]
    
    if {$trueOrFalse == "false" } {
	puts $Stack($realId)
	set Stack($realId) ""
    }
    s
    
}
proc s { } {
    global Stack
    foreach x [array names Stack] {
	puts $Stack($x)
    }
}
proc requirePackage { packageName } {
    set temp auto_path
    set auto_path [pwd]
    if {[catch {package require $packageName}]} {
	#tk_message -title "$packageName not Found"  -message "$packageName cannot be located" -icon info -type cancel
	return false;
    }

    package require ${packageName}::sqlite3
    puts $auto_path
    set auto_path $temp
    return true;
}
proc createInterface { } {
    wm geometry . 360x124+355+175
    set todoMainFrame [frame .todoFrame ]
    set addNewEntryButton [button $todoMainFrame.addNewTodo -text "Add Entry" -command [list AddNewEntry] ]
    set showEntryButton [button $todoMainFrame.showTodo -text "Show Entry" -command [list SetupEntryInterFace] ]
    pack $todoMainFrame -fill both -expand true
    pack $addNewEntryButton -pady 29 -anchor nw  -padx 60 -side left
    pack $showEntryButton -pady 29 -anchor nw -side left
}
proc Validate { textInput } {
    if {[string is integer $textInput]} {
	if {[string length $textInput] <= 2} {
	    return 1;
	}
	return 0;
    }
    return 0;
}
proc AddNewEntry { } {
    global todo-title dayvar monthvar yearvar todo-hour todo-minute todo-amPm detailsDetails
    catch { destroy .tableWindow }
    set addNewEntryTopLevel [toplevel .addNewEntryWindows]
    focus .addNewEntryWindows
    grab .addNewEntryWindows

    set TitleFrame [frame $addNewEntryTopLevel.titleFrame]
    set DateFrame [frame $addNewEntryTopLevel.dateFrame]
    set TimeFrame [frame $addNewEntryTopLevel.timeFrame]
    set TodoDetailsFrame [frame $addNewEntryTopLevel.todoDetailsFrame]
    set TodoOption [frame $addNewEntryTopLevel.todoOption]
    
    #set todoDateDayList {Monday Tuesday Wednesday Thursday Friday Saturday Sunday}
    set todoDateMonthList {January February March April May June July August September October November December}
    set currentYear [exec date "+%Y"]
    
    for {set i $currentYear} {$i <= 2050} {incr i} {
	lappend todoDateYearList $i
    }

    for {set i 1} {$i <= 30} {incr i} {
	lappend todoDateDayList $i
    }
    
    set titleLabel [label $TitleFrame.titleLabel -text "Title"]
    set titleEntry [entry $TitleFrame.titleEntry -textvariable todo-title ]
    
    
    set todoDate [label $DateFrame.todoDate -text "Date"]
    set todoDateDay [::ttk::combobox  $DateFrame.todoDay -value $todoDateDayList -textvariable dayvar -width 10]
    set todoDateMonth [::ttk::combobox  $DateFrame.todoMonth -value $todoDateMonthList -textvariable monthvar -width 10]
    set todoDateYear [::ttk::combobox  $DateFrame.todoYear -value $todoDateYearList -textvariable yearvar -width 10]

    set todoTime [label  $TimeFrame.todoTime -text "Time"]    
    set todoTimeHour [entry  $TimeFrame.todoHour -width 10 -validate key -vcmd [list Validate %P] \
			  -textvariable todo-hour]
    set todoTimeMinute [entry  $TimeFrame.todoMinute -width 10 -validate key -vcmd [list Validate %P] \
			    -textvariable todo-minute]
    set todoPmAm [::ttk::combobox $TimeFrame.todoAmPm -width 5 -value {Am Pm} -textvariable todoAmPm \
		      -textvariable todo-amPm]


    set detailsTitle [label $TodoDetailsFrame.detailsTitle -text "What are you planning to do?"]
    set detailsDetails [text $TodoDetailsFrame.text -yscrollcommand {.addNewEntryWindows.todoDetailsFrame.yview set} ]
    set YscrollBar [scrollbar $TodoDetailsFrame.yview -orient vertical \
			-command {.addNewEntryWindows.todoDetailsFrame.text yview}]
    
    set addNewButton [button $TodoOption.addNew -text "Add Todo" -command [list SetUpDatabase]]
    set cancelButton [button $TodoOption.cancel -text "Cancel" -command { destroy .addNewEntryWindows}]
    
    pack $TitleFrame -fill x -pady 5
    pack $DateFrame -fill x -pady 5
    pack $TimeFrame -fill x -pady 5
    pack $TodoDetailsFrame -fill x -pady 5
    pack $TodoOption -fill x -pady 5
    
    grid $titleLabel $titleEntry
    grid configure $titleLabel -padx 8
    grid configure $titleEntry -ipadx 5 -ipady 5
    grid $todoDate $todoDateDay $todoDateMonth $todoDateYear
    grid configure $todoDate -padx 8
    grid $todoTime $todoTimeHour $todoTimeMinute $todoPmAm
    grid $todoTime -padx 8

    grid $detailsTitle -sticky nw 
    grid $detailsDetails $YscrollBar -sticky news
    grid columnconfigure $TodoDetailsFrame 0 -weight 1


    grid $addNewButton $cancelButton
    
}

proc SetUpDatabase { } {
    set qq [requirePackage tdbc]
    #bind $buttonPath <ButtonPress-1> {}
    if {$qq eq "true"} {
	catch {tdbc::sqlite3::connection create TodoDatabase TodoSqliteDatabase.sql} err
	SqliteDatabase TodoDatabase
    }
}

proc SqliteDatabase { dbCmd } {
    global todo-title dayvar monthvar yearvar todo-hour todo-minute todo-amPm detailsDetails



    set title ${todo-title}
    set hour ${todo-hour}
    set minute ${todo-minute}
    set amPm ${todo-amPm}
    set sep :
    set content [$detailsDetails get 0.0 end]
    
    catch { destroy .addNewEntryWindows }
    
    if {[regexp {TodoDb} [$dbCmd tables]] == 0 } {
	$dbCmd allrows {
	    CREATE TABLE TodoDb (
	      id INTEGER PRIMARY KEY,
	      Title TEXT,
	      Day TEXT,
	      Month TEXT,
	      Year  TEXT,
	      Time TEXT,
	      Minute TEXT,
	      Hour TEXT,
	      AmPm TEXT,
	      Content TEXT);
	}
    }
    
    $dbCmd allrows {
	INSERT INTO TodoDb (Title,Day,Month,Year,Minute,Hour,AmPm,Content) VALUES ($title,$dayvar,$monthvar,$yearvar,$minute,$hour,$amPm,$content);
    }

    SetupEntryInterFace $dbCmd
}

proc SetupEntryInterFace { {dbCmd {}} } {
    global i dbCommand
    
    if { $dbCmd eq "" } {
	
	set qq [requirePackage tdbc]
	
	if {$qq eq "true"} {
	    catch {tdbc::sqlite3::connection create TodoDatabase TodoSqliteDatabase.sql} err
	    set dbCmd ::TodoDatabase
	}

    }
    set dbCommand $dbCmd
    set TableWindow [toplevel .tableWindow]
    focus .tableWindow
    grab .tableWindow

    wm title .tableWindow "TODO LIST"
    set tableFrame [frame $TableWindow.tableFrame]

    set id [label $tableFrame.id -text "ID" -relief raise -width 5]
    set title [label $tableFrame.title -text "TITLE" -relief raise -width 20]
    set date [label $tableFrame.date -text "DATE" -relief raise -width 20]
    set time [label $tableFrame.time -text "TIME" -relief raise -width 15]
    set todoDetail [label $tableFrame.todoDetail -text "TO DO" -relief raise -width 20]
    
    #pack $tableFrame -fill x -expand true -side left -anchor nw
    grid $tableFrame -sticky news
    grid $id $title $date $time $todoDetail
    
    set i 1;
    $dbCmd foreach row {SELECT * FROM TodoDb} {
	
	StyleEntry $row
    }
}


proc StyleEntry { createdTodo } {
    global i;
    
    catch { createMenu .tableWindow }
    set todoFrame [frame .tableWindow.todoFrame$i]
    set FrameDetails [frame .tableWindow.todoFrameDetails$i]

    
    set todoid [dict get $createdTodo id]
    set todotitle [dict get $createdTodo Title]
    
    set tododay [dict get $createdTodo Day]
    set todomonth [dict get $createdTodo Month]
    set todoyear [dict get $createdTodo Year]
    
    set tododate ${tododay}/${todomonth}/${todoyear}
    
    set todotime [dict get $createdTodo Hour]:[dict get $createdTodo Minute][dict get $createdTodo AmPm]
    
    set todocontent [string range [dict get $createdTodo Content] 0 10]

    
    
    set id [label $todoFrame.id -text $todoid  -width 5 -relief sunken]
    set title [label $todoFrame.title -text $todotitle -width 20  -relief sunken]

    set date [label $todoFrame.date -text $tododate  -width 20 -relief sunken]

    set time [label $todoFrame.time -text $todotime  -width 15 -relief sunken]
    
    set detail [label $todoFrame.detail -text "${todocontent}..." -justify left -compound left -width 20 -relief sunken]

    image create photo removeTodo -file [file join images remove.gif]
    image create photo openTodo -file [file join images open.gif]
    set todoRemove [button $todoFrame.btn-remove-todo -compound left -image removeTodo -relief flat]
    set todoOpen [button $todoFrame.btn-open-todo -compound left -image openTodo -relief flat]



    if { ($todomonth == [exec date "+%B"]) || ($todomonth != [exec date "+%B"]) } {
	
	if { $tododay <= [exec date "+%d"] } {
	    if { $todoyear <= [exec date "+%Y"] } {
		$id configure -bg red
		$title configure -bg red
		$date configure -bg red
		$time configure -bg red
		$detail configure -bg red
	    }
	}
    }
    
    #pack $todoFrame -fill x -expand true -anchor nw
    grid $todoFrame -sticky news
    grid $FrameDetails -sticky news
    #grid rowconfigure .tableWindow 0 -weight 1
    grid columnconfigure .tableWindow 0 -weight 1
    grid $id $title $date $time $detail $todoRemove $todoOpen
    bind $todoRemove <ButtonPress-1> [list RemoveTodo $todoFrame $todoid $FrameDetails %W]
    bind $todoOpen <ButtonPress-1> [list checkHeight $todoid $FrameDetails]
    incr i
}

proc checkHeight {todoid showContent} {
    if { [$showContent cget -height] == 300 } {
	CloseTodo $showContent
	return 
    }
    
    OpenTodo $todoid $showContent
}
proc CloseTodo {showContent} {
    
    #foreach children [grid slave $showContent] {
    #	grid forget $children
    #}

    grid forget $showContent
    
    
    for {set i [$showContent cget -height] } {$i >= 0} { } {	    
	$showContent configure -height $i
	set i [expr {$i - 10}]
	update idletasks
    }

}
proc OpenTodo {todoid showContent} {
    global dbCommand

    set dbCmd $dbCommand
    $dbCmd foreach openTodo {SELECT * FROM TodoDb WHERE id=$todoid} {
	
	set tododay [dict get $openTodo Day]
	set todomonth [dict get $openTodo Month]
	set todoyear [dict get $openTodo Year]
	
	set tododate ${tododay}/${todomonth}/${todoyear}
	
	set todotime [dict get $openTodo Hour]:[dict get $openTodo Minute][dict get $openTodo AmPm]
	
	set todocontent [dict get $openTodo Content]

	grid $showContent -sticky news
	
	catch { set todoDateFrame [frame $showContent.date-frame ]
	    set todoTimeFrame [frame $showContent.time-frame]
	    set todoContentFrame [frame $showContent.content-label]
	    
	    set todoDateLabel [label $todoDateFrame.date -text "Date:-"]
	    set todoDateValue [label $todoDateFrame.date-value -text "$tododate"]
	    
	    set todoTimeLabel [label $todoTimeFrame.time -text "Time:-"]
	    set todoTimeValue [label $todoTimeFrame.time-value -text "$todotime"]
	    
	    set todoContentLabel [label $todoContentFrame.content -text "\nWhat you Planned to do:\n"]
	    set todoContentValue [message $todoContentFrame.content-value -text "$todocontent" -aspect 1000]
	    
	    grid $todoDateFrame -sticky news
	    grid $todoTimeFrame  -sticky news
	    grid $todoContentFrame  -sticky news
	
	
	    
	    grid $todoDateLabel -row 0 -column 0
	    grid $todoDateValue -row 0 -column 1
	    
	    grid $todoTimeLabel -row 1 -column 0
	    grid $todoTimeValue -row 1 -column 1
	    

	    grid $todoContentLabel -row 2 -column 0
	    
	    
	    grid $todoContentValue -row 3 -columnspan 100 -sticky news}


        for {set i 0} {$i <= 300} { } {
	    $showContent configure -height $i
	    set i [expr {$i + 50}]
	    update idletasks
	}
    }
}
proc RemoveTodo {parent todoid showContent target} {
    global dbCommand

    set dbCmd $dbCommand

    set currIdLabel [lindex [grid slaves $parent] end]
    set currId [$currIdLabel cget -text]
    
    $dbCmd allrows {
	DELETE FROM TodoDb WHERE id=$todoid
    }
    set i 0;
    set j 1;
    set current [expr {$currId + $i}]
    set previous [expr {$currId + $j}]
    puts $current
    puts $previous
    $dbCmd foreach update {UPDATE TodoDb SET id=$current WHERE id=$previous} {
	puts "hi"
	incr i;
	incr j;
	set current [expr {$currId + $i}]
	set previous [expr {$currId + $j}]
    }
    
    grid forget $parent
    grid forget $showContent
}


createInterface

