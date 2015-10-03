on run {targetPhoneOrEmail, targetMessage}		
	tell application "Messages"		
		set targetService to 1st service whose service type = iMessage		
		set targetBuddy to buddy targetPhoneOrEmail of targetService		
		send targetMessage to targetBuddy		
	end tell		
end