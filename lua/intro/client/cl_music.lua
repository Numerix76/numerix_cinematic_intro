--[[ Cinematic Intro --------------------------------------------------------------------------------------

Cinematic Intro made by Numerix (https://steamcommunity.com/id/numerix/)

--------------------------------------------------------------------------------------------------]]
function Intro.PlayMusic(url)

    sound.PlayURL (url, "noplay", function( station )
        if ( IsValid( station ) ) then
            Intro.station = station
            station:Play()
            station:SetVolume(math.Clamp(Intro.Informations.MusicVolume, 0, 1))
        else
            LocalPlayer():IntroChatInfo(Intro.GetLanguage("An error occurred when trying to play music. Please contact server owner if the error persist."), 3)
        end
    end)

end

function Intro.StopMusic()
    if Intro.station and IsValid(Intro.station) then
		Intro.station:Stop()

		Intro.station = nil
	end
end

function Intro.PlayVideo(url, duration)
    Intro.frame = vgui.Create("DHTML")
    Intro.frame:SetPos(0,0)
    Intro.frame:SetSize(ScrW(), ScrH())
    Intro.frame:OpenURL("http://92.222.234.121/video/?url="..url)
    Intro.frame:AddFunction("console", "time", function(str)
        if math.Round(tonumber(str)) >= duration then
            Intro.StopVideo()
        end   
    end)
    Intro.frame:SetAllowLua( true )
    Intro.frame:RunJavascript("vid.volume = "..Intro.Informations.MusicVolume)
    Intro.frame.Think = function()
        if input.IsKeyDown(Intro.Settings.ExitKey) then
            Intro.StopVideo()
        end

        Intro.frame:RunJavascript("console.time(vid.currentTime);")
    end
end

function Intro.StopVideo()
    if IsValid(Intro.frame) then
        Intro.frame:Remove()
    end

    Intro.EndIntro()
end