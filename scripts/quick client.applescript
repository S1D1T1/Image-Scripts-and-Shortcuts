-- minimal script to submit a prompt request to SD image server.
-- requires the helper app "JSON Helper" (free)
-- https://apps.apple.com/us/app/json-helper-for-applescript/id453114608?mt=12

-- it doesn't use the image response, presumes you use it from the image generator


tell application "JSON Helper"
	set returnedImage to post as JSON {prompt:"rowdy puppies"} to URL "http://localhost:7860/sdapi/v1/txt2img"
	
	-- if you wanted to manage the response, it comes as a record, with an image array.
	set response to images of returnedImage
	set image1 to item 1 of response
end tell