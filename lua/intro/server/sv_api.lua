--[[ Cinematic Intro --------------------------------------------------------------------------------------

Cinematic Intro made by Numerix (https://steamcommunity.com/id/numerix/)

--------------------------------------------------------------------------------------------------]]
local baseUri = "http://92.222.234.121:3000"
local baseUriWS = "ws://92.222.234.121:3000"
local ensFunctions, ensFunctionsDegrade

local forceDegradeMode = false
if !Intro.Settings.DegradeMode then
	if util.IsBinaryModuleInstalled("gwsockets") then
		require("gwsockets")
	else
		MsgC( Color( 225, 20, 30 ), "[Cinematic Intro]", Color(255,255,255), " Passing into a degraded mode.\n")
		Intro.Settings.DegradeMode = true
		forceDegradeMode = true
	end
end

hook.Add("PlayerInitialSpawn", "Intro:PlayerInitialSpawnCheckGWSocket", function(ply)
	if ply:IsSuperAdmin() then
		timer.Simple(10, function()
			if forceDegradeMode then
				ply:IntroChatInfo(Intro.GetLanguage("The module GWSocket is not present on the server"), 3)
			end

			if !Intro.isloading and !Intro.setup_success then
				ply:IntroChatInfo(Intro.GetLanguage("Failed to setup the addon please check the server console for more information."), 3)
			end
		end)
	end
end)


local function printInfo(message)
	MsgC( Color( 225, 20, 30 ), "[Cinematic Intro] ", Color(255,255,255), message.."\n" )
end

local socket

local function errorIntro(data)
	if socket then
		socket:close()
	end

	printInfo(data.message)

	Intro.isloading = false
	Intro.setup_success = false

	if ( data.log ) then
		printInfo( Intro.GetLanguage("Logs") .. " : " .. data.log)
	end
end

local function connectWebsite()
	printInfo(Intro.GetLanguage("Connection to the backend"))
	
	http.Fetch(baseUri .. "/get/".. (Intro.Settings.Map[game.GetMap()].PlayVideo and "webm" or "mp3") .."/degrade", 
		function(body)
			for _, data in pairs(util.JSONToTable(body)) do
				if ensFunctionsDegrade[data.type] then
					ensFunctionsDegrade[data.type](data)
				end
			end
		end,
		function(errorMessage)
			errorIntro({message = string.format(Intro.GetLanguage("Can't connect to the backend or the conversion take too long. (%s)"), errorMessage) })
		end,

		{url = Intro.Settings.Map[game.GetMap()].URLMusic}
	)
end

local function upload(youtubeURL, fileData, callback)
	printInfo( Intro.GetLanguage("Starting the upload of the video to the backend.") )
	HTTP({
		method = "POST",
		url = baseUri .. "/upload?url=" .. youtubeURL,
		body = fileData,
		success = function(code, body)
			if ( code != 200 ) then
				errorRadio({message = string.format(Intro.GetLanguage("An error occured while uploading the file. (%s)"), code) })
				return 
			end
	
			if ( callback ) then
				callback(youtubeURL)
			end
		end,
		failed = function(message) 
			errorIntro({message = string.format(Intro.GetLanguage("An error occured while uploading the file. (%s)"), message) })
		end
	})
end

local function download(googleURL, youtubeURL)
	printInfo( Intro.GetLanguage("Downloading the video on the server.") )

	http.Fetch(googleURL,
		-- onSuccess function
		function( body, length, headers, code )
			if ( code == 403 ) then
				errorIntro({message = Intro.GetLanguage("The server IP seems to be banned from the google video services. Please contact the server owner.") })
				return
			end

			if ( code != 200 ) then
				errorIntro({message = string.format(Intro.GetLanguage("An error occured while downloading the file. (%s)"), code) })
				return 
			end

			local fileData = body

			if ( Intro.Settings.DegradeMode ) then
				upload(youtubeURL, fileData, connectWebsite)
			else
				upload(youtubeURL, fileData, function(youtubeURL)
					socket:write("upload_finished")
				end)
			end
		end,

		-- onFailure function
		function( message )
			errorIntro({message = string.format(Intro.GetLanguage("An error occured while downloading the file. (%s)"), message) })
		end
	)
end

local function infos_music(data)
	Intro.Duration = data.duration
end

local function download_url(data)
	download(data.googleURL, data.youtubeURL)
end

local function conversion_started(data)
	printInfo( Intro.GetLanguage("Starting conversion") )
end

local function conversion_progress(data)
	printInfo( string.format(Intro.GetLanguage("Conversion progress"), data.percent) )
end

local function conversion_finished(data)
	printInfo( Intro.GetLanguage("Finished conversion") )
end

local function finished(data)
	if socket then
		socket:close()
	end

	Intro.isloading = false
	Intro.setup_success = true
	Intro.URL = data.url

	printInfo( Intro.GetLanguage("Is ready to be used") )
end

local function connectWebsocket()
	printInfo(Intro.GetLanguage("Connection to the backend"))

	socket = GWSockets.createWebSocket( baseUriWS .. "/get/" .. (Intro.Settings.Map[game.GetMap()].PlayVideo and "webm" or "mp3") )

	function socket:onMessage(txt)
		local data = util.JSONToTable(txt)

		if ensFunctions[data.type] then
			ensFunctions[data.type](data)
		end
	end
	
	function socket:onError(txt)
		errorIntro({message = txt})
	end
	
	function socket:onConnected()
		socket:write(Intro.Settings.Map[game.GetMap()].URLMusic)
	end
	
	function socket:onDisconnected()
		Intro.isloading = false
	end

	socket:open()
end

function Intro.Setup()
	if Intro.isloading or Intro.setup_success then return end

	Intro.isloading = true

	if ( Intro.Settings.DegradeMode ) then
		connectWebsite()
	else
		connectWebsocket()
	end
end

--Need to set it after all functions have been created
ensFunctions = {
	["infos_music"] = infos_music,
	["download_url"] = download_url,
	["conversion_started"] = conversion_started,
	["conversion_progress"] = conversion_progress,
	["conversion_finished"] = conversion_finished,
	["finished"] = finished,
	["error"] = errorIntro,
}

ensFunctionsDegrade = {
	["infos_music"] = infos_music,
	["download_url"] = download_url,
	["finished"] = finished,
	["error"] = errorIntro,
}