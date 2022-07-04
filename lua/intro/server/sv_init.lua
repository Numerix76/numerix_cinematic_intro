--[[ Cinematic Intro --------------------------------------------------------------------------------------

Cinematic Intro made by Numerix (https://steamcommunity.com/id/numerix/)

--------------------------------------------------------------------------------------------------]]

util.AddNetworkString("Intro:OpenMenu")
util.AddNetworkString("Intro:Start")
util.AddNetworkString("Intro:StartWithMenu")
util.AddNetworkString("Intro:StartandStop")

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
            Intro.StartIntro(ply, true)
        end
        return ""
    end
end)

net.Receive("Intro:StartWithMenu", function(len, ply)
    if ply:IsValid() and ply:Alive() then
        Intro.StartIntro(ply, false)
    end
end)

net.Receive("Intro:StartandStop", function(len, ply)
    local start = net.ReadBool()
    
    if ply:IsValid() and ply:Alive() then
        if start then
            Intro.StartIntro(ply, false) 
        else
            Intro.StopIntro(ply)
        end
    end
end)

function Intro.StartIntro(ply, command)
    if !Intro.setup_success then
        ply:IntroChatInfo(Intro.GetLanguage("The addon is not ready actually. Please retry later."), 3)
        return
    end

    if !ply.InIntro then
        
        ply.InIntro = true
        
        ply.FreezeProps = ents.Create( "prop_physics" )
        if ( !IsValid( ply.FreezeProps ) ) then return end
        ply.FreezeProps:SetModel( "models/props_wasteland/laundry_dryer001.mdl" )
        ply.FreezeProps:SetPos( ply:GetPos() + Vector(0,0,50))
        ply.FreezeProps:Spawn()
        ply.FreezeProps:PhysicsDestroy()
        ply.FreezeProps:SetNoDraw( true )

        ply:GodEnable()

        ply.Weapons = {}
        
        for k, v in pairs(ply:GetWeapons()) do
            table.insert(ply.Weapons, v:GetClass())
            ply:StripWeapon(v:GetClass())
        end
    
        net.Start("Intro:Start")
        net.WriteString(Intro.URL)
        net.WriteUInt(Intro.Duration or 0, 16)
        net.Send(ply)
    end
end

function Intro.StopIntro(ply)
    if ply.InIntro then

        for k, v in pairs(ply.Weapons) do
            ply:Give(v)
        end
        
        ply.InIntro = false

        if IsValid(ply.FreezeProps) then
            ply.FreezeProps:Remove()
            ply.FreezeProps = nil
        end

        ply:GodDisable()

        if not file.Exists("numerix_intro/"..game.GetMap().."/player/"..ply:SteamID64()..".txt", "DATA") then
            file.Write("numerix_intro/"..game.GetMap().."/player/"..ply:SteamID64()..".txt", "true")
        end
    end
end

hook.Add("CanPlayerSuicide", "CanPlayerSuicide:DisableSuicideInIntro", function(ply)
    if ply.InIntro then return false end
end)

hook.Add("PlayerDisconnected", "Intro:PlayerDisconnected", function(ply)
    if IsValid(ply.FreezeProps) then
        ply.FreezeProps:Remove()
        ply.FreezeProps = nil
    end
end)