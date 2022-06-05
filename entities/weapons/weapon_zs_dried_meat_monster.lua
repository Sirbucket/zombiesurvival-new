AddCSLuaFile()
local math_random = math.random


SWEP.PrintName = "Meat Monster"

SWEP.Base = "weapon_zs_poisonzombie"

SWEP.MeleeDamage = 32
SWEP.BleedDamageMul = 12 / SWEP.MeleeDamage
SWEP.MeleeDamageVsProps = 54

SWEP.AlertDelay = 2.75

function SWEP:Reload()
	self:SecondaryAttack()
end

function SWEP:SecondaryAttack()
	if CurTime() < self:GetNextSecondaryFire() then return end
	self:SetNextSecondaryFire(CurTime() + self.AlertDelay)

	self:DoAlert()
end

function SWEP:PlayAttackSound()
	self:EmitSound("NPC_PoisonZombie.ThrowWarn.wav", 30, 60)
end

function SWEP:PlayAlertSound()
	self:GetOwner():EmitSound("npc/antlion_guard/angry"..math_random(3)..".wav", 35, 75)
end

function SWEP:MeleeHit(ent, trace, damage, forcescale)
	if not ent:IsPlayer() then
		damage = self.MeleeDamageVsProps
	end

	self.BaseClass.MeleeHit(self, ent, trace, damage, forcescale)
end

function SWEP:ApplyMeleeDamage(ent, trace, damage)
	if SERVER and ent:IsPlayer() then
		local bleed = ent:GiveStatus("bleed")
		if bleed and bleed:IsValid() then
			bleed:AddDamage(damage * self.BleedDamageMul)
			bleed.Damager = self:GetOwner()
		end
	end

	self.BaseClass.ApplyMeleeDamage(self, ent, trace, damage)
end

if not CLIENT then return end

function SWEP:ViewModelDrawn()
	render.ModelMaterialOverride(0)
end

function SWEP:PreDrawViewModel(vm)
	render.SetColorModulation(1, 0, 0)
end
