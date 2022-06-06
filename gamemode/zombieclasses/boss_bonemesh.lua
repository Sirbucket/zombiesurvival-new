CLASS.Name = "Bonemesh"
CLASS.TranslationName = "class_bonemesh"
CLASS.Description = "description_bonemesh"
CLASS.Help = "controls_bonemesh"

CLASS.Boss = true

CLASS.KnockbackScale = 0

CLASS.CanTaunt = true

CLASS.Health = 2000
CLASS.Speed = 195

CLASS.FearPerInstance = 1

CLASS.Points = 35

CLASS.SWEP = "weapon_zs_bonemesh"

CLASS.Model = Model("models/player/zombie_fast.mdl")
CLASS.OverrideModel = Model("models/Zombie/Poison.mdl")

CLASS.VoicePitch = 0.8

CLASS.Hull = {Vector(-16, -16, 0), Vector(16, 16, 58)}
CLASS.HullDuck = {Vector(-16, -16, 0), Vector(16, 16, 32)}
CLASS.ViewOffset = Vector(0, 0, 50)
CLASS.ViewOffsetDucked = Vector(0, 0, 24)

CLASS.PainSounds = {"npc/zombie/zombie_pain1.wav", "npc/zombie/zombie_pain2.wav", "npc/zombie/zombie_pain3.wav", "npc/zombie/zombie_pain4.wav", "npc/zombie/zombie_pain5.wav", "npc/zombie/zombie_pain6.wav"}
CLASS.DeathSounds = {"npc/zombie/zombie_die1.wav", "npc/zombie/zombie_die2.wav", "npc/zombie/zombie_die3.wav"}

local math_random = math.random

local STEPSOUNDTIME_NORMAL = STEPSOUNDTIME_NORMAL
local STEPSOUNDTIME_WATER_FOOT = STEPSOUNDTIME_WATER_FOOT
local STEPSOUNDTIME_ON_LADDER = STEPSOUNDTIME_ON_LADDER
local STEPSOUNDTIME_WATER_KNEE = STEPSOUNDTIME_WATER_KNEE
local ACT_ZOMBIE_LEAPING = ACT_ZOMBIE_LEAPING
local ACT_HL2MP_RUN_ZOMBIE_FAST = ACT_HL2MP_RUN_ZOMBIE_FAST
local PLAYERANIMEVENT_ATTACK_PRIMARY = PLAYERANIMEVENT_ATTACK_PRIMARY
local GESTURE_SLOT_ATTACK_AND_RELOAD = GESTURE_SLOT_ATTACK_AND_RELOAD
local ACT_GMOD_GESTURE_RANGE_ZOMBIE_SPECIAL = ACT_GMOD_GESTURE_RANGE_ZOMBIE_SPECIAL
local ACT_GMOD_GESTURE_TAUNT_ZOMBIE = ACT_GMOD_GESTURE_TAUNT_ZOMBIE
local ACT_INVALID = ACT_INVALID
local PLAYERANIMEVENT_RELOAD = PLAYERANIMEVENT_RELOAD

local g_tbl = {
	[1] = STEPSOUNDTIME_NORMAL,
	[2] = STEPSOUNDTIME_WATER_FOOT,
	[3] = STEPSOUNDTIME_ON_LADDER,
	[4] = STEPSOUNDTIME_WATER_KNEE,
	[5] = ACT_ZOMBIE_LEAPING,
	[6] = ACT_HL2MP_RUN_ZOMBIE_FAST,
	[7] = PLAYERANIMEVENT_ATTACK_PRIMARY,
	[8] = GESTURE_SLOT_ATTACK_AND_RELOAD,
	[9] = ACT_GMOD_GESTURE_RANGE_ZOMBIE_SPECIAL,
	[10] = ACT_GMOD_GESTURE_TAUNT_ZOMBIE,
	[11] = ACT_INVALID,
	[12] = PLAYERANIMEVENT_RELOAD
}

function CLASS:PlayerFootstep(pl, vFootPos, iFoot, strSoundName, fVolume, pFilter)
	if iFoot == 0 then
		pl:EmitSound("npc/antlion_guard/foot_light1.wav", 70, math_random(115, 120))
	else
		pl:EmitSound("npc/antlion_guard/foot_light2.wav", 70, math_random(115, 120))
	end

	return true
end

function CLASS:PlayerStepSoundTime(pl, iType, bWalking)
	local switch = {
		[g_tbl[1]] = function(pl) return 450 - pl:GetVelocity():Length() end,
		[g_tbl[2]] = function(pl) return 450 - pl:GetVelocity():Length() end,
		[g_tbl[3]] = function(pl) return 400 end,
		[g_tbl[4]] = function(pl) return 550 end
	}
	
	return switch[iType] and switch[iType](pl) or 250
end

function CLASS:CalcMainActivity(pl, velocity)
	if not pl:OnGround() or pl:WaterLevel() >= 3 then
		return g_tbl[5], -1
	end

	return g_tbl[6], -1
end

function CLASS:UpdateAnimation(pl, velocity, maxseqgroundspeed)
	if not pl:OnGround() or pl:WaterLevel() >= 3 then
		pl:SetPlaybackRate(1)

		if pl:GetCycle() >= 1 then
			pl:SetCycle(pl:GetCycle() - 1)
		end

		return true
	end
end

function CLASS:ScalePlayerDamage(pl, hitgroup, dmginfo)
	return true
end

function CLASS:IgnoreLegDamage(pl, dmginfo)
	return false
end

function CLASS:DoAnimationEvent(pl, event, data)
	local switch = {
		[g_tbl[7]] = function(pl) 
			pl:AnimRestartGesture(g_tbl[8], g_tbl[9], true)
			return g_tbl[11]
		end,
		[g_tbl[12]] = function(pl)
			pl:AnimRestartGesture(g_tbl[8], g_tbl[10], true)
			return g_tbl[11]
		end
	}

	return switch[event] and switch[event](pl)
end

if SERVER then
	function CLASS:OnSpawned(pl)
		pl:CreateAmbience("bonemeshambience")
	end
end

if not CLIENT then return end

CLASS.Icon = "zombiesurvival/killicons/bonemesh"
