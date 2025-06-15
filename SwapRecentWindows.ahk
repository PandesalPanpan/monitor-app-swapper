#Requires AutoHotkey v2
DetectHiddenWindows False

; Track recently focused windows
recentWindows := []
maxRecentWindows := 10

; Start monitoring window focus changes
SetTimer(TrackActiveWindow, 100)

; Hotkey: Ctrl+Shift+Q to swap the two most recent windows
^+q::SwapRecentWindows()

; Hotkey: Ctrl+Shift+E to exit the script
^+e::ExitApp()

TrackActiveWindow() {
    global recentWindows, maxRecentWindows
    try {
        hwnd := WinGetID("A")
        title := WinGetTitle("A")
        
        if (title != "" && DllCall("IsWindowVisible", "Ptr", hwnd)) {
            ; Remove this window from the list if it already exists
            for i, window in recentWindows {
                if (window.id == hwnd) {
                    recentWindows.RemoveAt(i)
                    break
                }
            }
            
            ; Add to the front of the list
            recentWindows.InsertAt(1, {id: hwnd, title: title})
            
            ; Keep only the most recent windows
            if (recentWindows.Length > maxRecentWindows) {
                recentWindows.RemoveAt(maxRecentWindows + 1)
            }
        }
    }
}

SwapRecentWindows() {
    global recentWindows
    if (recentWindows.Length < 2) {
        ; Not enough recent windows to swap
        return
    }
    
    ; Get the two most recent windows
    window1 := recentWindows[1]
    window2 := recentWindows[2]
    
    ; Verify both windows still exist and are visible
    if (!WinExist("ahk_id " window1.id) || !DllCall("IsWindowVisible", "Ptr", window1.id) ||
        !WinExist("ahk_id " window2.id) || !DllCall("IsWindowVisible", "Ptr", window2.id)) {
        ; Clean up invalid windows and try again
        CleanupInvalidWindows()
        if (recentWindows.Length < 2)
            return
        window1 := recentWindows[1]
        window2 := recentWindows[2]
    }
    
    ; Move first window
    try {
        WinActivate("ahk_id " window1.id)
        Sleep(50)
        Send("#+{Right}")
        Sleep(100)
    }
    
    ; Move second window
    try {
        WinActivate("ahk_id " window2.id)
        Sleep(50)
        Send("#+{Right}")
        Sleep(100)
    }
}

CleanupInvalidWindows() {
    global recentWindows
    validWindows := []
    for window in recentWindows {
        if (WinExist("ahk_id " window.id) && DllCall("IsWindowVisible", "Ptr", window.id)) {
            validWindows.Push(window)
        }
    }
    recentWindows := validWindows
} 