 Using Appirater

1) Require appirater in the scene e.g. splashScreen which is called from main.lua
2) Define onSystemEvent function with parameter event e.g. splashScreen.lua
	function onSystemEvent( event )
		if(event.type == "applicationStart") then
			appirater.appLaunched(true)
		elseif(event.type == "applicationResume") then
			appirater.appEnteredForeground(true)
		elseif(event.type == "applicationExit") then
		elseif(event.type == "applicationSuspend") then
			appirater.appWillResignActive()
		end
	end
3) Call the above function in a runtime event in the same scene e.g. splashScreen.lua
	Runtime:addEventListener( "system", onSystemEvent)
4) Require appirator and call appirater.userDidSignificantEvent(true) wherever there is some achievement  in the app e.g. the user completes the whole activity. 
5) Change the appID and appName as per your Application. 
