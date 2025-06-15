#Requires AutoHotkey v2
DetectHiddenWindows False

output := "Visible top-level windows:`n`n"

idList := WinGetList()
for this_id in idList {
    title := WinGetTitle("ahk_id " this_id)
    winClass := WinGetClass("ahk_id " this_id)
    proc := WinGetProcessName("ahk_id " this_id)
    x := y := w := h := ""
    try WinGetPos(&x, &y, &w, &h, "ahk_id " this_id)
    ; Only show visible windows with a title
    if (title != "" && DllCall("IsWindowVisible", "Ptr", this_id)) {
        output .= "[" proc "] '" title "' (Class: " winClass ") at (" x ", " y "), " w "x" h "`n"
    }
}

if (StrLen(output) < 4000)
    MsgBox output
else
    MsgBox "The list is too long for a message box. See ListWindows.txt."

; Write to a file for easier review
filePath := A_ScriptDir . "\ListWindows.txt"
try FileDelete(filePath)
FileAppend(output, filePath)
