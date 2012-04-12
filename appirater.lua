------------------------------------------------------------------------------
------------------------------------------------------------------------------
--[[

This file is part of Appirater for Corona SDK.
Copyright (c) 2012, RedBytes Software
All rights reserved.

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

* appirater.lua
* appirater
*
* Created on 12th April 2012 by: 
    Vimal Venugopolan - vimalvenugopalan22@gmail.com	Twitter: @vvvimal22	Facebook: www.facebook.com/vvvimal
    Aliasgar Poonawala - alipoonawala84@gmail.com	Twitter: @aliasgar84	Facebook: www.facebook.com/aliasgar.poonawala

* http://www.redbytes.in
* Copyright 2012 RedBytes Software. All rights reserved.

]]--
------------------------------------------------------------------------------
------------------------------------------------------------------------------

module(..., package.seeall)

require("sqlite3")



local appirater_App_ID = "301377083"
local appirater_App_Name = "RocketMouse"
local appirater_Message_Part1 = "If you enjoy using "
local appirater_Message_Part2 = ", would you mind taking a moment to rate it? It won't take more than a minute. Thanks for your support!"
local appirater_Message_Title = "Rate"
local appirater_Cancel_Button = "No, Thanks"
local appirater_Rate_Button = "Rate"
local appirater_Rate_Later = "Remind me later"
local appirater_Days_Until_Prompt = 0.01
local appirater_Uses_Until_Prompt = 3
local appirater_Sig_Events_Until_Prompt = 5
local appirater_Time_Before_Reminding = 0.01
local appirater_Debug = false
local canPromptForRating = false



local ratingAlert = nil
local userDefaults = {}

local templateReviewURL = "itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=";

------------------------ Reachability Listener ------------------------------

function networkReachabilityListener(event)
        print( "address", event.address )
        print( "isReachable", event.isReachable )
        print("isConnectionRequired", event.isConnectionRequired)
        print("isConnectionOnDemand", event.isConnectionOnDemand)
        print("IsInteractionRequired", event.isInteractionRequired)
        print("IsReachableViaCellular", event.isReachableViaCellular)
        print("IsReachableViaWiFi", event.isReachableViaWiFi)

	if event.isReachable == "isReachable" then
		return true
	elseif event.isReachable ~= "isReachable" then
		return false
	end 
end

------------------------- Check if connected to internet ----------------------

function connectedToNetwork()
	if network.canDetectNetworkStatusChanges then
        	network.setStatusListener( "www.apple.com", MyNetworkReachabilityListener )
		return true
	else
        	print("network reachability not supported on this platform")
		return false
	end
end

-------------------------- rating conditions met --------------------------------

function ratingConditionsHaveBeenMet()
	if (appirater_Debug == true) then
		return true	
	end

	local timeSinceFirstLaunch = os.difftime( os.time(), userDefaults[1].kAppiraterFirstUseDate)
	local timeUntilRate = 60 * 60 * 24 * appirater_Days_Until_Prompt
	
	if( timeSinceFirstLaunch < timeUntilRate) then		
		return false
	end	
	-- check if the app has been used enough
	local useCount = userDefaults[1].kAppiraterUseCount
	if (useCount <= appirater_Uses_Until_Prompt) then
		return false
	end
	-- check if the user has done enough significant events
	local sigEventCount = userDefaults[1].kAppiraterSignificantEventCount
	if (sigEventCount <= appirater_Sig_Events_Until_Prompt) then
		return false
	end
	-- has the user previously declined to rate this version of the app?		
	if (userDefaults[1].kAppiraterDeclinedToRate == 1) then
		return false
	end
	-- has the user already rated the app?
	if (userDefaults[1].kAppiraterRatedCurrentVersion == 1) then
		return false
	end
	-- if the user wanted to be reminded later, has enough time passed?
	local timeSinceReminderRequest = os.difftime( os.time(), userDefaults[1].kAppiraterReminderRequestDate)
	local timeUntilReminder = 60 * 60 * 24 * appirater_Time_Before_Reminding
	
	if( timeSinceReminderRequest < timeUntilReminder) then
		return false
	end
	
	return true
end

-------------------------- Increment Use Count -----------------------------------

function incrementUseCount()
		
	-- check if the first use date has been set. if not, set it.	
	if(userDefaults[1].kAppiraterFirstUseDate == 0) then
		userDefaults[1].kAppiraterFirstUseDate = os.time()
	end
	
	-- increment the use count
	local useCount = userDefaults[1].kAppiraterUseCount
	useCount = useCount + 1
	userDefaults[1].kAppiraterUseCount = useCount
	print("APPIRATER Use count: "..useCount)
	if(appirater_Debug == true) then
		print("APPIRATER Use count: "..useCount)	
	end

end

-----------------------------Increment Significant Event Count ---------------------

function incrementSignificantEventCount()
	-- check if the first use date has been set. if not, set it.	
	if(userDefaults[1].kAppiraterFirstUseDate == 0) then
		userDefaults[1].kAppiraterFirstUseDate = os.time()
	end
	
	-- increment the significant event count
	local sigEventCount = userDefaults[1].kAppiraterSignificantEventCount
	sigEventCount = sigEventCount + 1
	userDefaults[1].kAppiraterSignificantEventCount = sigEventCount
	
	if(appirater_Debug == true) then
		print("APPIRATER Significant event count: "..sigEventCount)	
	end
end

----------------------------- Increment and rate ----------------------------------

function incrementAndRate(canPromptForRating)
	incrementUseCount()
	if(canPromptForRating and ratingConditionsHaveBeenMet() and connectedToNetwork()) then
		showRatingAlert()
	end
end

----------------------------- Increment Significant Event and rate ----------------------------------

function incrementSignificantEventAndRate(canPromptForRating)
	incrementSignificantEventCount()
	if(canPromptForRating and ratingConditionsHaveBeenMet() and connectedToNetwork()) then
		showRatingAlert()
	end
end

-------------------------- Application Launched ---------------------------------

function appLaunched(canPromptForRating)
	connectedToNetwork()
	createSQLiteDB()
	userDefaults = selectSQLiteDB()
	if #userDefaults == 0 then
		local tempArray = {}
		tempArray.kAppiraterFirstUseDate = os.time()
		tempArray.kAppiraterUseCount = 0
		tempArray.kAppiraterSignificantEventCount = 0 
		tempArray.kAppiraterCurrentVersion = ""
		tempArray.kAppiraterRatedCurrentVersion = 0 
		tempArray.kAppiraterDeclinedToRate = 0
		tempArray.kAppiraterReminderRequestDate = 0
		table.insert(userDefaults, 1, tempArray)
	end
end

-------------------------- hiding rating alert ---------------------------

function hideRatingAlert()
	if(ratingAlert)	then
		--if(ratingAlert.isVisible == true) then
			if(appirater_Debug == true) then
				print("Appirater hiding Alert")
			end
			native.cancelAlert( ratingAlert )
		--end
	end
end

-------------------------- Application Will Resign Active ---------------------------

function appWillResignActive()
	if(appirater_Debug == true) then
		print("Appirater appWillResignActive")
	end
	insertSQLiteDB()
	hideRatingAlert()
	
end

------------------------- Application entered into foreground -------------------------

function appEnteredForeground(canPromptForRating)
	userDefaults = selectSQLiteDB()
	incrementAndRate(canPromptForRating)
end


--------------------------- user Did Significant Event  thread---------------------------------

function userDidSignificantEvent(canPromptForRating)
	incrementSignificantEventAndRate(canPromptForRating)
end

------------------------- alert asking for rating the app --------------------------- 

function showRatingAlert()
	ratingAlert = native.showAlert( appirater_Message_Title, appirater_Message_Part1..appirater_App_Name..appirater_Message_Part2, { appirater_Cancel_Button, appirater_Rate_Button, appirater_Rate_Later}, onAlertComplete )
end

------------------------- alert button click event handler ----------------------------

function onAlertComplete( event )
    	if "clicked" == event.action then
       		local i = event.index
        	if 1 == i then
            		userDefaults[1].kAppiraterDeclinedToRate = 1
        	elseif 2 == i then
            		system.openURL( templateReviewURL..appirater_App_ID )
	
		elseif 3 == i then
			userDefaults[1].kAppiraterReminderRequestDate = 1
		end	
    	end
end

----------------------------------SQLite DB functions -------------------------------
function createSQLiteDB()
	local path = system.pathForFile("dataBase.db", system.DocumentsDirectory)
	db = sqlite3.open( path )
	
--Setup the table if it doesn't exist

	local tablesetup = [[CREATE TABLE IF NOT EXISTS NSUserDefaults (id INTEGER PRIMARY KEY ON CONFLICT REPLACE, kAppiraterFirstUseDate INTEGER, kAppiraterUseCount INTEGER, kAppiraterSignificantEventCount INTEGER, kAppiraterCurrentVersion, kAppiraterRatedCurrentVersion INTEGER, kAppiraterDeclinedToRate INTEGER, kAppiraterReminderRequestDate INTEGER); ]]
	print(tablesetup)
	db:exec( tablesetup )
	db:close()
end

function insertSQLiteDB()

print("insertSQLiteDB")
--Open data.db.  If the file doesn't exist it will be created
	local path = system.pathForFile("dataBase.db", system.DocumentsDirectory)
	db = sqlite3.open( path )
	
	
--Insert the data in table
	local myValue = ""..userDefaults[1].kAppiraterFirstUseDate..", "..userDefaults[1].kAppiraterUseCount..", "..userDefaults[1].kAppiraterSignificantEventCount..", '"..userDefaults[1].kAppiraterCurrentVersion.."', "..userDefaults[1].kAppiraterRatedCurrentVersion..", "..userDefaults[1].kAppiraterDeclinedToRate..", "..userDefaults[1].kAppiraterReminderRequestDate..""
	
	local tablefill = [[INSERT OR REPLACE INTO NSUserDefaults VALUES ( 1, ]]..myValue..[[ ); ]]
	print(tablefill)
	db:exec( tablefill )
	myValue = ""
	db:close()
end

function selectSQLiteDB()

	print("selectSQLiteDB")
	
--Open data.db.  If the file doesn't exist it will be created
	local path = system.pathForFile("dataBase.db", system.DocumentsDirectory)
	db = sqlite3.open( path )
	local resultsArray = {}
	local query = "SELECT * FROM NSUserDefaults"
	
	print(query)
	
	for row in db:nrows(query) do
		table.insert(resultsArray,row)
	end
	db:close()
	
	print("resultsArray count = "..#resultsArray)
	
	return resultsArray	

end

-----------------------------------------------------------------------------------------	

