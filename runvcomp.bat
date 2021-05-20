REM Escape single quotes and change double quotes to single quotes for powershell.
SET A=%1
SET A=%A:'=''%
SET A=%A:"='%
REM This will point to .\vcomp.ps1 in the same directory as the bat file.
powershell -noexit "%~dp0vcomp.ps1" -InputFile %A%
