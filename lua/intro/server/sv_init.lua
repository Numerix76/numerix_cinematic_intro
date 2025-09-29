--[[ Cinematic Intro --------------------------------------------------------------------------------------

Cinematic Intro made by Numerix (https://steamcommunity.com/id/numerix/)

--------------------------------------------------------------------------------------------------]]

util.AddNetworkString("Intro:OpenMenu")
util.AddNetworkString("Intro:Start")
util.AddNetworkString("Intro:Stop")
util.AddNetworkString("Intro:StartWithMenu")
util.AddNetworkString("Intro:AskForStart")
util.AddNetworkString("Intro:AskForStop")

hook.Add("PlayerConnect", "Intro:PlayerConnect:Setup", function(ply)
    if Intro.Settings.Map[game.GetMap()] then
        Intro.Setup()
    end
end)

hook.Add("PlayerInitialSpawn", "Intro:PlayerInitialSpawn", function(ply)
    if Intro.Settings.Map[game.GetMap()] and (not file.Exists("numerix_intro/"..game.GetMap().."/player/"..ply:SteamID64()..".txt", "DATA") or Intro.Settings.Map[game.GetMap()].AlwaysShow) then
        net.Start("Intro:OpenMenu")
        net.Send(ply)
    end
end)

hook.Add("PlayerSay", "Intro:PlayerSay", function(ply, text)
    if Intro.Settings.Map[game.GetMap()] and string.sub(text, 1, string.len(Intro.Settings.Commande)) == Intro.Settings.Commande and Intro.Settings.Commande != "" then
        if ply:Alive() then
            Intro.StartIntro(ply)
        end
        return ""
    end
end)

net.Receive("Intro:StartWithMenu", function(len, ply)
    if ply:IsValid() and ply:Alive() then
        Intro.StartIntro(ply, false)
    end
end)

net.Receive("Intro:AskForStart", function(len, ply)    
    if ply:IsValid() and ply:Alive() then
        Intro.StartIntro(ply) 
    end
end)

net.Receive("Intro:AskForStop", function(len, ply)    
    if ply:IsValid() and ply:Alive() then
        Intro.StopIntro(ply)
    end
end)

function Intro.StartIntro(ply)
    if ( !IsValid(ply) ) then
        return
    end

    if !Intro.setup_success then
        ply:IntroChatInfo(Intro.GetLanguage("The addon is not ready actually. Please retry later."), 3)
        return
    end

    if ( ply.InIntro ) then
        return
    end

    ply.InIntro = true

    ply:Lock()

    ply:ScreenFade( SCREENFADE.OUT, color_black, 1, 0 )
        
    timer.Simple(0.9, function()
        ply:ScreenFade( SCREENFADE.IN, color_black, 5, 0 )

        net.Start("Intro:Start")
        net.WriteString(Intro.URL)
        net.WriteUInt(Intro.Duration or 0, 16)
        net.Send(ply)

        hook.Call("OnIntroStart", nil, ply)

        if ( !Intro.Settings.Map[game.GetMap()].PlayVideo ) then
            ply.ViewPointEnt = ents.Create("numerix_intro_camera")
            ply.ViewPointEnt:SetPos(Intro.Settings.Map[game.GetMap()].Camera[1].startpos)
            ply.ViewPointEnt:SetAngles(Intro.Settings.Map[game.GetMap()].Camera[1].startang)
            ply.ViewPointEnt:Spawn()

            ply.ViewPointEnt:SetPlayer(ply)
        end
    end)
end

function Intro.StopIntro(ply)
    if ( !ply.InIntro ) then
        return
    end
       
    ply.InIntro = false

    ply:UnLock()

    if ( IsValid(ply.ViewPointEnt) ) then
        ply.ViewPointEnt:Remove()
    end

    ply.ViewPointEnt = nil

    net.Start("Intro:Stop")
    net.Send(ply)

    hook.Call("OnIntroStop", nil, ply)

    if not file.Exists("numerix_intro/"..game.GetMap().."/player/"..ply:SteamID64()..".txt", "DATA") then
        file.Write("numerix_intro/"..game.GetMap().."/player/"..ply:SteamID64()..".txt", "true")
    end
end

hook.Add("CanPlayerSuicide", "CanPlayerSuicide:DisableSuicideInIntro", function(ply)
    if ply.InIntro then return false end
end)