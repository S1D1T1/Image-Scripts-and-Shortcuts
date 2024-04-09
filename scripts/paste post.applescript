-- requires the helper app "JSON Helper" (free)
-- https://apps.apple.com/us/app/json-helper-for-applescript/id453114608?mt=12

-- clipboard contains json containing the image request for a SD API server.

tell application "JSON Helper"
	set imageParams to read JSON from (the clipboard)
	set serverReply to post as JSON imageParams to URL "http://localhost:7860/sdapi/v1/txt2img"
	set firstImage to first item of images of serverReply
end tell

tell application "Finder" to set tmpfileName to (home as text) & "tmpFile.txt"
set the open_target_file to open for access tmpfileName with write permission
set eof of the open_target_file to 0
write firstImage to the open_target_file
close access the open_target_file
do shell script "cd ~/;base64 -D < tmpFile.txt > result.png"
