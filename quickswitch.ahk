#Requires AutoHotkey v2.0
#NoTrayIcon
#SingleInstance Force

; Loads VirtualDesktopAccessor.dll from this script's folder.
; Note: this build is 64-bit, so it must be run under 64-bit AutoHotkey v2.
global VDA_DLL := "C:\Users\Mizrab\Documents\AutoHotkey\VirtualDesktopAccessor.dll"
if !DllCall("LoadLibrary", "Str", VDA_DLL, "Ptr")
    throw Error("Failed to load VirtualDesktopAccessor.dll from " VDA_DLL)

; Remembers the last-active, unpinned window per desktop number so it can be
; restored after switching, since the DLL doesn't always refocus the right
; window on its own.
; See: https://github.com/Ciantic/VirtualDesktopAccessor/issues/77#issuecomment-1762913790
global ActiveWindowByDesktop := Map()

GetDesktopCount() {
    return DllCall("VirtualDesktopAccessor\GetDesktopCount", "Int")
}

GetCurrentDesktopNumber() {
    return DllCall("VirtualDesktopAccessor\GetCurrentDesktopNumber", "Int")
}

IsPinnedWindow(hwnd) {
    return DllCall("VirtualDesktopAccessor\IsPinnedWindow", "Ptr", hwnd, "Int")
}

; Windows blocks background processes from stealing foreground focus. Without
; this, the switch to a new desktop can leave the target window's taskbar
; icon flashing instead of actually focusing it. ASFW_ANY (-1) tells Windows
; to allow the next SetForegroundWindow call to succeed regardless of caller.
; See: https://github.com/pmb6tz/windows-desktop-switcher/issues/77
ASFW_ANY := -1

GoToDesktopNumber(n) {
    global ASFW_ANY
    DllCall("AllowSetForegroundWindow", "UInt", ASFW_ANY)
    DllCall("VirtualDesktopAccessor\GoToDesktopNumber", "Int", n)
}

RememberActiveWindow(desktop) {
    global ActiveWindowByDesktop
    try
        activeHwnd := WinGetID("A")
    catch TargetError
        return
    if (activeHwnd && !IsPinnedWindow(activeHwnd))
        ActiveWindowByDesktop[desktop] := activeHwnd
}

RestoreActiveWindow(desktop) {
    global ActiveWindowByDesktop
    if !ActiveWindowByDesktop.Has(desktop)
        return
    hwnd := ActiveWindowByDesktop[desktop]
    if WinExist("ahk_id " hwnd)
        WinActivate("ahk_id " hwnd)
}

SwitchDesktop(direction) {
    count := GetDesktopCount()
    current := GetCurrentDesktopNumber()
    target := current + direction
    if (target < 0 || target >= count)
        return
    RememberActiveWindow(current)
    GoToDesktopNumber(target)
    RestoreActiveWindow(target)
}

; Ctrl+Win+Right -> next desktop (matches default Windows shortcut)
^#Right::SwitchDesktop(1)

; Ctrl+Win+Left -> previous desktop (matches default Windows shortcut)
^#Left::SwitchDesktop(-1)
