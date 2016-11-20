#!/usr/bin/env wish

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
    puts $showContent
    foreach children [grid slave $showContent] {
	grid forget $children
    }
    for {set i [$showContent cget -height] } {$i >= 0} { } {

	$showContent configure -height $i
	set i [expr {$i - 1}]
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



	#set todoDateLabel [label $showContent.date-label -text "Date:-            $tododate"]
	#set todoTimeLabel [label $showContent.time-label -text "Time:-            $todotime"]
	#set todoContentLabel [label $showContent.content-label -text "$todocontent"]

	#grid $todoDateLabel -sticky news
	#grid $todoTimeLabel -sticky news
	#grid $todoContentLabel -sticky news
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
