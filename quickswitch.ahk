#NoTrayIcon

; ===========================================
; Virtual Desktop Switcher and Window Mover (Focus Restore + Auto-create right desktop)
; ===========================================

VDA_PATH := "C:\Users\Mizrab Sheikh\Documents\AutoHotkey\VirtualDesktopAccessor.dll"
hVirtualDesktopAccessor := DllCall("LoadLibrary", "Str", VDA_PATH, "Ptr")

; --- Get function pointers ---
GetDesktopCountProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GetDesktopCount", "Ptr")
GetCurrentDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GetCurrentDesktopNumber", "Ptr")
GoToDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GoToDesktopNumber", "Ptr")
MoveWindowToDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "MoveWindowToDesktopNumber", "Ptr")
GetWindowDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GetWindowDesktopNumber", "Ptr")
CreateDesktopProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "CreateDesktop", "Ptr")

; --- Track last active window per desktop ---
global LastWindow := {}

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

MoveWindowToDesktopNumber(hwnd, desktop_number) {
    global MoveWindowToDesktopNumberProc
    return DllCall(MoveWindowToDesktopNumberProc, "Ptr", hwnd, "Int", desktop_number, "Int")
}

GetWindowDesktopNumber(hwnd) {
    global GetWindowDesktopNumberProc
    return DllCall(GetWindowDesktopNumberProc, "Ptr", hwnd, "Int")
}

CreateDesktop() {
    global CreateDesktopProc
    return DllCall(CreateDesktopProc, "Int")
}

; ===========================================
; Hotkeys
; ===========================================

; Ctrl + Win + Right → Next desktop
^#Right::
    SwitchDesktop(1)
return

; Ctrl + Win + Left → Previous desktop
^#Left::
    SwitchDesktop(-1)
return

; Ctrl + Win + Down → Move current desktop right
^#Down::
    MoveCurrentDesktop(1)
return

; Ctrl + Win + Up → Move current desktop left
^#Up::
    MoveCurrentDesktop(-1)
return

; Win + Shift + Right → Move focused window to right (create if needed)
#+Right::
    MoveFocusedWindow(1)
return

; Win + Shift + Left → Move focused window to left
#+Left::
    MoveFocusedWindow(-1)
return

; ===========================================
; Switch desktop and restore last focused window
; ===========================================
SwitchDesktop(direction) {
    global LastWindow
    current := GetCurrentDesktopNumber()
    count := GetDesktopCount()
    target := current + direction
    if (target < 0 || target >= count)
        return

    ; Remember last active window on current desktop
    hwnd := WinExist("A")
    if hwnd
        LastWindow[current] := hwnd

    ; Switch desktop
    GoToDesktopNumber(target)
    Sleep, 80

    ; Restore last active window on target desktop
    if LastWindow.HasKey(target) {
        targetHwnd := LastWindow[target]
        if WinExist("ahk_id " targetHwnd)
            WinActivate, ahk_id %targetHwnd%
    }
}

; ===========================================
; Move current desktop (shifts all windows)
; ===========================================
MoveCurrentDesktop(direction) {
    current := GetCurrentDesktopNumber()
    count := GetDesktopCount()
    target := current + direction
    if (target < 0 || target >= count)
        return

    WinGet, id, List,,, Program Manager
    Loop, %id% {
        hwnd := id%A_Index%
        if (GetWindowDesktopNumber(hwnd) = current)
            MoveWindowToDesktopNumber(hwnd, target)
    }
    GoToDesktopNumber(target)
}

; ===========================================
; Move focused window (creates desktop if needed)
; ===========================================
MoveFocusedWindow(direction) {
    hwnd := WinExist("A")
    if !hwnd
        return

    current := GetWindowDesktopNumber(hwnd)
    count := GetDesktopCount()
    target := current + direction

    ; if moving right from last desktop → create new one
    if (target >= count && direction > 0) {
        CreateDesktop()
        count := GetDesktopCount()
        target := count - 1
    }

    if (target < 0 || target >= count)
        return

    MoveWindowToDesktopNumber(hwnd, target)
    Sleep, 100
    GoToDesktopNumber(target)

    ; Focus the moved window
    if WinExist("ahk_id " hwnd)
        WinActivate, ahk_id %hwnd%
}
