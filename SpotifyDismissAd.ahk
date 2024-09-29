#Requires AutoHotkey v1.1.37+

; ahk setup
SetWorkingDir, %A_ScriptDir%
DetectHiddenWindows, 1
; https://www.autohotkey.com/boards/viewtopic.php?t=6413
Process, Priority,, N
SetBatchLines, 30ms
ListLines, 0
SetTitleMatchMode 2
SetTitleMatchMode Fast
SetWinDelay, 0

; requires https://github.com/Masonjar13/AHK-Library/blob/master/Required-Libraries/VA.ahk
#Include %A_ScriptDir%/AHK-Library/Required-Libraries/VA.ahk
#Persistent
#SingleInstance Ignore
#WinActivateForce
#NoEnv
#KeyHistory 0
#MaxMem 1

; script compile directives and installs
;@Ahk2Exe-Obey U_bits, = %A_PtrSize% * 8
;@Ahk2Exe-Obey U_type, = "%A_IsUnicode%" ? "U" : "A"
;@Ahk2Exe-ExeName %A_ScriptDir%\Bin\%A_ScriptName~\.[^\.]+$%_%U_type%%U_bits%
;@Ahk2Exe-SetVersion 1.0.0.0
;@Ahk2Exe-SetMainIcon icon.ico
;@Ahk2Exe-SetName Spotify Dismiss Ad
;@Ahk2Exe-SetDescription Spotify Dismiss Ad
;@Ahk2Exe-SetLanguage 0x009
;@Ahk2Exe-SetCopyright Copyright (c) 2024 Shimei Sagar Das

FileInstall, icon.ico, icon.ico, 0
FileInstall, muted.png, muted.png, 0
FileInstall, unmuted.png, unmuted.png, 0

; variable initializations
global debug
global appPID
global cpuMaxUsgCount
global memMaxUsgCount

; Spotify window
global programName
global programPath
global spotifyWinID
global spotifyWinPID
global currSpotifyWinTitle
global spotifyWinState
global isSpotifyInstalled
global isAdBreak
global isMusicPaused
global isMute
global isManualMute

; gui
global appName
global mutedPicHandle
global unmutedPicHandle
global aboutText1
global aboutText2
global defaultSettings
global guiHwnd
global nowPlayingControlID
global launchSpotifyBtnControlID
global perfInfoControlID
global tabControlID
global muteBtnControlID
global radioAAAControlID
global radioAABControlID
global checkBAControlID

debug := 0
programName := "Spotify.exe"
appName := "Spotify Dismiss Ad"
mutedPicHandle := LoadPicture("muted.png", "GDI+ W32 H32", 0)
unmutedPicHandle := LoadPicture("unmuted.png", "GDI+ W32 H32", 0)
aboutText1 := "OS: " A_OSVersion " " (A_Is64bitOS?"64-bit":"32-bit") "`nAutoHotkey: " A_AhkVersion " " (A_PtrSize=8?"64-bit":"32-bit") "`nSpotify: "
aboutText2 = 
(
`n`nMade by <a href="https://github.com/thecipherninja">thecipherninja</a>
Source: <a href="https://github.com/thecipherninja/spotify-dismiss-ad/tree/main">GitHub</a>`n
Picture attributions:
<a href="https://www.flaticon.com/free-icons/silent" title="silent icons">Silent icons created by Freepik - Flaticon</a>
<a href="https://www.flaticon.com/free-icons/audio" title="audio icons">Audio icons created by Freepik - Flaticon</a>`n
<a href="https://github.com/thecipherninja/spotify-dismiss-ad/blob/main/LICENSE" title="title">Copyright (c) Notice</a>
)
defaultSettings =
(
radioAAAControlID=1
radioAABControlID=0
checkBAControlID=0
)
isSpotifyInstalled := 0
isManualMute := 0
appPID := DllCall("GetCurrentProcessId")

Menu, Tray, UseErrorLevel
Menu, Tray, Icon, icon.ico,, 1
Menu, Tray, Tip, %appName%

onError("onErrorCallback")
onExit("onExitCallback")
isSpotifyInstalled := getSpotifyInstall()
createGui()
loadSettings()
updateGui()

; update gui every x ms
SetTimer, updateGui, 500, 2
; update app performance info every x ms
SetTimer, checkPerf, 5000, 1

; hotkeys
^+F5::Reload
^+x::guiClose()

; function definitions

; initialize default variables
setDefaults() {
    spotifyWinPID := ""
    spotifyWinID := ""
    currSpotifyWinTitle := ""
    spotifyWinState := ""
    isAdBreak := ""
    isMusicPaused := ""
}

; check whether Spotify is installed
getSpotifyInstall() {
    Try {
        ; https://www.autohotkey.com/boards/viewtopic.php?p=373305#p373305
        dir := ComObjCreate("Shell.Application").NameSpace("shell:Appsfolder")
        for item in dir.Items {
            If item.name = "Spotify"
                programPath := item.path
        }
        If !(programPath)
            Return false
        ; if found check whether it is different from .ini file
        ; check whether Spotify was installed from web or MS Store
        If (programPath = "SpotifyAB.SpotifyMusic_zpdnekdrzrea0!Spotify") {
            regPaths := ["SOFTWARE\Classes\PackagedCom\Package", "SOFTWARE\Classes\ActivatableClasses\Package"
                        , "SOFTWARE\Classes\Extensions\ContractId\Windows.AppService\PackageId"]
            For _, regPath in regPaths
            {
                Loop, Reg, HKCU\%regPath%, K
                {
                    If A_LoopRegName contains SpotifyAB.SpotifyMusic,zpdnekdrzrea0
                    {
                        packageID := A_LoopRegName
                        Break
                    }
                }
                If (packageID)
                    Break
            }
            If !(packageID)
                Return false
            arr := StrSplit(packageID, "_")
            programVersion := arr[2]
            programBinaryType := (arr[3] = "x64" ? "64-bit" : "32-bit")
            programPath := "shell:AppsFolder\" programPath
        } Else {
            FileGetVersion, programVersion, %programPath%
            DllCall("GetBinaryTypeW", "WStr", programPath, "UIntP", binType)
            programBinaryType := (binType = 0) ? "32-bit" : ((binType = 6) ? "64-bit" : "")
        }
        aboutText1 .= programVersion " " programBinaryType
    } Catch, e {
        showErrorDialog("Failed to get Spotify installation path", e)
    }
    Return true
}

; launch Spotify
launchSpotify(ByRef processExists := false, ByRef winState := 0, ByRef playState := false) {
    Try {
        isSpotifyInstalled := getSpotifyInstall()
        If !(isSpotifyInstalled)
            Return false
        Try {
            Run, %programPath%
        } Catch, e {
            showErrorDialog("Failed to start Spotify process", e)
            Return false
        }
        Loop
        {
            Sleep, 200
        } Until (getAppInfo() && spotifyWinID)
        refreshSpotifyWindow(processExists, winState, playState)
        getAppInfo()
        (getMute() = "V1") ? setMute(0) : ""
    } Catch, e {
        showErrorDialog("Error launching Spotify", e)
    }
    Return % (spotifyWinID = "")
}

; relaunch Spotify
relaunchSpotify(ByRef killLast := true) {
    getAppInfo()
    lastWinState := spotifyWinState
    lastPlayState := !isMusicPaused
    If (killLast) {
        ; pause music
        Try {
            PostMessage, 0x0319,, 14 << 16,, ahk_id %spotifyWinID%
        } Catch, e {
            showErrorDialog("Failed to send window message Pause to Spotify", e)
        }
        ; kill Spotify
        If (spotifyWinPID)
            WinKill, ahk_pid %spotifyWinPID%
        Loop
        {
            Sleep, 200
            Process, Close, %programName%
            Process, Exist, %programName%
        } Until (!(ErrorLevel) || !(getAppInfo()))
        setDefaults()
        isAdBreak := 0
    }
    launchSpotify(killLast, lastWinState, lastPlayState)
    Return true
}

; get current Spotify process/window info
getAppInfo() {
    Try {
        Process, Exist, %programName%
        If !(ErrorLevel) {
            setDefaults()
            Return false
        }
        spotifyWinPID := ErrorLevel
        WinGet, spotifyWinID, ID, ahk_exe %programName% ahk_PID %spotifyWinPID% ahk_class Chrome_WidgetWin_1
        WinGet, spotifyWinState, MinMax, ahk_id %spotifyWinID%
        getSpotifyWinTitle()
        updateAppStartButton()
    } Catch, e {
        showErrorDialog("Error getting Spotify process info", e)
    }
    Return true
}

; get current Spotify window title text
getSpotifyWinTitle() {
    WinGetTitle, currSpotifyWinTitle, ahk_exe %programName% ahk_PID %spotifyWinPID% ahk_id %spotifyWinID% ahk_class Chrome_WidgetWin_1
    Return currSpotifyWinTitle
}

; check whether Ad is playing
getSpotifyAd() {
    If currSpotifyWinTitle contains -
    {
        If currSpotifyWinTitle contains Advertisement,Spotify - Advertisement
            isAdBreak := 1
        Else
            isAdBreak := 0
    }
    ; some ads do not have Advertisment word on window title
    Else
    {
        ; if music paused, window title will be "Spotify Free"
        If (!isMusicPaused)
            isAdBreak := 1
    }
    Return isAdBreak
}

; get now playing text info and mute/unmute
getNowPlayingText() {
    ; check Spotify installation
    If !(isSpotifyInstalled)
        Return "Install Spotify"
    ; check whether Spotify is running
    If !(spotifyWinPID)
        Return "Launch Spotify"
    ; check whether music is paused
    isMusicPaused := false
    If (currSpotifyWinTitle = "Spotify Free") {
        isMusicPaused := true
        Return "Music Paused"
    }
    Return currSpotifyWinTitle
}

; create app window gui
createGui() {
    static resetSettingsBtnControlID

    Gui, +HwndguiHwnd -Resize -MaximizeBox -Theme +OwnDialogs
    Gui, Font, s16, Verdana
    Gui, Add, Text, vnowPlayingControlID W500 R3 Center, Initializing

    Gui, Font, s12, Verdana
    Gui, Add, Button, vlaunchSpotifyBtnControlID HwndlaunchSpotifyBtnHwnd Section, Start Spotify

    Gui, Add, Picture, vmuteBtnControlID gsetMuteSetting HwndmuteBtnHwnd X+20 YS W32 H32 Center Section, HBITMAP:*%unmutedPicHandle%

    Gui, Font, s8, Verdana
    Gui, Add, Text, vperfInfoControlID X+20 YS W150 R4, CPU Usage:`nMemory Usage:

    ; static relaunchSpotifyBtnControlID
    ; Gui, Add, Button, vrelaunchSpotifyBtnControlID HwndrelaunchSpotifyBtnHwnd Section, Relaunch Spotify

    Gui, Add, Tab3, vtabControlID HwndtabHwnd X20 W500 Center, Settings||Help|About

    Gui, Tab, Settings,, Exact
    Gui, Add, GroupBox, XM+10 YP+30 W480 R2, Spotify
    Gui, Add, Text, XP+10 YP+20, Advertisement
    Gui, Add, Radio, vradioAAAControlID XP YP+20 Group Section, Mute
    Gui, Add, Radio, vradioAABControlID X+10, Skip

    Gui, Add, GroupBox, XM+10 YP+40 W480 R1, Application
    Gui, Add, Checkbox, vcheckBAControlID gcreateAppStartupShortcut XP+10 YP+20, Auto Start on Startup

    Gui, Add, Button, vresetSettingsBtnControlID XM+10 YP+30, Reset to Default

    Gui, Tab, Help,, Exact
    Gui, Add, Text, X+10 Y+10, Hotkeys:`n`nCtrl+Shift+F5 - Refresh`nCtrl+Shift+X - Quit

    Gui, Tab, About,, Exact
    Gui, Add, Link, X+10 Y+10, %aboutText1%%aboutText2%

    Try {
        ; https://www.autohotkey.com/boards/viewtopic.php?t=24432
        func1 := Func("performLongTask").Bind("launchSpotify")
        GuiControl, +g, launchSpotifyBtnControlID, %func1%
        ; func2 := Func("performLongTask").Bind("relaunchSpotify")
        ; GuiControl, +g, relaunchSpotifyBtnControlID, %func2%
        func3 := Func("performLongTask").Bind("saveSettings")
        GuiControl, +g, radioAAAControlID, %func3%
        GuiControl, +g, radioAABControlID, %func3%
        func4 := Func("loadSettings").Bind(true)
        GuiControl, +g, resetSettingsBtnControlID, %func4%
    } Catch, e {
        showErrorDialog("Error updating glabels of gui controls", e)
    }

    Try {
        ; set cursor to pointer while hovering on controls
        ; https://www.autohotkey.com/boards/viewtopic.php?p=536296#p536296
        cursor := DllCall("LoadImage", "Ptr", 0, "UInt", 32649, "UInt", 2, "Int", 0, "Int", 0, "UInt", (0x40)|(0x8000), "Ptr")
        winAPIFunc :=  A_PtrSize = 8 ? "SetClassLongPtrW" : "SetClassLongW"
        DllCall(winAPIFunc, "UInt", muteBtnHwnd, "Int", -12, "Ptr", cursor)
        DllCall(winAPIFunc, "UInt", launchSpotifyBtnHwnd, "Int", -12, "Ptr", cursor)
        DllCall(winAPIFunc, "UInt", tabHwnd, "Int", -12, "Ptr", cursor)
    } Catch, e {
        showErrorDialog("Error loading pointer cursor for gui", e)
    }

    Gui, Show,, %appName%

    aboutText1 := ""
    aboutText2 := ""
    Return
}

; restore gui if maximized
guiSize(ByRef GuiHwnd, ByRef EventInfo) {
    If (EventInfo = 2)
        Gui %GuiHwnd%:Restore
}

; update all gui components
updateGui() {
    getAppInfo()
    updateNowPlayingText()
    dismissSpotifyAd()
    Return
}

; Make the button active/inactive
updateAppStartButton() {
    buttonStatus := spotifyWinPID ? "Disable" : "Enable"
    Try {
        GuiControlGet, var, Enabled, launchSpotifyBtnControlID
        If ((spotifyWinPID) != (!var))
            GuiControl, %buttonStatus%, launchSpotifyBtnControlID
    } Catch, e {
        showErrorDialog("Error updating enable/disable app start button", e)
    }
	Return
}

; update now playing text
updateNowPlayingText() {
    checkTitleWorking()
    Try {
        GuiControl, Text, nowPlayingControlID, % getNowPlayingText()
    } Catch, e {
        showErrorDialog("Error updating Now Playing text", e)
    }
    Return
}

; change mute/unmute picture
updateMuteButton() {
    Try {
        pic = HBITMAP:*%unmutedPicHandle%
        If (isMute)
            pic = HBITMAP:*%mutedPicHandle%
        GuiControl,, muteBtnControlID, %pic%
    } Catch, e {
        showErrorDialog("Error updating mute button picture", e)
    }
    Return
}

; update performance info of app
updatePerfInfo(ByRef cpuUsePct, ByRef memUseMB) {
    Try {
        str := "CPU Usage: " Round(cpuUsePct, 1) " `%`nMemory Usage: " Round((memUseMB/1024), 1) " MB"
        GuiControl, Text, perfInfoControlID, %str%
    } Catch, e {
        showErrorDialog("Error updating performance info", e)
    }
    Return
}

; load settings from .ini
loadSettings(ByRef default := false) {
    Try {
        If (default || !(FileExist("settings.ini")))
            iniValues := defaultSettings
        Else
            IniRead, iniValues, settings.ini, Settings
        Loop, Parse, iniValues, `n
        {
            arr := StrSplit(A_LoopField, "=")
            GuiControl,, % arr[1], % arr[2]
        }
        performLongTask("saveSettings")
        createAppStartupShortcut()
    } Catch, e {
        showErrorDialog("Failed to load settings", e)
    }
    Return true
}

; save settings to .ini
saveSettings() {
    Try {
        path := "settings.ini"
        Gui %guiHwnd%:Submit, NoHide
        If !(FileExist(path))
            FileAppend,, %path%, UTF-16
        iniValues := defaultSettings
        Loop, Parse, iniValues, `n
        {
            key := StrSplit(A_LoopField, "=")[1]
            GuiControlGet, val,, %key%
            IniWrite, %val%, %path%, Settings, %key%
        }
    } Catch, e {
        showErrorDialog("Failed to save settings", e)
    }
    Return true
}

; mute/skip Spotify ad
dismissSpotifyAd() {
    getSpotifyAd()
    performLongTask("saveSettings")
    If (radioAAAControlID && !(isManualMute)) {
        ; if ad is playing AND NOT on mute, then mute
        If (isAdBreak && !(isMute))
            setMute(1)
        ; if ad is NOT playing AND is on mute, then unmute
        Else If (!(isAdBreak) && isMute)
            setMute(0)
    }
    If (radioAABControlID && isAdBreak)
        performLongTask("relaunchSpotify")
    Return
}

; check whether Spotify window title is empty
checkTitleEmpty() {
    getAppInfo()
    str := StrReplace(currSpotifyWinTitle, " ")
    Return % (spotifyWinID != "" ?  (str = "") : false)
}

; if Spotify window title is empty refresh window
checkTitleWorking() {
    getAppInfo()
    returnVal := (spotifyWinID != "" ? (checkTitleEmpty() ? performLongTask("refreshSpotifyWindow") : false) : true)
    Return returnVal
}

; refresh Spotify window
refreshSpotifyWindow(ByRef isRelaunched, ByRef lastWinState, ByRef lastPlayState) {
    Try {
        ; set window state to what it was after relaunching Spotify
        If (lastWinState = -1) {
            ; 0x0112 = WM_SYSCOMMAND, 0xF020 = SC_MINIMIZE
            PostMessage, 0x0112, 0xF020,,, ahk_id %spotifyWinID%
        ; Spotify was minimized to tray
        } Else If (lastWinState = "") {
            ; 0x0112 = WM_SYSCOMMAND, 0xF060 = SC_CLOSE
            PostMessage, 0x0112, 0xF060,,, ahk_id %spotifyWinID%
        } Else If (lastWinState = 0) {
            ; 0x0112 = WM_SYSCOMMAND, 0xF120 = SC_RESTORE
            PostMessage, 0x0112, 0xF120,,, ahk_id %spotifyWinID%
        } Else If (lastWinState = 1) {
            ; 0x0112 = WM_SYSCOMMAND, 0xF030 = SC_MAXIMIZE
            PostMessage, 0x0112, 0xF030,,, ahk_id %spotifyWinID%
        }

        ; toggle play/pause to update Spotify window title if Spotify is already running on another device
        SoundGet, mute, MASTER, MUTE
        If (mute = "Off")
            SoundSet, 1, MASTER, MUTE
        WinActivate, ahk_id %spotifyWinID%
        Sleep, 2000
        Try {
            PostMessage, 0x0319,, 14 << 16,, ahk_id %spotifyWinID%
            PostMessage, 0x0319,, 14 << 16,, ahk_id %spotifyWinID%
            If (isRelaunched && lastPlayState)
                PostMessage, 0x0319,, 14 << 16,, ahk_id %spotifyWinID%
        } Catch, e {
            showErrorDialog("Failed to send PostMessage to Spotify", e)
        }
        SoundGet, mute, MASTER, MUTE
        If (mute = "On")
            SoundSet, 0, MASTER, MUTE

        getAppInfo()
    } Catch, e {
        showErrorDialog("Error refreshing Spotify window", e)
    }
    Return % checkTitleEmpty()
}

; create/delete app shortcut in startup dir
createAppStartupShortcut() {
    saveSettings()
    If (checkBAControlID) {
        Try {
            FileCreateShortcut, %A_ScriptFullPath%,%A_Startup%\%appName%.lnk,%A_InitialWorkingDir%,,%appName%`n%A_ScriptFullPath%`n[Ctrl+Alt+S],%A_IconFile%,s
        } Catch, e {
            showErrorDialog("Error creating app shortcut", e)
        }
        Return
    }
    Try {
        Loop, Files, %A_Startup%\*.lnk, F
        {
            path := A_LoopFileFullPath
            FileGetShortcut, %path%, target
            If (target == A_ScriptFullPath)
                FileDelete, %path%
        }
    } Catch, e {
        showErrorDialog("Error deleting app shortcut", e)
    }
    Return
}

; toggle mute manually
setMuteSetting() {
    If (setMute("t"))
        isManualMute := isMute
    Return
}

; get Spotify mute info
getMute() {
    Try {
        If !(spotifyWinPID)
            Return false
        If !(volume := GetVolumeObject(spotifyWinPID))
            Return false
        VA_ISimpleAudioVolume_GetMute(volume, Mute)
        ObjRelease(volume)
        isMute := Mute
    } Catch, e {
        showErrorDialog("Error getting mute", e)
    }
	Return "V" Mute
}

; mute/unmute Spotify
setMute(ByRef mode) {
    Try {
        If !(volume := GetVolumeObject(spotifyWinPID))
            Return false
        VA_ISimpleAudioVolume_GetMute(volume, Mute)
        ; toggle mute/unmute
        If (mode == "t") {
            VA_ISimpleAudioVolume_SetMute(volume, !Mute)
        ; mute/unmute manually
        } Else If (mode == 1 || mode == 0) {
            If (Mute != mode)
                VA_ISimpleAudioVolume_SetMute(volume, mode)
        }
        VA_ISimpleAudioVolume_GetMute(volume, Mute)
        ObjRelease(volume)
        isMute := Mute
        updateMuteButton()
    } Catch, e {
        showErrorDialog("Error muting/unmuting", e)
    }
	Return "V" Mute
}

; perform tasks which need to halt timer
performLongTask(ByRef func) {
    SetTimer, updateGui, Off
    returnValue := %func%()
    SetTimer, updateGui, On
    Return returnValue
}

; check app performance
checkPerf() {
    cpuUsePct := getProcessTimes(appPID)
    memUseMB := getPrivateWorkingSet(appPID)
    updatePerfInfo(cpuUsePct, memUseMB)
    ; If cpu usage hits 50%
    If (cpuUsePct > 50.0)
        cpuMaxUsgCount++
    ; If memory usage hits 20 MB
    If (memUsePct > 20.0)
        memMaxUsgCount++
    ; If limits are reached for either for timer x 3 seconds, exit
    If ((cpuMaxUsgCount > 3) || (memMaxUsgCount > 3))
        ExitApp
    Return
}

; get app memory usage in MB
; https://www.autohotkey.com/boards/viewtopic.php?p=268808#p268808
getPrivateWorkingSet(ByRef PID) {
    bytes := ComObjGet("winmgmts:")
            .ExecQuery("Select * from Win32_PerfFormattedData_PerfProc_Process Where IDProcess=" PID)
            .ItemIndex(0).WorkingSetPrivate
    Return bytes//1024
}

; Process cpu usage as percent of total CPU
; https://www.autohotkey.com/board/topic/113942-solved-get-cpu-usage-in/
; Return values
; -1 on first run
; -2 if process doesn't exist or you don't have access to it
getProcessTimes(ByRef PID) {
    static aPIDs := []
    ; If called too frequently, will get mostly 0%, so it's better to just return the previous usage 
    if aPIDs.HasKey(PID) && A_TickCount - aPIDs[PID, "tickPrior"] < 250
        return aPIDs[PID, "usagePrior"] 

    DllCall("GetSystemTimes", "Int64*", lpIdleTimeSystem, "Int64*", lpKernelTimeSystem, "Int64*", lpUserTimeSystem)
    if !hProc := DllCall("OpenProcess", "UInt", 0x400, "Int", 0, "Ptr", pid)
        return -2, aPIDs.HasKey(PID) ? aPIDs.Remove(PID, "") : "" ; Process doesn't exist anymore or don't have access to it.
    DllCall("GetProcessTimes", "Ptr", hProc, "Int64*", lpCreationTime, "Int64*", lpExitTime, "Int64*", lpKernelTimeProcess, "Int64*", lpUserTimeProcess)
    DllCall("CloseHandle", "Ptr", hProc)
    
    if aPIDs.HasKey(PID) ; check if previously run
    {
        ; find the total system run time delta between the two calls
        systemKernelDelta := lpKernelTimeSystem - aPIDs[PID, "lpKernelTimeSystem"] ;lpKernelTimeSystemOld
        systemUserDelta := lpUserTimeSystem - aPIDs[PID, "lpUserTimeSystem"] ; lpUserTimeSystemOld
        ; get the total process run time delta between the two calls 
        procKernalDelta := lpKernelTimeProcess - aPIDs[PID, "lpKernelTimeProcess"] ; lpKernelTimeProcessOld
        procUserDelta := lpUserTimeProcess - aPIDs[PID, "lpUserTimeProcess"] ;lpUserTimeProcessOld
        ; sum the kernal + user time
        totalSystem :=  systemKernelDelta + systemUserDelta
        totalProcess := procKernalDelta + procUserDelta
        ; The result is simply the process delta run time as a percent of system delta run time
        result := 100 * totalProcess / totalSystem
    }
    else result := -1

    aPIDs[PID, "lpKernelTimeSystem"] := lpKernelTimeSystem
    aPIDs[PID, "lpUserTimeSystem"] := lpUserTimeSystem
    aPIDs[PID, "lpKernelTimeProcess"] := lpKernelTimeProcess
    aPIDs[PID, "lpUserTimeProcess"] := lpUserTimeProcess
    aPIDs[PID, "tickPrior"] := A_TickCount
    return aPIDs[PID, "usagePrior"] := result 
}

; unhandled errors callback
onErrorCallback(ByRef e) {
    showErrorDialog("Unhandled Exception", e)
    ; logError(e)
    Return true
}

; show gui dialog with error details
showErrorDialog(ByRef msg, ByRef e) {
    errorText := "Error Details:`n`n" msg
    If (debug) {
        errorText .= "`n`nFunction/Label: " e.What "`n`nMessage/ErrorLevel: " e.Message
        errorText .= "`n`nAdditional Info: " e.Extra "`n`nFile: " e.File "`n`nLine Number: " e.Line
        errorText .= "`n`nGetLastError(): " A_LastError
    }
    logError(e)
    SetTimer, updateGui, Off
    SetTimer, checkPerf, Off
    ; https://www.autohotkey.com/boards/viewtopic.php?t=60360
    Gui %guiHwnd%:+Disabled
    Gui, errorDialog:New, -MaximizeBox -Theme +Owner%guiHwnd%
    Gui, Add, Text,XM+20 YM+20 W400 H200, % errorText
    Gui, Show, AutoSize Center, Error Dialog
    Return
}

; things done after closing error dialog
errorDialogGuiClose() {
    Gui errorDialog:+Disabled +AlwaysOnTop
    Gui errorDialog:Destroy
    Gui %guiHwnd%:-Disabled
    Gui %guiHwnd%:Show
    SetTimer, updateGui, On
    SetTimer, checkPerf, Off
    Return
}

; log error
logError(ByRef e) {
    Try {
        If !(FileExist("error.log"))
            FileAppend, timestamp|file|line|what|message|extra`n, error.log
        FileAppend % A_NowUTC "|" e.File "|" e.Line "|" e.What "|" e.Message "|" e.Extra "`n", error.log
    } Catch, e {
        showErrorDialog("Error writing log", e)
    }
    Return
}

; things done after closing app gui
guiClose() {
    ExitApp
    Return
}

; callback on exiting app
onExitCallback() {
    Try {
        getAppInfo()
        Gui errorDialog:Destroy
        WinGet, appID, ID, ahk_pid %appPID% ahk_class AutoHotkeyGUI
        If (appID) {
            createAppStartupShortcut()
            Gui %guiHwnd%:Destroy
        }
        If (mutedPicHandle)
            DllCall("DeleteObject", "Ptr", mutedPicHandle)
        If (unmutedPicHandle) 
            DllCall("DeleteObject", "Ptr", unmutedPicHandle)
        SetTimer, updateGui, Delete
        SetTimer, checkPerf, Delete
    } Catch, e {
        showErrorDialog("Error exiting app", e)
    }
    Return
}

Return
