CLASS.Name = "Skeletal Walker"
CLASS.TranslationName = "class_skeletal_walker"
CLASS.Description = "description_skeletal_walker"
CLASS.Help = "controls_skeletal_walker"

CLASS.Wave = 2 / 6

CLASS.Health = 100
CLASS.Speed = 150

CLASS.CanTaunt = true

CLASS.Points = CLASS.Health/GM.SkeletonPointRatio

CLASS.SWEP = "weapon_zs_skeleton"

CLASS.BetterVersion = "Skeletal Shambler"

CLASS.Model = Model("models/player/skeleton.mdl")

CLASS.VoicePitch = 0.8

CLASS.CanFeignDeath = true

CLASS.BloodColor = -1

CLASS.Skeletal = true
CLASS.SkeletalRes = true
CLASS.PainSounds = {"npc/metropolice/pain1.wav", "npc/metropolice/pain2.wav", "npc/metropolice/pain3.wav", "npc/metropolice/pain4.wav"}
CLASS.DeathSounds = {"npc/zombie/zombie_die1.wav", "npc/zombie/zombie_die2.wav", "npc/zombie/zombie_die3.wav"}
local math_random = math.random
local math_min = math.min
local math_max = math.max
local string_format = string.format

local CurTime = CurTime

local ACT_HL2MP_ZOMBIE_SLUMP_RISE = ACT_HL2MP_ZOMBIE_SLUMP_RISE
local ACT_HL2MP_SWIM_PISTOL = ACT_HL2MP_SWIM_PISTOL
local ACT_HL2MP_IDLE_CROUCH_FIST = ACT_HL2MP_IDLE_CROUCH_FIST
local ACT_HL2MP_IDLE_KNIFE = ACT_HL2MP_IDLE_KNIFE
local ACT_HL2MP_WALK_CROUCH_KNIFE = ACT_HL2MP_WALK_CROUCH_KNIFE
local ACT_HL2MP_RUN_KNIFE = ACT_HL2MP_RUN_KNIFE
local ACT_HL2MP_WALK_ZOMBIE_01 = ACT_HL2MP_WALK_ZOMBIE_01
local GESTURE_SLOT_ATTACK_AND_RELOAD = GESTURE_SLOT_ATTACK_AND_RELOAD
local PLAYERANIMEVENT_ATTACK_PRIMARY = PLAYERANIMEVENT_ATTACK_PRIMARY

local g_tbl = {
	[1] = ACT_HL2MP_ZOMBIE_SLUMP_RISE,
	[2] = ACT_HL2MP_SWIM_PISTOL,
	[3] = ACT_HL2MP_IDLE_CROUCH_FIST,
	[4] = ACT_HL2MP_IDLE_KNIFE,
	[5] = ACT_HL2MP_WALK_CROUCH_KNIFE,
	[6] = ACT_HL2MP_RUN_KNIFE,
	[7] = GESTURE_SLOT_ATTACK_AND_RELOAD,
	[8] = PLAYERANIMEVENT_ATTACK_PRIMARY,
	[9] = PLAYERANIMEVENT_RELOAD,
	[10] = ACT_GMOD_GESTURE_TAUNT_ZOMBIE,
	[11] = ACT_INVALID
}

function CLASS:KnockedDown(pl, status, exists)
	pl:AnimResetGestureSlot(g_tbl[7])
end

function CLASS:PlayerFootstep(pl, vFootPos, iFoot, strSoundName, fVolume, pFilter)
	if iFoot == 0 then
		pl:EmitSound("npc/barnacle/neck_snap1.wav", 65, math_random(135, 150), 0.27)
	else
		pl:EmitSound("npc/barnacle/neck_snap2.wav", 65, math_random(135, 150), 0.27)
	end

	return true
end

function CLASS:CalcMainActivity(pl, velocity)
	local feign = pl.FeignDeath
	if feign and feign:IsValid() then
		return g_tbl[1], -1
	end

	if pl:WaterLevel() >= 3 then
		return g_tbl[2], -1
	end

	if velocity:Length2DSqr() <= 1 then
		if pl:Crouching() and pl:OnGround() then
			return g_tbl[3], -1 
		end

		return g_tbl[4], -1 
	end

	if pl:Crouching() and pl:OnGround() then
		return g_tbl[5], -1 
	end

	return g_tbl[6], -1 
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

	local len = velocity:Length()
	if len > 1 then
		pl:SetPlaybackRate(math_min(len / maxseqgroundspeed, 3))
	else
		pl:SetPlaybackRate(1)
	end

	return true
end

function CLASS:DoAnimationEvent(pl, event, data)
	local switch = {
		[g_tbl[8]] = function(pl, data)
			pl:DoZombieAttackAnim(data)
			return g_tbl[11]
		end,
		[g_tbl[9]] = function(pl, data)
			pl:AnimRestartGesture(g_tbl[7], g_tbl[10], true)
			return g_tbl[11]
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

	function CLASS:ProcessDamage(pl, dmginfo)
		local inflictor = dmginfo:GetInflictor()
	
		if not IsValid(inflictor) then return end
		local mul = 1
		local bullet = inflictor.IsBullet
		local melee = inflictor.IsMelee
		local bleed = inflictor.IsBleed
		
		if melee then
			mul = 1.25
		end
		if bullet then
			mul = 0.5
		end
		if bleed then
			mul = 0
		end

		dmginfo:SetDamage(dmginfo:GetDamage() * mul)
	end
end

if not CLIENT then return end

CLASS.Icon = "zombiesurvival/killicons/skeletal_walker"

