#NoTrayIcon

; ===========================================
; Virtual Desktop Switcher and Window Mover
; ===========================================

VDA_PATH := "C:\Users\Mizrab Sheikh\Documents\AutoHotkey\VirtualDesktopAccessor.dll"
hVirtualDesktopAccessor := DllCall("LoadLibrary", "Str", VDA_PATH, "Ptr")

; --- Get function pointers ---
GetDesktopCountProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GetDesktopCount", "Ptr")
GetCurrentDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GetCurrentDesktopNumber", "Ptr")
GoToDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GoToDesktopNumber", "Ptr")
MoveWindowToDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "MoveWindowToDesktopNumber", "Ptr")
GetWindowDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GetWindowDesktopNumber", "Ptr")

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

; Ctrl + Win + Down → Move current desktop right
^#Down::
    MoveCurrentDesktop(1)
return

; Ctrl + Win + Up → Move current desktop left
^#Up::
    MoveCurrentDesktop(-1)
return

; Win + Shift + Right → Move focused window to desktop on the right (and switch)
#+Right::
    MoveFocusedWindow(1)
return

; Win + Shift + Left → Move focused window to desktop on the left (and switch)
#+Left::
    MoveFocusedWindow(-1)
return

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
; Move currently focused window (and switch)
; ===========================================
MoveFocusedWindow(direction) {
    hwnd := WinExist("A")
    if !hwnd
        return

    current := GetWindowDesktopNumber(hwnd)
    count := GetDesktopCount()
    target := current + direction

    if (target < 0 || target >= count)
        return

    MoveWindowToDesktopNumber(hwnd, target)
    Sleep, 100  ; short delay to ensure move is registered
    GoToDesktopNumber(target)
}
