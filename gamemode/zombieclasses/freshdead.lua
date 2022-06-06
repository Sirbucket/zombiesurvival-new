CLASS.Name = "Fresh Dead"
CLASS.TranslationName = "class_fresh_dead"
CLASS.Description = "description_fresh_dead"
CLASS.Help = "controls_fresh_dead"

CLASS.Wave = 0
CLASS.Unlocked = true
CLASS.Hidden = true

CLASS.Health = 100
CLASS.Speed = 195

CLASS.Points = CLASS.Health/GM.HumanoidZombiePointRatio

CLASS.CanTaunt = true

CLASS.UsePreviousModel = true

CLASS.SWEP = "weapon_zs_freshdead"

CLASS.PainSounds = {"npc/zombie/zombie_pain1.wav", "npc/zombie/zombie_pain2.wav", "npc/zombie/zombie_pain3.wav", "npc/zombie/zombie_pain4.wav", "npc/zombie/zombie_pain5.wav", "npc/zombie/zombie_pain6.wav"}
CLASS.DeathSounds = {"npc/zombie/zombie_die1.wav", "npc/zombie/zombie_die2.wav", "npc/zombie/zombie_die3.wav"}

CLASS.VoicePitch = 0.65

CLASS.CanFeignDeath = true

local CurTime = CurTime
local math_random = math.random
local math_max = math.max
local math_min = math.min
local math_ceil = math.ceil
local math_Clamp = math.Clamp

local ACT_HL2MP_SWIM_PISTOL = ACT_HL2MP_SWIM_PISTOL
local ACT_HL2MP_RUN_ZOMBIE = ACT_HL2MP_RUN_ZOMBIE
local ACT_GMOD_GESTURE_RANGE_ZOMBIE = ACT_GMOD_GESTURE_RANGE_ZOMBIE
local ACT_HL2MP_ZOMBIE_SLUMP_RISE = ACT_HL2MP_ZOMBIE_SLUMP_RISE
local ACT_HL2MP_IDLE_CROUCH_ZOMBIE = ACT_HL2MP_IDLE_CROUCH_ZOMBIE
local ACT_HL2MP_WALK_CROUCH_ZOMBIE_01 = ACT_HL2MP_WALK_CROUCH_ZOMBIE_01
local PLAYERANIMEVENT_RELOAD = PLAYERANIMEVENT_RELOAD
local ACT_INVALID = ACT_INVALID
local GESTURE_SLOT_ATTACK_AND_RELOAD = GESTURE_SLOT_ATTACK_AND_RELOAD
local ACT_GMOD_GESTURE_TAUNT_ZOMBIE = ACT_GMOD_GESTURE_TAUNT_ZOMBIE
local PLAYERANIMEVENT_ATTACK_PRIMARY = PLAYERANIMEVENT_ATTACK_PRIMARY
local DIR_BACK = DIR_BACK

local g_tbl = {
	[1] = ACT_HL2MP_SWIM_PISTOL,
	[2] = ACT_HL2MP_RUN_ZOMBIE,
	[3] = ACT_GMOD_GESTURE_RANGE_ZOMBIE,
	[4] = ACT_HL2MP_ZOMBIE_SLUMP_RISE,
	[5] = ACT_HL2MP_IDLE_CROUCH_ZOMBIE,
	[6] = ACT_HL2MP_WALK_CROUCH_ZOMBIE_01,
	[7] = ACT_INVALID,
	[8] = GESTURE_SLOT_ATTACK_AND_RELOAD,
	[9] = PLAYERANIMEVENT_RELOAD,
	[10] = ACT_GMOD_GESTURE_TAUNT_ZOMBIE,
	[11] = PLAYERANIMEVENT_ATTACK_PRIMARY
}

function CLASS:PlayerFootstep(pl, vFootPos, iFoot, strSoundName, fVolume, pFilter)
	if iFoot == 0 then
		pl:EmitSound("npc/zombie/foot1.wav", 70)
	else
		pl:EmitSound("npc/zombie/foot2.wav", 70)
	end

	return true
end

function CLASS:CalcMainActivity(pl, velocity)
	local revive = pl.Revive
	if revive and revive:IsValid() then
		return g_tbl[4], -1
	end

	local feign = pl.FeignDeath
	if feign and feign:IsValid() then
		return g_tbl[4], -1
	end

	if pl:WaterLevel() >= 3 then
		return g_tbl[1], -1
	end

	if pl:Crouching() and pl:OnGround() then
		if velocity:Length2DSqr() <= 1 then
			return g_tbl[5], -1
		end

		return g_tbl[6] - 1 + math_ceil((CurTime() / 4 + pl:EntIndex()) % 3), -1
	end

	return g_tbl[2], -1
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

	local len2d = velocity:Length2D()
	if len2d > 1 then
		pl:SetPlaybackRate(math_min(len2d / maxseqgroundspeed, 3))
	else
		pl:SetPlaybackRate(1)
	end

	return true
end

function CLASS:DoAnimationEvent(pl, event, data)
	local switch = {
		[g_tbl[11]] = function(pl, data) 
			pl:DoZombieAttackAnim(data)
			return g_tbl[7]
		end,
		[g_tbl[8]] = function(pl, data)
			pl:AnimRestartGesture(g_tbl[9], g_tbl[10], true)
			return g_tbl[7]
		end
	}
	
	return switch[event] and switch[event](pl, data)
end

function CLASS:DoesntGiveFear(pl)
	return pl.FeignDeath and pl.FeignDeath:IsValid()
end

if SERVER then
	function CLASS:OnKilled(pl, attacker, inflictor, suicide, headshot, dmginfo)
		pl:SetZombieClass(GAMEMODE.DefaultZombieClass)
	end

	function CLASS:AltUse(pl)
		pl:StartFeignDeath()
	end
end

if not CLIENT then return end
local render_SetColorModulation = render.SetColorModulation
CLASS.Icon = "zombiesurvival/killicons/fresh_dead"

function CLASS:PrePlayerDraw(pl)
	render_SetColorModulation(0.5, 0.9, 0.5)
end

function CLASS:PostPlayerDraw(pl)
	render_SetColorModulation(1, 1, 1)
end
