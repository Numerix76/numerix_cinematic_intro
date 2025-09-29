AddCSLuaFile("cl_init.lua") 
AddCSLuaFile("shared.lua") 
include("shared.lua")

local CAMERA_MODEL = Model("models/hunter/blocks/cube025x025x025.mdl")

ENT.PhysShadowControl = {}
ENT.PhysShadowControl.secondstoarrive  = .01
ENT.PhysShadowControl.pos              = Vector(0, 0, 0)
ENT.PhysShadowControl.angle            = Angle(0, 0, 0)
ENT.PhysShadowControl.maxspeed         = 1000000
ENT.PhysShadowControl.maxangular       = 1000000
ENT.PhysShadowControl.maxspeeddamp     = 1000000
ENT.PhysShadowControl.maxangulardamp   = 1000000
ENT.PhysShadowControl.dampfactor       = 1
ENT.PhysShadowControl.teleportdistance = 0
ENT.PhysShadowControl.deltatime        = deltatime

function ENT:Initialize() 
	self.Entity:SetModel(CAMERA_MODEL)
	self.Entity:PhysicsInit(SOLID_VPHYSICS)
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
	self.Entity:SetSolid(SOLID_NONE)
	self.Entity:SetColor(Color(255,255,255,0))
	self.Entity:DrawShadow(false)
	
	self.Entity:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	
	self.Entity:SetColor(Color(0, 0, 0, 100))
	
	local phys = self:GetPhysicsObject()
	
	if phys and phys:IsValid() then
		phys:Wake()
	end

	self:SetNWInt("scene", 1)
	self:SetNWFloat("percentage", 0)
	self:SetNWBool("fading", false)
	self:SetNWBool("showText", true)
	self.player = nil

	self.config = table.Copy(Intro.Settings.Map[game.GetMap()])
	self.scenes = self.config.Camera;
	
	return self:StartMotionController()
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end

function ENT:CalcPerc()
	local scene = self:GetCurrentScene()
	
	self:SetNWFloat("percentage", math.Clamp(self:GetNWFloat("percentage", 0) + FrameTime()*scene.speed, 0, 1))
	
	local totalDistance = scene.startpos:Distance(scene.endpos)
    local currentDistance = self:GetPos():Distance(scene.endpos)
                
    if currentDistance < totalDistance/2.5*scene.speed/0.2 and !self:GetNWBool("fading", false) and scene.makefade then
		self:SetNWBool("fading", true)
		if ( IsValid(self.player) ) then
			self.player:ScreenFade(SCREENFADE.OUT, color_black, 1, 1)

			timer.Simple(1, function()
				self:SetNWBool("showText", false)
			end)

			timer.Simple(1.9, function()
				if ( IsValid(self.player) ) then
					self.player:ScreenFade(SCREENFADE.IN, color_black, 2, 0)

					self:SetNWBool("showText", true)

					timer.Simple(2, function() self:SetNWBool("fading", false) end)
				end
			end)
		end
	end
	
	if self:GetNWFloat("percentage", 0) >= 1 then
		self:SetNWFloat("percentage", 0)

		self:SetNWInt("scene", self:GetNWInt("scene", 1) + 1)
	end
end

function ENT:PhysicsSimulate(phys, deltatime)
	self:CalcPerc()
	phys:Wake()

	local scene = self:GetCurrentScene()
	if ( scene == nil ) then
		self:Remove()

		return
	end

	self.PhysShadowControl.pos = LerpVector(self:GetNWFloat("percentage", 0), scene.startpos, scene.endpos)
	self.PhysShadowControl.angle = LerpAngle(self:GetNWFloat("percentage", 0), scene.startang, scene.endang)
	self.PhysShadowControl.deltatime = deltatime

	-- si le percentage = 0 c'est qu'on a changé de scène, on doit donc TP la caméra
	if ( self:GetNWFloat("percentage", 0) == 0 ) then
		self.PhysShadowControl.teleportdistance = 1
		self.PhysShadowControl.deltatime = 0
	else
		self.PhysShadowControl.teleportdistance = 0
	end

	return phys:ComputeShadowControl(self.PhysShadowControl)
end

function ENT:SetPlayer(ply)
	self.player = ply

	if ( IsValid(ply) ) then
		ply:SetViewEntity(self.Entity)

		local plyPos = ply:GetPos()
		local plyAng = ply:GetAngles()

		if ( self.config.AnimReturnPlayer ) then
			table.insert(self.scenes, {
				startpos = plyPos + Vector(0, 0, self.config.AnimReturnPlayerHigh), 
				endpos = plyPos + Vector(0, 0, 100),
				startang = Angle(90, plyAng.yaw, plyAng.raw),
				endang = Angle(90, plyAng.yaw, plyAng.raw),
				text = self.config.textend,
				speed = self.config.Speedback,
				makefade = false,
			})
		end
	end
end

function ENT:OnRemove()
	if ( IsValid(self.player) ) then
		Intro.StopIntro(self.player)
		self.player:SetViewEntity(self.player)
	end
end
