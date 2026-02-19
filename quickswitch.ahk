#NoTrayIcon
#WinActivateForce ; Helps force focus when Windows is being stubborn

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
CreateDesktopProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "CreateDesktop", "Ptr")

global LastWindow := {}

; --- Helper Functions ---
GetDesktopCount() {
    global GetDesktopCountProc
    return DllCall(GetDesktopCountProc, "Int")
}

GetCurrentDesktopNumber() {
    global GetCurrentDesktopNumberProc
    return DllCall(GetCurrentDesktopNumberProc, "Int")
}

; This is the "Magic" function that prevents the flashing taskbar
PerformCleanSwitch(targetNum) {
    global GoToDesktopNumberProc
    
    ; 1. Neutralize focus by targeting the Taskbar (prevents flashing)
    ControlFocus,, ahk_class Shell_TrayWnd
    
    ; 2. Perform the jump
    DllCall(GoToDesktopNumberProc, "Int", targetNum, "Int")
    
    ; 3. Small buffer for the Shell to update
    Sleep, 60 
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

^#Right:: SwitchDesktop(1)
^#Left:: SwitchDesktop(-1)
^#Down:: MoveCurrentDesktop(1)
^#Up:: MoveCurrentDesktop(-1)
#+Right:: MoveFocusedWindow(1)
#+Left:: MoveFocusedWindow(-1)

; ===========================================
; Logic Blocks
; ===========================================

SwitchDesktop(direction) {
    global LastWindow
    current := GetCurrentDesktopNumber()
    count := GetDesktopCount()
    target := current + direction
    
    if (target < 0 || target >= count)
        return

    ; Store current active window
    activeHwnd := WinExist("A")
    if activeHwnd
        LastWindow[current] := activeHwnd

    PerformCleanSwitch(target)

    ; Restore focus on the new desktop
    if LastWindow.HasKey(target) {
        tHwnd := LastWindow[target]
        if WinExist("ahk_id " tHwnd) {
            WinActivate, ahk_id %tHwnd%
        }
    }
}

MoveCurrentDesktop(direction) {
    current := GetCurrentDesktopNumber()
    count := GetDesktopCount()
    target := current + direction
    if (target < 0 || target >= count)
        return

    ; Move only visible windows to avoid moving background system processes
    WinGet, windows, List
    Loop, %windows% {
        this_hwnd := windows%A_Index%
        WinGetTitle, title, ahk_id %this_hwnd%
        if (title = "") ; Skip windows with no title (usually background tasks)
            continue
            
        if (GetWindowDesktopNumber(this_hwnd) = current)
            MoveWindowToDesktopNumber(this_hwnd, target)
    }
    PerformCleanSwitch(target)
}

MoveFocusedWindow(direction) {
    hwnd := WinExist("A")
    if !hwnd
        return

    current := GetWindowDesktopNumber(hwnd)
    count := GetDesktopCount()
    target := current + direction

    if (target >= count && direction > 0) {
        CreateDesktop()
        target := GetDesktopCount() - 1
    }

    if (target < 0 || target >= GetDesktopCount())
        return

    MoveWindowToDesktopNumber(hwnd, target)
    PerformCleanSwitch(target)
    
    ; Force focus on the moved window
    WinActivate, ahk_id %hwnd%
}
