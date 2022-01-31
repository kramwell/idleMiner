;Written by KramWell.com - 11/JUN/2018
;A program to mine CPU coins when a computer is deemed idle.

#NoEnv
SetWorkingDir %A_ScriptDir%

#Persistent
#NoTrayIcon
#SingleInstance FORCE

;check for ini file to load config.
INICONF := "config.ini"

	IniRead, TimeIdleSettings, %A_ScriptDir%\%INICONF%, SETTINGS, TIMEIDLESETTINGS
	if (TimeIdleSettings = "ERROR" OR !TimeIdleSettings){
		;no settings specified
		FileAppend,[%TimeString%] ERROR: TimeIdleSettings value not set or present in ini- using default TimeIdle.`n, %outputFile%
		TimeIdleSettings := "TimeIdle"
	}

	IniRead, IdleTimer, %A_ScriptDir%\%INICONF%, SETTINGS, IDLESTATETIMER
	if (IdleTimer = "ERROR" OR !IdleTimer){
		;no settings specified
		FileAppend,[%TimeString%] ERROR: IdleTimer value not set or present in ini- using default.`n, %outputFile%
		IdleTimer := "5000"
	}

	
;here is where we dump the ini file settings to log for debugging.

FileAppend,     TimeIdle Settings: %TimeIdleSettings%.`n, %outputFile%
FileAppend,     idleState Timer: %IdleTimer%.`n, %outputFile%	
	
;###################
;this is the main driver of the app. when run it will collect the idle time of the user. idle time is based on A_TimeIdle but can be altered in settings.

FileDelete, %A_ScriptDir%\logs\*-idleTime.log

logfile = %A_ScriptDir%\logs\%A_UserName%-idleTime.log

SetTimer, IdleTime, %IdleTimer%

IdleTime:

	if (TimeIdleSettings = "TimeIdle"){
		PickedTimeIdle := A_TimeIdle
	}else if (TimeIdleSettings = "TimeIdlePhysical"){
		PickedTimeIdle := A_TimeIdlePhysical
	}else if (TimeIdleSettings = "TimeIdleKeyboard"){
		PickedTimeIdle := A_TimeIdleKeyboard
	}else if (TimeIdleSettings = "TimeIdleMouse"){
		PickedTimeIdle := A_TimeIdleMouse
	}else{
		;default if nothing specified- just in case
		PickedTimeIdle := A_TimeIdle
	}

	FormatTime, TimeString, A_Now, dd/MM/yy HH:mm:ss
	NewTime := ConvertMSToMinSec(PickedTimeIdle)
	FileAppend, %PickedTimeIdle%:::%A_UserName%:::[%TimeString%]:::[%NewTime%]`n, %logfile%

Return

ConvertMSToMinSec(ms){
  return floor(ms / 1000 / 60) "m " . round(mod(ms / 1000, 60)) "s"
}

