#Requires AutoHotkey v2
DetectHiddenWindows False

MsgBox "Moving all windows using Win+Shift+Right Arrow...`nThis will move windows to the next monitor."

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

MsgBox "Found " windowsToMove.Length " windows to move. Starting in 2 seconds..."
Sleep(2000)

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
        ; Wait longer to ensure window is properly focused
        Sleep(200)
        
        ; Verify the window is actually active
        activeId := WinGetID("A")
        if (activeId != window.id) {
            skippedCount++
            continue
        }
        
        ; Send Win+Shift+Right Arrow to move to next monitor
        Send("#+{Right}")
        
        ; Wait for the move to complete
        Sleep(300)
        
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

MsgBox "Window moving complete!`nMoved: " movedCount " windows`nSkipped: " skippedCount " windows" 