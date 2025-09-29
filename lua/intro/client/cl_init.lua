--[[ Cinematic Intro --------------------------------------------------------------------------------------

Cinematic Intro made by Numerix (https://steamcommunity.com/id/numerix/)

--------------------------------------------------------------------------------------------------]]
local colorline_frame = Color( 255, 255, 255, 100 )
local colorbg_frame = Color(52, 55, 64, 200)

local colorline_button = Color( 255, 255, 255, 100 )
local colorbg_button = Color(33, 31, 35, 200)
local color_hover = Color(0, 0, 0, 100)

local color_text = Color(255,255,255,255)

local nombat_vol

Intro.Informations = Intro.Settings.Map[game.GetMap()]

local blur = Material("pp/blurscreen")
local function blurPanel(p, a, h)
    local x, y = p:LocalToScreen(0, 0)
    local scrW, scrH = ScrW(), ScrH()
    surface.SetDrawColor(Color(255, 255, 255, 255))
    surface.SetMaterial(blur)
    for i = 1, (h or 3) do
        blur:SetFloat("$blur", (i/3)*(a or 6))
        blur:Recompute()
        render.UpdateScreenEffectTexture()
        surface.DrawTexturedRect(x*-1,y*-1,scrW,scrH)
    end
end

local BaseIntro
local PanelToReRender = {};
local function HideAllVGUI()
    for key, value in ipairs(vgui.GetAll()) do
        if ( value:GetName() == "DFrame" and value:IsVisible() and value != BaseIntro ) then
            table.insert(PanelToReRender, value)
            value:SetVisible(false)
        end
    end
end

local function ShowAllVGUIHidden()
    if ( timer.Exists("Intro:HideAllVGUI") ) then
        timer.Remove("Intro:HideAllVGUI")
    end

    for key, value in ipairs(PanelToReRender) do
        if ( IsValid(value) ) then
            value:SetVisible(true)
        end
    end

    PanelToReRender = {}
end

local MenuOpen = false
net.Receive("Intro:OpenMenu", function()
    Intro.OpenMenuIntro()
    MenuOpen = true
end)

net.Receive("Intro:Start", function()
    local url      = net.ReadString()
    local duration = net.ReadUInt(16)

    Intro.StartIntro(url, duration)
end)

function Intro.OpenMenuIntro()
    if MenuOpen then return end

    BaseIntro = vgui.Create( "DFrame" )
    BaseIntro:SetPos( 0, 0 )
    BaseIntro:SetSize( ScrW(), ScrH() )
    BaseIntro:SetTitle( "" )
    BaseIntro:SetDraggable( false )
    BaseIntro:ShowCloseButton(false)
    BaseIntro:MakePopup()
    BaseIntro.Paint = function(self, w, h)
        if Intro.Informations.Blur then
            blurPanel(self, 4)
        else
            draw.RoundedBox(0, 0, 0, w, h, Intro.Informations.BGColor)
        end
        draw.SimpleText(Intro.Informations.Title, "Intro.Text", ScrW()/2, ScrH()/10, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local StartButton = vgui.Create( "DButton", BaseIntro )
    StartButton:SetText( Intro.GetLanguage("Start the introduction") )
    StartButton:SetTextColor(Color(255,255,255,255))
    StartButton:SetFont("Intro.Text")
    StartButton:SizeToContentsX(100)
    StartButton:SizeToContentsY(10)					
    StartButton:SetPos( ScrW()/2 - StartButton:GetWide()/2 , ScrH()/2 - StartButton:GetTall()/2 )					
    StartButton.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, colorbg_button)

		surface.SetDrawColor( colorline_button )
		surface.DrawOutlinedRect( 0, 0, w, h )

		if self:IsHovered() or self:IsDown() then
			draw.RoundedBox( 0, 0, 0, w, h, color_hover )
		end	
    end
    StartButton.DoClick = function()
        net.Start("Intro:AskForStart")
        net.SendToServer()

        BaseIntro:Remove()
    end

    if !Intro.Informations.ForceIntro then
        local CloseButton = vgui.Create( "DButton", BaseIntro )
        CloseButton:SetText( Intro.GetLanguage("Skip the introduction") )
        CloseButton:SetTextColor(color_text)
        CloseButton:SetFont("Intro.Text")
        CloseButton:SizeToContentsX(100)
        CloseButton:SizeToContentsY(10)					
        CloseButton:SetPos( ScrW()/2 - CloseButton:GetWide()/2 , ScrH()/1.5 - CloseButton:GetTall()/2 )					
        CloseButton.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, colorbg_button)

            surface.SetDrawColor( colorline_button )
            surface.DrawOutlinedRect( 0, 0, w, h )

            if self:IsHovered() or self:IsDown() then
                draw.RoundedBox( 0, 0, 0, w, h, color_hover )
            end	
        end				
        CloseButton.DoClick = function()				
            BaseIntro:Remove()

            ShowAllVGUIHidden()
        end
    end

    timer.Create("Intro:HideAllVGUI", 0.1, 0, function() HideAllVGUI() end)
end

net.Receive("Intro:Start", function()
    local url      = net.ReadString()
    local duration = net.ReadUInt(16)

    hook.Remove( "CalcView", "zzzzzzzNumerix_CalcView_Intro" )
    hook.Remove( "DrawOverlay", "Intro:DrawOverlay" )
    hook.Remove( "HUDShouldDraw", "Intro:HUDShouldDraw" )

    RunConsoleCommand("cl_drawhud", 0)
    RunConsoleCommand("simple_thirdperson_enabled", 0)
    
    nombat_vol = GetConVar("nombat.volume") and GetConVar("nombat.volume"):GetInt() or 50
    RunConsoleCommand("nombat.volume", 0)

    if Intro.Informations.PlayVideo then
        Intro.PlayVideo(url, duration)
        return
    else
        Intro.PlayMusic(url)
    end

    hook.Add("CalcView", "Intro:CalcView", function(ply, pos, angles, fov)
        if input.IsKeyDown(Intro.Settings.ExitKey) then
            net.Start("Intro:AskForStop")
            net.SendToServer()
        end
    end)

    hook.Add("DrawOverlay", "Intro:DrawOverlay", function()
        draw.RoundedBox(0, 0, 0, ScrW(), Intro.Informations.BlackStripTall(), color_black)
        draw.RoundedBox(0, 0, ScrH() - Intro.Informations.BlackStripTall(), ScrW(), Intro.Informations.BlackStripTall(), color_black)

        local ent = LocalPlayer():GetViewEntity()
        if ( !IsValid(ent) or ent:GetClass() != 'numerix_intro_camera' ) then
            return
        end

        local scene = ent:GetCurrentScene()
        if ( scene == nil ) then
            return
        end

        if ( ent:GetNWBool("showText", true) ) then
            Intro.Informations.HUD(scene.text)
        end

        return false
    end)
    
    hook.Add( "HUDShouldDraw", "Intro:HUDShouldDraw", function(name)    
        return false
    end)

    hook.Call("OnIntroStart", nil, LocalPlayer())
end)

net.Receive("Intro:Stop", function()
    hook.Remove( "CalcView", "Intro:CalcView" )
    hook.Remove( "DrawOverlay", "Intro:DrawOverlay" )
    hook.Remove( "HUDShouldDraw", "Intro:HUDShouldDraw" )

    RunConsoleCommand("stopsound")
    RunConsoleCommand("cl_drawhud", 1)
    RunConsoleCommand("nombat.volume", nombat_vol)

    ShowAllVGUIHidden()

    PanelToReRender = {}

    Intro.StopMusic()

    hook.Call("OnIntroStop", nil, LocalPlayer())
end)

concommand.Add("numerix_addcampos", function(ply)
    if !ply.SecondCommmand then
        ply.FirstPos = ply:GetPos()
        ply.FirstAngle = ply:GetAngles()
        ply.SecondCommmand = true
        print(Intro.GetLanguage("Okay now go where you want the second camera, then re-enter the command."))
    else
        ply.SecondPos = ply:GetPos()
        ply.SecondAngle = ply:GetAngles()
        ply.SecondCommmand = false
        print(Intro.GetLanguage("Insert this in sh_config_custom.lua").." :\n")
        print(" {")
        print("     startpos = Vector("..math.Round(ply.FirstPos[1])..", "..math.Round(ply.FirstPos[2])..", "..math.Round(ply.FirstPos[3]).."),")
        print("     endpos = Vector("..math.Round(ply.SecondPos[1])..", "..math.Round(ply.SecondPos[2])..", "..math.Round(ply.SecondPos[3]).."),")
        print("     startang = Angle("..math.Round(ply.FirstAngle[1])..", "..math.Round(ply.FirstAngle[2])..", "..math.Round(ply.FirstAngle[3]).."),")
        print("     endang = Angle("..math.Round(ply.SecondAngle[1])..", "..math.Round(ply.SecondAngle[2])..", "..math.Round(ply.SecondAngle[3]).."),")
        print('     text = "Text to change",' )   
        print("     speed = 0.2, --Camera speed")
        print("     makefade = false, --Fade in during camera transition?")
        print(" },")

        ply.FirstPos = nil
        ply.FirstAngle = nil
        ply.SecondPos = nil
        ply.SecondAngle = nil
    end
end)