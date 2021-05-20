This works great with a context menu entry. It's meant to be interactive rather than a shell command (otherwise why not just use ffmpeg directly?).

Here are example registry keys to add it to right-clicking on mp4, and this might not work on your system because context menu registry keys are a mess.

Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Classes\SystemFileAssociations\.mp4\Shell\VComp
- (Default) VComp
Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Classes\SystemFileAssociations\.mp4\Shell\VComp\command
- (Default) C:\repos\vcomp\runvcomp.bat "%1"

runvcomp.bat is included because it seems to be impossible to pass %1 to powershell safely with just a single command.

And by safely, I mean escaping single quotes in filenames, which are quite common in "Mukunda Johnson's" Zoom recordings.

VComp requires ffmpeg accessible on the %PATH%
