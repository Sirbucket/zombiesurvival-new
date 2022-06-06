CLASS.Name = "Ghoul"
CLASS.TranslationName = "class_ghoul"
CLASS.Description = "description_ghoul"
CLASS.Help = "controls_ghoul"

CLASS.Wave = 0
CLASS.Unlocked = true

CLASS.BetterVersion = "Noxious Ghoul"

CLASS.Health = 210
CLASS.Speed = 175

CLASS.Points = CLASS.Health/GM.HumanoidZombiePointRatio

CLASS.CanTaunt = true

CLASS.SWEP = "weapon_zs_ghoul"

CLASS.Model = Model("models/player/corpse1.mdl")

CLASS.VoicePitch = 0.7

CLASS.CanFeignDeath = true

CLASS.BloodColor = BLOOD_COLOR_YELLOW

CLASS.PainSounds = {"npc/zombie_poison/pz_warn1.wav", "npc/zombie_poison/pz_warn2.wav"}
CLASS.DeathSounds = {"npc/zombie_poison/pz_die2.wav"}

local CurTime = CurTime
local math_random = math.random
local math_max = math.max
local math_min = math.min
local math_ceil = math.ceil

local STEPSOUNDTIME_NORMAL = STEPSOUNDTIME_NORMAL
local STEPSOUNDTIME_WATER_FOOT = STEPSOUNDTIME_WATER_FOOT
local STEPSOUNDTIME_ON_LADDER = STEPSOUNDTIME_ON_LADDER
local STEPSOUNDTIME_WATER_KNEE = STEPSOUNDTIME_WATER_KNEE
local ACT_HL2MP_ZOMBIE_SLUMP_RISE = ACT_HL2MP_ZOMBIE_SLUMP_RISE
local ACT_HL2MP_SWIM_PISTOL = ACT_HL2MP_SWIM_PISTOL
local ACT_HL2MP_IDLE_CROUCH_ZOMBIE = ACT_HL2MP_IDLE_CROUCH_ZOMBIE
local ACT_HL2MP_IDLE_ZOMBIE = ACT_HL2MP_IDLE_ZOMBIE
local ACT_HL2MP_WALK_CROUCH_ZOMBIE_01 = ACT_HL2MP_WALK_CROUCH_ZOMBIE_01
local ACT_HL2MP_WALK_ZOMBIE_01 = ACT_HL2MP_WALK_ZOMBIE_01
local GESTURE_SLOT_ATTACK_AND_RELOAD = GESTURE_SLOT_ATTACK_AND_RELOAD
local PLAYERANIMEVENT_ATTACK_PRIMARY = PLAYERANIMEVENT_ATTACK_PRIMARY
local PLAYERANIMEVENT_RELOAD = PLAYERANIMEVENT_RELOAD
local ACT_GMOD_GESTURE_TAUNT_ZOMBIE = ACT_GMOD_GESTURE_TAUNT_ZOMBIE
local ACT_INVALID = ACT_INVALID

local g_tbl = {
	[1] = STEPSOUNDTIME_NORMAL,
	[2] = STEPSOUNDTIME_WATER_FOOT,
	[3] = STEPSOUNDTIME_ON_LADDER,
	[4] = STEPSOUNDTIME_WATER_KNEE,
	[5] = ACT_HL2MP_ZOMBIE_SLUMP_RISE,
	[6] = ACT_HL2MP_SWIM_PISTOL,
	[7] = ACT_HL2MP_IDLE_CROUCH_ZOMBIE,
	[8] = ACT_HL2MP_IDLE_ZOMBIE,
	[9] = ACT_HL2MP_WALK_CROUCH_ZOMBIE_01,
	[10] = ACT_HL2MP_WALK_ZOMBIE_01,
	[11] = GESTURE_SLOT_ATTACK_AND_RELOAD,
	[12] = PLAYERANIMEVENT_ATTACK_PRIMARY,
	[13] = PLAYERANIMEVENT_RELOAD,
	[14] = ACT_GMOD_GESTURE_TAUNT_ZOMBIE,
	[15] = ACT_INVALID
}

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
		[g_tbl[1]] = function(pl) return 625 - pl:GetVelocity():Length() end,
		[g_tbl[2]] = function(pl) return 625 - pl:GetVelocity():Length() end,
		[g_tbl[3]] = function(pl) return 600 end, 
		[g_tbl[4]] = function(pl) return 750 end
	}

	return switch[iType] and switch[iType](pl) or 450
end

function CLASS:KnockedDown(pl, status, exists)
	pl:AnimResetGestureSlot(g_tbl[11])
end

function CLASS:CalcMainActivity(pl, velocity)
	local feign = pl.FeignDeath
		return g_tbl[5], -1
	end

	if pl:WaterLevel() >= 3 then
		return g_tbl[6], -1
	end

	if velocity:Length2DSqr() <= 1 then
		if pl:Crouching() and pl:OnGround() then
			return g_tbl[7], -1
		end

		return g_tbl[8], -1
	end

	if pl:Crouching() and pl:OnGround() then
		return g_tbl[9] - 1 + math_ceil((CurTime() / 3 + pl:EntIndex()) % 3), -1
	end

	return g_tbl[10] - 1 + math_ceil((CurTime() / 3 + pl:EntIndex()) % 3), -1
end

function CLASS:UpdateAnimation(pl, velocity, maxseqgroundspeed)
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

	local len2d = velocity:Length2D()
	if len2d > 1 then
		pl:SetPlaybackRate(math_min(len2d / maxseqgroundspeed * 0.5, 3))
	else
		pl:SetPlaybackRate(1)
	end

	return true
end

function CLASS:DoAnimationEvent(pl, event, data)
	local switch = {
		[g_tbl[12]] = function(pl, data)
			pl:DoZombieAttackAnim(data)
			return g_tbl[15]
		end,
		[g_tbl[13]] = function(pl, data)
			pl:AnimRestartGesture(g_tbl[11], g_tbl[14], true)
			return g_tbl[15]
		end
	}

	return switch[event] and switch[event](pl, data)
end

function CLASS:DoesntGiveFear(pl)
	return pl.FeignDeath and pl.FeignDeath:IsValid()
end

if SERVER then
	function CLASS:AltUse(pl)
		pl:StartFeignDeath()
	end
end

if not CLIENT then return end

CLASS.Icon = "zombiesurvival/killicons/ghoul"
