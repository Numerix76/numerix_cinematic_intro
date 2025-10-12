include("shared.lua")

function ENT:Initialize()
	self.Entity:SetNoDraw(true)

	self.config = table.Copy(Intro.Settings.Map[game.GetMap()])
	self.scenes = self.config.Camera;

	local ply = LocalPlayer()
	if ( IsValid(ply) ) then
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