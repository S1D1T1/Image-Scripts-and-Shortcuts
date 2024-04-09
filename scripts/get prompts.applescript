--	Save off metadata from EXIF

-- 	for all of the image files in the front window in Finder, and all subfolders, diving down indefinitely
--	
--	get the file name & exif "description" field, in the hopes it contains all image generation params.
-- store in a table, for later use, in the file <foldername>-exif.csv
-- because some tools in your workflow may discard that data, such as upscalers, format conversions, etc.


-- cloned off of 'Save Exif' script. don't write file, just return

tell application "Finder"
	set frontfolder to target of window 1
	my saveExifs(frontfolder)
end tell

on saveExifs(picFolder)
	set imagefiles to files of picFolder --whose kind contains "image"	-- too slow.
	set progress total steps to count of imagefiles
	set progress description to "cataloging folder: " & name of picFolder
	set filesdone to 0
	
	set exifList to ""
	
	-- step through list of files
	repeat with afile in imagefiles
		if kind of afile contains "image" then
			tell application "Image Events"
				set this_image to open file (afile as string)
				
				-- look for "Description" metadata
				-- **Unfortunately**, this property is read only, so we can't use it later to restore the description
				
				set descTags to (metadata tags of this_image whose name is "description")
				
				
				-- if description isn't empty, append to file name
				if descTags ≠ {} then set imgInfo to ",\"" & value of (item 1 of descTags) & quote
				close this_image
			end tell
			
			-- that's adding an embedded newline char, appending to end of list.
			set exifList to exifList & "
" & imgInfo
			set filesdone to filesdone + 1
			set progress completed steps to filesdone
		end if
	end repeat
	return exifList
end saveExifs
