
SWEP.Base = "weapon_ttt_knife"


if SERVER then
	AddCSLuaFile()
end

if CLIENT then

	function SWEP:Draw()
		local lply = LocalPlayer()
		if not lply then return end

		if lply == self.unaware then
			self:DrawModel()
		end
	end

end