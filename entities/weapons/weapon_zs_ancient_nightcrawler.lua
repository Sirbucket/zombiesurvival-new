AddCSLuaFile()

SWEP.Base = "weapon_zs_zombie"

SWEP.PrintName = "Ancient Nightcrawler"

SWEP.MeleeDelay = 0.25
SWEP.MeleeReach = 64
SWEP.MeleeDamage = 50
SWEP.SwingAnimSpeed = 3

SWEP.DelayWhenDeployed = true

function SWEP:Reload()
	self:SecondaryAttack()
end

function SWEP:StartMoaning()
end

function SWEP:StopMoaning()
end

function SWEP:IsMoaning()
	return false
end
