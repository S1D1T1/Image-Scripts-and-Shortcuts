--- make json-based transforms to these images, and submit new json to DT server.
-- Transforms: 
--    Prompt: add word, remove word
--    param values: set value, vary by amount, proportion.
--    add keyword, remove keyword


use AppleScript version "2.4" -- Yosemite (10.10) or later
use framework "Foundation"
use scripting additions
set AppleScript's text item delimiters to "x" -- for size: "WxH"

--   embedded newlines in prompt
-- this doesn 't find hires fix if it's on. it's buried in the v2 block 
--   deal with lora

tell application "Finder" to set selectedFiles to (the selection as list)

repeat with afile in selectedFiles
	if kind of afile contains "image" then
		set resp to getConfig(afile)
		
		tell application "JSON Helper"
			set params to read JSON from resp
			set newRecord to my translateRecord(params)
			set nativeRecord to my transform(newRecord)
			--return nativeRecord
			try
				post as JSON nativeRecord to URL "http://localhost:7860/sdapi/v1/txt2img"
			end try
		end tell
	end if
	
end repeat
--------------------------------------------------------------------------
-- the heart of the script. re-run with a json change

on transform(newRecord)
	--set oldPrompt to prompt of newRecord
	set clip_skip of newRecord to 1
	return newRecord
end transform

--------------------------------------------------------------------------

on changeWord(oldWord, newWord, prompt)
	set loc to offset of oldWord in prompt
	if loc = 0 then return prompt
	set oldLen to length of oldWord
	set newPrompt to text 1 thru (loc - 1) of prompt & newWord
	set promptsuffix to text (loc + oldLen) thru -1 of prompt
	return newPrompt & promptsuffix
end changeWord


-- get image parameters for this file from metadata
on getConfig(afile)
	
	set fpath to POSIX path of (afile as alias)
	set theFilePath to quoted form of fpath
	--raw keeps out the command echo
	set shellstring to "mdls -name kMDItemComment -raw " & theFilePath
	return do shell script shellstring
	
end getConfig

-- turn any "size" type value into "width" and "height" values
-- so "first_stage_size" becomes "first_stage_width" & "first_stage_height", and so on
-- first_stage_size, negative_original_size,original_size,size,target_size
on parseSize(sizeKey, sizeVal, newRecord)
	set oldsize to sizeVal as text
	set newWidth to (text item 1 of oldsize) as number
	set newHeight to (text item 2 of oldsize) as number
	
	if sizeKey is "size" then
		set keybase to ""
	else if sizeKey is "first_stage_size" then
		set keybase to "hires_fix_"
	else
		set keybase to text 1 thru -5 of sizeKey
	end if
	set newKey to keybase & "width"
	set newRecord to addToRecord(newRecord, newKey, newWidth)
	set newKey to keybase & "height"
	set newRecord to addToRecord(newRecord, newKey, newHeight)
	return newRecord
end parseSize



-- translate Params from DT to .. DT ?
on translateRecord(params)
	set respKeys to getKeys(params)
	-- these are sometimes left out - we inherit wrong values in DT UI
	set newRecord to {hires_fix:false, clip_skip:1}
	set skipKeys to {"v2", "second_stage_strength", "lora", "control"} -- *sometimes* first_stage_size ?
	repeat with akey in respKeys
		if skipKeys does not contain akey then
			set oldVal to my getVal(akey, params)
			
			set newKey to akey as text
			
			if newKey contains "size" then
				set newRecord to parseSize(newKey, oldVal, newRecord)
			else
				
				if newKey = "c" then
					set newKey to "prompt"
				else if newKey is "uc" then
					set newKey to "negative_prompt"
				else if newKey = "scale" then
					set newKey to "guidance_scale"
				end if
				set newRecord to addToRecord(newRecord, newKey, oldVal)
			end if
		end if
	end repeat
	if sampler of newRecord is "Euler Ancestral" then set sampler of newRecord to "Euler a"
	
	return newRecord
end translateRecord


-- json functions
on getKeys(rec)
	(current application's NSDictionary's dictionaryWithDictionary:rec)'s allKeys() as list
end getKeys

on getVal(keyname, theRecord)
	set v to (current application's NSDictionary's dictionaryWithDictionary:theRecord)'s objectForKey:keyname
	return v
end getVal

on addToRecord(theRecord, theLabel, theValue)
	set theDictionary to current application's NSMutableDictionary's dictionaryWithDictionary:theRecord
	theDictionary's setObject:theValue forKey:theLabel
	return theDictionary as record
end addToRecord

on recordFromLabelsAndValues(theseLabels, theseValues)
	-- create a Cocoa dictionary using lists of keys and values
	set theResult to Â
		current application's NSDictionary's dictionaryWithObjects:theseValues forKeys:theseLabels
	-- return the resulting dictionary as an AppleScript record
	return theResult as record
end recordFromLabelsAndValues

