CLASS.Name = "Zombie"
CLASS.TranslationName = "class_zombie"
CLASS.Description = "description_zombie"
CLASS.Help = "controls_zombie"

CLASS.BetterVersion = "Eradicator"

CLASS.Wave = 0
CLASS.Unlocked = true
CLASS.IsDefault = true
CLASS.Order = 0

CLASS.Health = 225
CLASS.Speed = 175
CLASS.Revives = true

CLASS.CanTaunt = true

CLASS.Points = CLASS.Health/GM.HumanoidZombiePointRatio

CLASS.SWEP = "weapon_zs_zombie"

CLASS.Model = Model("models/player/zombie_classic_hbfix.mdl")

CLASS.PainSounds = {"npc/zombie/zombie_pain1.wav", "npc/zombie/zombie_pain2.wav", "npc/zombie/zombie_pain3.wav", "npc/zombie/zombie_pain4.wav", "npc/zombie/zombie_pain5.wav", "npc/zombie/zombie_pain6.wav"}
CLASS.DeathSounds = {"npc/zombie/zombie_die1.wav", "npc/zombie/zombie_die2.wav", "npc/zombie/zombie_die3.wav"}

CLASS.VoicePitch = 0.65

CLASS.CanFeignDeath = true

local CurTime = CurTime
local math_random = math.random
local math_ceil = math.ceil
local math_Clamp = math.Clamp
local math_min = math.min
local math_max = math.max
local ACT_HL2MP_ZOMBIE_SLUMP_RISE = ACT_HL2MP_ZOMBIE_SLUMP_RISE
local ACT_HL2MP_SWIM_PISTOL = ACT_HL2MP_SWIM_PISTOL
local ACT_HL2MP_RUN_ZOMBIE = ACT_HL2MP_RUN_ZOMBIE
local ACT_HL2MP_IDLE_CROUCH_ZOMBIE = ACT_HL2MP_IDLE_CROUCH_ZOMBIE
local ACT_HL2MP_IDLE_ZOMBIE = ACT_HL2MP_IDLE_ZOMBIE
local ACT_HL2MP_WALK_CROUCH_ZOMBIE_01 = ACT_HL2MP_WALK_CROUCH_ZOMBIE_01
local ACT_HL2MP_WALK_ZOMBIE_01 = ACT_HL2MP_WALK_ZOMBIE_01
local GESTURE_SLOT_ATTACK_AND_RELOAD = GESTURE_SLOT_ATTACK_AND_RELOAD
local PLAYERANIMEVENT_ATTACK_PRIMARY = PLAYERANIMEVENT_ATTACK_PRIMARY
local ACT_GMOD_GESTURE_RANGE_ZOMBIE = ACT_GMOD_GESTURE_RANGE_ZOMBIE
local ACT_INVALID = ACT_INVALID
local PLAYERANIMEVENT_RELOAD = PLAYERANIMEVENT_RELOAD
local ACT_GMOD_GESTURE_TAUNT_ZOMBIE = ACT_GMOD_GESTURE_TAUNT_ZOMBIE
local STEPSOUNDTIME_NORMAL = STEPSOUNDTIME_NORMAL
local STEPSOUNDTIME_WATER_FOOT = STEPSOUNDTIME_WATER_FOOT
local STEPSOUNDTIME_ON_LADDER = STEPSOUNDTIME_ON_LADDER
local STEPSOUNDTIME_WATER_KNEE = STEPSOUNDTIME_WATER_KNEE
local HITGROUP_HEAD = HITGROUP_HEAD
local HITGROUP_LEFTLEG = HITGROUP_LEFTLEG
local HITGROUP_RIGHTLEG = HITGROUP_RIGHTLEG
local DMG_ALWAYSGIB = DMG_ALWAYSGIB
local DMG_BURN = DMG_BURN
local DMG_CRUSH = DMG_CRUSH
local DIR_BACK = DIR_BACK
local bit_band = bit.band

local g_tbl = {
	[1] = ACT_HL2MP_ZOMBIE_SLUMP_RISE,
	[2] = ACT_HL2MP_SWIM_PISTOL,
	[3] = ACT_HL2MP_RUN_ZOMBIE,
	[4] = ACT_HL2MP_IDLE_CROUCH_ZOMBIE,
	[5] = ACT_HL2MP_IDLE_ZOMBIE,
	[6] = ACT_HL2MP_WALK_CROUCH_ZOMBIE_01,
	[7] = ACT_HL2MP_WALK_ZOMBIE_01,
	[8] = GESTURE_SLOT_ATTACK_AND_RELOAD,
	[9] = PLAYERANIMEVENT_ATTACK_PRIMARY,
	[10] = ACT_GMOD_GESTURE_RANGE_ZOMBIE,
	[11] = ACT_INVALID,
	[12] = PLAYERANIMEVENT_RELOAD,
	[13] = ACT_GMOD_GESTURE_TAUNT_ZOMBIE,
	[14] = STEPSOUNDTIME_NORMAL,
	[15] = STEPSOUNDTIME_WATER_FOOT,
	[16] = STEPSOUNDTIME_ON_LADDER,
	[17] = STEPSOUNDTIME_WATER_KNEE
}

function CLASS:KnockedDown(pl, status, exists)
	pl:AnimResetGestureSlot(g_tbl[8])
end

function CLASS:PlayerFootstep(pl, vFootPos, iFoot, strSoundName, fVolume, pFilter)
	if iFoot == 0 then
		pl:EmitSound("npc/zombie/foot1.wav", 70)
	else
		pl:EmitSound("npc/zombie/foot2.wav", 70)
	end

	return true
end

function CLASS:PlayerStepSoundTime(pl, iType, bWalking)
	local switch = {
		[g_tbl[14]] = function(pl) return 625 - pl:GetVelocity():Length() end,
		[g_tbl[15]] = function(pl) return 625 - pl:GetVelocity():Length() end,
		[g_tbl[16]] = function(pl) return 600 end, 
		[g_tbl[17]] = function(pl) return 750 end
	}

	return switch[iType] and switch[iType](pl) or 450
end

function CLASS:CalcMainActivity(pl, velocity)
	local revive = pl.Revive
	if revive and revive:IsValid() then
		return g_tbl[1], -1
	end

	local feign = pl.FeignDeath
	if feign and feign:IsValid() then
		return g_tbl[1], -1
	end

	if pl:WaterLevel() >= 3 then
		return g_tbl[2], -1
	end

	local wep = pl:GetActiveWeapon()
	if wep:IsValid() and wep.IsMoaning and wep:IsMoaning() then
		return g_tbl[3], -1
	end

	if velocity:Length2DSqr() <= 1 then
		if pl:Crouching() and pl:OnGround() then
			return g_tbl[4], -1
		end

		return g_tbl[5], -1
	end

	if pl:Crouching() and pl:OnGround() then
		return g_tbl[6] - 1 + math_ceil((CurTime() / 4 + pl:EntIndex()) % 3), -1
	end

	return g_tbl[7] - 1 + math_ceil((CurTime() / 3 + pl:EntIndex()) % 3), -1
end

function CLASS:UpdateAnimation(pl, velocity, maxseqgroundspeed)
	local revive = pl.Revive
	if revive and revive:IsValid() then
		pl:SetCycle(0.4 + (1 - math_Clamp((revive:GetReviveTime() - CurTime()) / revive.AnimTime, 0, 1)) * 0.6)
		pl:SetPlaybackRate(0)
		return true
	end

	local feign = pl.FeignDeath
	if feign and feign:IsValid() then
		if feign:GetState() == 1 then
			pl:SetCycle(1 - math_max(feign:GetStateEndTime() - CurTime(), 0) * 0.666)
		else
			pl:SetCycle(math_max(feign:GetStateEndTime() - CurTime(), 0) * 0.666)
		end
		pl:SetPlaybackRate(0)
		return true
	end

	local len2d = velocity:Length()
	if len2d > 1 then
		local wep = pl:GetActiveWeapon()
		if wep:IsValid() and wep.IsMoaning and wep:IsMoaning() then
			pl:SetPlaybackRate(math_min(len2d / maxseqgroundspeed, 3))
		else
			pl:SetPlaybackRate(math_min(len2d / maxseqgroundspeed * 0.666, 3))
		end
	else
		pl:SetPlaybackRate(1)
	end

	return true
end

function CLASS:DoAnimationEvent(pl, event, data)
	local switch = {
		[g_tbl[9]] = function(pl, data)
			pl:DoZombieAttackAnim(data)
			return g_tbl[11]
		end,
		[g_tbl[12]] = function(pl, data)
			pl:AnimRestartGesture(g_tbl[8], g_tbl[13], true)
			return g_tbl[11]
		end
	}

	return switch[event] and switch[event](pl, data)
end

function CLASS:DoesntGiveFear(pl)
	return pl.FeignDeath and pl.FeignDeath:IsValid()
end

if SERVER then
	local timer_Simple = timer.Simple
	function CLASS:AltUse(pl)
		pl:StartFeignDeath()
	end

	function CLASS:ProcessDamage(pl, dmginfo)
		local damage = dmginfo:GetDamage()
		if damage >= 70 or damage < pl:Health() then return end

		local attacker, inflictor = dmginfo:GetAttacker(), dmginfo:GetInflictor()
		if attacker == pl or not attacker:IsPlayer() or inflictor.IsMelee or inflictor.NoReviveFromKills then return end

		local hitgroup = pl:LastHitGroup()
		if pl:WasHitInHead() or pl:GetStatus("shockdebuff") or hitgroup == HITGROUP_LEFTLEG or hitgroup == HITGROUP_RIGHTLEG then return end

		local dmgtype = dmginfo:GetDamageType()
		if bit_band(dmgtype, DMG_ALWAYSGIB) ~= 0 or bit_band(dmgtype, DMG_BURN) ~= 0 or bit_band(dmgtype, DMG_CRUSH) ~= 0 then return end

		if pl.FeignDeath and pl.FeignDeath:IsValid() then return end

		if CurTime() < (pl.NextZombieRevive or 0) then return end
		pl.NextZombieRevive = CurTime() + 3

		dmginfo:SetDamage(0)
		pl:SetHealth(10)

		local status = pl:GiveStatus("revive_slump")
		if status then
			status:SetReviveTime(CurTime() + 2.25)
			status:SetReviveHeal(10)
		end

		return true
	end

	function CLASS:ReviveCallback(pl, attacker, dmginfo)
		if not pl:ShouldReviveFrom(dmginfo) then return false end

		local classtable = math_random(3) == 3 and GAMEMODE.ZombieClasses["Zombie Legs"] or GAMEMODE.ZombieClasses["Zombie Torso"]
		if classtable then
			pl:RemoveStatus("overridemodel", false, true)
			local deathclass = pl.DeathClass or pl:GetZombieClass()
			pl:SetZombieClass(classtable.Index)
			pl:DoHulls(classtable.Index, TEAM_UNDEAD)
			pl.DeathClass = deathclass

			pl:EmitSound("physics/flesh/flesh_bloody_break.wav", 100, 75)

			if classtable == GAMEMODE.ZombieClasses["Zombie Torso"] then
				local ent = ents.Create("prop_dynamic_override")
				if ent:IsValid() then
					ent:SetModel(Model("models/Zombie/Classic_legs.mdl"))
					ent:SetPos(pl:GetPos())
					ent:SetAngles(pl:GetAngles())
					ent:Spawn()
					ent:Fire("kill", "", 1.5)
				end
			end

			pl:Gib()
			pl.Gibbed = nil

			timer_Simple(0, function()
				if pl:IsValid() then
					pl:SecondWind()
				end
			end)

			return true
		end

		return false
	end

	function CLASS:OnSecondWind(pl)
		pl:EmitSound("npc/zombie/zombie_voice_idle"..math_random(14)..".wav", 100, 85)
	end
end

if CLIENT then
	CLASS.Icon = "zombiesurvival/killicons/zombie"
end
