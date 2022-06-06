CLASS.Base = "freshdead"

CLASS.Name = "Agile Dead"
CLASS.TranslationName = "class_agile_dead"
CLASS.Description = "description_agile_dead"
CLASS.Help = "controls_agile_dead"

CLASS.BetterVersion = "Fast Zombie"

CLASS.SWEP = "weapon_zs_agiledead"

CLASS.Unlocked = true

CLASS.Health = 125
CLASS.Points = CLASS.Health/GM.NoHeadboxZombiePointRatio
CLASS.Speed = 220

CLASS.Hull = {Vector(-16, -16, 0), Vector(16, 16, 58)}
CLASS.HullDuck = {Vector(-16, -16, 0), Vector(16, 16, 32)}
CLASS.ViewOffset = Vector(0, 0, 50)
CLASS.ViewOffsetDucked = Vector(0, 0, 24)

CLASS.UsePlayerModel = true
CLASS.UsePreviousModel = false
local ACT_ZOMBIE_LEAPING = ACT_ZOMBIE_LEAPING
local ACT_HL2MP_RUN_ZOMBIE_FAST = ACT_HL2MP_RUN_ZOMBIE_FAST
local ACT_ZOMBIE_CLIMB_UP = ACT_ZOMBIE_CLIMB_UP
local ACT_GMOD_GESTURE_TAUNT_ZOMBIE = ACT_GMOD_GESTURE_TAUNT_ZOMBIE
local ACT_GMOD_GESTURE_RANGE_ZOMBIE_SPECIAL = ACT_GMOD_GESTURE_RANGE_ZOMBIE_SPECIAL
local ACT_INVALID = ACT_INVALID
local PLAYERANIMEVENT_ATTACK_PRIMARY = PLAYERANIMEVENT_ATTACK_PRIMARY
local PLAYERANIMEVENT_RELOAD = PLAYERANIMEVENT_RELOAD
local GESTURE_SLOT_ATTACK_AND_RELOAD = GESTURE_SLOT_ATTACK_AND_RELOAD

local g_tbl = {
	[1] = ACT_ZOMBIE_LEAPING,
	[2] = ACT_HL2MP_RUN_ZOMBIE_FAST,
	[3] = ACT_ZOMBIE_CLIMB_UP,
	[4] = ACT_GMOD_GESTURE_TAUNT_ZOMBIE,
	[5] = ACT_GMOD_GESTURE_RANGE_ZOMBIE_SPECIAL,
	[6] = ACT_INVALID,
	[7] = PLAYERANIMEVENT_ATTACK_PRIMARY,
	[8] = PLAYERANIMEVENT_RELOAD,
	[9] = GESTURE_SLOT_ATTACK_AND_RELOAD
}


local math_Clamp = math.Clamp
local math_min = math.min

function CLASS:Move(pl, mv)
	local wep = pl:GetActiveWeapon()
	if wep.Move and wep:Move(mv) then
		return true
	end

	if mv:GetForwardSpeed() <= 0 then
		mv:SetMaxSpeed(math_min(mv:GetMaxSpeed(), 120))
		mv:SetMaxClientSpeed(math_min(mv:GetMaxClientSpeed(), 120))
	end
end

function CLASS:ScalePlayerDamage(pl, hitgroup, dmginfo)
	return true
end

function CLASS:IgnoreLegDamage(pl, dmginfo)
	return false
end

function CLASS:CalcMainActivity(pl, velocity)
	local wep = pl:GetActiveWeapon()
	if wep:IsValid() and wep.GetClimbing and wep:GetClimbing() then
		return g_tbl[3], -1
	end

	if not pl:OnGround() or pl:WaterLevel() >= 3 then
		return g_tbl[1], -1
	end

	return g_tbl[2], -1
end

function CLASS:UpdateAnimation(pl, velocity, maxseqgroundspeed)
	local wep = pl:GetActiveWeapon()
	if wep:IsValid() and wep.GetClimbing and wep:GetClimbing() then
		local vel = pl:GetVelocity()
		local speed = vel:LengthSqr()
		if speed > 64 then
			pl:SetPlaybackRate(math_Clamp(speed / 3600, 0, 1) * (vel.z < 0 and -1 or 1) * 0.25)
		else
			pl:SetPlaybackRate(0)
		end

		return true
	end

	if not pl:OnGround() or pl:WaterLevel() >= 3 then
		pl:SetPlaybackRate(1)

		if pl:GetCycle() >= 1 then
			pl:SetCycle(pl:GetCycle() - 1)
		end

		return true
	end
end

function CLASS:DoAnimationEvent(pl, event, data)
	local switch = {
		[g_tbl[7]] = function(pl)
			pl:AnimRestartGesture(g_tbl[9], g_tbl[5], true)
			return g_tbl[6]
		end,
		[g_tbl[8]] = function(pl)
			pl:AnimRestartGesture(g_tbl[9], g_tbl[4], true)
			return g_tbl[6]
		end
	}

	return switch[event] and switch[event](pl)
end

if SERVER then
	function CLASS:AltUse(pl)
        pl:StartFeignDeath()
    end
end

if not CLIENT then return end

CLASS.Icon = "zombiesurvival/killicons/fresh_dead"
