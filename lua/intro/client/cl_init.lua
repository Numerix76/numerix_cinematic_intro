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

local MenuOpen = false
net.Receive("Intro:OpenMenu", function()
    Intro.OpenMenuIntro()
    MenuOpen = true
end)

net.Receive("Intro:Start", function()
    local url      = net.ReadString()
    local duration = net.ReadUInt(16)

    LocalPlayer():ScreenFade( SCREENFADE.OUT, color_black, 1, 0 )
    timer.Simple(1, function()
        Intro.StartIntro( url, duration )   
    end)
    
end)

local IntroStart
function Intro.OpenMenuIntro()
    if MenuOpen then return end

    local BaseIntro = vgui.Create( "DFrame" )
    BaseIntro:SetPos( 0, 0 )
    BaseIntro:SetSize( ScrW(), ScrH() )
    BaseIntro:SetTitle( "" )
    BaseIntro:SetDraggable( false )
    BaseIntro:ShowCloseButton(false)
    BaseIntro:MakePopup()
    BaseIntro.Think = function(self)
        self:MoveToBack()
    end
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
        net.Start("Intro:StartandStop")
        net.WriteBool(true)
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
        end
    end
end

function Intro.StartIntro(url, duration)
    if !IntroStart then

        hook.Remove( "CalcView", "zzzzzzzNumerix_CalcView_Intro" )
        hook.Remove( "DrawOverlay", "Intro:DrawOverlay" )
        hook.Remove( "HUDShouldDraw", "Intro:HUDShouldDraw" )
        
        IntroStart = true
        
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
        
        --if Intro.Informations.PlayVideo then return end

        LocalPlayer():ScreenFade( SCREENFADE.IN, color_black, 5, 0 )

        local scene = 1
        local fraction = 0
        local returntoply = false
        local fadeout = false
        local fadein = false
        local finalscene = false
        local showtext = true
        hook.Add("CalcView", "zzzzzzzNumerix_CalcView_Intro", function(ply, pos, angles, fov)

            if input.IsKeyDown(Intro.Settings.ExitKey) then
                Intro.EndIntro()
            end
            
            if scene <= #Intro.Informations.Camera then
                
                fraction = math.Clamp(fraction + FrameTime()*Intro.Informations.Camera[scene].speed, 0, 1)
                if fraction == 0 then return end
                
                local view = {}
                view.origin = LerpVector( fraction, Intro.Informations.Camera[scene].startpos, Intro.Informations.Camera[scene].endpos )
                view.angles = LerpAngle(fraction, Intro.Informations.Camera[scene].startang, Intro.Informations.Camera[scene].endang)
                view.fov = fov
                view.drawviewer = true

                local totaldist = Intro.Informations.Camera[scene].startpos:Distance(Intro.Informations.Camera[scene].endpos)
                local actualdist = view.origin:Distance(Intro.Informations.Camera[scene].endpos)
                
                if actualdist < totaldist/2.5*Intro.Informations.Camera[scene].speed/0.2 and !fadeout and Intro.Informations.Camera[scene].makefade then
                    if scene < #Intro.Informations.Camera and !finalscene then
                        ply:ScreenFade( SCREENFADE.OUT, color_black, 1, 1 )
                        fadeout = true

                        timer.Simple(1, function()
                            showtext = false
                        end)

                        timer.Simple(2, function() 
                            fadeout = false
                        end)
                    end
                end
                if view.origin:IsEqualTol( Intro.Informations.Camera[scene].endpos, 5 ) then
                    fraction = 0

                    if scene <= #Intro.Informations.Camera then
                        if !fadein and Intro.Informations.Camera[scene].makefade then
                            ply:ScreenFade( SCREENFADE.IN, color_black, 2, 0 )
                            fadein = true
                            showtext = true
                            
                            timer.Simple(2, function() 
                                fadein = false
                            end)
                        end
                    end

                    scene = scene + 1
                end

                return view
            elseif !returntoply and Intro.Informations.AnimReturnPlayer then
                finalscene = true
                fraction = math.Clamp(fraction + FrameTime()*0.3, 0, 1)
                
                local ang = ply:GetAngles()
                local view = {}
                view.origin = LerpVector( fraction, ply:GetPos() + Vector(0, 0, Intro.Informations.AnimReturnPlayerHigh), ply:GetPos() + Vector(0,0, 100) )
                view.angles = Angle(90,ang.yaw,ang.raw)
                view.fov = fov
                view.drawviewer = true
                
                if view.origin:IsEqualTol( ply:GetPos() + Vector(0,0,100), 5 ) then
                    returntoply = true
                end
                
                return view
            else
                Intro.EndIntro()
            end
        end)

        local text
        hook.Add("DrawOverlay", "Intro:DrawOverlay", function() --aa to be the first HUD executed
            draw.RoundedBox(0, 0, 0, ScrW(), Intro.Informations.BlackStripTall(), color_black)
            draw.RoundedBox(0, 0, ScrH() - Intro.Informations.BlackStripTall(), ScrW(), Intro.Informations.BlackStripTall(), color_black)

            if showtext then
                if scene <= #Intro.Informations.Camera then
                    text =  Intro.Informations.Camera[scene].text
                else
                    text = Intro.Informations.textend
                end

                Intro.Informations.HUD(text)
            end
            return false
        end)
        
        hook.Add( "HUDShouldDraw", "Intro:HUDShouldDraw", function(name)    
            return false
        end)
    end
end

function Intro.EndIntro()
    hook.Remove( "CalcView", "zzzzzzzNumerix_CalcView_Intro" )
    hook.Remove( "DrawOverlay", "Intro:DrawOverlay" )
    hook.Remove( "HUDShouldDraw", "Intro:HUDShouldDraw" )

    net.Start("Intro:StartandStop")
    net.WriteBool(false)
    net.SendToServer()

    RunConsoleCommand("stopsound")
    RunConsoleCommand("cl_drawhud", 1)
    RunConsoleCommand("nombat.volume", nombat_vol)

    Intro.StopMusic()
    IntroStart = false
end

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