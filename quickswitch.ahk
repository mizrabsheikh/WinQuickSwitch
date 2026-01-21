#NoTrayIcon

; ===========================================
; Virtual Desktop Switcher (Ctrl + Win + Left/Right)
; ===========================================

; --- Load VirtualDesktopAccessor.dll ---
VDA_PATH := A_ScriptDir . "\VirtualDesktopAccessor.dll"
hVirtualDesktopAccessor := DllCall("LoadLibrary", "Str", VDA_PATH, "Ptr")

; --- Get function pointers from the DLL ---
GetDesktopCountProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GetDesktopCount", "Ptr")
GetCurrentDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GetCurrentDesktopNumber", "Ptr")
GoToDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GoToDesktopNumber", "Ptr")

; --- Functions ---
GetDesktopCount() {
    global GetDesktopCountProc
    return DllCall(GetDesktopCountProc, "Int")
}

GoToDesktopNumber(num) {
    global GoToDesktopNumberProc
    DllCall(GoToDesktopNumberProc, "Int", num, "Int")
}

GetCurrentDesktopNumber() {
    global GetCurrentDesktopNumberProc
    return DllCall(GetCurrentDesktopNumberProc, "Int")
}

; ===========================================
; Hotkeys
; ===========================================

; Ctrl + Win + Right → Next desktop
^#Right::
    current := GetCurrentDesktopNumber()
    last := GetDesktopCount() - 1
    if (current < last)
        GoToDesktopNumber(current + 1)
return

; Ctrl + Win + Left → Previous desktop
^#Left::
    current := GetCurrentDesktopNumber()
    if (current > 0)
        GoToDesktopNumber(current - 1)
return
