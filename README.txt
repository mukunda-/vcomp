This works great with a context menu entry. It's meant to be interactive rather than a shell command (typically you'd just use ffmpeg otherwise).

Example registry keys to add it to mp4. Might not work because context menu registry keys are a mess.

Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Classes\SystemFileAssociations\.mp4\Shell\VComp
- (Default) VComp
Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Classes\SystemFileAssociations\.mp4\Shell\VComp\command
- (Default) powershell -noexit "C:\path\to\vcomp.ps1" -InputFile '%1'
