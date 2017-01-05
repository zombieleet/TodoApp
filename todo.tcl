#!/usr/bin/env wish
package require tdbc
package require tdbc::sqlite3
::tdbc::sqlite3::connection create TodoDatabase TodoSqliteDatabase.sql


source menu.tcl


proc setFontColor {} {

    set fgColor [tk_chooseColor]
    if { $fgColor != "" } {
	
	TodoDatabase allrows {
	    INSERT INTO ConfigDb (foreground) VALUES ($fgColor);
	}
	option add *foreground $fgColor
    }
    
    destroy .tableWindow
    SetupEntryInterFace
}

proc setBgColor {} {

    set bgColor [tk_chooseColor]
    
    if { $bgColor != "" } {
	
	TodoDatabase allrows {
	    INSERT INTO ConfigDb (background) VALUES ($bgColor);
	}
	option add *background $bgColor
	
    }
    
    destroy .tableWindow
    SetupEntryInterFace
}

proc setFont { } {
    
    set topLevel [toplevel .setFont]
    grab $topLevel
    focus $topLevel
    

    wm title $topLevel "set font style"
    wm protocol $topLevel WM_DELETE_WINDOW SaveFont
    
    set fontFrame [frame $topLevel.fontFrame]
    set btnFrame [frame $topLevel.btnFrame]
    set fontFamilies [font families]

    set scrbY [scrollbar $fontFrame.scrllBars -orient vertical -command "$fontFrame.fntListbox yview"]
    set fntListbox [listbox $fontFrame.fntListbox -listvariable fntFamily -width 50 -height 20 -yscrollcommand "$scrbY set" -selectmode single]

    set fntTest [message $fontFrame.fntTest -aspect 3000 -text "the quick brown fox jumped over the fence" ]

    set buttonOk [button $btnFrame.btnOk -text "Save" -command SaveFont]
    set buttonCancel [button $btnFrame.btnCancel -text "Cancel" -command {destroy .setFont}]
    


    foreach fnt $fontFamilies {
	$fntListbox insert end $fnt
    }
    
    pack $fontFrame -fill x
    grid $fntListbox -row 0 -column 0 -sticky ns
    grid $scrbY -row 0 -column 1 -sticky news
    grid $fntTest -row 0 -column 2 -sticky ns
    
    pack $btnFrame -side left -fill x
    pack $buttonOk $buttonCancel -side left

    bind $fntListbox <ButtonPress-1> [list setGlobFont %W $fntTest]
    
}

proc SaveFont { } {
    global globalFont
    if {[info exist globalFont]} {

	TodoDatabase allrows {
	    INSERT INTO ConfigDb (font) VALUES ($globalFont);
	}
	
	option add *font $globalFont

	destroy .setFont
	destroy .tableWindow
	SetupEntryInterFace
	
	return ;
    }
    set result [tk_messageBox -title "Font not selected"  -message "You did not choose a font" -icon info -type retrycancel]
    if {$result == "cancel"} {
	destroy .setFont
    }
    
}
proc setGlobFont { path fntTest} {
    global globalFont
    upvar $fntTest fontTest
    
    if {[$path curselection] == "" } return ;
    
    set fontFamily "[$path get [$path curselection]]"
    set fontSize 12
    set fontWeight normal
    if {[info exist globalFont]} {
	unset globalFont
    }
    set globalFont [list $fontFamily $fontSize $fontWeight]
    
    $fntTest configure -font $globalFont
}

proc RemoveSelectedTodo { } {
    global j

    destroy .tableWindow
    
    set topLevel [toplevel .todoListsToRemove]

    grab $topLevel
    focus $topLevel

    set frBtn [frame $topLevel.frButtons]
    
    # set selectAll [button $frBtn.select-all -text "Select All" ]
    #set unselectAll [button $frBtn.unselect-all -text "Unselect All" -command [list unselectAllTodos]]
    set delete [button $frBtn.delete -text "Delete " -command [list DeleteTodos]]
    set cancel [button $frBtn.cancel -text "Cancel" -command { destroy .todoListsToRemove; SetupEntryInterFace}]

    set frLbTodo [frame $topLevel.frLbTodo]
    set titleLabel [label $frLbTodo.titleLabel -text "Title"]
    set idLabel [label $frLbTodo.idlb -text "ID"]
    
    pack $idLabel $titleLabel -side left -anchor nw -padx 38

    pack configure $titleLabel -padx 12


    #bind $selectAll <Button-1> [list selectAllTodos %W]
    
    
    pack $frLbTodo  -fill x
    set j 0
    TodoDatabase foreach row {SELECT * FROM TodoDb} {

	StyleRemove $row
    }
    #pack $selectAll $unselectAll $delete $cancel -side left -anchor nw
    pack $delete $cancel -side left -anchor nw
    pack $frBtn -fill x
}

############################################################################
#proc selectAllTodos { path } {
#    global Stack
#   set children [pack slave .todoListsToRemove]
#   if { $children != "" } {
#	foreach ch $children {
#	    if {[regexp {(frLabels)} $ch]} {
#		#puts $ch
#		set chkBtnNum [regexp {[[:digit:]]+} $ch num]
#		${ch}.chkBtn_$num invoke
#
#	    }
#	}
#	$path configure -state disabled
#	bind $path <ButtonPress-1> {}
#    }   
#}#######################################################################

proc StyleRemove { createdTodo } {
    global j frLabels todoid
    set topLevel .todoListsToRemove
    set todoid [dict get $createdTodo id]
    set todotitle [dict get $createdTodo Title]

    set frLabels [frame $topLevel.frLabels$j]
    set todoID [label $frLabels.idLabel -text "$todoid" ]
    set todoTITLE [label $frLabels.idTitle -text "$todotitle"]
    



    set chkBtn [checkbutton $frLabels.chkBtn_$j -variable $todoid -onvalue "false" -offvalue "true" ]
    
    pack $chkBtn $todoID $todoTITLE -side left -fill x -anchor nw
    
    
    
    pack configure $todoID -padx 15
    pack configure $todoTITLE -padx 20
    pack $frLabels  -fill x

    
    bind $chkBtn <Button-1> [list saveMe $frLabels $todoid $todoid]
    bind $todoID <ButtonPress-1> {[list $chkBtn select]}
    bind $todoTITLE <ButtonPress-1> {[list $chkBtn select]}
    incr j
    
}

proc saveMe { path tdid realId } {
    global Stack
    upvar 1 $tdid trueOrFalse
    set Stack($realId) [list $path $trueOrFalse $realId]
    puts "realId:$realId \n path:$path trueOrFalse:$trueOrFalse"
    if {$trueOrFalse == "false" } {
	puts [array names Stack]
	unset Stack($realId)
    }
}
proc DeleteTodos { } {
    global Stack
    foreach x [array names Stack] {

	set parent [lindex $Stack($x) 0]
	set todoid [lindex $Stack($x) 2]

	
	pack forget $parent
	
	TodoDatabase allrows {
	    DELETE FROM TodoDb WHERE id=$todoid
	}

    }
}

proc createInterface { } {
    
    catch {
	TodoDatabase foreach row {SELECT * FROM ConfigDb} {
	    lappend configlist $row
	}
    
	foreach l $configlist {
	    lassign $l key value
	    option add *${key} ${value}
	}
    }
    
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
    set detailsDetails [text $TodoDetailsFrame.text -yscrollcommand {.addNewEntryWindows.todoDetailsFrame.yview set} -height 12]
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
    
    catch {tdbc::sqlite3::connection create TodoDatabase TodoSqliteDatabase.sql} err
    SqliteDatabase
}

proc SqliteDatabase { } {
    global todo-title dayvar monthvar yearvar todo-hour todo-minute todo-amPm detailsDetails


    set title ${todo-title}
    set hour ${todo-hour}
    set minute ${todo-minute}
    set amPm ${todo-amPm}
    set sep :
    set content [$detailsDetails get 0.0 end]
    
    catch { destroy .addNewEntryWindows }
    
    if {[regexp {TodoDb} [TodoDatabase tables]] == 0 } {
	TodoDatabase allrows {
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

    if {[regexp {ConfigDb} [TodoDatabase tables]] == 0} {
	TodoDatabase allrows {
	    CREATE TABLE ConfigDb (
				   foreground TEXT,
				   background TEXT,
				   font TEXT
				   );
	}
    }

    
    TodoDatabase allrows {
	INSERT INTO TodoDb (Title,Day,Month,Year,Minute,Hour,AmPm,Content) VALUES ($title,$dayvar,$monthvar,$yearvar,$minute,$hour,$amPm,$content);
    }

    SetupEntryInterFace
}

proc SetupEntryInterFace { } {
    
    global i
    
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
    

    grid $tableFrame -sticky news
    grid $id $title $date $time $todoDetail
    
    set i 1;
    
    if { [catch {
	
	TodoDatabase foreach row {SELECT * FROM TodoDb} {
	    StyleEntry $row
	}
	
    } err ] } {
	destroy .tableWindow
	set selection [tk_messageBox -title "No Todo in Database" \
			   -message "You have not added any todo yet \n Do you want to add a new Todo" \
			   -icon info -type yesno]

	puts $err

	if { $selection == "yes" } {
	    AddNewEntry
	}
    }
    wm withdraw .
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


    set todoRemove [button $todoFrame.btn-remove-todo -compound left -image removeTodo -relief flat \
			-command [list RemoveTodo $todoFrame $todoid $FrameDetails]]
    
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
    # bind $todoRemove <ButtonPress-1> [list RemoveTodo $todoFrame $todoid $FrameDetails]
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
    foreach x [grid slave $showContent] {
    	grid forget $x
	# destroy the window. It should not exists
	# This was done to fix a bug
	# grid forget $x forgets the widgets, but the widget name still exists

	destroy $x
    }
    #grid forget $showContent
    
    
    for {set i [$showContent cget -height] } {$i >= 0} { } {	    
	$showContent configure -height $i
	set i [expr {$i - 10}]
	update idletasks
    }

}
proc OpenTodo {todoid showContent} {

    TodoDatabase foreach openTodo {SELECT * FROM TodoDb WHERE id=$todoid} {
	
	set tododay [dict get $openTodo Day]
	set todomonth [dict get $openTodo Month]
	set todoyear [dict get $openTodo Year]
	
	set tododate ${tododay}/${todomonth}/${todoyear}
	
	set todotime [dict get $openTodo Hour]:[dict get $openTodo Minute][dict get $openTodo AmPm]
	
	set todocontent [dict get $openTodo Content]

	set todoDateFrame [frame $showContent.date-frame ]
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
	
	
	grid $todoContentValue -row 3 -columnspan 100 -sticky news
	

        for {set i 0} {$i <= 300} { } {
	    $showContent configure -height $i
	    set i [expr {$i + 50}]
	    update idletasks
	}
    }
}


proc RemoveTodo {parent todoid { showContent {}}} {

    
    
    grid forget $parent
    grid forget $showContent	


    
    TodoDatabase allrows {
	DELETE FROM TodoDb WHERE id=$todoid
    }


    
    
    if { 0 } {
	set currId [${parent}.id cget -text]
	TodoDatabase allrows {
	    DELETE FROM TodoDb WHERE id=$todoid
	}
	
	set i 0;
	set j 1;
	set current [expr {$currId + $i}]
	set previous [expr {$currId + $j}]
	puts "$current $previous"
	while { 1 }  {
	    #TodoDatabase foreach update {UPDATE TodoDb SET id=$current WHERE id=$previous} {
	    #incr i;
	    #incr j;
	    #set current [expr {$currId + $i}]
	    #set previous [expr {$currId + $j}]
	    #}
	    incr i;
	    incr j;
	    set current [expr {$currId + $i} ]
	    set previous [expr {$currId + $j}]
	    break; 
	}
	

	destroy .tableWindow
	SetupEntryInterFace
    }

    
}


createInterface
