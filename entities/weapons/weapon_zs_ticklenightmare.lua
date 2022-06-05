AddCSLuaFile()

SWEP.PrintName = "The Tickle Nightmare"

SWEP.Base = "weapon_zs_zombie"

SWEP.MeleeDamage = 32
SWEP.MeleeDamageVsProps = 40
SWEP.MeleeReach = 175
SWEP.MeleeSize = 4

local math_random = math.random

function SWEP:Reload()
	self:SecondaryAttack()
end

function SWEP:MeleeHit(ent, trace, damage, forcescale)
	if not ent:IsPlayer() then
		damage = self.MeleeDamageVsProps
	end

	self.BaseClass.MeleeHit(self, ent, trace, damage, forcescale)
end

function SWEP:PlayAlertSound()
	self:GetOwner():EmitSound("npc/barnacle/barnacle_tongue_pull"..math_random(3)..".wav")
end
SWEP.PlayIdleSound = SWEP.PlayAlertSound

function SWEP:PlayAttackSound()
	self:EmitSound("npc/barnacle/barnacle_bark"..math_random(2)..".wav")
end

if not CLIENT then return end

local render_ModelMaterialOverride = render.ModelMaterialOverride
function SWEP:ViewModelDrawn()
	render_ModelMaterialOverride(0)
end

local matSheet = Material("Models/Charple/Charple1_sheet")
function SWEP:PreDrawViewModel(vm)
	render_ModelMaterialOverride(matSheet)
end
