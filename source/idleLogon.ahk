;Written by KramWell.com - 11/JUN/2018
;A program to mine CPU coins when a computer is deemed idle.

#NoEnv
SetWorkingDir %A_ScriptDir%

#NoTrayIcon

;###########################
;what this does: it stops then starts user idle process that collects all the log files- 
;this happens when the user logs on. and triggers everyone who is logged on to run the program again.

;check for ini file to load config.
INICONF := "config.ini"
;Check if ini file exists
if !FileExist(INICONF){
	FileAppend,[%TimeString%] ERROR: %INICONF% file does not exist. Program will exit.`n, %outputFile%
	ExitApp
}

	IniRead, EXEminer, %A_ScriptDir%\%INICONF%, SETTINGS, EXEMINER
	if (EXEminer = "ERROR" OR !EXEminer){
		;no settings specified
		FileAppend,[%TimeString%] ERROR: EXEMINER value not set or present in ini.`n, %outputFile%
		ExitApp
	}

outputFile := A_ScriptDir "\idleOutput.log"

FormatTime, TimeString, A_Now, dd/MM/yy HH:mm:ss

FileAppend,[%TimeString%] USER LOGGED IN`n, %outputFile%

	If InStr(StdOutToVar("SCHTASKS /END /TN ""\Idle Miner\idleStateTask"" "), "SUCCESS"){
		FileAppend,[%TimeString%] Successfully ended idleStateTask task`n, %outputFile%
	
		If InStr(StdOutToVar("TASKKILL /F /IM idleState.exe /T"), "SUCCESS"){
			FileAppend,[%TimeString%] Closed idleState.exe`n, %outputFile%
		}else{
			FileAppend,[%TimeString%] No process to close (idleState.exe)`n, %outputFile%
		}
	
		Sleep, 10000
		
		FormatTime, TimeString, A_Now, dd/MM/yy HH:mm:ss
		If InStr(StdOutToVar("SCHTASKS /RUN /TN ""\Idle Miner\idleStateTask"" /I "), "SUCCESS"){
			FileAppend,[%TimeString%] Successfully started idleStateTask task`n, %outputFile%
			
			Sleep, 10000
			
			FormatTime, TimeString, A_Now, dd/MM/yy HH:mm:ss	
			COMMANDTORUN := "TASKKILL /F /IM " EXEminer " /T"	
			If InStr(StdOutToVar(COMMANDTORUN), "SUCCESS"){
				FileAppend,[%TimeString%] Closed %EXEminer%`n, %outputFile%
			}else{
				FileAppend,[%TimeString%] No process to close (%EXEminer%)`n, %outputFile%
			}				
					
			FileAppend,[%TimeString%] Finished running idleLogon`n, %outputFile%
				
		}else{
			FileAppend,[%TimeString%] ERROR: Could not restart idleStateTask`n, %outputFile%
		}
		
	}else{
		FileAppend,[%TimeString%] ERROR: could not end idleStateTask task`n, %outputFile%
	}



StdOutToVar( sCmd ) { ;  GAHK32 ; Modified Version : SKAN 05-Jul-2013  http://goo.gl/j8XJXY                             
  Static StrGet := "StrGet"     ; Original Author  : Sean 20-Feb-2007  http://goo.gl/mxCdn  
   
  DllCall( "CreatePipe", UIntP,hPipeRead, UIntP,hPipeWrite, UInt,0, UInt,0 )
  DllCall( "SetHandleInformation", UInt,hPipeWrite, UInt,1, UInt,1 )

  VarSetCapacity( STARTUPINFO, 68, 0  )      ; STARTUPINFO          ;  http://goo.gl/fZf24
  NumPut( 68,         STARTUPINFO,  0 )      ; cbSize
  NumPut( 0x100,      STARTUPINFO, 44 )      ; dwFlags    =>  STARTF_USESTDHANDLES = 0x100 
  NumPut( hPipeWrite, STARTUPINFO, 60 )      ; hStdOutput
  NumPut( hPipeWrite, STARTUPINFO, 64 )      ; hStdError

  VarSetCapacity( PROCESS_INFORMATION, 16 )  ; PROCESS_INFORMATION  ;  http://goo.gl/b9BaI      
  
  If ! DllCall( "CreateProcess", UInt,0, UInt,&sCmd, UInt,0, UInt,0 ;  http://goo.gl/USC5a
              , UInt,1, UInt,0x08000000, UInt,0, UInt,0
              , UInt,&STARTUPINFO, UInt,&PROCESS_INFORMATION ) 
   Return "" 
   , DllCall( "CloseHandle", UInt,hPipeWrite ) 
   , DllCall( "CloseHandle", UInt,hPipeRead )
   , DllCall( "SetLastError", Int,-1 )     

  hProcess := NumGet( PROCESS_INFORMATION, 0 )                 
  hThread  := NumGet( PROCESS_INFORMATION, 4 )                      

  DllCall( "CloseHandle", UInt,hPipeWrite )

  AIC := ( SubStr( A_AhkVersion, 1, 3 ) = "1.0" )                   ;  A_IsClassic 
  VarSetCapacity( Buffer, 4096, 0 ), nSz := 0 
  
  While DllCall( "ReadFile", UInt,hPipeRead, UInt,&Buffer, UInt,4094, UIntP,nSz, UInt,0 )
   sOutput .= ( AIC && NumPut( 0, Buffer, nSz, "UChar" ) && VarSetCapacity( Buffer,-1 ) ) 
              ? Buffer : %StrGet%( &Buffer, nSz, "CP850" )
 
  DllCall( "GetExitCodeProcess", UInt,hProcess, UIntP,ExitCode )
  DllCall( "CloseHandle", UInt,hProcess  )
  DllCall( "CloseHandle", UInt,hThread   )
  DllCall( "CloseHandle", UInt,hPipeRead )

Return sOutput,  DllCall( "SetLastError", UInt,ExitCode )
}