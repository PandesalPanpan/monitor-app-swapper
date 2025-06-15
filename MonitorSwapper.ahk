#Requires AutoHotkey v2
DetectHiddenWindows False

; Track recently focused windows
recentWindows := []
maxRecentWindows := 10

; Start monitoring window focus changes
SetTimer(TrackActiveWindow, 100)

; Hotkey: Ctrl+Shift+Q to swap the two most recent windows
^+q::SwapRecentWindows()

; Hotkey: Ctrl+Shift+E to swap ALL windows
^+e::SwapAllWindows()

; Hotkey: Ctrl+Shift+X to exit the script
^+x::ExitApp()

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

SwapAllWindows() {
    movedCount := 0
    skippedCount := 0
    processedWindows := Map()

    ; Get initial window list and positions
    idList := WinGetList()
    windowsToMove := []

    ; First pass: collect all windows to move and their initial positions
    for this_id in idList {
        title := WinGetTitle("ahk_id " this_id)
        proc := WinGetProcessName("ahk_id " this_id)
        
        ; Only move visible windows with a title
        if (title != "" && DllCall("IsWindowVisible", "Ptr", this_id)) {
            ; Get initial position
            x := y := w := h := ""
            try WinGetPos(&x, &y, &w, &h, "ahk_id " this_id)
            
            windowsToMove.Push({
                id: this_id,
                title: title,
                proc: proc,
                initialX: x,
                initialY: y
            })
        }
    }

    ; Second pass: move each window
    for window in windowsToMove {
        ; Skip if we already processed this window
        if (processedWindows.Has(window.id))
            continue
            
        try {
            ; Check if window still exists and is visible
            if (!WinExist("ahk_id " window.id) || !DllCall("IsWindowVisible", "Ptr", window.id)) {
                skippedCount++
                continue
            }
            
            ; Get current position before moving
            x := y := w := h := ""
            WinGetPos(&x, &y, &w, &h, "ahk_id " window.id)
            
            ; Focus the window first
            WinActivate("ahk_id " window.id)
            ; Minimal delay to ensure window is focused
            Sleep(50)
            
            ; Verify the window is actually active
            activeId := WinGetID("A")
            if (activeId != window.id) {
                skippedCount++
                continue
            }
            
            ; Send Win+Shift+Right Arrow to move to next monitor
            Send("#+{Right}")
            
            ; Brief wait for the move to complete
            Sleep(100)
            
            ; Verify the window actually moved
            newX := newY := newW := newH := ""
            WinGetPos(&newX, &newY, &newW, &newH, "ahk_id " window.id)
            
            if (newX != x || newY != y) {
                ; Window moved successfully
                movedCount++
            } else {
                ; Window didn't move, might be stuck or can't move
                skippedCount++
            }
            
            ; Mark as processed
            processedWindows[window.id] := true
            
        } catch as err {
            skippedCount++
        }
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